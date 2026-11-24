"""End-to-end tests for the C++ TITAN AI engine with a fake Gemini API.

No real provider keys or network calls are used. The binary is built once per
test run into a temporary directory.
"""
from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

SUBSYSTEM = Path(__file__).resolve().parents[1]
ROOT = SUBSYSTEM.parents[1]
BINARY: Path | None = None


class GeminiHandler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")
        grounded = "tools" in payload
        candidate = {
            "content": {
                "role": "model",
                "parts": [
                    {"text": "Arch Linux [1]was released in 2002." if grounded
                             else "Arch Linux was released in 2002."}
                ],
            },
            "finishReason": "STOP",
        }
        if grounded:
            candidate["groundingMetadata"] = {
                "groundingChunks": [
                    {"web": {"title": "Arch Linux", "uri": "https://archlinux.org/about/"}}
                ],
                "groundingSupports": [
                    {
                        "segment": {"text": "Arch Linux was released in 2002.", "endIndex": 10},
                        "groundingChunkIndices": [0],
                    }
                ],
            }
        body = json.dumps({"candidates": [candidate]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args: object) -> None:
        pass


@unittest.skipUnless(shutil.which("cmake") and shutil.which("g++"), "C++ toolchain required")
class CppEngineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        global BINARY
        cls.work = tempfile.TemporaryDirectory(prefix="titan-ai-cpp-test-")
        build = Path(cls.work.name) / "build"
        subprocess.run(
            ["cmake", "-S", str(SUBSYSTEM), "-B", str(build), "-DCMAKE_BUILD_TYPE=Release"],
            check=True, capture_output=True, text=True, timeout=120,
        )
        subprocess.run(
            ["cmake", "--build", str(build), "--parallel"],
            check=True, capture_output=True, text=True, timeout=180,
        )
        BINARY = build / "titan-ai"
        if not BINARY.exists():
            raise RuntimeError("titan-ai binary was not produced")

        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), GeminiHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.port = cls.server.server_address[1]

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=5)
        cls.work.cleanup()

    def setUp(self) -> None:
        self.home = Path(tempfile.mkdtemp(prefix="titan-ai-home-", dir=self.work.name))
        self.env = os.environ.copy()
        for key in ("OPENAI_API_KEY", "ANTHROPIC_API_KEY", "CLAUDE_API_KEY", "GOOGLE_API_KEY"):
            self.env.pop(key, None)
        self.env.update({
            "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home),
            "GEMINI_API_KEY": "fake-key",
            "GEMINI_BASE_URL": f"http://127.0.0.1:{self.port}",
            "TITAN_AI_GOOGLE_AUTH": "api_key", "NO_COLOR": "1",
        })

    def cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        assert BINARY is not None
        return subprocess.run(
            [str(BINARY), *args], capture_output=True, text=True, env=self.env, timeout=30
        )

    def test_version_and_status(self) -> None:
        version = self.cli("--version")
        self.assertEqual(version.returncode, 0)
        self.assertIn("2.0.0", version.stdout)
        status = self.cli("status")
        self.assertEqual(status.returncode, 0)
        self.assertIn("Gemini (Google)", status.stdout)
        self.assertIn("gemini-2.5-flash", status.stdout)

    def test_config_roundtrip_is_private(self) -> None:
        result = self.cli("config", "set", "models.gemini", "gemini-test")
        self.assertEqual(result.returncode, 0, result.stderr)
        config = self.home / "archtitan" / "titan-ai.json"
        self.assertTrue(config.exists())
        self.assertEqual(stat.S_IMODE(config.stat().st_mode), 0o600)
        self.assertEqual(json.loads(config.read_text())["models"]["gemini"], "gemini-test")
        shown = self.cli("config", "show")
        self.assertIn("gemini-test", shown.stdout)
        self.assertNotIn("fake-key", shown.stdout)

    def test_plain_ask(self) -> None:
        result = self.cli("-p", "gemini", "when was Arch released?")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Arch Linux was released in 2002.", result.stdout)
        self.assertNotIn("Sources:", result.stdout)

    def test_grounded_search_has_citations(self) -> None:
        result = self.cli("search", "Arch history")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[1]", result.stdout)
        self.assertIn("Sources:", result.stdout)
        self.assertIn("https://archlinux.org/about/", result.stdout)

    def test_links_only(self) -> None:
        result = self.cli("search", "--links", "Arch history")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("https://archlinux.org/about/", result.stdout)
        self.assertNotIn("was released", result.stdout)

    def test_json_output(self) -> None:
        result = self.cli("-j", "-p", "gemini", "hello")
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["text"], "Arch Linux was released in 2002.")
        self.assertIn("raw", payload)

    def test_kitty_assets(self) -> None:
        fragment = SUBSYSTEM / "configs" / "kitty-titan-ai.conf"
        wrapper = SUBSYSTEM / "kitty" / "titan-ai-kitty.sh"
        self.assertIn("ctrl+shift+s", fragment.read_text())
        self.assertIn("launch --type=window", fragment.read_text())
        self.assertTrue(wrapper.stat().st_mode & stat.S_IXUSR)
        self.assertIn("titan-ai", wrapper.read_text())
        self.assertIn("command -v titan-ai", wrapper.read_text())
        for conf in (
            ROOT / "airootfs/etc/skel/.config/kitty/kitty.conf",
            ROOT / "airootfs/home/archtitan/.config/kitty/kitty.conf",
        ):
            self.assertIn("include conf.d/*.conf", conf.read_text())


if __name__ == "__main__":
    unittest.main()
