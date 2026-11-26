# TITAN AI

> **Subsystem:** TITAN AI  
> **Status:** ✅ Implemented (C++ engine + Kitty shortcut)<br>
> **Command:** `titan-ai` · fish alias `ai` · **Kitty:** <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd>

## Overview

TITAN AI gives ArchTitan OS one unified AI/search interface for:

- **Gemini / Google** — Generative Language API (primary)
- **Google Search** — Gemini `google_search` grounding with inline citations
- **ChatGPT / OpenAI** — Chat Completions API (API key)
- **Claude / Anthropic** — Messages API (API key)

Google sign-in is the default onboarding path: Gemini chat and Kitty search work with your
Google account, and a Gemini API key is only a fallback. ChatGPT and Claude still use their
own provider API keys; a Google account cannot authenticate those APIs.

The engine is a **C++20 binary** using libcurl and OpenSSL with a small in-tree JSON parser.
No Python interpreter, pip packages or third-party JSON library are required in the ISO.
Credentials are never baked into the image: they come from environment variables or a
private user config file (`0600`).

## Use it inside Kitty (no command to type)

Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> in any Kitty window. Kitty opens a **new
window** with a `search>` prompt; type your query and press Enter. The grounded answer and
numbered source links appear in that window, while your original shell stays untouched.
Press <kbd>q</kbd> at the follow-up prompt to close it.

The shortcut is defined in `configs/kitty-titan-ai.conf`:

```
map ctrl+shift+s launch --type=window --title=TITAN-AI-SEARCH /usr/local/bin/titan-ai-kitty
```

`kitty/titan-ai-kitty.sh` is a thin prompt wrapper that calls the same C++ engine internally
(`titan-ai search`). Both Kitty config files include `conf.d/*.conf`, so the fragment is picked
up automatically. To change the shortcut or open a tab instead, edit
`~/.config/kitty/conf.d/titan-ai.conf`.

## CLI quick start

```sh
titan-ai setup                       # Google sign-in first; Gemini API key is optional
titan-ai auth google --setup         # guided Desktop-app client setup + sign-in
titan-ai auth google                 # prompts for your OAuth client ID, then signs you in
titan-ai docs                        # full Google sign-in guide, also on installed systems
titan-ai search 'latest Arch Linux news'
titan-ai 'explain btrfs snapshots'   # Gemini is the default provider
titan-ai -p gemini 'summarise this topic'
titan-ai chat                        # interactive session (/provider, /model, /search, /quit)
```

`setup` and `auth google` both walk you through the one-time Google Cloud Desktop OAuth
client ID. That ID is public and stored locally; no secret is shipped in the ISO. If you
already have a GEMINI_API_KEY, `setup` can store it as a fallback.

Environment variables work too and take precedence over the config file:

```sh
export GEMINI_API_KEY='...'
export OPENAI_API_KEY='sk-...'       # only for -p chatgpt / openai
export ANTHROPIC_API_KEY='sk-ant-...' # only for -p claude / anthropic
```

The complete guide also lives in [`docs/GOOGLE_AUTH.md`](docs/GOOGLE_AUTH.md) and is printed
by `titan-ai docs`:

```sh
titan-ai auth google            # browser callback (PKCE loopback)
titan-ai auth google --device   # headless terminal / SSH
titan-ai auth status
```

## Command reference

| Command | Purpose |
|---|---|
| `titan-ai PROMPT` / `titan-ai ask PROMPT` | Ask the default/first configured provider |
| `titan-ai -p NAME PROMPT` | Force `openai`/`chatgpt`, `claude`/`anthropic`, `gemini`/`google` |
| `titan-ai --all PROMPT` | Ask every configured provider and print labelled answers |
| `titan-ai search QUERY` | Google Search grounding via Gemini, with citations |
| `titan-ai search --links QUERY` | Print only source links |
| `titan-ai chat` | Interactive multi-turn session |
| `titan-ai status` | Show providers, models and auth methods |
| `titan-ai setup` | Google-sign-in-first setup; optional Gemini API key fallback (`0600` config) |
| `titan-ai config {show,path,edit,set,unset}` | Manage settings |
| `titan-ai auth {google,status,logout}` | Google sign-in management (`--setup` guide, `--device` headless) |
| `titan-ai docs` | Print the full Google sign-in and Search guide |

Global options: `-p/--provider`, `-m/--model`, `--system`, `--max-tokens`, `--temperature`,
`--timeout`, `--all`, `-j/--json`, `--links`. Use `-` to read the prompt from stdin, e.g.
`cat README.md | titan-ai -p claude - 'summarise this'`. With `-j`, output is a JSON object
`{provider, text, raw}` for scripting.

## Configuration

File: `$XDG_CONFIG_HOME/archtitan/titan-ai.json` (default `~/.config/archtitan/titan-ai.json`),
mode `0600`. A non-secret template ships at
`~/.config/archtitan/titan-ai.example.json`.

```json
{
  "default_provider": "auto",
  "system": "You are Titan AI ...",
  "timeout": 120,
  "max_tokens": 2048,
  "models": {
    "openai": "gpt-5.4-mini",
    "claude": "claude-haiku-5-5",
    "gemini": "gemini-2.5-flash"
  },
  "providers": {
    "openai": {"api_key": null},
    "claude": {"api_key": null},
    "gemini": {"api_key": null}
  },
  "google_oauth": {"client_id": null, "client_secret": null, "project_id": null}
}
```

Environment overrides: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`/`GOOGLE_API_KEY`,
`TITAN_AI_<PROVIDER>_MODEL`, `OPENAI_BASE_URL`, `ANTHROPIC_BASE_URL`, `GEMINI_BASE_URL`,
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_CLOUD_PROJECT`, `XDG_CONFIG_HOME`.
`default_provider: "auto"` prefers Gemini whenever Google sign-in, an API key or ADC is
available; `setup`/`auth google` set it to `gemini` explicitly. For Google, an explicit
sign-in takes precedence over an API key; set `TITAN_AI_GOOGLE_AUTH=api_key|oauth|adc`
to force one method.

## Build / integration

Install on your host machine (builds and installs to `/usr/local/bin`, or to `~/.local/bin`
if sudo is not available; also configures Kitty conf.d and fish completions):

```sh
bash subsystems/titan-ai/install-host.sh
```

Stage into the ISO `airootfs`:

```sh
bash subsystems/titan-ai/build.sh
```

The ISO build script compiles with CMake and installs:

- `airootfs/usr/local/bin/titan-ai` — C++ engine
- `airootfs/usr/local/bin/titan-ai-kitty` — Kitty prompt wrapper
- `configs/kitty-titan-ai.conf` → `~/.config/kitty/conf.d/titan-ai.conf` for skel + live user
- example config and fish completions

Build host requirements: `cmake`, `pkgconf`, a C++20 compiler, libcurl headers (the `curl`
package) and OpenSSL headers. All are available from the Arch repos; at runtime only `curl`
(via `libcurl.so`) is needed and it is already in `packages.x86_64`. `profiledef.sh` grants
the executable bits in the ISO.

Run the tests (fake Gemini API, no keys or network needed):

```sh
python3 -m unittest discover -s subsystems/titan-ai/tests -v
```

The C++ suite builds the binary and exercises plain answers, grounded answers with citations,
`--links`, JSON output, private config files and the Kitty assets. The older Python file in
`src/` is kept only as a reference implementation; it is not installed in the image.

## Folder structure

```
subsystems/titan-ai/
├── src/titan_ai.cpp                 # C++20 engine
├── src/json.hpp                     # minimal JSON parser/serializer
├── src/http.hpp                     # libcurl wrapper
├── src/titan_ai.py                  # legacy reference (not installed)
├── CMakeLists.txt
├── kitty/titan-ai-kitty.sh          # Kitty prompt wrapper
├── configs/kitty-titan-ai.conf      # Ctrl+Shift+S keybinding
├── configs/titan-ai.example.json    # non-secret config template
├── configs/titan-ai.fish            # fish completions
├── docs/GOOGLE_AUTH.md              # sign-in setup guide
├── tests/test_cpp_engine.py         # C++ end-to-end tests
├── tests/test_titan_ai.py           # legacy Python unit tests
├── build.sh                         # compile + install into airootfs
└── README.md
```

## Security notes

- No key, token or OAuth client secret is stored in the ISO image.
- Config and token files are created with `0600` in a `0700` directory.
- `titan-ai config show` masks secrets.
- API calls go directly from the user's session to the provider over HTTPS.
- Search uses Gemini `google_search` grounding — the official Google path for new projects.
  Gemini has a limited free tier; grounding may be billed separately. Google's Custom Search
  JSON API is closed to new customers, and scraping search results is not used. Check quota
  at https://aistudio.google.com/app/apikey and https://console.cloud.google.com/apis/dashboard.
