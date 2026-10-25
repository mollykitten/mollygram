"""Role dispatch and formatter isolation checks; no live services required."""

import importlib.util
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("agents", ROOT / ".superset/agents.py")
AGENTS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AGENTS)


def state(role):
    agent, _, models, mode, effort, _ = AGENTS.ROLES[role]
    return {"harness": agent + "-acp", "modeId": mode, "configOptions": [
        {"id": "model", "currentValue": models[0]},
        {"id": "effort" if agent == "claude" else "reasoning_effort", "currentValue": effort},
    ]}


class RolesTest(unittest.TestCase):
    def test_all_role_configurations(self):
        for role in AGENTS.ROLES:
            with self.subTest(role=role):
                AGENTS.validate(state(role), role)

    def test_wrong_actual_model_effort_mode_harness(self):
        for field in ("model", "effort", "mode", "harness"):
            actual = state("review")
            if field == "model":
                actual["configOptions"][0]["currentValue"] = "gpt-6-astra"
            elif field == "effort":
                actual["configOptions"][1]["currentValue"] = "medium"
            elif field == "mode":
                actual["modeId"] = "workspace-write"
            else:
                actual["harness"] = "codex"
            with self.subTest(field=field), self.assertRaises(ValueError):
                AGENTS.validate(actual, "review")

    def test_fable_launch_name_is_not_actual_picker_id(self):
        actual = state("plan")
        actual["configOptions"][0]["currentValue"] = "claude-fable-5-1"
        with self.assertRaises(ValueError):
            AGENTS.validate(actual, "plan")

    def test_no_task_sent_on_mismatch(self):
        with patch.dict(os.environ, {"SUPERSET_WORKSPACE_ID": "test"}), \
                patch.object(sys, "argv", ["agents.py", "send", "review", "session", "task"]), \
                patch.object(AGENTS, "configuration", return_value=state("implement")), \
                patch.object(AGENTS, "cli") as cli:
            with self.assertRaises(ValueError):
                AGENTS.main()
            cli.assert_not_called()

    def test_missing_config_refuses_dispatch(self):
        with patch.object(AGENTS, "cli", return_value={"envelopes": []}):
            with self.assertRaises(ValueError):
                AGENTS.configuration("workspace", "session")

    def test_launch_is_idle(self):
        with patch.dict(os.environ, {"SUPERSET_WORKSPACE_ID": "test"}), \
                patch.object(sys, "argv", ["agents.py", "review"]), \
                patch.object(AGENTS, "cli", return_value={"kind": "chat", "sessionId": "test-session"}) as cli:
            AGENTS.main()
            self.assertNotIn("--prompt", cli.call_args_list[0].args)
            self.assertEqual(cli.call_args_list[1].args[1], "open")

    def test_prompt_has_newlines(self):
        self.assertIn("\n\nTask: test", AGENTS.prompt("check", "test"))

    def test_hook_command_is_quoted(self):
        settings = json.loads((ROOT / ".claude/settings.json").read_text())
        command = settings["hooks"]["PostToolUse"][0]["hooks"][0]["command"]
        self.assertEqual(shlex.split(command), ["python3", "$CLAUDE_PROJECT_DIR/.claude/hooks/format-dart.py"])


class FormatHookTest(unittest.TestCase):
    def test_malformed_inputs_are_ignored(self):
        for payload in ("not json", "[]", "null", '{"tool_input": null}', "{}"):
            with self.subTest(payload=payload):
                result = subprocess.run(
                    [sys.executable, str(ROOT / ".claude/hooks/format-dart.py")],
                    input=payload, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout + result.stderr, "")

    def test_paths_and_pinned_formatter(self):
        with tempfile.TemporaryDirectory(prefix="mollygram hook ") as temporary:
            root = Path(temporary).resolve()
            dart = root / ".fvm/flutter_sdk/bin/dart"
            dart.parent.mkdir(parents=True)
            log = root / "formatted.json"
            dart.write_text("#!" + sys.executable + "\nimport json,sys\n"
                            + "from pathlib import Path\n"
                            + f"Path({str(log)!r}).write_text(json.dumps(sys.argv[1:]))\n")
            dart.chmod(0o755)
            owned = root / "packages/app/lib/file with spaces.dart"
            owned.parent.mkdir(parents=True)
            owned.write_text("void main() {}")
            external = root.parent / (root.name + "-outside.dart")
            external.write_text("void main() {}")
            try:
                escaped = root / "escape.dart"
                escaped.symlink_to(external)
                for relative in [str(owned), "packages/app/lib/file with spaces.dart",
                                 "packages/plugin_host/third_party/vendor.dart",
                                 "packages/tdlib/lib/src/generated/api.dart",
                                 "packages/app/lib/model.g.dart", str(external), str(escaped), "README.md"]:
                    candidate = root / relative
                    if not candidate.exists() and candidate.suffix == ".dart":
                        candidate.parent.mkdir(parents=True, exist_ok=True)
                        candidate.write_text("void main() {}")
                    log.unlink(missing_ok=True)
                    result = subprocess.run(
                        [sys.executable, str(ROOT / ".claude/hooks/format-dart.py")],
                        input=json.dumps({"tool_input": {"file_path": relative}}),
                        env={**os.environ, "CLAUDE_PROJECT_DIR": str(root)},
                        text=True, capture_output=True, check=True)
                    with self.subTest(path=relative):
                        self.assertEqual(result.stderr, "")
                        self.assertEqual(log.exists(), candidate.resolve() == owned)
                        if log.exists():
                            self.assertEqual(json.loads(log.read_text()), ["format", str(owned)])
            finally:
                external.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
