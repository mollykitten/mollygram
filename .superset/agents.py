#!/usr/bin/env python3
"""Launch idle ACP chats, then verify their configuration before sending work."""

import json
import os
from pathlib import Path
import subprocess
import sys


# role: agent, requested model, accepted actual model ids, mode, effort, contract
ROLES = {
    "implement": ("codex", "gpt-6.1-sol", ("gpt-6.1-sol",),
                  "agent-full-access", "medium", "Implement the requested task."),
    "risky": ("codex", "gpt-6.1-sol", ("gpt-6.1-sol",),
              "agent-full-access", "high", "Implement the requested risky change; include evidence and request review."),
    "review": ("codex", "gpt-6.1-sol", ("gpt-6.1-sol",),
               "agent-full-access", "high", "Review the current diff with file locations and evidence. Do not edit files."),
    "check": ("codex", "gpt-6-luna", ("gpt-6-luna",),
              "agent-full-access", "medium", "Run appropriate verification and report results. Do not edit files."),
    "mechanical": ("codex", "gpt-6-luna", ("gpt-6-luna",),
                   "agent-full-access", "medium", "Make only the requested small mechanical changes."),
    "plan": ("claude", "claude-fable-5-1", ("claude-fable-5-1[1m]",),
             "bypassPermissions", "high", "Advice and planning only. Do not implement or edit files."),
    "plan-astra": ("codex", "gpt-6-astra", ("gpt-6-astra",),
                   "agent-full-access", "high", "Fallback planning because Fable ACP is unavailable. Do not implement or edit files."),
}


def cli(workspace, *args):
    result = subprocess.run(
        ["superset", "sessions", *args, "--workspace", workspace,
         "--local", "--json"], check=True, text=True, capture_output=True)
    # `open` can return a plain-text confirmation even with --json.
    return None if args[0] == "open" else json.loads(result.stdout)


def configuration(workspace, session_id):
    data = cli(workspace, "read", "--session", session_id, "--limit", "500")
    states = [e["event"]["session"] for e in data.get("envelopes", [])
              if e.get("event", {}).get("type") == "session"]
    if not states:
        raise ValueError("No ACP session configuration found; wait for startup and retry.")
    return states[-1]


def validate(state, role):
    agent, _, models, mode, effort, _ = ROLES[role]
    options = {o["id"]: o.get("currentValue")
               for o in state.get("configOptions", [])}
    expected_harness = "codex-acp" if agent == "codex" else "claude-acp"
    checks = {
        "harness": (state.get("harness"), (expected_harness,)),
        "model": (options.get("model"), models),
        "mode": (options.get("mode", state.get("modeId")), (mode,)),
        "effort": (options.get("reasoning_effort", options.get("effort")), (effort,)),
    }
    mismatches = [f"{key}: actual {actual!r}, expected {' or '.join(expected)}"
                  for key, (actual, expected) in checks.items()
                  if actual not in expected]
    if mismatches:
        raise ValueError("Task not sent. Set ACP pickers, then retry:\n" + "\n".join(mismatches))


def prompt(role, task):
    return (
        "Read AGENTS.md and its referenced repository rules first. "
        + ROLES[role][-1] + "\n"
        "Use Grep/Glob/Read for code discovery, not Bash. You are not alone in "
        "the codebase; preserve others' edits. Do not broaden the assigned scope. "
        "Do not commit, push, merge, publish, or message others unless explicitly requested.\n"
        "Finish with SUPERSET_WORKER_DONE followed by task, summary, files, checks, "
        "and handoff fields; if blocked use SUPERSET_WORKER_BLOCKED with task, "
        "reason, and needs. These are text markers; the coordinator must read "
        "your result and verify evidence.\n\nTask: " + task
    )


def main():
    args = sys.argv[1:]
    sending = bool(args and args[0] == "send")
    if sending:
        args.pop(0)
    if not args or args[0] not in ROLES or (sending and len(args) < 3) or (not sending and len(args) != 1):
        raise ValueError(
            "usage: sh .superset/agent.sh ROLE\n"
            "       sh .superset/agent.sh send ROLE SESSION TASK...\n"
            "roles: " + " | ".join(ROLES))
    role = args[0]
    workspace = os.environ.get("SUPERSET_WORKSPACE_ID")
    if not workspace:
        raise ValueError("Set SUPERSET_WORKSPACE_ID to the current Superset workspace ID.")
    root = Path(__file__).resolve().parent.parent
    os.chdir(root)
    if sending:
        session_id, task = args[1], " ".join(args[2:])
        validate(configuration(workspace, session_id), role)
        cli(workspace, "send", "--session", session_id, "--prompt", prompt(role, task))
        print(f"Sent {role} task to ACP session {session_id}.")
    else:
        agent, model, _, mode, effort, _ = ROLES[role]
        created = cli(workspace, "create", "--agent", agent, "--model", model, "--mode", mode)
        if created.get("kind") != "chat":
            raise ValueError("Expected an ACP chat session; refusing an unexpected launch result.")
        session_id = created["sessionId"]
        print(f"Created idle ACP session: {session_id}")
        print(f"Expected {model}, {mode}, effort {effort}. Verify/set ACP pickers before sending.")
        print(f"sh .superset/agent.sh send {role} {session_id} 'your task'")
        cli(workspace, "open", "--session", session_id)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            print(error.stderr.strip(), file=sys.stderr)
        sys.exit(1)
