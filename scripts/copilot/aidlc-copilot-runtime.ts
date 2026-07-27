import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync, cpSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const INSTALL_ROOT = dirname(fileURLToPath(import.meta.url));
export const RUNTIME_HARNESS_ROOT = join(INSTALL_ROOT, "runtime", ".claude");
export const MEMORY_SEED_ROOT = join(INSTALL_ROOT, "memory-seed");
export const KNOWLEDGE_SEED_ROOT = join(INSTALL_ROOT, "knowledge");

export function projectDir(explicit?: string): string {
  const value = explicit ?? process.env.AIDLC_PROJECT_DIR ?? process.env.CLAUDE_PROJECT_DIR ?? process.cwd();
  return resolve(value);
}

export function runtimeEnvironment(project: string): Record<string, string> {
  return {
    ...process.env,
    AIDLC_PROJECT_DIR: project,
    CLAUDE_PROJECT_DIR: project,
    AIDLC_HARNESS_DIR: ".claude",
    AIDLC_HARNESS_NAME: "claude",
    AIDLC_RUNTIME_HARNESS_ROOT: RUNTIME_HARNESS_ROOT,
    AIDLC_MEMORY_SEED_DIR: MEMORY_SEED_ROOT,
  } as Record<string, string>;
}

function copyMissingTree(source: string, destination: string): void {
  if (statSync(source).isDirectory()) {
    mkdirSync(destination, { recursive: true });
    for (const entry of readdirSync(source)) {
      copyMissingTree(join(source, entry), join(destination, entry));
    }
    return;
  }
  if (existsSync(destination)) return;
  mkdirSync(dirname(destination), { recursive: true });
  cpSync(source, destination);
}

function managedBlock(content: string, source: string): string {
  const begin = "<!-- ai-workflow-kit:org-rules:start -->";
  const end = "<!-- ai-workflow-kit:org-rules:end -->";
  const sourceBegin = source.indexOf(begin);
  const sourceEnd = source.indexOf(end);
  if (sourceBegin < 0 || sourceEnd < sourceBegin) return content;
  const block = source.slice(sourceBegin, sourceEnd + end.length);
  const targetBegin = content.indexOf(begin);
  const targetEnd = content.indexOf(end);
  if (targetBegin >= 0 && targetEnd >= targetBegin) {
    return content.slice(0, targetBegin) + block + content.slice(targetEnd + end.length);
  }
  return `${content.trimEnd()}\n\n${block}\n`;
}

function syncTeamRules(project: string): void {
  const source = join(MEMORY_SEED_ROOT, "team.md");
  if (!existsSync(source)) return;
  const destination = join(project, "aidlc", "spaces", "default", "memory", "team.md");
  mkdirSync(dirname(destination), { recursive: true });
  const current = existsSync(destination) ? readFileSync(destination, "utf-8") : "# Team Practices\n";
  writeFileSync(destination, managedBlock(current, readFileSync(source, "utf-8")), "utf-8");
}

function syncKnowledge(project: string): void {
  if (!existsSync(KNOWLEDGE_SEED_ROOT)) return;
  for (const entry of readdirSync(KNOWLEDGE_SEED_ROOT, { withFileTypes: true })) {
    const source = join(KNOWLEDGE_SEED_ROOT, entry.name);
    const destination = join(project, "aidlc", "spaces", "default", "knowledge", entry.name);
    copyMissingTree(source, destination);
  }
}

export function ensureProjectData(project: string): void {
  const memoryDestination = join(project, "aidlc", "spaces", "default", "memory");
  mkdirSync(memoryDestination, { recursive: true });
  for (const entry of readdirSync(MEMORY_SEED_ROOT, { withFileTypes: true })) {
    copyMissingTree(join(MEMORY_SEED_ROOT, entry.name), join(memoryDestination, entry.name));
  }
  syncTeamRules(project);
  syncKnowledge(project);
}

export function parseProjectArg(args: readonly string[]): string {
  const index = args.indexOf("--project-dir");
  return projectDir(index >= 0 ? args[index + 1] : undefined);
}

export function toolPath(tool: string): string {
  return join(RUNTIME_HARNESS_ROOT, "tools", tool);
}

export function hookPath(hook: string): string {
  return join(RUNTIME_HARNESS_ROOT, "hooks", hook);
}

export function readJsonStdin(): Record<string, unknown> {
  const input = readFileSync(0, "utf-8");
  if (!input.trim()) return {};
  try {
    const value: unknown = JSON.parse(input);
    return value !== null && typeof value === "object" ? value as Record<string, unknown> : {};
  } catch {
    return {};
  }
}

export function toolInput(input: Record<string, unknown>): Record<string, unknown> {
  const value = input.tool_input;
  return value !== null && typeof value === "object" ? value as Record<string, unknown> : {};
}

export function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}
