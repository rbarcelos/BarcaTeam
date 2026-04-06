# Security Audit

Structured security review for the full application stack. Used by the `security-reviewer` agent.

## Trigger

Used by agents with `security-audit` in their skills list, or when security review is requested.

## Procedure

### STEP 1: ENUMERATE ATTACK SURFACE

```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai

# API endpoints
grep -rn "@router\.\(get\|post\|put\|delete\|patch\)" apps/ --include="*.py"

# External API integrations
grep -rn "httpx\|requests\|fetch\|axios" apps/ packages/ --include="*.py" --include="*.ts" | grep -v "__pycache__\|node_modules"

# Database operations
grep -rn "\.execute\|\.executemany\|conn\." apps/ --include="*.py" | head -30

# Environment variables / secrets
grep -rn "os\.environ\|os\.getenv\|env\.\|process\.env" apps/ packages/ frontend/ --include="*.py" --include="*.ts" --include="*.tsx" | grep -v "node_modules\|__pycache__"
```

### STEP 2: SECRETS SCAN

```bash
# Hardcoded secrets (high signal patterns)
grep -rn "sk-\|pk_\|api_key.*=.*['\"]" apps/ packages/ frontend/ --include="*.py" --include="*.ts" --include="*.tsx" | grep -v "node_modules\|__pycache__\|\.env"

# Check .gitignore covers sensitive files
cat .gitignore | grep -i "env\|secret\|key\|credential\|token"

# Check if .env exists and is gitignored
ls -la .env* 2>/dev/null
git status .env* 2>/dev/null

# Secrets in logs
grep -rn "logger\.\(info\|debug\|warning\|error\)" apps/ --include="*.py" | grep -i "key\|token\|secret\|password" | head -10
```

### STEP 3: INJECTION CHECKS

#### SQL Injection
```bash
# Find raw SQL (non-parameterized)
grep -rn "f\".*SELECT\|f\".*INSERT\|f\".*UPDATE\|f\".*DELETE\|\.format.*SELECT" apps/ --include="*.py"

# Verify parameterized queries
grep -rn "\.execute(" apps/ --include="*.py" | head -20
```

#### XSS
```bash
# Check for dangerouslySetInnerHTML (React)
grep -rn "dangerouslySetInnerHTML\|__html" frontend/ --include="*.tsx" --include="*.ts"

# Check for unescaped user content in templates
grep -rn "{{ \|{%.*raw\|safe\|markup" packages/reports/templates/ --include="*.html" | head -20
```

#### Prompt Injection
```bash
# Read system prompts
cat apps/chat/prompts/agent_system.md | head -50

# Check if user messages are sanitized before LLM calls
grep -rn "user_message\|user_input\|message.*content" apps/chat/ --include="*.py" | head -20
```

### STEP 4: AUTH & ACCESS CONTROL

```bash
# Check for authentication middleware/dependencies
grep -rn "Depends\|middleware\|auth\|authenticate\|authorize" apps/ --include="*.py" | head -20

# Check if session/workspace access is scoped
grep -rn "session_id\|workspace_id" apps/chat/api/ --include="*.py" | head -20

# Check CORS configuration
grep -rn "CORS\|cors\|Access-Control\|allow_origins" apps/ --include="*.py"
```

### STEP 5: DATA HANDLING

```bash
# Check what's stored in SQLite
grep -rn "CREATE TABLE\|INSERT INTO" apps/ --include="*.py" | head -20

# Check for PII in logs
grep -rn "logger\.\(info\|debug\)" apps/ --include="*.py" | grep -i "address\|email\|name\|phone" | head -10

# Check data retention / cleanup
grep -rn "DELETE FROM\|cleanup\|expire\|retention\|purge" apps/ --include="*.py" | head -10
```

### STEP 6: DEPENDENCY AUDIT

```bash
# Check Python dependencies for known vulnerabilities
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null | head -50

# Check Node dependencies
cat frontend/package.json | grep -A 5 "dependencies"
```

### STEP 7: SECURITY HEADERS

```bash
# Check for security headers in middleware
grep -rn "X-Frame-Options\|X-Content-Type-Options\|Strict-Transport\|Content-Security-Policy\|X-XSS-Protection" apps/ --include="*.py"

# Check for HTTPS enforcement
grep -rn "https\|ssl\|tls\|redirect.*http" apps/ --include="*.py" | head -10
```

### STEP 8: PRODUCE FINDINGS

Write findings using the security-reviewer's output format (see agent config). Include OWASP category and estimated CVSS where applicable.

## Risk Classification

| Severity | Examples |
|----------|---------|
| **Critical** | Hardcoded API keys in code, SQL injection in parameterized queries, auth bypass |
| **High** | XSS in report generation, prompt injection that leaks system prompt, broken access control between sessions |
| **Medium** | Missing security headers, overly permissive CORS, sensitive data in debug logs |
| **Low** | Outdated but unexploitable dependency, missing rate limiting on non-critical endpoints |

## Rules

- Every finding must reference specific code (file:line)
- Distinguish between exploitable vulnerabilities and theoretical risks
- Always check the full context — a finding in isolation may not be exploitable
- Prioritize findings that could affect financial data integrity
- LLM-specific risks (prompt injection, data exfiltration) are as important as traditional web risks
- Don't recommend enterprise solutions for an early-stage product — right-size the fix
