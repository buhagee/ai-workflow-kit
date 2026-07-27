#!/usr/bin/env bun
import { existsSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import {
  hookPath,
  projectDir,
  runtimeEnvironment,
  stringValue,
  toolInput,
  RUNTIME_HARNESS_ROOT,
} from "./aidlc-copilot-runtime.ts";

const target = process.argv[2] ?? "";
let input: Record<string, unknown> = {};
try {
  input = JSON.parse(readFileSync(0, "utf-8")) as Record<string, unknown>;
} catch {
  process.exit(0);
}
const project = projectDir(stringValue(input.cwd) || undefined);
const env = runtimeEnvironment(project);

function runCore(hook: string, payload: Record<string, unknown>, captureStderr = false): number {
  const result = spawnSync(process.execPath, [hookPath(hook)], {
    cwd: project,
    env,
    input: JSON.stringify(payload),
    encoding: "utf-8",
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (captureStderr && result.stderr) process.stderr.write(result.stderr);
  return result.status ?? 0;
}

function canonicalTool(name: string): "Bash" | "Write" | "Edit" | "TaskUpdate" | "Task" | "" {
  if (["run_in_terminal", "run_terminal", "terminal", "bash", "execute_bash", "shell"].includes(name)) return "Bash";
  if (["create_file", "write_file", "fs_write"].includes(name)) return "Write";
  if (["replace_string_in_file", "edit_file", "apply_patch", "str_replace", "fs_append"].includes(name)) return "Edit";
  if (["update_todo", "update_plan", "todo_list"].includes(name)) return "TaskUpdate";
  if (["runSubagent", "run_subagent", "subagent", "task"].includes(name)) return "Task";
  return "";
}

function commandFrom(inputValue: Record<string, unknown>): string {
  return stringValue(inputValue.command) || stringValue(inputValue.cmd) || stringValue(inputValue.script) || stringValue(inputValue.text);
}

function fileFrom(inputValue: Record<string, unknown>): string {
  return stringValue(inputValue.file_path) || stringValue(inputValue.filePath) || stringValue(inputValue.path) || stringValue(inputValue.uri);
}

function coreInput(tool: "Bash" | "Write" | "Edit" | "TaskUpdate" | "Task"): Record<string, unknown> {
  const rawToolInput = toolInput(input);
  const payload: Record<string, unknown> = {
    hook_event_name: stringValue(input.hook_event_name),
    tool_name: tool,
    tool_input: {},
  };
  if (tool === "Bash") payload.tool_input = { command: commandFrom(rawToolInput) };
  else if (tool === "Write" || tool === "Edit") payload.tool_input = { file_path: fileFrom(rawToolInput) };
  else if (tool === "TaskUpdate") payload.tool_input = { task: rawToolInput.task ?? rawToolInput.plan ?? rawToolInput };
  else payload.tool_input = rawToolInput;
  return payload;
}

async function blockWhileGateIsOpen(): Promise<boolean> {
  try {
    const lib = await import(pathToFileURL(join(RUNTIME_HARNESS_ROOT, "tools", "aidlc-lib.ts")).href);
    const statePath = lib.stateFilePath(project);
    const content = existsSync(statePath) ? readFileSync(statePath, "utf-8") : null;
    if (lib.isAutonomousMode(content) || lib.humanPresenceGuardDisabled() || !lib.hasOpenGate(content)) return false;
    if (lib.humanActedSinceGate(project)) return false;
    process.stderr.write(
      "An AI-DLC approval gate is open and requires a human turn before another tool call proceeds. " +
        "Answer the gate, then continue the workflow.\n",
    );
    return true;
  } catch {
    return false;
  }
}

if (target === "session-start") {
  const code = runCore("aidlc-session-start.ts", { hook_event_name: "SessionStart", source: "startup" });
  process.exit(code);
}

if (target === "mint") {
  process.exit(runCore("aidlc-mint-presence.ts", { hook_event_name: "UserPromptSubmit" }));
}

if (target === "pretool") {
  const tool = canonicalTool(stringValue(input.tool_name));
  if (!tool) {
    process.exit(0);
    return;
  }
  const guardCode = runCore("aidlc-state-transition-guard.ts", coreInput(tool), true);
  if (guardCode !== 0) process.exit(guardCode);
  if (await blockWhileGateIsOpen()) process.exit(2);
  process.exit(0);
}

if (target === "posttool") {
  const tool = canonicalTool(stringValue(input.tool_name));
  if (!tool) {
    process.exit(0);
    return;
  }
  if ((tool === "Write" || tool === "Edit") && fileFrom(toolInput(input))) {
    const payload = coreInput(tool);
    runCore("aidlc-audit-logger.ts", payload);
    runCore("aidlc-sensor-fire.ts", payload);
  }
  if (tool === "Bash") {
    runCore("aidlc-runtime-compile.ts", {
      hook_event_name: "PostToolUse",
      tool_name: "Bash",
      tool_input: { command: "", source: "ide-audit-sync" },
    });
  }
  if (tool === "TaskUpdate") runCore("aidlc-sync-statusline.ts", coreInput(tool));
  if (tool === "Task") {
    runCore("aidlc-log-subagent.ts", {
      hook_event_name: "SubagentStop",
      agent_type: stringValue(input.agent_type) || "unknown",
      last_assistant_message: stringValue(input.tool_response) || stringValue(input.result),
    });
  }
  process.exit(0);
}

if (target === "subagent-stop") {
  process.exit(runCore("aidlc-log-subagent.ts", {
    hook_event_name: "SubagentStop",
    agent_type: stringValue(input.agent_type) || "unknown",
    last_assistant_message: stringValue(input.last_assistant_message) || stringValue(input.result) || stringValue(input.tool_response),
  }));
}

if (target === "precompact") {
  process.exit(runCore("aidlc-validate-state.ts", { hook_event_name: "PreCompact" }));
}

if (target === "stop") {
  const temp = spawnSync(process.execPath, [hookPath("aidlc-stop.ts")], {
    cwd: project,
    env,
    input: JSON.stringify({ hook_event_name: "Stop", stop_hook_active: false }),
    encoding: "utf-8",
  });
  if (temp.stderr) process.stderr.write(temp.stderr);
  if (temp.stdout?.trim()) {
    try {
      const value = JSON.parse(temp.stdout) as { decision?: string; reason?: string };
      if (value.decision === "block") {
        process.stdout.write(JSON.stringify({ continue: false, stopReason: value.reason ?? "AI-DLC workflow still has pending work." }) + "\n");
      }
    } catch {
      process.stdout.write(temp.stdout);
    }
  }
  process.exit(temp.status ?? 0);
}

process.stderr.write(`Unknown AI-DLC Copilot hook target: ${target}\n`);
process.exit(2);
