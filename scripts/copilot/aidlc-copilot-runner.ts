#!/usr/bin/env bun
import { spawnSync } from "node:child_process";
import { ensureProjectData, parseProjectArg, runtimeEnvironment, projectDir, toolPath } from "./aidlc-copilot-runtime.ts";

function rewriteCopilotSurfaceText(text: string): string {
  return text
    .replace(
      /bun \.claude\/tools\/aidlc-orchestrate\.ts/g,
      'bun "$HOME/.copilot/aidlc/aidlc-copilot-runner.ts" orchestrate',
    )
    .replace(
      /bun \.claude\/tools\/([A-Za-z0-9._-]+\.ts)/g,
      'bun "$HOME/.copilot/aidlc/aidlc-copilot-runner.ts" tool $1',
    )
    .replace(/\.claude\//g, "$HOME/.copilot/aidlc/runtime/.claude/");
}

function rewriteOutput(output: string): string {
  const hadTrailingNewline = output.endsWith("\n");
  const trimmed = output.trim();
  if (!trimmed) return output;

  // Keep orchestrate JSON directives valid by rewriting the parsed message.
  try {
    const parsed: unknown = JSON.parse(trimmed);
    if (
      parsed !== null &&
      typeof parsed === "object" &&
      "message" in parsed &&
      typeof (parsed as { message: unknown }).message === "string"
    ) {
      const withRewrittenMessage = {
        ...(parsed as Record<string, unknown>),
        message: rewriteCopilotSurfaceText((parsed as { message: string }).message),
      };
      const serialized = JSON.stringify(withRewrittenMessage);
      return hadTrailingNewline ? `${serialized}\n` : serialized;
    }
  } catch {
    // Not a directive JSON payload - fall through to plain-text rewrite.
  }

  return rewriteCopilotSurfaceText(output);
}

const args = process.argv.slice(2);
const project = parseProjectArg(args);
ensureProjectData(project);

let tool = "";
let forwarded: string[] = [];
if (args[0] === "orchestrate") {
  tool = "aidlc-orchestrate.ts";
  forwarded = args.slice(1);
} else if (args[0] === "tool" && args[1]) {
  tool = args[1];
  forwarded = args.slice(2);
} else if (["next", "report", "park"].includes(args[0] ?? "")) {
  tool = "aidlc-orchestrate.ts";
  forwarded = args;
} else {
  process.stderr.write("Usage: aidlc-copilot-runner.ts orchestrate <next|report|park> [args...]\n");
  process.stderr.write("   or: aidlc-copilot-runner.ts tool <aidlc-tool.ts> [args...]\n");
  process.exit(2);
}

const result = spawnSync(process.execPath, [toolPath(tool), ...forwarded], {
  cwd: project,
  env: runtimeEnvironment(project),
  stdio: ["inherit", "pipe", "pipe"],
  encoding: "utf-8",
});

if (result.stdout) process.stdout.write(rewriteOutput(result.stdout));
if (result.stderr) process.stderr.write(rewriteOutput(result.stderr));

process.exit(result.status ?? 1);
