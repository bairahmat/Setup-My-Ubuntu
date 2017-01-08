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
# Website:	https://github.com/meyerlasse/Linux-Startup

###################################################################################################################################################
### VARIABLES #####################################################################################################################################
###################################################################################################################################################

# User variables, use parameters to override or set them all manually and then set USER_CUSTOM=1
USER_CUSTOM=0

USER_GIT_NAME="Lasse Meyer"
USER_GIT_EMAIL="meyer.lasse@gmail.com"
USER_SSH_BANNER="Lasse Meyer <meyer.lasse@gmail.com>"
USER_SSH_KEYS=(\
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUMuxgGk1fje/hwY7TGC6cF+9AndEo6mryQ7VYKCOlBk8kVgLDRYG7uK8iotzFo/czIFzIi30smYh4B9XPAhYS6viPlhd4pSlob7OPK6eL8goO3mSU4mWzCOPW7ceRXlmQcLU1Q6q+zGts4Cw4anWVQNx9VhTxth0AyZMaKGXMerFG6Abwycsm1QncNZpQtghfCDa1f332LagZQnd1ds5TtAHoPBuwLbk6gYeLit6OJgqXW+bLK27IT2NoNOTkeDob5IzJUeb6U0kHuiXvCWnWr9FDsh3QJ4pIXgbothO3IkevIWsDTJL9zUCVLVIeawnNffY8hIQl8JfDLnYLmWPL lasse@ubuntu"\
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDS30gjjffeXZefF4bp6DMf6HaP6YAgicZthSLZkgcta6wVa3wVsgm8XHH9drZR8oo6XCYaFWMUt/LQSlxwU8OXd6hWN8CoB3IVNFb1w7FdliP8Ek8+/TVEHx4rMZvzHXCzWGfuI1CkLLZOmI3dXWvAsIvZFffGyDHbxEZd/mMkBGLMTwkInLWKMLSJqL7nfaOcQc1oL2Squo8EW/PErafDfJQN+j792ZCsRa7K7WXJ2LzdENoE0cMc9mc0kfnu5e4TPamptq7csa01dkofJ91C+C55X/bdW0AUqenivho3Jm1/bHtvn/PmAN+ihKzxoRijMG5Nsk1rYADkcHEydrxx meyer.lasse@gmail.com")
USER_DLLOC=de

USER_GIT_NAME_C=0
USER_GIT_EMAIL_C=0
USER_SSH_BANNER_C=0
USER_SSH_KEYS_C=0
USER_DLLOC_C=0

# Formatting variables
readonly FORMAT_BOLD="\e[1m"
readonly FORMAT_RESET_ALL="\e[0m"

readonly COLOR_DEFAULT="\e[39m"
readonly COLOR_RED="\e[31m"
readonly COLOR_GREEN="\e[32m"
readonly COLOR_YELLOW="\e[33m"
readonly COLOR_BLUE="\e[34m"

# Static general purpose variables
readonly PWD_START=$PWD
readonly DL_PREFIX="/tmp"
readonly DEFAULTS="$HOME/.local/share/applications/defaults.list"
readonly FILE_BASHRC="$HOME"/.bashrc
readonly FILE_CUSTOMRC="$HOME"/.customrc
readonly FILE_PROFILE="$HOME"/.profile
readonly FILE_CUSTOMPROFILE="$HOME"/.customprofile
# Used by functions if parameter count is invalid
readonly INV_ARGS=45

# Parameter variables
PARAM_QUICK=0
PARAM_LONG=0
PARAM_IMPORTANT=0
PARAM_OFFLINE=0
PARAM_4K=0
PARAM_FORCE=0
PARAM_RESTART=0
PARAM_HELP=0
PARAM_REWRITE_CONFIG=0
PARAM_DO_UPDATE=1
PARAM_DO_INSTALL=1
PARAM_DO_CONFIG=1
PARAM_DO_HOMEDIR=1

# Other variables
DOS_CLEANED=0
DLLOC_CHANGED=0
export DEBIAN_FRONTEND="noninteractive"

###################################################################################################################################################
### HELPER FUNCTIONS ##############################################################################################################################
###################################################################################################################################################

## Printing

# Print info message
# $1 = String to print
_print_info () {
	printf "[$COLOR_GREEN%s$COLOR_DEFAULT] %s\n" "INF" "$1"
	return $?
}

# Print warning message
# $1 = String to print
_print_warning () {
	printf "[$COLOR_YELLOW%s$COLOR_DEFAULT] %s\n" "WRN" "$1"
	return $?
}

# Print error message
# $1 = String to print
_print_error () {
	printf "[$COLOR_RED%s$COLOR_DEFAULT] %s\n" "ERR" "$1"
	return $?
}

# Print installation failure error message
# $1 = Name of software
_install_fail () {
	_print_error "Installing $1 failed"
	return $?
}

# Print installation start info message
# $1 = Name of software
_install_start () {
	_print_info "Installing $1 ..."
	return $?
}

#########################################################################

## Downloading

# Download file with wget
# $1 = File URL
# $2 = Download location
_download () {
	wget --tries=3 "$1" -P "$2" -q
	return $?
}

# Clone a git repository
# $1 = Git repo URL
# $2 = Target location
_clone_git () {
	if _is_installed "git"; then
		git clone "$1" "$2" &> /dev/null
		return $?
	else
		return 1
	fi
}

#########################################################################

## Installing
# See also _install_start & _install_fail in printing section

# Check if program is installed already. Has to be somewhere in $PATH.
# $1 = Name of program to check
_is_installed () {
	which "$1" &> /dev/null
	return $?
}

# Install program with apt-get
# $1 = Name of software
_install_apt () {
	if ! _is_installed; then
		_install_start "$1"
		_install_apt_generic "$1"
		return $?
	fi
	return 0
}

# Install large program with apt-get
# $1 = Name of software
_install_apt_long () {
	_print_info "Installing $1 ... (this could take a while)"
	_install_apt_generic "$1"
	return $?
}

# Download and install dpkg package, if not installed already
# $1 = Name of software (name of binary)
# $2 = File URL
_install_dpkg () {
	if ! _is_installed "$1"; then
		local SUCCESS=0
		_install_start "$1"
		_download "$2" "$DL_PREFIX"
		if (( $? == 0 )); then
			sudo dpkg -i -G $DL_PREFIX/"${2##*/}" > /dev/null
			if (( $? != 0 )); then
				_install_fail "$1"
				SUCCESS=1
			fi
			rm -f $DL_PREFIX/"${2##*/}"
		else
			_install_fail "$1"
			SUCCESS=1
		fi
	fi
	return $SUCCESS
}

# Download and install script with curl, if not installed already somewhere in $PATH
# $1 = Name of script
# $2 = URL of script
# $3 = Destination file name (full path)
_install_script () {
	local SUCCESS=0
	if ! _is_installed "$1"; then
		_install_start "$1"
		curl --retry 3 -s "$2" > "$3" 2> /dev/null
		SUCCESS=$?
		if (( SUCCESS == 0 )); then
			chmod +x "$3"
			SUCCESS=$?
		fi
		if (( SUCCESS != 0 )); then
			_install_fail "$1"
		fi
	fi
	return $SUCCESS
}

# "Install" git repository. Checks if certain binary ($1) is present and if target directory already exists. If both are false, clones repo.
# $1 = Name of software
# $2 = URL of repo
# $3 = Target directory
_install_git_repo () {
	local SUCCESS=0
	if ! _is_installed "$1"; then
		if [[ ! -d "$3" ]]; then
			_install_start "$1"
			_clone_git "$2" "$3"
			if (( $? != 0 )); then
				_install_fail "$1"
				SUCCESS=1
			fi
		fi
	fi
	return $SUCCESS
}

# Install dependencies for something with apt-get
# $1 = Array of dependencies (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of software that needs dependencies
_install_apt_depends () {
	local SUCCESS=0
	local -a -r DEPENDS=("${!1}")
	for DEP in "${DEPENDS[@]}"; do
		_install_apt_generic "$DEP"
		if (( $? != 0 )); then
			SUCCESS=1
		fi
	done
	if (( SUCCESS != 0 )); then
		_print_error "Installing dependencies for $2 failed"
	fi
	return $SUCCESS
}

# Function to be used by other _install_apt functions. Does the actual installation.
# $1 = Name of software
_install_apt_generic () {
	local SUCCESS=0
	sudo apt-get -y -qq install "$1" &> /dev/null
	if (( $? != 0 )); then
		_install_fail "$1"
		SUCCESS=1
	fi
	return $SUCCESS
}

#########################################################################

## Other

# Append path to $PATH globally, permanently. The path is appended only if it isn't included already.
# $1 = Path to append to $PATH
_append_to_path () {
	local -r ENV_FILE="/etc/environment"
	# Is the path already in PATH?
	grep "PATH=.*$1" < "$ENV_FILE" &> /dev/null
	if (( $? != 0 )); then
		# Cut off "
		sudo sed -i '/^PATH=/ s/\"$//' $ENV_FILE
		# Add new path and add "
		sudo sed -i "/^PATH=/ s|$|:${1}\"|" $ENV_FILE
	fi
	return 0
}

# Set standard applications for MIME types (file types)
# $1 = Array of MIME types (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of desktop file that should be applied
_setmimes () {
	local -a -r MIMES=("${!1}")
	for MIMETYPE in "${MIMES[@]}"; do
		echo "$MIMETYPE=$2" >> "$DEFAULTS"
	done
	return 0
}

# Delete an array of directories
# $1 = Array of directories to delete (has to be passed like this: NAME_OF_ARRAY[@])
_delete_dirs () {
	local -a -r DIRECS=("${!1}")
	for DIR in "${DIRECS[@]}"; do
		rm -rf "$DIR"
	done
	return 0
}

# Change download server location for apt-get. Uses USER_DLLOC variable.
_change_dlloc () {
	if (( PARAM_OFFLINE != 1 && DLLOC_CHANGED != 1 )); then
		sudo sed -i "s|http://..\.archive|http://${USER_DLLOC}.archive|g" /etc/apt/sources.list
		sudo apt-get -qq update &> /dev/null
		DLLOC_CHANGED=1
	fi
	return $?
}

# Add user to group
# $1 = Group name
# $2 = User name
_add_user2group () {
	if (( $# != 2 )); then
		return $INV_ARGS;
	fi
	sudo bash -c "usermod -a -G $1 $2"
	return $?
}

# Check if user has input y/yes (case-insensitive) returns 0, anything else returns 1
# $1 = Question to display
_check_choice_text () {
	printf "[$COLOR_YELLOW%s$COLOR_DEFAULT] %s " "WRN" "$1"
	read
	case "$REPLY" in
		[y/Y])
			return 0
			;;
		[yY][eE][sS])
			return 0
			;;
		*)
			return 1
			;;
	esac
}

# Check for user choice with dialog, yes returns 0, no returns 1
# $1 = Question to display
_check_choice_gui () {
	dialog --yesno "$1" 0 0
	RET=$?
	clear
	return $RET
}

# Check for user choice, yes returns 0, no returns 1
# $1 = Question to display
_check_choice () {
	if _is_installed dialog; then
		_check_choice_gui "$1"
		return $?
	else
		_check_choice_text "$1"
		return $?
	fi
}

###################################################################################################################################################
### DO_HOMEDIR ####################################################################################################################################
###################################################################################################################################################

# Main homedir function
_do_homedir () {
	_print_info "Setting up home directory ..."

	_do_homedir_customprofile
	_do_homedir_customrc
	_do_homedir_cleanup
	_do_homedir_dirs

	return 0
}

# Create ~/.customprofile
_do_homedir_customprofile () {
	cat <<- 'EOF' > "$FILE_CUSTOMPROFILE"
		export PATH=$PATH:$HOME/bin
		export PS4='[ $LINENO ] '
		export EDITOR="nano"

	EOF

	# Check if .customprofile is sourced in .profile
	grep "customprofile" < "$FILE_PROFILE" &> /dev/null
	if (( $? != 0 )); then
		echo -e "\nsource ~/.customprofile" >> "$FILE_PROFILE"
	fi

	return 0
}

_do_homedir_customrc () {
	cat <<- 'EOF' > "$FILE_CUSTOMRC"
		# Moving through, looking at & searching through directories
		alias go-dl='cd ~/Downloads'
		alias go-pr='cd ~/projects'
		alias go-re='cd ~/repos'
		alias repwd='cd "$PWD"'
		alias ll='ls -AlFh --color=auto'
		alias ls='ls -lFh --color=auto'
		alias l='ls -ACF --color=auto'
		alias exp='nautilus . &> /dev/null &'
		alias dsize='du -sh'
		alias grap='grep -R -n -i -e'
		alias fond='find . -name'

		# Git
		alias git-count='git rev-list --all --count'
		alias giff='git diff HEAD'
		alias giss='git status'
		alias gpush='git push'
		alias gpull='git pull'
		alias ggui='git gui'
		alias gadd='git add'
		alias gunst='git reset HEAD'

		# Applications
		alias more='less -F'
		alias less='less -F'
		alias cloc-all='cloc *.c *.h Makefile'
		alias make='make -j4'
		alias ag='ag --hidden'

		# Other
		alias src='. ~/.bashrc'
		alias dta='dmesg | tail'
		alias grip='ps aux | grep -i -e'
		alias updog='sudo aptitude update; sudo aptitude upgrade'
		alias dl='sudo aptitude install'

		# Create directory and enter it
		# $1 = Name of new directory
		mkc () {
		    mkdir "$1"
		    if (( $? == 0 )); then
		        cd "$1"
		        return 0
		    else
		        return 1
		    fi
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
	EOF

	_do_homedir_customrc_programs

	# Check if .customrc is sourced in .bashrc
	grep "customrc" < "$FILE_BASHRC" &> /dev/null
	if (( $? != 0 )); then
		echo -e "\nsource ~/.customrc" >> "$FILE_BASHRC"
	fi

	return 0
}

_do_homedir_customrc_programs () {
	_do_homedir_customrc_programs_hstr
	return 0
}

_do_homedir_customrc_programs_hstr () {
	if _is_installed hh; then
		cat <<- 'EOF' >> "$FILE_CUSTOMRC"

			# HSTR settings
			export HH_CONFIG=hicolor,rawhistory,blacklist
			bind '"\C-r": "\C-a hh \C-j"'
		EOF
	fi
	return 0
}

# Delete most preexisting repositories in home directory
_do_homedir_cleanup () {
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

	return 0
}

# Create standard directories
_do_homedir_dirs () {
	mkdir -p "$HOME/bin"
	mkdir -p "$HOME/projects/Archiv"
	mkdir -p "$HOME/repos"

	return 0
}


###################################################################################################################################################
### DO_UPDATE #####################################################################################################################################
###################################################################################################################################################

# Main update function
_do_update () {
	_print_info "Updating ..."
	_change_dlloc

	_do_update_add_repos
	_do_update_update
	_do_update_upgrade

	return 0
}

# Add repositories
_do_update_add_repos () {
	sudo add-apt-repository -y ppa:texlive-backports/ppa &> /dev/null
	sudo add-apt-repository -y ppa:ultradvorka/ppa &> /dev/null
	return 0
}

# Update
_do_update_update () {
	sudo apt-get -qq update &> /dev/null
	return $?
}

# Upgrade
_do_update_upgrade () {
	if (( PARAM_QUICK != 1 )); then
		_print_info "Upgrading ... (this could take a while)"
		sudo apt-get -y -qq upgrade > /dev/null
		if (( $? != 0 )); then
			_print_error "Upgrade failed"
			return 1
		fi
	fi
	return 0
}

###################################################################################################################################################
### DO_INSTALL ####################################################################################################################################
###################################################################################################################################################

# Main installation function
_do_install () {
	_change_dlloc

	_install_apt git
	_install_apt git-gui
	_install_apt tmux
	_install_apt xclip
	_install_apt htop
	_install_apt build-essential
	_install_apt unp
	_install_apt hh
	_do_install_sublime
	_do_install_chrome

	if (( PARAM_IMPORTANT != 1 )); then
		_install_apt tmuxinator
		_install_apt openssh-server
		_install_apt cloc
		_install_apt tig
		_install_apt subversion
		_install_apt cmake
		_install_apt automake
		_install_apt autoconf
		_install_apt libtool
		_install_apt shellcheck
		_install_apt valgrind
		_install_apt bear
		_install_apt unity-tweak-tool
		_install_apt qalc
		_install_apt tpp
		_install_apt hollywood
		_install_apt rar
		_install_apt unrar
		_install_apt rtorrent
		_install_apt silversearcher-ag
		_install_apt aptitude
		_install_apt xdotool
		_do_install_oclint
		_do_install_hr
		_do_install_tmux_gitbar
	fi

	if (( PARAM_LONG == 1 )); then
		_install_apt_long ubuntu-restricted-extras
		_install_apt_long texlive
		_install_apt_long latexmk
		_install_apt_long texlive-lang-german
		_install_apt_long texlive-latex-extra
		_install_apt_long texlive-fonts-extra
		_install_apt_long texlive-bibtex-extra
		_install_apt_long openjdk-8-jdk
	fi

	sudo apt-get autoremove -y -qq > /dev/null

	_do_homedir_customrc

	return 0
}

#########################################################################

## Manual installation functions
# Programs that need extra parameters get their own functions, to keep the main _do_install function clean

# Install oclint
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
		if (( OCLINT_RETURN == 0 )); then
			cd "$DL_PREFIX"
			tar xzf "$DL_PREFIX/$OCLINT_FILE"
			OCLINT_RETURN=$!
			rm -f "$DL_PREFIX/$OCLINT_FILE"
		fi
		# Install
		if (( OCLINT_RETURN == 0 )); then
			cd "$DL_PREFIX/$OCLINT_DIR"
			OCLINT_RETURN=$!
		fi
		if (( OCLINT_RETURN == 0 )); then
			sudo cp bin/oclint* /usr/local/bin/
			sudo cp -rp lib/* /usr/local/lib/
			rm -r -f "${DL_PREFIX:?}/$OCLINT_DIR"
		fi

		if (( OCLINT_RETURN != 0 )); then
			_install_fail "oclint"
		fi

		cd "$PWD_START"
	fi
	return $OCLINT_RETURN
}

# Install Sublime Text
_do_install_sublime () {
	local -r SUBL_VERSION=3126
	_install_dpkg "subl" "https://download.sublimetext.com/sublime-text_build-${SUBL_VERSION}_amd64.deb"
	return $?
}

# Install Google Chrome
_do_install_chrome () {
	# shellcheck disable=2034
	local -r -a CHROME_DEPENDS=("libpango1.0-0" "libindicator7" "libappindicator1")
	_install_apt_depends CHROME_DEPENDS[@] "google-chrome"
	if (( $? == 0 )); then
		_install_dpkg "google-chrome" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
		return $?
	else
		return 1
	fi
}

# Install hr
_do_install_hr () {
	_install_script "hr" "https://raw.githubusercontent.com/LuRsT/hr/master/hr" "${HOME}/bin/hr"
	return $?
}

# Install tmux gitbar
_do_install_tmux_gitbar () {
	_install_git_repo "tmux-gitbar" "https://github.com/aurelien-rainone/tmux-gitbar.git" "$HOME/.tmux-gitbar"
	return $?
}

###################################################################################################################################################
### DO_CONFIG #####################################################################################################################################
###################################################################################################################################################

# Main config function
_do_config () {
	_print_info "Configuring ..."

	# Pre-installed
	_do_config_variables
	_do_config_general
	_do_config_ssh
	_do_config_desktop
	_do_config_gnome_terminal
	_do_config_nano

	# Manually installed
	_do_config_git
	_do_config_tmux
	_do_config_openssh_server

	return 0
}

#########################################################################

## Configuration of everything not program-specific or specific for pre-installed software

# Configure global environment variables
_do_config_variables () {
	local -r LOCAL_LIB=/usr/local/lib
	local -r LD_CONFIG_PATH=/etc/ld.so.conf.d
	local -r LD_CONFIG_CUSTOM=$LD_CONFIG_PATH/user.conf

	grep -R $LD_CONFIG_PATH -e $LOCAL_LIB &> /dev/null
	if (( $? != 0 )); then
		sudo bash -c "echo $LOCAL_LIB > $LD_CONFIG_CUSTOM"
	fi
	_append_to_path "/usr/local/bin"
	_append_to_path "/usr/local/sbin"

	return 0
}

# Configure all kinds of stuff
_do_config_general () {
	# Add user to groups
	_add_user2group "dialout" "$USER"
	_add_user2group "tty" "$USER"

	# Remove file that causes to display useless, unclosable error window
	rm -f "$HOME"/.config/monitors.xml

	# Disable guest account
	local -r LIGHTDM_CONF="/usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf"
	grep 'allow-guest=false' < $LIGHTDM_CONF &> /dev/null
	if (( $? != 0 )); then
		sudo bash -c "echo 'allow-guest=false' >> $LIGHTDM_CONF"
	fi

	# Change download server location
	_change_dlloc

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

	# PS1 for root
	sudo bash -c "echo 'export PS1=\"\\\${debian_chroot:+(\\\$debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# \"' > /root/.customrc"
	sudo bash -c "grep customrc < /root/.bashrc &> /dev/null"
	if (( $? != 0 )); then
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

	return 0
}

# Configure desktop settings
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

	if (( PARAM_4K == 1 )); then
		gsettings set org.gnome.desktop.interface scaling-factor 1.75
	fi

	return 0
}

# Configure gnome-terminal
_do_config_gnome_terminal () {
	# Terminal
	local TPROFILE
	TPROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default)
	TPROFILE=${TPROFILE:1:-1}
	dconf write /org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/palette "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,205)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(250,235,215)', 'rgb(64,64,64)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(0,0,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
	dconf write /org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/use-theme-colors false
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ background-color "#000000"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ foreground-color "#FFFFFF"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$TPROFILE"/ scrollback-unlimited true
	

	return 0
}

# Configure nano
_do_config_nano () {
	# shellcheck disable=2034
	local -r NANO_CONFIG="$HOME"/.nanorc
	cat <<- 'EOF' > "$NANO_CONFIG"
		set tabsize 4
		set const

	EOF

	return 0
}

#########################################################################

## Configuration of manually installed software

# Configure git
_do_config_git () {
	if _is_installed git; then
		git config --global user.email "$USER_GIT_EMAIL"
		git config --global user.name "$USER_GIT_NAME"
		git config --global push.default simple
		return 0
	else
		return 1
	fi
}

# Configure tmux
_do_config_tmux () {
	if _is_installed tmux; then
		# shellcheck disable=2034
		local -r TMUX_CONFIG="$HOME"/.tmux.conf
		cat <<- 'EOF' > "$TMUX_CONFIG"
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

		EOF
		if [[ -d "$HOME/.tmux-gitbar" ]]; then
			cat <<- EOF >> "$TMUX_CONFIG"
				set -g status-right-length 100
				source-file $HOME/.tmux-gitbar/tmux-gitbar.tmux
			EOF
		fi

		return 0
	else
		return 1
	fi
}

# Configure OpenSSH server
_do_config_openssh_server () {
	if _is_installed sshd; then
		local -r SSHD_CONFIG=/etc/ssh/sshd_config
		if [[ -f $SSHD_CONFIG ]]; then
			sudo cp $SSHD_CONFIG $SSHD_CONFIG.default
		fi
		sudo sed -i '/#PasswordAuthentication/c\PasswordAuthentication no' $SSHD_CONFIG
		sudo sed -i '/#Banner/c\Banner /etc/issue.net' $SSHD_CONFIG
		sudo sed -i -e "\$a${USER_SSH_BANNER}" /etc/issue.net
		sudo systemctl restart ssh

		return 0
	else
		return 1
	fi
}

###################################################################################################################################################
### OTHER #########################################################################################################################################
###################################################################################################################################################

# Call functions to rewrite config files, including .customrc
_rewrite_config () {
	_print_info "Rewriting config files..."

	_do_homedir_customprofile
	_do_homedir_customrc
	_do_homedir_customrc_programs
	_do_config_nano
	_do_config_tmux
}

###################################################################################################################################################
### HELP ##########################################################################################################################################
###################################################################################################################################################

# Show help
# shellcheck disable=2059
_show_help () {
	local -r COMMAND_LENGTH=18

	# General stuff
	printf "${FORMAT_BOLD}${COLOR_BLUE}***${COLOR_DEFAULT} Linux-Startup user manual ${COLOR_BLUE}***${COLOR_DEFAULT}${FORMAT_RESET_ALL}\n"
	printf "A script to install, set and configure basic things that you need for a new Linux setup.\n\n"
	# Parameters
	printf "${FORMAT_BOLD}Parameters:${FORMAT_RESET_ALL}\n\n"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-q / --quick" "Don't do anything that takes a significant amount of time (~ >1 min), e.g. \`apt-get upgrade\`"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-l / --long" "Install large software packets that take a while to install. Ignores parameter -q/--quick."
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-i / --important" "Only install important programs, e.g. git or tmux"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--4K" "Configure desktop to be more usuable with a 4K resolution"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-o / --offline" "Don't do anything that requires an internet connection. Overrides parameters -l/--long, -i/--important and --do_install"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-f / --force" "Ignore all warnings"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-r / --restart" "Restart when finished"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "-h / --help" "Show help, don't do anything else"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--rewrite_config" "Rewrite configuration files"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--do_homedir" "Call homedir function"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--do_update" "Call update function"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--do_install" "Call install function"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--do_config" "Call config function"
	printf -- "%-${COMMAND_LENGTH}s %s\n" "--user_*" "Override user variables (see README.md for more information)"
	printf "\n* If one or more of the *--do_** or --rewrite_config parameters are used, only the according functions will be called, but not the others.\n"
	printf "* The order of parameters is irrelevant.\n\n"
	# Info
	printf "${FORMAT_BOLD}Info:${FORMAT_RESET_ALL}\n\n"
	printf "Author:\t\tLasse Meyer\n"
	printf "Website:\thttps://github.com/meyerlasse/Linux-Startup\n"
	printf "License:\tMIT (https://github.com/meyerlasse/Linux-Startup/blob/master/LICENSE.md)\n"
	return 0
}

###################################################################################################################################################
### PARAMETER PARSING #############################################################################################################################
###################################################################################################################################################

# If one or more of the --do_* parameters is used, this function makes sure only those functions are called, but not the others
_clean_dos () {
	if (( DOS_CLEANED != 1 )); then
		PARAM_DO_UPDATE=0
		PARAM_DO_INSTALL=0
		PARAM_DO_CONFIG=0
		PARAM_DO_HOMEDIR=0
		DOS_CLEANED=1
	fi
	return 0
}

# Parameter parsing
while (( $# > 0 )); do
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
		-f|--force)
			PARAM_FORCE=1
			shift
			;;
		--4K)
			PARAM_4K=1
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
		--rewrite_config)
			_clean_dos
			PARAM_REWRITE_CONFIG=1
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
		--user_git_name)
			USER_GIT_NAME="$2"
			USER_GIT_NAME_C=1
			shift; shift
			;;
		--user_git_email)
			USER_GIT_EMAIL="$2"
			USER_GIT_EMAIL_C=1
			shift; shift
			;;
		--user_ssh_banner)
			USER_SSH_BANNER="$2"
			USER_SSH_BANNER_C=1
			shift; shift
			;;
		--user_ssh_keys)
			USER_SSH_KEYS="$2"
			USER_SSH_KEYS_C=1
			shift; shift
			;;
		--user_dlloc)
			USER_DLLOC="$2"
			USER_DLLOC_C=1
			shift; shift
			;;
		*)
			_print_error "Invalid parameter: $PARAM"
			_print_error "Use --help parameter to show help."
			exit 1
		;;
	esac
done

# Protect user variables
declare -r USER_GIT_NAME
declare -r USER_GIT_EMAIL
declare -r USER_SSH_BANNER
declare -r USER_SSH_KEYS
declare -r USER_DLLOC

###################################################################################################################################################
### EXECUTION #####################################################################################################################################
###################################################################################################################################################

# Check if help parameter was used
if (( PARAM_HELP == 1 )); then
	_show_help
	exit 0
fi

# Check if run with normal user privileges
if (( EUID == 0 )); then
	_print_error "Don't run with sudo or as root!"
	exit 1
fi

# If sudo is needed at some point, ask for password right away
if (( PARAM_DO_UPDATE == 1 || PARAM_DO_INSTALL == 1 || PARAM_DO_CONFIG == 1 )); then
	sudo test
fi

# Check USER variables, if needed at all
if (( PARAM_DO_UPDATE == 1 || PARAM_DO_INSTALL == 1 || PARAM_DO_CONFIG == 1 )); then
	if (( USER_CUSTOM == 1 )); then
		_print_info "Using custom user variables..."
	else
		if (( (USER_GIT_NAME_C & USER_GIT_EMAIL_C & USER_SSH_BANNER_C & USER_SSH_KEYS_C & USER_DLLOC_C) == 0 && PARAM_FORCE == 0)); then
			_print_warning "At least one USER variable is set to its default value, continue anyway? [y/n]"
			read
			if ! _check_choice; then
				exit 0
			fi
		fi
	fi
fi

# Call functions
if (( PARAM_DO_HOMEDIR == 1 )); then
	_do_homedir
fi
if (( PARAM_DO_UPDATE == 1 && PARAM_OFFLINE == 0 )); then
	_do_update
fi
if (( PARAM_DO_INSTALL == 1 && PARAM_OFFLINE == 0 )); then
	_do_install
fi
if (( PARAM_DO_CONFIG == 1 )); then
	_do_config
fi

if (( PARAM_REWRITE_CONFIG == 1 )); then
	_rewrite_config
fi

###################################################################################################################################################
### END ###########################################################################################################################################
###################################################################################################################################################

cd "$PWD_START"
_print_info "Done."

if (( PARAM_RESTART == 0 )); then
	if (( PARAM_DO_HOMEDIR == 1 || PARAM_REWRITE_CONFIG == 1 )); then
		# shellcheck disable=2059
		printf "[${COLOR_GREEN}INF${COLOR_DEFAULT}] You should run '${FORMAT_BOLD}. ~/.bashrc${FORMAT_RESET_ALL}' now.\n"
		if _is_installed xdotool; then
			xdotool type ". ~/.bashrc"
		fi
	fi
else
	_print_info "Rebooting..."
	sudo reboot
fi

exit 0
