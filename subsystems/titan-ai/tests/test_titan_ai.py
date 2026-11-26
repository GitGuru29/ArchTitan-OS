#!/usr/bin/env python3
"""Offline tests for titan-ai. No network access and no real keys required."""

import contextlib
import importlib.util
import io
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SRC = Path(__file__).resolve().parents[1] / "src" / "titan_ai.py"
spec = importlib.util.spec_from_file_location("titan_ai", SRC)
titan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(titan)

OPTS = {"system": "Be concise.", "max_tokens": 1024, "temperature": None, "timeout": 5}


class TitanAITests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="titan-ai-test-")
        self.addCleanup(self.tmp.cleanup)
        self.env = mock.patch.dict(os.environ, {
            "XDG_CONFIG_HOME": self.tmp.name,
            "HOME": self.tmp.name,
        }, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)
        adc = mock.patch.object(titan, "adc_path",
                                return_value=Path(self.tmp.name) / "gcloud-adc.json")
        adc.start()
        self.addCleanup(adc.stop)

    def test_config_and_oauth_files_are_private(self):
        titan.save_config({"providers": {"openai": {"api_key": "sk-secret-key"}}})
        titan.store_oauth({"access_token": "secret-token", "refresh_token": "refresh"})
        for path in (titan.config_path(), titan.oauth_path()):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
        buf = io.StringIO()
        with mock.patch.object(sys, "argv", ["titan-ai", "config", "show"]), \
                contextlib.redirect_stdout(buf):
            titan.main()
        self.assertNotIn("sk-secret-key", buf.getvalue())
        self.assertNotIn("secret-token", buf.getvalue())
        self.assertIn("sk-s...-key", buf.getvalue())

    def test_openai_payload(self):
        seen = {}

        def fake_request(url, **kwargs):
            seen.update(url=url, **kwargs)
            return {"choices": [{"message": {"content": "Hello from ChatGPT"}}]}

        with mock.patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test"}), \
                mock.patch.object(titan, "request", side_effect=fake_request):
            text, raw, model = titan.call_openai("Hi", [], OPTS["system"], OPTS, {})

        self.assertEqual(text, "Hello from ChatGPT")
        self.assertEqual(seen["url"], "https://api.openai.com/v1/chat/completions")
        self.assertEqual(seen["headers"]["Authorization"], "Bearer sk-test")
        self.assertEqual(seen["payload"]["messages"][0],
                         {"role": "developer", "content": "Be concise."})
        self.assertEqual(seen["payload"]["max_completion_tokens"], 1024)
        self.assertEqual(model, titan.DEFAULT_MODELS["openai"])

    def test_claude_payload(self):
        seen = {}

        def fake_request(url, **kwargs):
            seen.update(url=url, **kwargs)
            return {"content": [{"type": "text", "text": "Hello from Claude"}]}

        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "sk-ant-test"}), \
                mock.patch.object(titan, "request", side_effect=fake_request):
            text, _raw, _model = titan.call_claude("Hi", [], OPTS["system"], OPTS, {})

        self.assertEqual(text, "Hello from Claude")
        self.assertEqual(seen["url"], "https://api.anthropic.com/v1/messages")
        self.assertEqual(seen["headers"]["x-api-key"], "sk-ant-test")
        self.assertEqual(seen["headers"]["anthropic-version"], "2023-06-01")
        self.assertEqual(seen["payload"]["system"], "Be concise.")
        self.assertEqual(seen["payload"]["messages"][-1]["role"], "user")

    def test_gemini_search_uses_google_grounding(self):
        seen = {}

        def fake_request(url, **kwargs):
            seen.update(url=url, **kwargs)
            return {"candidates": [{
                "content": {"parts": [{"text": "Arch Linux was released in 2002."}]},
                "groundingMetadata": {
                    "groundingChunks": [
                        {"web": {"uri": "https://archlinux.org/about/", "title": "Arch Linux"}},
                    ],
                    "groundingSupports": [{
                        "segment": {"startIndex": 0, "endIndex": 11},
                        "groundingChunkIndices": [0],
                    }],
                },
            }]}

        with mock.patch.object(titan, "google_credentials", return_value=("api_key", "gem-test")), \
                mock.patch.object(titan, "request", side_effect=fake_request):
            text, raw, _model = titan.call_gemini("When was Arch released?", [],
                                                  OPTS["system"], OPTS, {}, search=True)

        self.assertEqual(text, "Arch Linux was released in 2002.")
        self.assertEqual(seen["headers"]["x-goog-api-key"], "gem-test")
        self.assertEqual(seen["payload"]["tools"], [{"google_search": {}}])
        self.assertEqual(seen["payload"]["systemInstruction"]["parts"][0]["text"], "Be concise.")
        self.assertTrue(seen["url"].endswith(":generateContent"))

        meta, sources = titan.grounding(raw)
        self.assertEqual(sources, [("Arch Linux", "https://archlinux.org/about/")])
        self.assertTrue(titan.annotate_citations(text, meta).startswith("Arch Linux [1]"))

    def test_gemini_oauth_uses_bearer_header(self):
        seen = {}

        def fake_request(url, **kwargs):
            seen.update(url=url, **kwargs)
            return {"candidates": [{"content": {"parts": [{"text": "ok"}]}}]}

        with mock.patch.object(titan, "google_credentials", return_value=("oauth", "ya29.test")), \
                mock.patch.object(titan, "request", side_effect=fake_request):
            titan.call_gemini("Hi", [], None, OPTS, {}, search=False)

        self.assertEqual(seen["headers"]["Authorization"], "Bearer ya29.test")
        self.assertNotIn("x-goog-api-key", seen["headers"])
        self.assertNotIn("tools", seen["payload"])

    def test_resolve_provider_auto_and_missing_key(self):
        with mock.patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test"}, clear=True):
            self.assertEqual(titan.resolve_provider({}), "openai")
        empty = {"XDG_CONFIG_HOME": self.tmp.name, "HOME": self.tmp.name}
        with mock.patch.dict(os.environ, empty, clear=True):
            with self.assertRaises(titan.TitanError):
                titan.resolve_provider({})
        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "sk-ant"}, clear=True):
            self.assertEqual(titan.resolve_provider({}, "claude"), "claude")
        with mock.patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test"}, clear=True):
            self.assertEqual(titan.resolve_provider({"default_provider": "chatgpt"}), "openai")

    def test_json_output(self):
        with mock.patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test"}), \
                mock.patch.object(titan, "request", return_value={
                    "choices": [{"message": {"content": "42"}}]
                }):
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf), mock.patch.object(
                    sys, "argv", ["titan-ai", "-p", "openai", "-j", "answer?"]):
                code = titan.main()
        self.assertEqual(code, 0)
        result = json.loads(buf.getvalue())
        self.assertEqual(result["provider"], "openai")
        self.assertEqual(result["text"], "42")

    def test_config_set_and_unset(self):
        with mock.patch.object(sys, "argv", ["titan-ai", "config", "set",
                                             "models.openai", "gpt-test"]):
            self.assertEqual(titan.main(), 0)
        self.assertEqual(titan.load_config()["models"]["openai"], "gpt-test")
        with mock.patch.object(sys, "argv", ["titan-ai", "config", "unset",
                                             "models.openai"]):
            self.assertEqual(titan.main(), 0)
        self.assertEqual(titan.load_config()["models"], {})

    def test_device_sign_in_flow(self):
        cfg = {"google_oauth": {"client_id": "client.apps.googleusercontent.com",
                                "client_secret": "secret"}}
        answers = [
            {"device_code": "abc", "user_code": "ABCD-1234",
             "verification_uri": "https://google.com/device", "interval": 0,
             "expires_in": 120},
            {"access_token": "ya29.new", "refresh_token": "rtoken", "expires_in": 3600},
        ]
        with mock.patch.object(titan, "request", side_effect=answers), \
                mock.patch.object(titan.time, "sleep"), \
                mock.patch.object(titan.shutil, "which", return_value=None), \
                contextlib.redirect_stdout(io.StringIO()):
            titan.auth_google_device(cfg)
        saved = titan.load_oauth()
        self.assertEqual(saved["access_token"], "ya29.new")
        self.assertEqual(stat.S_IMODE(titan.oauth_path().stat().st_mode), 0o600)


if __name__ == "__main__":
    unittest.main()
