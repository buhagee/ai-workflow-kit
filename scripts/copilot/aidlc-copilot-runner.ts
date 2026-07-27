#!/usr/bin/env bun
import { spawnSync } from "node:child_process";
import { ensureProjectData, parseProjectArg, runtimeEnvironment, projectDir, toolPath } from "./aidlc-copilot-runtime.ts";

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
  stdio: "inherit",
});

process.exit(result.status ?? 1);
