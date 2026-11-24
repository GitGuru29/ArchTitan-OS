#!/usr/bin/env bash
# Kitty-side front end for the C++ TITAN AI engine.
# Launched by `map ctrl+shift+s launch ...` in kitty.conf; the user never types titan-ai.
set -uo pipefail

ENGINE="${TITAN_AI_ENGINE:-}"
if [[ -z "${ENGINE}" ]]; then
    ENGINE="$(command -v titan-ai || true)"
fi
ENGINE="${ENGINE:-/usr/local/bin/titan-ai}"
MODE="${1:-search}"

printf '\033]0;TITAN AI - Search\007'

if [[ "$MODE" == "--chat" || "$MODE" == "chat" ]]; then
    printf '\033]0;TITAN AI - Chat\007'
    if [[ ! -x "$ENGINE" ]]; then
        echo "titan-ai engine not installed at $ENGINE"
        read -r -p 'Press Enter to close...' _
        exit 1
    fi
    exec "$ENGINE" chat
fi

if [[ ! -x "$ENGINE" ]]; then
    echo "titan-ai engine not installed at $ENGINE"
    read -r -p 'Press Enter to close...' _
    exit 1
fi

while true; do
    printf '\n\033[1;36mTITAN AI\033[0m  \033[2mGoogle Search via Gemini\033[0m\n'
    printf '\033[2m────────────────────────────────────────────────────────\033[0m\n'
    read -r -p 'search> ' query || break
    [[ -z "$query" ]] && break

    printf '\n'
    if ! "$ENGINE" search "$query"; then
        printf '\n\033[31mSearch failed. In a terminal run `titan-ai auth google` or `titan-ai setup`.\033[0m\n'
        printf '\033[2mHelp: `titan-ai docs`  |  Details: `titan-ai status`\033[0m\n'
    fi

    printf '\n\033[2mEnter: new search  |  q: close window\033[0m\n'
    read -r -p '> ' again || break
    [[ "$again" == 'q' || "$again" == 'quit' || "$again" == 'exit' ]] && break
done
