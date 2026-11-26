#!/usr/bin/env python3
"""TITAN AI - one terminal client for ChatGPT, Claude, Gemini and Google Search.

Standard library only, so it works directly in the ArchTitan live ISO.
No credentials are baked into the image: keys/tokens live in the user's
$XDG_CONFIG_HOME/archtitan directory with 0600 permissions.
"""

from __future__ import annotations

import argparse
import base64
import getpass
import hashlib
import json
import os
import secrets
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

VERSION = "1.0.0"

PROVIDERS = ("openai", "claude", "gemini")
ALIASES = {
    "openai": "openai", "chatgpt": "openai",
    "claude": "claude", "anthropic": "claude",
    "gemini": "gemini", "google": "gemini",
}
LABELS = {
    "openai": "ChatGPT (OpenAI)",
    "claude": "Claude (Anthropic)",
    "gemini": "Gemini (Google)",
}
DEFAULT_MODELS = {
    "openai": "gpt-5.4-mini",
    "claude": "claude-haiku-5-5",
    "gemini": "gemini-2.5-flash",
}
DEFAULT_BASES = {
    "openai": "https://api.openai.com/v1",
    "claude": "https://api.anthropic.com",
    "gemini": "https://generativelanguage.googleapis.com",
}
KEY_ENV = {
    "openai": ("OPENAI_API_KEY",),
    "claude": ("ANTHROPIC_API_KEY", "CLAUDE_API_KEY"),
    "gemini": ("GEMINI_API_KEY", "GOOGLE_API_KEY"),
}
MODEL_ENV = {
    "openai": "TITAN_AI_OPENAI_MODEL",
    "claude": "TITAN_AI_CLAUDE_MODEL",
    "gemini": "TITAN_AI_GEMINI_MODEL",
}
BASE_ENV = {
    "openai": "OPENAI_BASE_URL",
    "claude": "ANTHROPIC_BASE_URL",
    "gemini": "GEMINI_BASE_URL",
}
DEFAULT_SYSTEM = (
    "You are Titan AI, a helpful assistant running in the ArchTitan OS terminal. "
    "Be concise and clear; use Markdown where it helps."
)

GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_DEVICE_URL = "https://oauth2.googleapis.com/device/code"
GOOGLE_SCOPES = (
    "https://www.googleapis.com/auth/cloud-platform "
    "https://www.googleapis.com/auth/generative-language.retriever"
)


class TitanError(Exception):
    """User-facing error."""


class APIError(TitanError):
    def __init__(self, status, message, payload=None):
        super().__init__(f"HTTP {status}: {message}")
        self.status = status
        self.message = message
        self.payload = payload


# ── small terminal helpers ────────────────────────────────────────────────────

def _use_colour():
    return sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def _paint(code, text):
    return f"\033[{code}m{text}\033[0m" if _use_colour() else str(text)


def dim(text):
    return _paint("2", text)


def cyan(text):
    return _paint("36", text)


def green(text):
    return _paint("32", text)


def red(text):
    return _paint("31", text)


# ── HTTP ──────────────────────────────────────────────────────────────────────

def request(url, *, method="POST", headers=None, payload=None, form=None, timeout=120):
    """Make a JSON/Form request and return the decoded JSON body."""
    data = None
    hdrs = {"Accept": "application/json", "User-Agent": f"titan-ai/{VERSION}"}
    if headers:
        hdrs.update(headers)
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        hdrs["Content-Type"] = "application/json"
    elif form is not None:
        data = urllib.parse.urlencode(form).encode("utf-8")
        hdrs["Content-Type"] = "application/x-www-form-urlencoded"

    req = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        parsed = None
        message = body[:500] or exc.reason
        try:
            parsed = json.loads(body)
            if isinstance(parsed, dict):
                err = parsed.get("error", parsed)
                if isinstance(err, dict):
                    message = err.get("message") or err.get("error_type") or json.dumps(err)[:500]
                else:
                    message = str(err)
        except (ValueError, TypeError):
            pass
        raise APIError(exc.code, message, parsed) from None
    except urllib.error.URLError as exc:
        host = urllib.parse.urlsplit(url).netloc
        raise TitanError(
            f"cannot reach {host}: {exc.reason}. Check the network, DNS or proxy settings."
        ) from None

    if not raw:
        return {}
    try:
        return json.loads(raw)
    except ValueError:
        raise TitanError(f"{urllib.parse.urlsplit(url).netloc} returned invalid JSON") from None


# ── config and credentials (runtime only) ────────────────────────────────────

def config_dir():
    base = os.environ.get("XDG_CONFIG_HOME") or str(Path.home() / ".config")
    return Path(base) / "archtitan"


def config_path():
    return config_dir() / "titan-ai.json"


def oauth_path():
    return config_dir() / "titan-ai-google.json"


def adc_path():
    return Path.home() / ".config" / "gcloud" / "application_default_credentials.json"


def load_config():
    path = config_path()
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        raise TitanError(f"invalid config at {path}: {exc}") from None
    if not isinstance(data, dict):
        raise TitanError(f"invalid config at {path}: expected a JSON object")
    return data


def _write_private(path, data):
    """Write a secret file with 0600 permissions (atomically enough for a CLI)."""
    path.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    try:
        os.chmod(path.parent, 0o700)
    except OSError:
        pass
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    os.chmod(path, 0o600)


def save_config(cfg):
    _write_private(config_path(), cfg)


def get_cfg(cfg, *path, env=None, default=None):
    if env:
        value = os.environ.get(env)
        if value:
            return value
    node = cfg
    for key in path:
        if not isinstance(node, dict) or key not in node:
            return default
        node = node[key]
    return default if node is None or node == "" else node


def mask(value):
    if not value:
        return dim("(not set)")
    text = str(value)
    if len(text) <= 8:
        return "****"
    return f"{text[:4]}...{text[-4:]}"


def normalize_provider(name):
    if not name or str(name).strip().lower() == "auto":
        return None
    key = str(name).strip().lower()
    if key not in ALIASES:
        raise TitanError(
            f"unknown provider '{name}' (choose: openai/chatgpt, claude/anthropic, "
            "gemini/google, auto)"
        )
    return ALIASES[key]


def env_key(provider):
    for name in KEY_ENV[provider]:
        if os.environ.get(name):
            return os.environ[name]
    return None


def has_credentials(provider, cfg):
    if provider == "gemini":
        return bool(env_key("gemini") or get_cfg(cfg, "providers", "gemini", "api_key")
                    or oauth_path().exists() or adc_path().exists())
    return bool(env_key(provider) or get_cfg(cfg, "providers", provider, "api_key"))


def resolve_provider(cfg, requested=None, need_key=True):
    name = normalize_provider(requested) if requested else normalize_provider(
        get_cfg(cfg, "default_provider", default="auto")
    )
    if name in (None, "auto"):
        for provider in PROVIDERS:
            if has_credentials(provider, cfg):
                return provider
        raise TitanError("no API credentials found. Run `titan-ai setup` or set an API key env var.")
    if need_key and not has_credentials(name, cfg):
        hint = "`titan-ai auth google`" if name == "gemini" else "`titan-ai setup`"
        raise TitanError(f"no credentials for {LABELS[name]}. Run {hint} or set an API key env var.")
    return name


def settings_for(provider, cfg, args=None):
    args = args or argparse.Namespace(model=None)
    model = getattr(args, "model", None) or get_cfg(
        cfg, "models", provider, env=MODEL_ENV[provider], default=DEFAULT_MODELS[provider]
    )
    base = get_cfg(
        cfg, "providers", provider, "base_url", env=BASE_ENV[provider],
        default=DEFAULT_BASES[provider],
    ).rstrip("/")
    key = env_key(provider) or get_cfg(cfg, "providers", provider, "api_key")
    return {"model": model, "base_url": base, "api_key": key}


def options_for(args, cfg):
    return {
        "system": args.system if args.system is not None
                  else get_cfg(cfg, "system", default=DEFAULT_SYSTEM),
        "max_tokens": args.max_tokens if args.max_tokens is not None
                      else get_cfg(cfg, "max_tokens", default=2048),
        "temperature": args.temperature if args.temperature is not None
                       else get_cfg(cfg, "temperature"),
        "timeout": args.timeout or get_cfg(cfg, "timeout", default=120),
    }


# ── Google auth (API key, "Sign in with Google", or gcloud ADC) ──────────────

def load_oauth():
    path = oauth_path()
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else None
    except (OSError, ValueError):
        return None


def store_oauth(data):
    _write_private(oauth_path(), data)


def _expired_token_error(detail=""):
    suffix = f" ({detail})" if detail else ""
    raise TitanError(
        "Google sign-in is expired or invalid" + suffix + ". Run `titan-ai auth google` again."
    )


def refresh_google_token(saved):
    if not saved.get("refresh_token") or not saved.get("client_id"):
        _expired_token_error("missing refresh token")
    form = {
        "grant_type": "refresh_token",
        "refresh_token": saved["refresh_token"],
        "client_id": saved["client_id"],
    }
    if saved.get("client_secret"):
        form["client_secret"] = saved["client_secret"]
    try:
        fresh = request(GOOGLE_TOKEN_URL, form=form)
    except APIError as exc:
        _expired_token_error(exc.message)
    if "access_token" not in fresh:
        _expired_token_error()
    saved.update(fresh)
    saved["expires_at"] = time.time() + int(fresh.get("expires_in", 3600))
    store_oauth(saved)
    return saved["access_token"]


def google_adc_token():
    """Fallback for users who already ran `gcloud auth application-default login`."""
    path = adc_path()
    if not path.exists():
        return None
    try:
        adc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if adc.get("type") != "authorized_user" or not adc.get("refresh_token"):
        return None
    try:
        fresh = request(GOOGLE_TOKEN_URL, form={
            "grant_type": "refresh_token",
            "refresh_token": adc["refresh_token"],
            "client_id": adc["client_id"],
            "client_secret": adc.get("client_secret", ""),
        })
    except TitanError:
        return None
    return fresh.get("access_token")


def oauth_access_token(saved):
    if saved.get("access_token") and float(saved.get("expires_at", 0)) > time.time() + 60:
        return saved["access_token"]
    return refresh_google_token(saved)


def google_credentials(cfg):
    """Return (kind, secret): ('api_key'|'oauth'|'adc', value).

    Explicit sign-in wins over an API key; TITAN_AI_GOOGLE_AUTH can force a mode:
    api_key, oauth or adc.
    """
    mode = (os.environ.get("TITAN_AI_GOOGLE_AUTH") or "auto").strip().lower()
    key = env_key("gemini") or get_cfg(cfg, "providers", "gemini", "api_key")
    saved = load_oauth()

    if mode == "api_key":
        if not key:
            raise TitanError("TITAN_AI_GOOGLE_AUTH=api_key but no Gemini API key is configured")
        return "api_key", key
    if mode == "oauth":
        if not saved:
            raise TitanError("TITAN_AI_GOOGLE_AUTH=oauth but no Google sign-in found; run `titan-ai auth google`")
        return "oauth", oauth_access_token(saved)
    if mode == "adc":
        token = google_adc_token()
        if not token:
            raise TitanError("TITAN_AI_GOOGLE_AUTH=adc but no gcloud credentials found")
        return "adc", token
    if mode not in ("auto", ""):
        raise TitanError("TITAN_AI_GOOGLE_AUTH must be auto, api_key, oauth or adc")

    if saved:
        try:
            return "oauth", oauth_access_token(saved)
        except TitanError:
            if not key:
                raise
    if key:
        return "api_key", key
    token = google_adc_token()
    if token:
        return "adc", token
    raise TitanError(
        "Google access not configured. Add a Gemini API key with `titan-ai setup`, "
        "or sign in with `titan-ai auth google`."
    )


def google_project(cfg):
    return (os.environ.get("GOOGLE_CLOUD_PROJECT")
            or os.environ.get("GOOGLE_CLOUD_PROJECT_ID")
            or get_cfg(cfg, "google_oauth", "project_id"))


def oauth_client(cfg):
    client_id = (os.environ.get("GOOGLE_CLIENT_ID")
                 or get_cfg(cfg, "google_oauth", "client_id"))
    if not client_id:
        raise TitanError(
            "No Google OAuth client ID. Create a 'Desktop app' OAuth client in Google Cloud, "
            "then set google_oauth.client_id in `titan-ai config edit` or GOOGLE_CLIENT_ID. "
            "See `titan-ai docs` / subsystems/titan-ai/docs/GOOGLE_AUTH.md."
        )
    secret = (os.environ.get("GOOGLE_CLIENT_SECRET")
              or get_cfg(cfg, "google_oauth", "client_secret"))
    return client_id, secret


def _save_token_response(data, client_id, client_secret):
    saved = {
        "client_id": client_id,
        "client_secret": client_secret,
        "access_token": data["access_token"],
        "refresh_token": data.get("refresh_token"),
        "scope": data.get("scope", GOOGLE_SCOPES),
        "expires_at": time.time() + int(data.get("expires_in", 3600)),
    }
    store_oauth(saved)
    return saved


class _CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.server.result = urllib.parse.parse_qs(
            urllib.parse.urlparse(self.path).query
        )
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(
            b"<h1>Signed in to Titan AI</h1><p>You can close this window.</p>"
        )

    def log_message(self, *_args):
        pass


def auth_google_loopback(cfg, timeout=300):
    """OAuth authorization-code flow with PKCE on a local loopback port."""
    client_id, client_secret = oauth_client(cfg)
    server = HTTPServer(("127.0.0.1", 0), _CallbackHandler)
    server.timeout = 5
    port = server.server_port
    redirect_uri = f"http://127.0.0.1:{port}/oauth2callback"

    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode("ascii")).digest()
    ).rstrip(b"=").decode("ascii")
    state = secrets.token_urlsafe(24)
    params = urllib.parse.urlencode({
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": GOOGLE_SCOPES,
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
        "access_type": "offline",
        "prompt": "consent",
    })
    url = f"{GOOGLE_AUTH_URL}?{params}"

    print("Sign in with Google to enable Gemini and Google Search grounding.")
    print(f"  Open: {cyan(url)}")
    if shutil.which("xdg-open"):
        try:
            subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
        except OSError:
            pass
    print(f"  Waiting for the browser callback on 127.0.0.1:{port} ...")

    deadline = time.time() + timeout
    try:
        while not getattr(server, "result", None) and time.time() < deadline:
            server.handle_request()
    finally:
        server.server_close()

    result = getattr(server, "result", None)
    if not result:
        raise TitanError("Google sign-in timed out. Try `titan-ai auth google --device`.")
    if result.get("error"):
        raise TitanError(f"Google sign-in was denied: {result['error'][0]}")
    if result.get("state", [None])[0] != state:
        raise TitanError("Google sign-in state mismatch; please try again.")
    code = result.get("code", [None])[0]
    if not code:
        raise TitanError("Google sign-in returned no authorization code.")

    form = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri,
        "client_id": client_id,
        "code_verifier": verifier,
    }
    if client_secret:
        form["client_secret"] = client_secret
    data = request(GOOGLE_TOKEN_URL, form=form)
    _save_token_response(data, client_id, client_secret)
    print(green("✓ Signed in. Token saved to "
                f"{oauth_path()} (mode 0600)."))


def auth_google_device(cfg, timeout=600):
    """OAuth device flow for headless terminals (no local browser callback)."""
    client_id, client_secret = oauth_client(cfg)
    form = {"client_id": client_id, "scope": GOOGLE_SCOPES}
    if client_secret:
        form["client_secret"] = client_secret
    challenge = request(GOOGLE_DEVICE_URL, form=form)

    code = challenge["device_code"]
    user_code = challenge["user_code"]
    uri = challenge.get("verification_uri") or challenge.get("verification_url")
    interval = int(challenge.get("interval", 5))
    deadline = time.time() + min(int(challenge.get("expires_in", 1800)), timeout)

    print("Sign in with Google to enable Gemini and Google Search grounding.")
    print(f"  1. Open {cyan(uri)}")
    print(f"  2. Enter code {cyan(user_code)}")
    if shutil.which("wl-copy"):
        try:
            subprocess.run(["wl-copy"], input=user_code.encode(), check=False,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("     (code copied to the Wayland clipboard)")
        except OSError:
            pass
    if shutil.which("xdg-open"):
        try:
            subprocess.Popen(["xdg-open", uri], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
        except OSError:
            pass

    while time.time() < deadline:
        time.sleep(interval)
        poll = {
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "device_code": code,
            "client_id": client_id,
        }
        if client_secret:
            poll["client_secret"] = client_secret
        try:
            data = request(GOOGLE_TOKEN_URL, form=poll)
        except APIError as exc:
            error = (exc.payload or {}).get("error") if isinstance(exc.payload, dict) else None
            if error == "authorization_pending":
                continue
            if error == "slow_down":
                interval += 5
                continue
            if error == "expired_token":
                raise TitanError("The sign-in code expired. Run the command again.") from None
            raise TitanError(f"Google sign-in failed: {exc.message}") from None
        _save_token_response(data, client_id, client_secret)
        print(green("✓ Signed in. Token saved to "
                    f"{oauth_path()} (mode 0600)."))
        return
    raise TitanError("Google sign-in timed out. Run the command again.")


# ── provider calls ────────────────────────────────────────────────────────────

def openai_messages(history, system, model):
    messages = []
    if system:
        role = "developer" if model.startswith(("o1", "o3", "o4", "gpt-5", "gpt-6", "codex")) else "system"
        messages.append({"role": role, "content": system})
    messages.extend({"role": m["role"], "content": m["content"]} for m in history)
    return messages


def call_openai(prompt, history, system, opts, cfg):
    settings = settings_for("openai", cfg)
    model = settings["model"]
    if not settings["api_key"]:
        raise TitanError("OpenAI API key missing. Run `titan-ai setup` or set OPENAI_API_KEY.")
    messages = openai_messages(history, system, model)
    messages.append({"role": "user", "content": prompt})
    payload = {"model": model, "messages": messages}
    if opts["max_tokens"]:
        payload["max_completion_tokens"] = int(opts["max_tokens"])
    if opts["temperature"] is not None:
        payload["temperature"] = float(opts["temperature"])

    raw = request(
        settings["base_url"] + "/chat/completions",
        payload=payload,
        headers={"Authorization": f"Bearer {settings['api_key']}"},
        timeout=opts["timeout"],
    )
    try:
        text = raw["choices"][0]["message"].get("content") or ""
    except (KeyError, IndexError, TypeError):
        text = ""
    return text, raw, model


def call_claude(prompt, history, system, opts, cfg):
    settings = settings_for("claude", cfg)
    if not settings["api_key"]:
        raise TitanError("Anthropic API key missing. Run `titan-ai setup` or set ANTHROPIC_API_KEY.")
    messages = [{"role": m["role"], "content": m["content"]} for m in history]
    messages.append({"role": "user", "content": prompt})
    payload = {
        "model": settings["model"],
        "messages": messages,
        "max_tokens": int(opts["max_tokens"] or 2048),
    }
    if system:
        payload["system"] = system
    if opts["temperature"] is not None:
        payload["temperature"] = float(opts["temperature"])

    base = settings["base_url"]
    url = base + ("/messages" if base.endswith("/v1") else "/v1/messages")
    raw = request(
        url,
        payload=payload,
        headers={
            "x-api-key": settings["api_key"],
            "anthropic-version": "2023-06-01",
        },
        timeout=opts["timeout"],
    )
    text = "".join(block.get("text", "") for block in raw.get("content", [])
                   if isinstance(block, dict) and block.get("type") == "text")
    return text, raw, settings["model"]


def gemini_contents(history, prompt, system):
    contents = []
    for item in history:
        role = "model" if item["role"] == "assistant" else "user"
        contents.append({"role": role, "parts": [{"text": item["content"]}]})
    contents.append({"role": "user", "parts": [{"text": prompt}]})
    return contents


def call_gemini(prompt, history, system, opts, cfg, search=False):
    settings = settings_for("gemini", cfg)
    kind, secret = google_credentials(cfg)
    model = settings["model"]
    headers = {}
    if kind == "api_key":
        headers["x-goog-api-key"] = secret
    else:
        headers["Authorization"] = f"Bearer {secret}"
    project = google_project(cfg)
    if project:
        headers["x-goog-user-project"] = project

    if search:
        prompt = "Use Google Search to answer accurately and cite your sources.\n\n" + prompt
    contents = gemini_contents(history, prompt, system)
    generation = {}
    if opts["max_tokens"]:
        generation["maxOutputTokens"] = int(opts["max_tokens"])
    if opts["temperature"] is not None:
        generation["temperature"] = float(opts["temperature"])
    payload = {"contents": contents}
    if generation:
        payload["generationConfig"] = generation
    if system:
        payload["systemInstruction"] = {"parts": [{"text": system}]}
    if search:
        payload["tools"] = [{"google_search": {}}]

    url = (settings["base_url"] + "/v1beta/models/"
           + urllib.parse.quote(model, safe=".") + ":generateContent")
    raw = request(url, payload=payload, headers=headers, timeout=opts["timeout"])
    try:
        candidate = raw["candidates"][0]
    except (KeyError, IndexError):
        raise TitanError("Gemini returned no candidate response") from None
    text = "".join(part.get("text", "")
                   for part in candidate.get("content", {}).get("parts", []))
    if not text and candidate.get("finishReason") == "SAFETY":
        raise TitanError("Gemini blocked this response with its safety filters")
    return text, raw, model


CALLERS = {"openai": call_openai, "claude": call_claude, "gemini": call_gemini}


# ── output formatting ─────────────────────────────────────────────────────────

def grounding(raw):
    try:
        meta = raw["candidates"][0].get("groundingMetadata", {})
    except (KeyError, IndexError, TypeError):
        meta = {}
    sources = []
    for chunk in meta.get("groundingChunks", []):
        web = chunk.get("web", {}) if isinstance(chunk, dict) else {}
        uri = web.get("uri")
        if uri:
            sources.append((web.get("title") or urllib.parse.urlsplit(uri).netloc, uri))
    return meta, sources


def annotate_citations(text, meta):
    inserts = {}
    for support in meta.get("groundingSupports", []):
        indices = support.get("groundingChunkIndices", [])
        if not indices:
            continue
        marker = "".join(f"[{i + 1}]" for i in indices)
        segment = support.get("segment") or {}
        segments = segment if isinstance(segment, list) else [segment]
        for part in segments:
            end = part.get("endIndex") if isinstance(part, dict) else None
            if isinstance(end, int):
                pos = max(0, min(end, len(text)))
                inserts.setdefault(pos, set()).add(marker)
    if not inserts:
        return text
    out = []
    for i, char in enumerate(text):
        if i in inserts:
            out.extend(sorted(inserts[i]))
        out.append(char)
    if len(text) in inserts:
        out.extend(sorted(inserts[len(text)]))
    return "".join(out)


def print_answer(provider, text, raw, as_json, search=False, links_only=False):
    if as_json:
        print(json.dumps({"provider": provider, "text": text, "raw": raw},
                         indent=2, ensure_ascii=False))
        return
    if search:
        meta, sources = grounding(raw)
        if links_only:
            text = ""
        else:
            text = annotate_citations(text, meta)
        if text:
            print(text)
        if sources:
            print("\n" + dim("Sources:"))
            for i, (title, uri) in enumerate(sources, 1):
                print(f"  {dim(f'[{i}]')} {title}\n      {dim(uri)}")
        return
    print(text if text else dim("(empty response)"))


# ── commands ──────────────────────────────────────────────────────────────────

def ask(provider, prompt, history, opts, cfg, as_json=False, search=False, links_only=False):
    text, raw, model = CALLERS[provider](prompt, history, opts["system"], opts, cfg, search=search) \
        if provider == "gemini" else CALLERS[provider](prompt, history, opts["system"], opts, cfg)
    print_answer(provider, text, raw, as_json, search=search, links_only=links_only)
    return text


def cmd_ask(args, cfg, prompt):
    if args.all:
        return cmd_all(args, cfg, prompt)
    provider = resolve_provider(cfg, args.provider)
    opts = options_for(args, cfg)
    ask(provider, prompt, [], opts, cfg, as_json=args.json)
    return 0


def cmd_all(args, cfg, prompt):
    opts = options_for(args, cfg)
    any_ok = False
    for provider in PROVIDERS:
        if not has_credentials(provider, cfg):
            print(f"{dim('── ' + LABELS[provider] + ': no credentials, skipped')}")
            continue
        print(f"\n{cyan('══ ' + LABELS[provider] + ' ══')}")
        try:
            text, raw, model = (CALLERS[provider](prompt, [], opts["system"], opts, cfg, search=False)
                                if provider == "gemini"
                                else CALLERS[provider](prompt, [], opts["system"], opts, cfg))
            print(dim(f"model: {model}"))
            print_answer(provider, text, raw, args.json)
            any_ok = True
        except TitanError as exc:
            print(red(f"  {exc}"))
    if not any_ok:
        raise TitanError("no provider answered the prompt")
    return 0


def cmd_search(args, cfg, prompt):
    provider = normalize_provider(args.provider) if args.provider else "gemini"
    if provider != "gemini":
        raise TitanError("Google Search grounding is only available through Gemini (-p gemini)")
    opts = options_for(args, cfg)
    ask("gemini", prompt, [], opts, cfg, as_json=args.json,
        search=True, links_only=bool(args.links))
    return 0


def cmd_chat(args, cfg):
    provider = resolve_provider(cfg, args.provider)
    system = options_for(args, cfg)["system"]
    history = []
    print(f"{cyan('Titan AI chat')} - {LABELS[provider]} "
          f"({dim('type /help for commands, Ctrl-D to exit')})")
    while True:
        try:
            line = input(f"{dim('titan-ai')}[{provider}]> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not line:
            continue
        if line.startswith("/"):
            parts = line[1:].split(maxsplit=1)
            command = parts[0].lower() if parts else ""
            value = parts[1] if len(parts) > 1 else ""
            if command in ("quit", "exit", "q"):
                return 0
            if command == "help":
                print(dim("/provider NAME  /model NAME  /system TEXT  /clear  /quit"))
                continue
            if command == "clear":
                history.clear()
                print(dim("Conversation cleared."))
                continue
            if command == "provider":
                provider = resolve_provider(cfg, value)
                print(dim(f"Switched to {LABELS[provider]}."))
                continue
            if command == "model":
                if not value:
                    print(dim(f"model: {settings_for(provider, cfg, args)['model']}"))
                else:
                    args.model = value
                    print(dim(f"model set to {value}."))
                continue
            if command == "system":
                system = value
                print(dim("System prompt updated." if value else "System prompt cleared."))
                continue
            if command == "search":
                if not value:
                    print(dim("Usage: /search <query>"))
                    continue
                try:
                    opts = options_for(args, cfg)
                    opts["system"] = system
                    ask("gemini", value, [], opts, cfg, search=True)
                except TitanError as exc:
                    print(red(str(exc)))
                continue
            print(red(f"Unknown command: /{command}"))
            continue

        opts = options_for(args, cfg)
        opts["system"] = system
        history.append({"role": "user", "content": line})
        try:
            text, _raw, _model = (CALLERS[provider](line, history[:-1], system, opts, cfg, search=False)
                                  if provider == "gemini"
                                  else CALLERS[provider](line, history[:-1], system, opts, cfg))
        except TitanError as exc:
            print(red(str(exc)))
            history.pop()
            continue
        print(text if text else dim("(empty response)"))
        history.append({"role": "assistant", "content": text})


def cmd_status(args, cfg):
    print(cyan("TITAN AI status") + f"  {dim('config: ' + str(config_path()))}")
    for provider in PROVIDERS:
        settings = settings_for(provider, cfg)
        if provider == "gemini":
            kind, _ = "none", None
            try:
                kind, _secret = google_credentials(cfg)
            except TitanError:
                pass
            auth = {"api_key": "API key", "oauth": "Google sign-in",
                    "adc": "gcloud ADC", "none": "not configured"}[kind]
        else:
            auth = "API key" if (env_key(provider) or settings["api_key"]) else "not configured"
        print(f"  {LABELS[provider]:<22} {dim('model:')} {settings['model']:<24} "
              f"{dim('auth:')} {auth}")
    saved = load_oauth()
    if saved:
        left = float(saved.get("expires_at", 0)) - time.time()
        print(f"  {dim('Google token:')} {'valid' if left > 0 else 'expired'} "
              f"({dim(str(int(abs(left) // 60)) + ' min')})")


def cmd_setup(args, cfg):
    print(cyan("Titan AI setup") + dim("  (values are stored locally, never in the ISO)"))
    providers = cfg.setdefault("providers", {})
    for provider, label in (("openai", "OpenAI / ChatGPT"),
                            ("claude", "Anthropic / Claude"),
                            ("gemini", "Google Gemini")):
        current = env_key(provider) or get_cfg(cfg, "providers", provider, "api_key")
        answer = getpass.getpass(f"{label} API key (blank to skip, current: {mask(current)}): ").strip()
        if answer:
            providers.setdefault(provider, {})["api_key"] = answer
    client = input("Google OAuth client ID for 'Sign in with Google' (blank to skip): ").strip()
    if client:
        cfg.setdefault("google_oauth", {})["client_id"] = client
        secret = getpass.getpass("Client secret (blank for public/native clients): ").strip()
        if secret:
            cfg["google_oauth"]["client_secret"] = secret
    default = input("Default provider [auto/openai/claude/gemini] (blank keeps current): ").strip()
    if default:
        normalize_provider(default)
        cfg["default_provider"] = default
    save_config(cfg)
    print(green(f"✓ Saved {config_path()} (mode 0600)."))


def cmd_auth(args, cfg):
    action = args.auth_command
    if action == "google":
        if args.device:
            auth_google_device(cfg)
        else:
            auth_google_loopback(cfg)
        return 0
    if action == "status":
        cmd_status(args, cfg)
        return 0
    if action == "logout":
        path = oauth_path()
        if path.exists():
            path.unlink()
            print(green("✓ Google sign-in removed."))
        else:
            print(dim("No Google sign-in stored."))
        return 0
    raise TitanError("usage: titan-ai auth {google|status|logout}")


def _coerce(value):
    if value.lower() in ("true", "yes", "on"):
        return True
    if value.lower() in ("false", "no", "off"):
        return False
    if value.lower() in ("null", "none"):
        return None
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        return value


def _dig(cfg, keys, create=False):
    node = cfg
    for key in keys[:-1]:
        if key not in node:
            if not create:
                return None, None
            node[key] = {}
        node = node[key]
        if not isinstance(node, dict):
            raise TitanError(f"config path '{'.'.join(keys)}' is not an object")
    return node, keys[-1]


def cmd_config(args, cfg):
    action = args.config_command
    if action in (None, "show"):
        shown = json.loads(json.dumps(cfg))
        for providers in (shown.get("providers") or {}).values():
            if isinstance(providers, dict) and providers.get("api_key"):
                providers["api_key"] = mask(providers["api_key"])
        for key in ("client_secret",):
            if (shown.get("google_oauth") or {}).get(key):
                shown["google_oauth"][key] = mask(shown["google_oauth"][key])
        print(json.dumps(shown, indent=2, ensure_ascii=False))
        return 0
    if action == "path":
        print(config_path())
        return 0
    if action == "edit":
        editor = os.environ.get("EDITOR") or os.environ.get("VISUAL") or "nvim"
        save_config(cfg) if not config_path().exists() else None
        os.execvp(editor, [editor, str(config_path())])
    if action in ("set", "unset"):
        keys = args.key.split(".")
        if not all(keys):
            raise TitanError("invalid config key")
        node, last = _dig(cfg, keys, create=(action == "set"))
        if action == "set":
            if node is None:
                raise TitanError("invalid config path")
            node[last] = _coerce(args.value)
        else:
            if node is not None and last in node:
                del node[last]
        save_config(cfg)
        print(green(f"✓ {config_path()} updated."))
        return 0
    raise TitanError("usage: titan-ai config {show|path|edit|set KEY VALUE|unset KEY}")


def cmd_docs():
    root = Path(__file__).resolve().parent
    docs = [
        root / "docs" / "GOOGLE_AUTH.md",
        Path("/usr/share/doc/titan-ai/GOOGLE_AUTH.md"),
    ]
    for path in docs:
        if path.exists():
            print(path.read_text(encoding="utf-8"))
            return 0
    print("Google sign-in guide: subsystems/titan-ai/docs/GOOGLE_AUTH.md")
    return 0


# ── argument parsing / entry point ───────────────────────────────────────────

COMMON = argparse.ArgumentParser(add_help=False)
COMMON.add_argument("-p", "--provider", default=argparse.SUPPRESS, metavar="NAME",
                    help="openai/chatgpt, claude/anthropic or gemini/google")
COMMON.add_argument("-m", "--model", default=argparse.SUPPRESS, metavar="NAME",
                    help="override the configured model")
COMMON.add_argument("--system", default=argparse.SUPPRESS, metavar="TEXT",
                    help="system prompt (empty string disables it)")
COMMON.add_argument("--max-tokens", default=argparse.SUPPRESS, type=int, metavar="N")
COMMON.add_argument("--temperature", default=argparse.SUPPRESS, type=float, metavar="N")
COMMON.add_argument("--timeout", default=argparse.SUPPRESS, type=float, metavar="SECONDS")
COMMON.add_argument("--all", action="store_true", default=argparse.SUPPRESS,
                    help="ask every configured provider")
COMMON.add_argument("-j", "--json", action="store_true", default=argparse.SUPPRESS,
                    help="print the full JSON response (for scripts)")

DEFAULTS = {
    "provider": None, "model": None, "system": None, "max_tokens": None,
    "temperature": None, "timeout": 120.0, "all": False, "json": False,
    "links": False, "device": False, "command": None,
    "auth_command": None, "config_command": None,
}

COMMANDS = {"chat", "ask", "search", "setup", "status", "docs", "auth", "config"}
OPTIONS_WITH_VALUE = {
    "-p", "--provider", "-m", "--model", "--system", "--max-tokens",
    "--temperature", "--timeout",
}


def inject_ask_command(argv):
    """Treat a bare prompt as `ask` even when global options precede it."""
    argv = list(argv)
    i = 0
    while i < len(argv):
        token = argv[i]
        if token in OPTIONS_WITH_VALUE:
            i += 2
            continue
        if token == "--":
            argv.insert(i, "ask")
            return argv
        if token.startswith("-") and token != "-":
            i += 1
            continue
        if token in COMMANDS:
            return argv
        argv.insert(i, "ask")
        return argv
    return argv


def build_parser():
    parser = argparse.ArgumentParser(
        prog="titan-ai", parents=[COMMON],
        description="ChatGPT, Claude, Gemini and Google Search from the ArchTitan terminal.",
        epilog="examples:\n"
               "  titan-ai 'explain btrfs snapshots'\n"
               "  titan-ai -p claude 'review this code'\n"
               "  titan-ai search 'latest Arch Linux news'\n"
               "  titan-ai --all -- 'compare these two designs'\n"
               "  titan-ai chat   # interactive session\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--version", action="version", version=f"titan-ai {VERSION}")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("chat", parents=[COMMON], help="interactive chat session")
    sub.add_parser("ask", parents=[COMMON], help="ask a single question")
    search = sub.add_parser("search", parents=[COMMON],
                            help="Google Search grounding via Gemini (with citations)")
    search.add_argument("--links", action="store_true", default=argparse.SUPPRESS,
                        help="print only the source links")
    sub.add_parser("setup", help="interactively store API keys in user config")
    sub.add_parser("status", help="show providers, models and auth methods")
    sub.add_parser("docs", help="print the Google sign-in guide")

    auth = sub.add_parser("auth", help="Google sign-in management")
    auth_sub = auth.add_subparsers(dest="auth_command")
    login = auth_sub.add_parser("google", help="sign in with Google (OAuth)")
    login.add_argument("--device", action="store_true",
                       help="device-code flow for headless terminals")
    auth_sub.add_parser("status", help="show auth status")
    auth_sub.add_parser("logout", help="remove the stored Google token")

    config = sub.add_parser("config", help="manage ~/.config/archtitan/titan-ai.json")
    config_sub = config.add_subparsers(dest="config_command")
    config_sub.add_parser("show", help="show config with secrets masked")
    config_sub.add_parser("path", help="print the config file path")
    config_sub.add_parser("edit", help="open config in $EDITOR")
    set_cmd = config_sub.add_parser("set", help="set a dotted config key")
    set_cmd.add_argument("key")
    set_cmd.add_argument("value")
    unset_cmd = config_sub.add_parser("unset", help="remove a dotted config key")
    unset_cmd.add_argument("key")
    return parser


def extract_prompt(parser, extras):
    tokens = []
    for token in extras:
        if token.startswith("-") and not token.lstrip("-").isdigit():
            parser.error(f"unexpected argument '{token}' (put global options before the command)")
        tokens.append(token)
    return " ".join(tokens).strip()


def run(argv=None):
    parser = build_parser()
    argv = inject_ask_command(sys.argv[1:] if argv is None else argv)
    args, extras = parser.parse_known_args(argv)
    for key, value in DEFAULTS.items():
        if not hasattr(args, key):
            setattr(args, key, value)
    prompt = extract_prompt(parser, extras)

    if args.command == "docs":
        return cmd_docs()
    cfg = load_config()

    if args.command == "setup":
        return cmd_setup(args, cfg)
    if args.command == "status":
        return cmd_status(args, cfg)
    if args.command == "auth":
        return cmd_auth(args, cfg)
    if args.command == "config":
        return cmd_config(args, cfg)
    if args.command == "chat":
        return cmd_chat(args, cfg)
    if args.command == "search":
        if not prompt:
            parser.error("search needs a query")
        return cmd_search(args, cfg, prompt)
    if args.command == "ask":
        if not prompt:
            parser.error("ask needs a prompt")
        return cmd_ask(args, cfg, prompt)

    # No subcommand: prompt argument, piped stdin, or interactive chat.
    if prompt == "-":
        prompt = sys.stdin.read().strip()
    if not prompt and not sys.stdin.isatty():
        prompt = sys.stdin.read().strip()
    if not prompt:
        return cmd_chat(args, cfg)
    return cmd_ask(args, cfg, prompt)


def main(argv=None):
    try:
        return run(argv)
    except KeyboardInterrupt:
        print("\nInterrupted." , file=sys.stderr)
        return 130
    except TitanError as exc:
        print(f"{red('titan-ai:')} {exc}", file=sys.stderr)
        return 2
    except BrokenPipeError:
        return 0


if __name__ == "__main__":
    sys.exit(main())
