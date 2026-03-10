#!/usr/bin/env bash
# BarcaTeam — Dev Environment Manager
# Starts/stops the str_simulation server and runs investFlorida.ai demos.
#
# Usage:
#   ./dev-env.sh server start        Start str_simulation API server (background)
#   ./dev-env.sh server stop         Stop the server
#   ./dev-env.sh server status       Check if server is running
#   ./dev-env.sh report [ARGS]       Run demo_e2e.py with given args
#   ./dev-env.sh test [REPO]         Run pytest on a repo (investflorida|str_simulation)
#   ./dev-env.sh check               Verify all environments are set up
#
# Examples:
#   ./dev-env.sh server start
#   ./dev-env.sh report --property biscayne --no-browser
#   ./dev-env.sh report --property biscayne --no-cache --report-version v2
#   ./dev-env.sh test investflorida
#   ./dev-env.sh test str_simulation
#
# Environment:
#   CONDA_ROOT    Miniconda install path (default: /mnt/c/Users/$WSLUSER/miniconda3)
#   WSLUSER       Windows username (default: auto-detected from /mnt/c/Users/)
#   REPOS_DIR     Repos directory (default: ~/repos)

set -euo pipefail

# --- Config ---
REPOS_DIR="${REPOS_DIR:-$HOME/repos}"
SERVER_REPO="$REPOS_DIR/str_simulation"
CLIENT_REPO="$REPOS_DIR/investFlorida.ai"
SERVER_PID_FILE="/tmp/str_simulation_server.pid"
SERVER_LOG="/tmp/str_simulation_server.log"
SERVER_PORT=8000

# Auto-detect Windows user
if [ -z "${WSLUSER:-}" ]; then
    WSLUSER=$(ls /mnt/c/Users/ | grep -v -E '^(Public|Default|All Users|Default User|desktop.ini)$' | head -1)
fi
CONDA_ROOT="${CONDA_ROOT:-/mnt/c/Users/$WSLUSER/miniconda3}"

# Conda Python paths
PYTHON_CLIENT="$CONDA_ROOT/envs/investflorida/python.exe"
PYTHON_SERVER="$CONDA_ROOT/envs/str_simulation/python.exe"

# --- Functions ---

check_env() {
    local ok=true
    echo "Checking dev environment..."
    echo ""

    # Check repos
    for repo in "$SERVER_REPO" "$CLIENT_REPO"; do
        if [ -d "$repo" ]; then
            echo "  [OK] Repo: $repo"
        else
            echo "  [FAIL] Repo not found: $repo"
            ok=false
        fi
    done

    # Check conda envs
    if [ -x "$PYTHON_CLIENT" ]; then
        ver=$("$PYTHON_CLIENT" --version 2>&1)
        echo "  [OK] investflorida conda env: $ver"
    else
        echo "  [FAIL] investflorida conda env not found at $PYTHON_CLIENT"
        echo "         Fix: conda create -n investflorida python=3.12 && conda activate investflorida && pip install -r $CLIENT_REPO/requirements.txt"
        ok=false
    fi

    if [ -x "$PYTHON_SERVER" ]; then
        ver=$("$PYTHON_SERVER" --version 2>&1)
        echo "  [OK] str_simulation conda env: $ver"
    else
        echo "  [FAIL] str_simulation conda env not found at $PYTHON_SERVER"
        echo "         Fix: conda create -n str_simulation python=3.12 && conda activate str_simulation && pip install -r $SERVER_REPO/requirements.txt"
        ok=false
    fi

    # Check server status
    echo ""
    server_status

    echo ""
    if $ok; then
        echo "All checks passed."
    else
        echo "Some checks failed. See above for fixes."
        return 1
    fi
}

server_status() {
    if [ -f "$SERVER_PID_FILE" ]; then
        pid=$(cat "$SERVER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Server: RUNNING (PID $pid, port $SERVER_PORT, log: $SERVER_LOG)"
            return 0
        else
            echo "  Server: STALE PID file (process $pid not running)"
            rm -f "$SERVER_PID_FILE"
            return 1
        fi
    else
        echo "  Server: NOT RUNNING"
        return 1
    fi
}

server_start() {
    # Check if already running
    if [ -f "$SERVER_PID_FILE" ] && kill -0 "$(cat "$SERVER_PID_FILE")" 2>/dev/null; then
        echo "Server already running (PID $(cat "$SERVER_PID_FILE"))"
        return 0
    fi

    if [ ! -x "$PYTHON_SERVER" ]; then
        echo "ERROR: str_simulation conda env not found. Run: ./dev-env.sh check"
        return 1
    fi

    echo "Starting str_simulation server on port $SERVER_PORT..."
    cd "$SERVER_REPO"
    "$PYTHON_SERVER" run.py > "$SERVER_LOG" 2>&1 &
    local pid=$!
    echo "$pid" > "$SERVER_PID_FILE"

    # Wait for startup (up to 60s)
    echo -n "Waiting for server"
    for i in $(seq 1 60); do
        if curl -s "http://127.0.0.1:$SERVER_PORT/health" >/dev/null 2>&1; then
            echo ""
            echo "Server started (PID $pid, port $SERVER_PORT)"
            echo "Logs: $SERVER_LOG"
            return 0
        fi
        echo -n "."
        sleep 1
    done

    echo ""
    echo "WARNING: Server process started (PID $pid) but health check not responding."
    echo "This is expected in WSL2 — the server binds to Windows localhost."
    echo "The investflorida client (also Windows Python) CAN reach it at 127.0.0.1:$SERVER_PORT."
    echo "WSL curl cannot reach Windows-bound ports directly."
    echo ""
    echo "Check logs: tail -f $SERVER_LOG"
    return 0
}

server_stop() {
    if [ -f "$SERVER_PID_FILE" ]; then
        pid=$(cat "$SERVER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping server (PID $pid)..."
            kill "$pid" 2>/dev/null
            sleep 2
            kill -9 "$pid" 2>/dev/null || true
            echo "Server stopped."
        else
            echo "Server not running (stale PID file)."
        fi
        rm -f "$SERVER_PID_FILE"
    else
        echo "No PID file found. Server may not be running."
        # Try to find and kill by port
        local pids=$(ps aux | grep "run.py" | grep -v grep | awk '{print $2}')
        if [ -n "$pids" ]; then
            echo "Found server process(es): $pids"
            echo "$pids" | xargs kill 2>/dev/null || true
        fi
    fi
}

run_report() {
    if [ ! -x "$PYTHON_CLIENT" ]; then
        echo "ERROR: investflorida conda env not found. Run: ./dev-env.sh check"
        return 1
    fi

    # Auto-start server if not running
    if ! ([ -f "$SERVER_PID_FILE" ] && kill -0 "$(cat "$SERVER_PID_FILE")" 2>/dev/null); then
        echo "Server not running. Starting it first..."
        server_start
        echo ""
    fi

    echo "Running report: $PYTHON_CLIENT demos/demo_e2e.py $*"
    echo ""
    cd "$CLIENT_REPO"
    "$PYTHON_CLIENT" demos/demo_e2e.py "$@"
}

run_tests() {
    local repo="${1:-investflorida}"
    case "$repo" in
        investflorida|investFlorida.ai|client)
            echo "Running investFlorida.ai tests..."
            cd "$CLIENT_REPO"
            "$PYTHON_CLIENT" -m pytest tests/ -x --tb=short -q "$@"
            ;;
        str_simulation|server)
            echo "Running str_simulation tests..."
            cd "$SERVER_REPO"
            "$PYTHON_SERVER" -m pytest tests/ -x --tb=short -q "$@"
            ;;
        *)
            echo "Unknown repo: $repo. Use: investflorida, str_simulation"
            return 1
            ;;
    esac
}

# --- Main ---

case "${1:-help}" in
    server)
        case "${2:-status}" in
            start)  server_start ;;
            stop)   server_stop ;;
            status) server_status ;;
            log|logs) tail -f "$SERVER_LOG" ;;
            *)      echo "Usage: $0 server {start|stop|status|logs}" ;;
        esac
        ;;
    report)
        shift
        run_report "$@"
        ;;
    test)
        shift
        run_tests "$@"
        ;;
    check)
        check_env
        ;;
    help|--help|-h)
        head -17 "$0" | tail -16
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage."
        exit 1
        ;;
esac
