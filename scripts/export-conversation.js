#!/usr/bin/env node
/**
 * export-conversation.js — Export Claude Code conversation messages to markdown on clipboard
 *
 * Usage:
 *   node scripts/export-conversation.js                    # latest conversation (current project)
 *   node scripts/export-conversation.js <session-id>       # specific session
 *   node scripts/export-conversation.js --last N           # last N messages (default: all)
 *   node scripts/export-conversation.js --range 5-15       # messages 5 through 15
 *   node scripts/export-conversation.js --project <name>   # specific project slug
 *   node scripts/export-conversation.js --list             # list recent conversations
 *   node scripts/export-conversation.js --file out.md      # write to file instead of clipboard
 *   node scripts/export-conversation.js --no-tools         # omit tool call/result details
 *   node scripts/export-conversation.js --compact          # user/assistant text only, no metadata
 */

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const CLAUDE_DIR = path.join(
  process.env.HOME || process.env.USERPROFILE,
  ".claude"
);
const PROJECTS_DIR = path.join(CLAUDE_DIR, "projects");

// --- Arg parsing ---
const args = process.argv.slice(2);
function getFlag(name) {
  const i = args.indexOf(name);
  if (i === -1) return null;
  args.splice(i, 1);
  return true;
}
function getArg(name) {
  const i = args.indexOf(name);
  if (i === -1) return null;
  const val = args[i + 1];
  args.splice(i, 2);
  return val;
}

const listMode = getFlag("--list");
const compact = getFlag("--compact");
const noTools = getFlag("--no-tools");
const lastN = getArg("--last");
const range = getArg("--range");
const projectSlug = getArg("--project");
const outFile = getArg("--file");
const sessionArg = args[0];

// --- Find project dir ---
function findProjectDir() {
  if (projectSlug) {
    const candidates = fs.readdirSync(PROJECTS_DIR);
    const match = candidates.find(
      (c) => c.toLowerCase().includes(projectSlug.toLowerCase()) && !c.includes("memory")
    );
    if (match) return path.join(PROJECTS_DIR, match);
    console.error(`No project matching "${projectSlug}" found.`);
    console.error("Available:", candidates.join(", "));
    process.exit(1);
  }
  // Default: detect from cwd — build the expected slug
  const cwd = process.cwd().replace(/\\/g, "/");
  const slug = cwd.replace(/^([A-Z]):/, "$1-").replace(/\//g, "-");  // C:/Users/foo -> C--Users-foo
  const candidates = fs.readdirSync(PROJECTS_DIR);
  // Exact slug match first, then partial
  const exactMatch = candidates.find((c) => c === slug);
  if (exactMatch) return path.join(PROJECTS_DIR, exactMatch);
  // Longest prefix match (prefer C--Users-rbarcelo-repo-barcaTeam over shorter)
  const prefixMatches = candidates
    .filter((c) => slug.startsWith(c) || c === slug.replace(/^([A-Z])-/, "$1--"))
    .sort((a, b) => b.length - a.length);
  if (prefixMatches.length) return path.join(PROJECTS_DIR, prefixMatches[0]);
  // Fallback: basename match
  const baseMatch = candidates.find((c) => c.endsWith(path.basename(cwd)));
  if (baseMatch) return path.join(PROJECTS_DIR, baseMatch);
  // Fallback: most recently modified
  const dirs = candidates
    .map((c) => ({ name: c, dir: path.join(PROJECTS_DIR, c) }))
    .filter((d) => fs.statSync(d.dir).isDirectory())
    .sort((a, b) => fs.statSync(b.dir).mtimeMs - fs.statSync(a.dir).mtimeMs);
  return dirs[0]?.dir;
}

const projectDir = findProjectDir();
if (!projectDir) {
  console.error("Could not determine project directory.");
  process.exit(1);
}

// --- List conversations ---
function listConversations() {
  const files = fs
    .readdirSync(projectDir)
    .filter((f) => f.endsWith(".jsonl"))
    .map((f) => {
      const fpath = path.join(projectDir, f);
      const stat = fs.statSync(fpath);
      // Read first user message for preview
      const lines = fs.readFileSync(fpath, "utf8").trim().split("\n");
      let preview = "";
      for (const line of lines) {
        try {
          const obj = JSON.parse(line);
          if (obj.type === "user" && typeof obj.message?.content === "string") {
            preview = obj.message.content.substring(0, 80);
            break;
          }
        } catch {}
      }
      return {
        id: f.replace(".jsonl", ""),
        modified: stat.mtime,
        size: stat.size,
        preview,
      };
    })
    .sort((a, b) => b.modified - a.modified);

  console.log(`\nConversations in: ${path.basename(projectDir)}\n`);
  files.slice(0, 20).forEach((f, i) => {
    const date = f.modified.toISOString().replace("T", " ").substring(0, 16);
    const sizeKB = Math.round(f.size / 1024);
    console.log(
      `  ${i + 1}. [${date}] ${sizeKB}KB  ${f.id.substring(0, 8)}...`
    );
    if (f.preview) console.log(`     "${f.preview}"`);
  });
  console.log(
    "\nUse: node export-conversation.js <session-id> to export one."
  );
}

if (listMode) {
  listConversations();
  process.exit(0);
}

// --- Find conversation file ---
function findConversation() {
  if (sessionArg) {
    const files = fs.readdirSync(projectDir).filter((f) => f.endsWith(".jsonl"));
    const match = files.find((f) => f.startsWith(sessionArg));
    if (match) return path.join(projectDir, match);
    console.error(`No conversation starting with "${sessionArg}".`);
    process.exit(1);
  }
  // Latest
  const files = fs
    .readdirSync(projectDir)
    .filter((f) => f.endsWith(".jsonl"))
    .map((f) => ({
      name: f,
      mtime: fs.statSync(path.join(projectDir, f)).mtimeMs,
    }))
    .sort((a, b) => b.mtime - a.mtime);
  return path.join(projectDir, files[0].name);
}

const convFile = findConversation();
const convId = path.basename(convFile, ".jsonl");

// --- Parse conversation ---
function parseConversation(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim().split("\n");
  const messages = [];

  for (const line of raw) {
    try {
      const obj = JSON.parse(line);
      if (obj.type === "file-history-snapshot" || obj.type === "progress" || obj.type === "queue-operation") continue;

      const msg = obj.message;
      if (!msg) continue;

      const role = obj.type === "user" ? "user" : obj.type === "assistant" ? "assistant" : obj.type;
      const timestamp = obj.timestamp;

      if (role === "user") {
        if (typeof msg.content === "string") {
          messages.push({ role: "user", text: msg.content, timestamp });
        } else if (Array.isArray(msg.content)) {
          // Tool results from user turns
          for (const block of msg.content) {
            if (block.type === "tool_result") {
              const resultText =
                typeof block.content === "string"
                  ? block.content
                  : Array.isArray(block.content)
                  ? block.content
                      .filter((c) => c.type === "text")
                      .map((c) => c.text)
                      .join("\n")
                  : "";
              if (resultText && !noTools) {
                messages.push({
                  role: "tool_result",
                  toolUseId: block.tool_use_id,
                  text: resultText,
                  timestamp,
                  isError: block.is_error,
                });
              }
            }
          }
        }
      } else if (role === "assistant") {
        if (Array.isArray(msg.content)) {
          for (const block of msg.content) {
            if (block.type === "text" && block.text?.trim()) {
              messages.push({ role: "assistant", text: block.text, timestamp });
            } else if (block.type === "tool_use" && !noTools) {
              const toolName = block.name;
              const input = block.input || {};
              let summary = "";
              if (toolName === "Bash") {
                summary = `\`$ ${input.command || ""}\``;
              } else if (toolName === "Read") {
                summary = `Read \`${input.file_path || ""}\``;
              } else if (toolName === "Write") {
                summary = `Write \`${input.file_path || ""}\``;
              } else if (toolName === "Edit") {
                summary = `Edit \`${input.file_path || ""}\``;
              } else if (toolName === "Glob") {
                summary = `Glob \`${input.pattern || ""}\``;
              } else if (toolName === "Grep") {
                summary = `Grep \`${input.pattern || ""}\``;
              } else if (toolName === "Agent") {
                summary = `Agent: ${input.description || input.prompt?.substring(0, 60) || ""}`;
              } else {
                summary = `${toolName}(${JSON.stringify(input).substring(0, 100)})`;
              }
              messages.push({
                role: "tool_call",
                tool: toolName,
                id: block.id,
                text: summary,
                timestamp,
              });
            }
          }
        }
      }
    } catch {}
  }
  return messages;
}

// --- Format as Markdown ---
function formatMarkdown(messages) {
  // Apply range/last filters
  let filtered = messages;
  if (range) {
    const [start, end] = range.split("-").map(Number);
    // Filter to user-visible message indices
    let visibleIdx = 0;
    filtered = messages.filter((m) => {
      if (m.role === "user" || m.role === "assistant") {
        visibleIdx++;
        return visibleIdx >= start && visibleIdx <= end;
      }
      return false; // skip tools when using range
    });
  } else if (lastN) {
    // Take last N user/assistant exchanges
    const n = parseInt(lastN);
    const visible = messages.filter(
      (m) => m.role === "user" || m.role === "assistant"
    );
    const keep = visible.slice(-n);
    const keepTimestamps = new Set(keep.map((m) => m.timestamp));
    filtered = messages.filter(
      (m) =>
        keepTimestamps.has(m.timestamp) ||
        (m.role === "tool_call" && !noTools) ||
        (m.role === "tool_result" && !noTools)
    );
    // Actually, just take the last N visible messages and their tools
    const lastVisible = visible.slice(-n);
    if (lastVisible.length > 0) {
      const minTs = lastVisible[0].timestamp;
      filtered = messages.filter((m) => m.timestamp >= minTs);
    }
  }

  const lines = [];
  lines.push(`# Conversation Export`);
  lines.push(`**Session:** \`${convId.substring(0, 8)}...\``);
  lines.push(
    `**Exported:** ${new Date().toISOString().replace("T", " ").substring(0, 19)}`
  );
  lines.push(`**Project:** ${path.basename(projectDir)}`);
  lines.push("");
  lines.push("---");
  lines.push("");

  let msgNum = 0;

  for (const msg of filtered) {
    if (compact && msg.role !== "user" && msg.role !== "assistant") continue;

    if (msg.role === "user") {
      msgNum++;
      const ts = msg.timestamp
        ? new Date(msg.timestamp).toISOString().replace("T", " ").substring(11, 19)
        : "";
      lines.push(`## User ${compact ? "" : `[${ts}]`}`);
      lines.push("");
      lines.push(msg.text);
      lines.push("");
    } else if (msg.role === "assistant") {
      const ts = msg.timestamp
        ? new Date(msg.timestamp).toISOString().replace("T", " ").substring(11, 19)
        : "";
      lines.push(`## Assistant ${compact ? "" : `[${ts}]`}`);
      lines.push("");
      lines.push(msg.text);
      lines.push("");
    } else if (msg.role === "tool_call") {
      lines.push(`> **Tool:** ${msg.text}`);
      lines.push("");
    } else if (msg.role === "tool_result") {
      const truncated =
        msg.text.length > 500 ? msg.text.substring(0, 500) + "\n... (truncated)" : msg.text;
      const label = msg.isError ? "Error" : "Result";
      lines.push(`> <details><summary>${label}</summary>`);
      lines.push(">");
      lines.push(`> \`\`\``)
      lines.push(`> ${truncated.split("\n").join("\n> ")}`);
      lines.push(`> \`\`\``);
      lines.push(`> </details>`);
      lines.push("");
    }
  }

  return lines.join("\n");
}

// --- Main ---
const messages = parseConversation(convFile);
const md = formatMarkdown(messages);

if (outFile) {
  fs.writeFileSync(outFile, md, "utf8");
  console.log(`Exported ${messages.length} messages to ${outFile}`);
} else {
  // Copy to clipboard — Windows: clip, macOS: pbcopy, Linux: xclip
  try {
    if (process.platform === "win32") {
      // Use PowerShell Set-Clipboard for Unicode support
      execSync("powershell.exe -NoProfile -Command Set-Clipboard -Value $input", {
        input: md,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } else if (process.platform === "darwin") {
      execSync("pbcopy", { input: md });
    } else {
      execSync("xclip -selection clipboard", { input: md });
    }
    const userMsgCount = messages.filter((m) => m.role === "user").length;
    const assistantMsgCount = messages.filter((m) => m.role === "assistant").length;
    console.log(
      `Copied to clipboard: ${userMsgCount} user + ${assistantMsgCount} assistant messages (${md.length} chars)`
    );
  } catch (e) {
    // Fallback: write to temp file
    const tmpFile = path.join(
      process.env.TEMP || "/tmp",
      `claude-export-${Date.now()}.md`
    );
    fs.writeFileSync(tmpFile, md, "utf8");
    console.log(`Clipboard failed. Written to: ${tmpFile}`);
  }
}
