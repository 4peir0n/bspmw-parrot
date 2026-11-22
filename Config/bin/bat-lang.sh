#!/bin/sh
# Select a bat syntax theme from the language requested with -l / --language.
# All original arguments are passed through to bat unchanged.

default_theme="${BAT_THEME:-OneHalfDark}"

theme_for_lang() {
    case "$1" in
        java|jsp|kt|kts|scala|groovy)             printf '%s\n' 'Visual Studio Dark+' ;;
        lua)                                      printf '%s\n' 'Nord' ;;
        js|jsx|mjs|ts|tsx|javascript|typescript)  printf '%s\n' 'Dracula' ;;
        rb|ruby)                                  printf '%s\n' 'Dracula' ;;
        sh|bash|zsh|fish|shell)                   printf '%s\n' 'Solarized (dark)' ;;
        json|yaml|yml|toml|ini|xml)               printf '%s\n' 'GitHub' ;;
        c|h|cpp|hpp|cc|cxx)                       printf '%s\n' 'Coldark-Dark' ;;
        html|css|scss|sass|less|vue)              printf '%s\n' 'Coldark-Dark' ;;
        rs|rust)                                  printf '%s\n' 'TwoDark' ;;
        go|golang)                                printf '%s\n' 'Monokai Extended Origin' ;;
        sql|php)                                  printf '%s\n' 'Sublime Snazzy' ;;
        *)                                        printf '%s\n' "$default_theme" ;;
    esac
}

lang=''
need_value=0
for arg in "$@"; do
    if [ "$need_value" -eq 1 ]; then
        lang="$arg"
        break
    fi
    case "$arg" in
        -l|--language) need_value=1 ;;
        -l=*)          lang="${arg#-l=}"; break ;;
        --language=*)  lang="${arg#--language=}"; break ;;
        -l*)           lang="${arg#-l}"; break ;;
    esac
done

if [ -n "$lang" ]; then
    lang=$(printf '%s' "$lang" | tr '[:upper:]' '[:lower:]')
    exec bat --theme "$(theme_for_lang "$lang")" "$@"
fi
exec bat "$@"
