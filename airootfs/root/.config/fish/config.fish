# ArchTitan OS — fish shell, mirroring the host terminal experience.
if status is-interactive
    # Root login gets the ArchTitan system summary.
    fastfetch

    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end

    # Apply the host-style terminal palette (OSC sequences) so prompts stay
    # consistent in terminals that do not read ~/.config/kitty/current-theme.conf.
    if test -f ~/.config/kitty/sequences.txt
        cat ~/.config/kitty/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end

# THM help by default
function help
    if test (count $argv) -eq 0
        if command -s titan-hwm >/dev/null
            command titan-hwm help
            return 0
        end
    end
    echo "fish help disabled. Use 'titan-hwm help' for THM commands or 'man <cmd>' for docs."
    return 0
end
