# TITAN AI

> **Subsystem:** TITAN AI  
> **Status:** ✅ Implemented (C++ engine + Kitty shortcut)<br>
> **Command:** `titan-ai` · fish alias `ai` · **Kitty:** <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd>

## Overview

TITAN AI gives ArchTitan OS one unified AI/search interface for:

- **ChatGPT / OpenAI** — Chat Completions API
- **Claude / Anthropic** — Messages API
- **Gemini / Google** — Generative Language API
- **Google Search** — Gemini `google_search` grounding with inline citations

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
titan-ai setup                       # store API keys in ~/.config/archtitan/titan-ai.json
titan-ai 'explain btrfs snapshots'   # provider chosen automatically
titan-ai -p claude 'review this shell script'
titan-ai -p chatgpt 'write a fish alias for git status'
titan-ai --all 'compare these two approaches'
titan-ai search 'latest Arch Linux news'
titan-ai chat                        # interactive session (/provider, /model, /search, /quit)
```

Environment variables work too and take precedence over the config file:

```sh
export OPENAI_API_KEY='sk-...'
export ANTHROPIC_API_KEY='sk-ant-...'
export GEMINI_API_KEY='...'
```

For Google sign-in without an API key, see [`docs/GOOGLE_AUTH.md`](docs/GOOGLE_AUTH.md):

```sh
titan-ai config set google_oauth.client_id '...apps.googleusercontent.com'
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
| `titan-ai setup` | Interactive key setup (writes a `0600` config) |
| `titan-ai config {show,path,edit,set,unset}` | Manage settings |
| `titan-ai auth {google,status,logout}` | Google sign-in management |
| `titan-ai docs` | Print the Google sign-in guide |

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
`default_provider: "auto"` picks the first provider with working credentials. For Google,
an explicit sign-in takes precedence over an API key; set `TITAN_AI_GOOGLE_AUTH=api_key|oauth|adc`
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
- Search grounding may be billed by Google; check your provider quotas.
