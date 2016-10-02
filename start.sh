#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2016 Lasse Meyer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Author: 	Lasse Meyer
# Source:	https://github.com/meyerlasse/Linux-Startup

## User variables - NEED TO BE CHANGED

readonly USER_GIT_NAME="Lasse Meyer"
readonly USER_GIT_EMAIL="meyer.lasse@gmail.com"
readonly USER_SSH_BANNER="Lasse Meyer <meyer.lasse@gmail.com>"
readonly USER_SSH_KEYS=("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUMuxgGk1fje/hwY7TGC6cF+9AndEo6mryQ7VYKCOlBk8kVgLDRYG7uK8iotzFo/czIFzIi30smYh4B9XPAhYS6viPlhd4pSlob7OPK6eL8goO3mSU4mWzCOPW7ceRXlmQcLU1Q6q+zGts4Cw4anWVQNx9VhTxth0AyZMaKGXMerFG6Abwycsm1QncNZpQtghfCDa1f332LagZQnd1ds5TtAHoPBuwLbk6gYeLit6OJgqXW+bLK27IT2NoNOTkeDob5IzJUeb6U0kHuiXvCWnWr9FDsh3QJ4pIXgbothO3IkevIWsDTJL9zUCVLVIeawnNffY8hIQl8JfDLnYLmWPL lasse@ubuntu"\
			   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDS30gjjffeXZefF4bp6DMf6HaP6YAgicZthSLZkgcta6wVa3wVsgm8XHH9drZR8oo6XCYaFWMUt/LQSlxwU8OXd6hWN8CoB3IVNFb1w7FdliP8Ek8+/TVEHx4rMZvzHXCzWGfuI1CkLLZOmI3dXWvAsIvZFffGyDHbxEZd/mMkBGLMTwkInLWKMLSJqL7nfaOcQc1oL2Squo8EW/PErafDfJQN+j792ZCsRa7K7WXJ2LzdENoE0cMc9mc0kfnu5e4TPamptq7csa01dkofJ91C+C55X/bdW0AUqenivho3Jm1/bHtvn/PmAN+ihKzxoRijMG5Nsk1rYADkcHEydrxx meyer.lasse@gmail.com")
readonly USER_DLLOC=de

## Variables

readonly PWD_START=$PWD

readonly FORMAT_BOLD="\e[1m"
readonly FORMAT_RESET_ALL="\e[0m"

readonly COLOR_DEFAULT="\e[39m"
readonly COLOR_RED="\e[31m"
readonly COLOR_GREEN="\e[32m"
readonly COLOR_YELLOW="\e[33m"
readonly COLOR_BLUE="\e[34m"

readonly DL_PREFIX="/tmp"
readonly DEFAULTS="$HOME/.local/share/applications/defaults.list"
readonly ENV_FILE="/etc/environment"

PARAM_QUICK=0
PARAM_LONG=0
PARAM_IMPORTANT=0
PARAM_OFFLINE=0
PARAM_RESTART=0
PARAM_HELP=0
PARAM_DO_UPDATE=1
PARAM_DO_INSTALL=1
PARAM_DO_CONFIG=1
PARAM_DO_HOMEDIR=1
DOS_CLEANED=0
DLLOC_CHANGED=0

export DEBIAN_FRONTEND="noninteractive"

## Functions

# $1 = String to print
_print_info () {
	printf "[$COLOR_GREEN%s$COLOR_DEFAULT] %s\n" "INF" "$1"
}

# $1 = String to print
_print_warning () {
	printf "[$COLOR_YELLOW%s$COLOR_DEFAULT] %s\n" "WRN" "$1"
}

# $1 = String to print
_print_error () {
	printf "[$COLOR_RED%s$COLOR_DEFAULT] %s\n" "ERR" "$1"
}

# $1 = Name of binary to check
_is_installed () {
	which "$1" &> /dev/null
	return $?
}

# $1 = File URL
# $2 = Download location
_download () {
	wget --tries=3 "$1" -P "$2" -q
	return $!
}

# $1 = Git repo URL
# $2 = Target location
_clone () {
	if _is_installed "git"; then
		git clone "$1" "$2" &> /dev/null
		return $?
	else
		return 1
	fi
}

# $1 = Name of software
_install_fail () {
	_print_error "Installing $1 failed"
	return 0
}

# $1 = Name of software
_install_start () {
	_print_info "Installing $1 ..."
	return 0
}

# $1 = Name of software
_install_generic () {
	local SUCCESS=0
	sudo apt-get -y -qq install "$1" &> /dev/null
	if [[ $? -ne 0 ]]; then
		_install_fail "$1"
		SUCCESS=1
	fi
	return $SUCCESS
}

# $1 = Name of software
_install_long () {
	_print_info "Installing $1 ... (this could take a while)"
	_install_generic "$1"
	return $?
}

# $1 = Name of software
_install () {
	_install_start "$1"
	_install_generic "$1"
	return $?
}

# $1 = Array of dependencies (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of software that needs dependencies
_install_depends () {
	local SUCCESS=0
	local -a -r DEPENDS=("${!1}")
	for DEP in "${DEPENDS[@]}"; do
		_install_generic "$DEP"
		if [[ $? -ne 0 ]]; then
			SUCCESS=1
		fi
	done
	if [[ $SUCCESS -ne 0 ]]; then
		_print_error "Installing dependencies for $2 failed"
	fi
	return $SUCCESS
}

# $1 = Name of software
# $2 = Download prefix (without file name, without / at the end)
# $3 = File name to download and install
_install_dpkg () {
	local SUCCESS=0
	_install_start "$1"
	_download "$2/$3" "$DL_PREFIX"
	if [[ $? -eq 0 ]]; then
		sudo dpkg -i -G $DL_PREFIX/"$3" > /dev/null
		if [[ $? -ne 0 ]]; then
			_install_fail "$1"
			SUCCESS=1
		fi
		rm -f $DL_PREFIX/"$3"
	else
		_install_fail "$1"
		SUCCESS=1
	fi
	return $SUCCESS
}

# $1 = Name of software
# $2 = URL of script
# $3 = Destination file name (full path)
_install_script () {
	local SUCCESS=0
	_install_start "$1"
	curl --retry 3 -s "$2" > "$3" 2> /dev/null
	SUCCESS=$?
	if [[ $SUCCESS -eq 0 ]]; then
		chmod +x "$3"
		SUCCESS=$?
	fi
	if [[ $SUCCESS -ne 0 ]]; then
		_install_fail "$1"
	fi
	return $SUCCESS
}

# $1 = Name of software
# $2 = URL of repo
# $3 = Target directory
_install_repo () {
	_install_start "$1"
	_clone "$2" "$3"
	if [[ $? -ne 0 ]]; then
		_install_fail "$1"
		return 1
	else
		return 0
	fi
}

# $1 = Array of MIME types (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of desktop file that should be applied
_setmimes () {
	local -a -r MIMES=("${!1}")
	for MIMETYPE in "${MIMES[@]}"; do
		echo "$MIMETYPE=$2" >> "$DEFAULTS"
	done
	return 0
}

# $1 = Path to append to PATH
_append_to_path () {
	# Is the path already in PATH?
	grep "PATH=.*$1" < "$ENV_FILE" &> /dev/null
	if [[ $? -ne 0 ]]; then
		# Cut off "
		sudo sed -i '/^PATH=/ s/\"$//' $ENV_FILE
		# Add new path and add "
		sudo sed -i "/^PATH=/ s|$|:${1}\"|" $ENV_FILE
	fi
	return 0
}

# $1 = Array of directories to delete (has to be passed like this: NAME_OF_ARRAY[@])
_delete_dirs () {
	local -a -r DIRECS=("${!1}")
	for DIR in "${DIRECS[@]}"; do
		rm -rf "$DIR"
	done
	return 0
}

_change_dlloc () {
	if [[ $PARAM_OFFLINE -ne 1 ]]; then
		sudo sed -i "s|http://..\.archive|http://${USER_DLLOC}.archive|g" /etc/apt/sources.list
		sudo apt-get -qq update &> /dev/null
		DLLOC_CHANGED=1
	fi
}

_do_homedir () {
	_print_info "Setting up home directory ..."

	# Create .customrc and .customprofile
	local -r FILE_PROFILE="$HOME"/.profile
	local -r FILE_BASHRC="$HOME"/.bashrc
	# shellcheck disable=2034
	local -r FILE_CUSTOMPROFILE="$HOME"/.customprofile
	# shellcheck disable=2034
	local -r FILE_CUSTOMRC="$HOME"/.customrc

	cat <<- 'EOF' > "$FILE_CUSTOMPROFILE"
		export PATH=$PATH:$HOME/bin
		export PS4='[ \$LINENO ] '
		export EDITOR="nano"

	EOF

	cat <<- 'EOF' > "$FILE_CUSTOMRC"
		# Moving through, looking at & searching through directories
		alias go-dl='cd ~/Downloads'
		alias go-pr='cd ~/projects'
		alias go-re='cd ~/repos'
		alias ll='ls -AlFh --color=auto'
		alias ls='ls -lFh --color=auto'
		alias l='ls -ACF --color=auto'
		alias exp='nautilus . &> /dev/null &'
		alias dsize='du -sh'
		alias grap='grep -R -n -i -e'
		alias fond='find . -name'

		# Applications
		alias more='less -F'
		alias less='less -F'
		alias git-count='git rev-list --all --count'
		alias giff='git diff HEAD'
		alias giss='git status'
		alias gpush='git push'
		alias gpull='git pull'
		alias ggui='git gui'
		alias cloc-all='cloc *.c *.h Makefile'
		alias make='make -j4'

		# Other
		alias src='. ~/.bashrc'
		alias dta='dmesg | tail'
		alias grip='ps aux | grep -i -e'
		alias updog='sudo apt-get update; sudo apt-get upgrade'
		alias dl='sudo apt-get install'

		# Create directory and enter it
		# $1 = Name of new directory
		mkc () {
		    mkdir "$1"
		    cd "$1"
		}

		# Move up multiple directories at once
		# $1 = Number of directories to go up
		up () {
		    local D=""
		    limit=$1
		    for ((I=1 ; I <= limit ; I++)); do
		        D=$D/..
		    done
		    D=$(echo $D | sed 's/^\///')
		    if [[ -z "$D" ]]; then
		        D=..
		    fi
		    cd $D
		}

		# For colored manpages
		export LESS_TERMCAP_mb=$'\E[01;31m'
		export LESS_TERMCAP_md=$'\E[01;31m'
		export LESS_TERMCAP_me=$'\E[0m'
		export LESS_TERMCAP_se=$'\E[0m'
		export LESS_TERMCAP_so=$'\E[01;44;33m'
		export LESS_TERMCAP_ue=$'\E[0m'
		export LESS_TERMCAP_us=$'\E[01;32m'

		# Command history settings
		# Combine multiline commands into one in history
		shopt -s cmdhist
		shopt -s histappend
		HISTCONTROL=ignoreboth:erasedups
		HISTIGNORE="${HISTIGNORE}:ls:ll:l:cd:"
		HISTFILESIZE=10000
		HISTSIZE=${HISTFILESIZE}
		PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

		# HSTR settings
		export HH_CONFIG=hicolor,rawhistory,blacklist
		bind '"\C-r": "\C-a hh \C-j"'

		# qfc
		[[ -s "$HOME/.qfc/bin/qfc.sh" ]] && source "$HOME/.qfc/bin/qfc.sh"
		qfc_quick_command 'cd' '\C-n' 'cd $0'

	EOF

	# Check if .customrc is sourced in .bashrc
	grep "customrc" < "$FILE_BASHRC" &> /dev/null
	if [[ $? -ne 0 ]]; then
		echo -e "\nsource ~/.customrc" >> "$FILE_BASHRC"
	fi

	# Check if .customprofile is sourced in .profile
	grep "customprofile" < "$FILE_PROFILE" &> /dev/null
	if [[ $? -ne 0 ]]; then
		echo -e "\nsource ~/.customprofile" >> "$FILE_PROFILE"
	fi

	# Delete most preexisting repositories in home directory
	# shellcheck disable=2034
	local -a -r DEL_DIRS=(\
		"$HOME/Documents"\
		"$HOME/Dokumente"\
		"$HOME/Music"\
		"$HOME/Musik"\
		"$HOME/Videos"\
		"$HOME/Pictures"\
		"$HOME/Bilder"\
		"$HOME/Templates"\
		"$HOME/Vorlagen"\
		"$HOME/Public"\
		"$HOME/Öffentlich")
	_delete_dirs DEL_DIRS[@]
	rm -f "$HOME"/examples.desktop

	# Create standard directories
	mkdir -p "$HOME/bin"
	mkdir -p "$HOME/projects/Archiv"
	mkdir -p "$HOME/repos"

	return 0
}

_do_update () {
	_print_info "Updating ..."

	if [ $DLLOC_CHANGED -ne 1 ]; then
		_change_dlloc
	fi

	# Add texlive repository after first update, because it would always cause
	# apt-get update to throw errors that really should be warnings
	sudo add-apt-repository -y ppa:texlive-backports/ppa &> /dev/null
	sudo add-apt-repository -y ppa:ultradvorka/ppa &> /dev/null
	sudo apt-get -qq update &> /dev/null

	if [[ $PARAM_QUICK -ne 1 ]]; then
		_print_info "Upgrading ... (this could take a while)"
		sudo apt-get -y -qq upgrade > /dev/null
		if [[ $? -ne 0 ]]; then
			_print_error "Upgrade failed"
		fi
	fi

	return 0
}

_configure_git () {
	git config --global user.email "$USER_GIT_EMAIL"
	git config --global user.name "$USER_GIT_NAME"

	return 0
}

_configure_tmux () {
	# shellcheck disable=2034
	local -r TMUX_CONFIG="$HOME"/.tmux.conf
	cat <<- 'EOF' > "$TMUX_CONFIG"
		# Enable mouse mode (tmux 2.1 and above)
		# set -g mouse on

		######################
		### DESIGN CHANGES ###
		######################

		# panes
		set -g pane-border-fg black
		set -g pane-active-border-fg brightred

		## Status bar design
		# status line
		set -g status-utf8 on
		set -g status-justify left
		set -g status-bg default
		set -g status-fg colour12
		set -g status-interval 1

		# messaging
		set -g message-fg black
		set -g message-bg yellow
		set -g message-command-fg blue
		set -g message-command-bg black

		# window mode
		setw -g mode-bg colour6
		setw -g mode-fg colour0

		# window status
		setw -g window-status-format " #F#I:#W#F "
		setw -g window-status-current-format " #F#I:#W#F "
		setw -g window-status-format "#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "
		setw -g window-status-current-format "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W "
		setw -g window-status-current-bg colour0
		setw -g window-status-current-fg colour11
		setw -g window-status-current-attr dim
		setw -g window-status-bg green
		setw -g window-status-fg black
		setw -g window-status-attr reverse

		# Info on left (I don't have a session display for now)
		set -g status-left ''

		# loud or quiet?
		set-option -g visual-activity off
		set-option -g visual-bell off
		set-option -g visual-silence off
		set-window-option -g monitor-activity off
		set-option -g bell-action none

		set -g default-terminal "screen-256color"

		# The modes
		setw -g clock-mode-colour colour135
		setw -g mode-attr bold
		setw -g mode-fg colour196
		setw -g mode-bg colour238

		# The panes
		set -g pane-border-bg colour0
		set -g pane-border-fg colour238
		set -g pane-active-border-bg colour0
		set -g pane-active-border-fg colour51

		# The statusbar
		set -g status-position bottom
		set -g status-bg colour234
		set -g status-fg colour137
		set -g status-attr dim
		set -g status-left ''
		set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
		set -g status-right-length 50
		set -g status-left-length 20

		setw -g window-status-current-fg colour81
		setw -g window-status-current-bg colour238
		setw -g window-status-current-attr bold
		setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '

		setw -g window-status-fg colour138
		setw -g window-status-bg colour235
		setw -g window-status-attr none
		setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

		setw -g window-status-bell-attr bold
		setw -g window-status-bell-fg colour255
		setw -g window-status-bell-bg colour1

		# The messages
		set -g message-attr bold
		set -g message-fg colour232
		set -g message-bg colour166

		# Activate pane switching with ALT + ARROW
		bind -n M-Left select-pane -L
		bind -n M-Right select-pane -R
		bind -n M-Up select-pane -U
		bind -n M-Down select-pane -D

		# Activate window switching with CTRL + SHIFT + ARROW
		bind -n C-S-Left previous-window
		bind -n C-S-Right next-window

		# Activate scroll mode with CTRL + PageUp
		bind -n C-Pageup copy-mode -u

		# Activate copying to system buffer
		setw -g mode-keys vi
		bind -t vi-copy y copy-pipe 'xclip -in -selection clipboard'

	EOF
	if _is_installed git; then
		git clone https://github.com/aurelien-rainone/tmux-gitbar.git "$HOME"/.tmux-gitbar &> /dev/null
		if [[ $? -eq 0 ]]; then
			cat <<- 'EOF' >> "$TMUX_CONFIG"
				# Git-bar
				set -g status-right-length 100
				source-file "~/.tmux-gitbar/tmux-gitbar.tmux"

			EOF
		fi
	fi

	return 0
}

_do_install_oclint () {
	local OCLINT_RETURN=0
	if ! _is_installed oclint; then
		local -r OCLINT_VERSION="0.10.2"
		local -r OCLINT_SITE="https://github.com/oclint/oclint/releases/download/v${OCLINT_VERSION}"
		local -r OCLINT_FILE="oclint-${OCLINT_VERSION}-x86_64-linux-3.13.0-48-generic.tar.gz"
		local -r OCLINT_DIR="oclint-${OCLINT_VERSION}"
		_install_start "oclint"

		# Download
		_download "$OCLINT_SITE/$OCLINT_FILE" "$DL_PREFIX"
		OCLINT_RETURN=$!
		# Unpack
		if [[ $OCLINT_RETURN -eq 0 ]]; then
			cd "$DL_PREFIX"
			tar xzf "$DL_PREFIX/$OCLINT_FILE"
			OCLINT_RETURN=$!
			rm -f "$DL_PREFIX/$OCLINT_FILE"
		fi
		# Install
		if [[ $OCLINT_RETURN -eq 0 ]]; then
			cd "$DL_PREFIX/$OCLINT_DIR"
			OCLINT_RETURN=$!
		fi
		if [[ $OCLINT_RETURN -eq 0 ]]; then
			sudo cp bin/oclint* /usr/local/bin/
			sudo cp -rp lib/* /usr/local/lib/
			rm -r -f "${DL_PREFIX:?}/$OCLINT_DIR"
		fi

		if [[ $OCLINT_RETURN -ne 0 ]]; then
			_install_fail "oclint"
		fi

		cd "$PWD_START"
	fi
	return $OCLINT_RETURN
}

_do_install_sublime () {
	if ! _is_installed subl; then
		local -r SUBL_VERSION=3126
		local -r SUBL_NAME="Sublime Text 3"
		local -r SUBL_SITE="https://download.sublimetext.com"
		local -r SUBL_FILE="sublime-text_build-${SUBL_VERSION}_amd64.deb"
		_install_dpkg "$SUBL_NAME" $SUBL_SITE $SUBL_FILE
		return $?
	fi
	return 0
}

_do_install_chrome () {
	if ! _is_installed google-chrome; then
		local -r CHROME_NAME="Google Chrome"
		local -r CHROME_SITE="https://dl.google.com/linux/direct"
		local -r CHROME_FILE="google-chrome-stable_current_amd64.deb"
		# shellcheck disable=2034
		local -r -a CHROME_DEPENDS=("libindicator7" "libappindicator1")
		_install_depends CHROME_DEPENDS[@] "$CHROME_NAME"
		if [[ $? -eq 0 ]]; then
			_install_dpkg "$CHROME_NAME" $CHROME_SITE $CHROME_FILE
			return $?
		fi
		return 1
	fi
	return 0
}

_do_install_hr () {
	if ! _is_installed hr; then
		local -r HR_NAME="hr"
		local -r HR_URL="https://raw.githubusercontent.com/LuRsT/hr/master/hr"
		local -r HR_FILE="$HOME"/bin/hr
		_install_script "$HR_NAME" "$HR_URL" "$HR_FILE"
		return $?
	fi
	return 0
}

_do_install_qfc () {
	if ! _is_installed "git"; then
		_install_fail "qfc"
		return 1
	fi
	if ! _is_installed "qfc"; then
		git clone https://github.com/pindexis/qfc "$HOME"/.qfc &> /dev/null
		if [[ $? -ne 0 ]]; then
			_install_fail "qfc"
		fi
	fi
	return 0
}

_do_install () {
	if [ $DLLOC_CHANGED -ne 1 ]; then
		_change_dlloc
	fi

	_install git && _configure_git
	_install git-gui
	_install tmux && _configure_tmux
	_install xclip
	_install htop
	_install build-essential
	_install unp
	_install hh
	_do_install_sublime
	_do_install_chrome

	if [[ $PARAM_IMPORTANT -ne 1 ]]; then
		_install tmuxinator
		_install openssh-server
		_install cloc
		_install tig
		_install subversion
		_install cmake
		_install automake
		_install shellcheck
		_install valgrind
		_install bear
		_install unity-tweak-tool
		_install qalc
		_install tpp
		_install hollywood
		_install rar
		_install unrar
		_install rtorrent
		_do_install_oclint
		_do_install_hr
		_do_install_qfc
	fi

	if [[ $PARAM_LONG -eq 1 ]]; then
		_install_long ubuntu-restricted-extras
		_install_long texlive
		_install_long latexmk
		_install_long texlive-lang-german
		_install_long texlive-latex-extra
		_install_long texlive-fonts-extra
		_install_long texlive-bibtex-extra
		_install_long openjdk-8-jdk
	fi

	sudo apt-get autoremove > /dev/null

	return 0
}

_do_config_general () {
	sudo bash -c "usermod -a -G dialout $USER"
	sudo bash -c "usermod -a -G tty $USER"
	rm -f "$HOME"/.config/monitors.xml
	local -r LIGHTDM_CONF="/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
	grep 'allow-guest=false' < $LIGHTDM_CONF &> /dev/null
	if [[ $? -ne 0 ]]; then
		sudo bash -c "echo 'allow-guest=false' >> $LIGHTDM_CONF"
	fi
	if [ $DLLOC_CHANGED -ne 1 ]; then
		_change_dlloc
	fi
	# Locale and timezone
	timedatectl set-timezone Europe/Berlin
	sudo locale-gen de_DE.UTF-8 > /dev/null
	sudo update-locale LANG=de_DE.UTF-8
	# Default applications
	echo "[Default Applications]" > "$DEFAULTS"
	local -r DESKTOP_SUBL="sublime_text.desktop"
	# shellcheck disable=2034
	local -a -r MIMES_SUBL=(\
		"text/xml"\
		"text/richtext"\
		"text/x-java"\
		"text/plain"\
		"text/tab-separated-values"\
		"text/x-c++hdr"\
		"text/x-c++src"\
		"text/x-chdr"\
		"text/x-csrc"\
		"text/x-sql"\
		"text/x-python"\
		"text/x-dtd"\
		"text/mathml"\
		"application/x-perl")
	_setmimes MIMES_SUBL[@] $DESKTOP_SUBL
	local -r DESKTOP_CHROME="google-chrome.desktop"
	# shellcheck disable=2034
	local -a -r MIMES_CHROME=(\
		"appplication/xhtml+xml"\
		"application/xhtml_xml"\
		"text/html"\
		"x-scheme-handler/http"\
		"x-scheme-handler/https"\
		"x-scheme-handler/ftp")
	_setmimes MIMES_CHROME[@] $DESKTOP_CHROME

	return 0
}

_do_config_variables () {
	# Modifying global environment variables and library search path for linker
	local -r LOCAL_LIB=/usr/local/lib
	local -r LD_CONFIG_PATH=/etc/ld.so.conf.d
	local -r LD_CONFIG_CUSTOM=$LD_CONFIG_PATH/user.conf

	grep -R $LD_CONFIG_PATH -e $LOCAL_LIB &> /dev/null
	if [[ $? -ne 0 ]]; then
		sudo bash -c "echo $LOCAL_LIB > $LD_CONFIG_CUSTOM"
	fi
	_append_to_path "/usr/local/bin"
	_append_to_path "/usr/local/sbin"

	return 0
}

_do_config_desktop () {
	dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-capture-mouse false
	dconf write /org/compiz/profiles/unity/plugins/unityshell/icon-size 35
	gsettings set com.ubuntu.update-notifier no-show-notifications true
	gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/Flora_by_Marek_Koteluk.jpg
	gsettings set org.gnome.desktop.interface clock-show-date true
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0
	gsettings set org.compiz.unityshell:/org/compiz/profiles/unity/plugins/unityshell/ launcher-minimize-window true
	gsettings set com.canonical.Unity always-show-menus true
	gsettings set com.canonical.Unity integrated-menus true
	gsettings set com.canonical.Unity.Launcher favorites "['application://gnome-terminal.desktop', 'application://org.gnome.Nautilus.desktop', 'application://google-chrome.desktop', 'application://sublime_text.desktop', 'application://unity-control-center.desktop', 'unity://running-apps', 'unity://expo-icon', 'unity://devices', 'unity://desktop-icon']"
	gsettings set org.gnome.desktop.media-handling automount-open false

	return 0
}

_do_config_terminal () {
	# Terminal
	local TPROFILE
	TPROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default)
	TPROFILE=${TPROFILE:1:-1}
	dconf write /org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/palette "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,205)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(250,235,215)', 'rgb(64,64,64)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(0,0,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
	dconf write /org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/use-theme-colors false
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ background-color "#000000"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ foreground-color "#FFFFFF"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ scrollback-unlimited true
	# PS1 for root
	local -r ROOTCUSTOMRC="/root/.customrc"
	sudo bash -c "echo 'export PS1=\"\\\${debian_chroot:+(\\\$debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# \"' > $ROOTCUSTOMRC"
	sudo bash -c "grep customrc < /root/.bashrc &> /dev/null"
	if [[ $? -ne 0 ]]; then
		sudo bash -c "echo '\nsource ~/.customrc' >> /root/.bashrc"
	fi

	return 0
}

_do_config_ssh () {
	local -r SSH_DIR=$HOME/.ssh
	local -r SSH_FILE=$SSH_DIR/id_rsa
	local -r SSH_PFILE=$SSH_FILE.pub
	local -r SSH_KFILE=$SSH_DIR/authorized_keys

	mkdir -p "$SSH_DIR"
	chmod 700 "$SSH_DIR"
	if [[ -f $SSH_FILE ]]; then
		mv "$SSH_FILE" "$SSH_DIR"/id_rsa.old
		_print_warning "SSH key files already existed, renamed to id_rsa.old and id_rsa.pub.old"
	fi
	if [[ -f $SSH_PFILE ]]; then
		mv "$SSH_PFILE" "$SSH_DIR"/old_id_rsa.pub.old
	fi
	ssh-keygen -q -t rsa -N "" -f "$SSH_FILE"
	touch "$SSH_KFILE"
	chmod 600 "$SSH_KFILE"

	for I in "${USER_SSH_KEYS[@]}"; do
		echo "$I" >> "$SSH_KFILE"
	done

	# SSH server
	if _is_installed sshd; then
		local -r SSH_SCONFIG=/etc/ssh/sshd_config
		if [[ -f $SSH_SCONFIG ]]; then
			sudo cp $SSH_SCONFIG $SSH_SCONFIG.default
		fi
		sudo sed -i '/#PasswordAuthentication/c\PasswordAuthentication no' $SSH_SCONFIG
		sudo sed -i '/#Banner/c\Banner /etc/issue.net' $SSH_SCONFIG
		sudo sed -i -e "\$a${USER_SSH_BANNER}" /etc/issue.net
		sudo systemctl restart ssh
	fi

	return 0
}

_do_config_nano () {
	if _is_installed nano; then
		# shellcheck disable=2034
		local -r NANO_CONFIG="$HOME"/.nanorc
		cat <<- 'EOF' > "$NANO_CONFIG"
			set tabsize 4
			set const

		EOF
	fi

	return 0
}

_do_config () {
	_print_info "Configuring ..."

	_do_config_general
	_do_config_variables
	_do_config_desktop
	_do_config_terminal
	_do_config_ssh
	_do_config_nano

	return 0
}

# shellcheck disable=2059
_show_help () {
	# General stuff
	printf "${FORMAT_BOLD}${COLOR_BLUE}***${COLOR_DEFAULT} Linux-Startup user manual ${COLOR_BLUE}***${COLOR_DEFAULT}${FORMAT_RESET_ALL}\n"
	printf "A script to install, set and configure basic things that you need for a new Linux setup.\n\n"
	# Parameters
	printf "${FORMAT_BOLD}Parameters:${FORMAT_RESET_ALL}\n\n"
	printf -- "-q / --quick\t\tDon't do anything that takes a significant amount of time (~ >1 min)\n"
	printf -- "-i / --important\tOnly install important programs\n"
	printf -- "-o / --offline\t\tDon't do anything that requires an internet connection\n"
	printf -- "-r / --restart\t\tRestart when done\n"
	printf -- "-h / --help\t\tShow help, don't do anything else\n"
	printf -- "--do_homedir\t\tCall homedir function\n"
	printf -- "--do_update\t\tCall update function\n"
	printf -- "--do_install\t\tCall install function\n"
	printf -- "--do_ssh\t\tCall SSH function\n"
	printf -- "--do_config\t\tCall config function\n\n"
	printf "If one or more of the *--do_** parameters are used, only the according functions will be called, but not the others.\n"
	printf "These parameters do not have priority, so if you use both *--offline* and *--do_install*, nothing will happen.\n\n"
	# Info
	printf "${FORMAT_BOLD}Info:${FORMAT_RESET_ALL}\n\n"
	printf "Author:\t\tLasse Meyer\n"
	printf "Source:\t\thttps://github.com/meyerlasse/Linux-Startup\n"
	printf "License:\tMIT (https://github.com/meyerlasse/Linux-Startup/blob/master/LICENSE.md)\n"
}

_clean_dos () {
	if [[ $DOS_CLEANED -ne 1 ]]; then
		PARAM_DO_UPDATE=0
		PARAM_DO_INSTALL=0
		PARAM_DO_CONFIG=0
		PARAM_DO_HOMEDIR=0
		DOS_CLEANED=1
	fi
	return 0
}

## Parameter parsing

while [[ $# -gt 0 ]]; do
	PARAM="$1"
	case $PARAM in
		-q|--quick)
			PARAM_QUICK=1
			shift
			;;
		-l|--long)
			PARAM_LONG=1
			shift
			;;
		-i|--important)
			PARAM_IMPORTANT=1
			shift
			;;
		-o|--offline)
			PARAM_OFFLINE=1
			shift
			;;
		-r|--restart)
			PARAM_RESTART=1
			shift
			;;
		-h|--help)
			PARAM_HELP=1
			shift
			;;
		--do_update)
			_clean_dos
			PARAM_DO_UPDATE=1
			shift
			;;
		--do_install)
			_clean_dos
			PARAM_DO_INSTALL=1
			shift
			;;
		--do_config)
			_clean_dos
			PARAM_DO_CONFIG=1
			shift
			;;
		--do_homedir)
			_clean_dos
			PARAM_DO_HOMEDIR=1
			shift
			;;
		*)
			_print_error "Invalid parameter: $PARAM"
			exit 1
		;;
	esac
done

## Check if run without sudo

if [[ $PARAM_HELP -eq 1 ]]; then
	_show_help
	exit 0
fi

if [[ $EUID == 0 ]]; then
	_print_error "Don't run with sudo or as root!"
	exit 1
fi

if [[ $PARAM_DO_UPDATE -eq 1 || $PARAM_DO_INSTALL -eq 1 || $PARAM_DO_CONFIG -eq 1 ]]; then
	sudo test
fi

if [[ $PARAM_DO_HOMEDIR -eq 1 ]]; then
	_do_homedir
fi
if [[ $PARAM_DO_UPDATE -eq 1 && $PARAM_OFFLINE -eq 0 ]]; then
	_do_update
fi
if [[ $PARAM_DO_INSTALL -eq 1 && $PARAM_OFFLINE -eq 0 ]]; then
	_do_install
fi
if [[ $PARAM_DO_CONFIG -eq 1 ]]; then
	_do_config
fi

## End

cd "$PWD_START"
_print_info "Done."

if [[ $PARAM_RESTART -eq 0 ]]; then
	# shellcheck disable=2059
	printf "[${COLOR_GREEN}INF${COLOR_DEFAULT}] You should run '${FORMAT_BOLD}. ~/.bashrc${FORMAT_RESET_ALL}' now.\n"
else
	_print_info "Restarting..."
	sudo reboot
fi

exit 0
