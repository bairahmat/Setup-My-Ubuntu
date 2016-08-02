#!/bin/bash
# Author: 	Lasse Meyer
# Source:	https://github.com/meyerlasse/Linux-Init
# License: 	MIT (https://github.com/meyerlasse/Linux-Init/blob/master/LICENSE)

## Variables

PARAM_QUICK=0
PARAM_OFFLINE=0
PARAM_DO_UPDATE=1
PARAM_DO_INSTALL=1
PARAM_DO_SSH=1
PARAM_DO_CONFIG=1
PARAM_DO_HOMEDIR=1

DOS_CLEANED=0

DL_PREFIX=/tmp
DEFAULTS=$HOME/.local/share/applications/defaults.list
ENV_FILE=/etc/environment
RED='\e[31m'
NC='\e[0m'

export DEBIAN_FRONTEND=noninteractive

## Functions

_print_red () {
	echo -e "${RED}${1}${NC}"
}

_install_fail () {
	_print_red "Installing $1 failed"
}

_install_start () {
	echo -e "Installing $1 ..."
}

_install_generic () {
	SUCCESS=0
	sudo apt-get -y -qq install $1 > /dev/null
	if [[ $? -ne 0 ]]; then
		_install_fail $1
		SUCCESS=1
	fi
	return $SUCCESS
}

_install () {
	_install_start $1
	_install_generic $1
	return $?
}

# $1 = Array of dependencies (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of software that needs dependencies
_install_depends () {
	SUCCESS=0
	declare -a DEPENDS=("${!1}")
	for DEP in "${DEPENDS[@]}"; do
		_install_generic $DEP
		if [[ $? -ne 0 ]]; then
			SUCCESS=1
		fi
	done
	if [[ SUCCESS -ne 0 ]]; then
		_print_red "Installing dependencies for $2 failed"
	fi
	return $SUCCESS
}

# $1 = Name of software
# $2 = Download prefix (without file name, without / at the end)
# $3 = File name to download and install
_install_dpkg () {
	SUCCESS=0
	_install_start $1
	wget --tries=3 $2/$3 -P $DL_PREFIX -q
	if [[ $? -eq 0 ]]; then
		sudo dpkg -i -G $DL_PREFIX/$3 > /dev/null
		if [[ $? -ne 0 ]]; then
			_install_fail $1
			SUCCESS=1
		fi
		rm -f $DL_PREFIX/$3
	else
		_install_fail $1
		SUCCESS=1
	fi
	return $SUCCESS
}

# $1 = Array of MIME types (has to be passed like this: NAME_OF_ARRAY[@])
# $2 = Name of desktop file that should be applied
_setmimes () {
	declare -a MIMES=("${!1}")
	for MIMETYPE in "${MIMES[@]}"; do
		echo "$MIMETYPE=$2" >> $DEFAULTS
	done
}

# $1 = Path to append to PATH
_append_to_path () {
	# Is the path already in PATH?
	cat $ENV_FILE | grep PATH=.*$1 &> /dev/null
	if [[ $? -ne 0 ]]; then
		# Cut off "
		sudo sed -i '/^PATH=/ s/\"$//' $ENV_FILE
		# Add new path and add "
		sudo sed -i "/^PATH=/ s|$|:${1}\"|" $ENV_FILE
	fi
}

_do_update () {
	sudo add-apt-repository -y ppa:texlive-backports/ppa > /dev/null

	echo "Updating ..."
	sudo apt-get -qq update
	if [[ $? -ne 0 ]]; then
		_print_red "Update failed"
	fi

	if [[ $PARAM_QUICK -ne 1 ]]; then
		echo "Upgrading ... (this could take a while)"
		sudo apt-get -y -qq upgrade > /dev/null
		if [[ $? -ne 0 ]]; then
			_print_red "Upgrade failed"
		fi
	fi
}

_do_install () {
	_install git
	_install git-gui
	_install subversion
	_install tmux
	_install cloc
	_install htop
	_install openssh-server
	_install build-essential
	_install cmake
	_install unity-tweak-tool

	if [[ $PARAM_QUICK -ne 1 ]]; then
		_install ubuntu-restricted-extras
		_install texlive
		_install latexmk
		_install texlive-lang-ger
		_install texlive-latex-extra
		_install texlive-fonts-extra
	fi

	SUBL3_VERSION=114
	SUBL3_NAME="Sublime_Text_3"
	SUBL3_SITE="https://download.sublimetext.com"
	SUBL3_FILE="sublime-text_build-3${SUBL3_VERSION}_amd64.deb"
	_install_dpkg $SUBL3_NAME $SUBL3_SITE $SUBL3_FILE

	CHROME_NAME="Google_Chrome"
	CHROME_SITE="https://dl.google.com/linux/direct"
	CHROME_FILE="google-chrome-stable_current_amd64.deb"
	CHROME_DEPENDS=("libindicator7" "libappindicator1")
	_install_depends CHROME_DEPENDS[@] $CHROME_NAME
	if [[ $? -eq 0 ]]; then
		_install_dpkg $CHROME_NAME $CHROME_SITE $CHROME_FILE
	fi

	sudo apt-get autoremove > /dev/null
}

_do_ssh () {
	echo -e "Setting up SSH ..."

	SSH_DIR=$HOME/.ssh
	SSH_FILE=$SSH_DIR/id_rsa
	SSH_PFILE=$SSH_FILE.pub
	SSH_KFILE=$SSH_DIR/authorized_keys

	mkdir -p $SSH_DIR
	chmod 700 $SSH_DIR
	if [[ -f $SSH_FILE ]]; then
		mv $SSH_FILE $SSH_DIR/old_id_rsa
		echo -e "SSH key files already existed, renamed to old_id_rsa(.pub)"
	fi
	if [[ -f $SSH_PFILE ]]; then
		mv $SSH_PFILE $SSH_DIR/old_id_rsa.pub
	fi
	ssh-keygen -q -t rsa -N "" -f $SSH_FILE
	touch $SSH_KFILE
	chmod 600 $SSH_KFILE

	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUMuxgGk1fje/hwY7TGC6cF+9AndEo6mryQ7VYKCOlBk8kVgLDRYG7uK8iotzFo/czIFzIi30smYh4B9XPAhYS6viPlhd4pSlob7OPK6eL8goO3mSU4mWzCOPW7ceRXlmQcLU1Q6q+zGts4Cw4anWVQNx9VhTxth0AyZMaKGXMerFG6Abwycsm1QncNZpQtghfCDa1f332LagZQnd1ds5TtAHoPBuwLbk6gYeLit6OJgqXW+bLK27IT2NoNOTkeDob5IzJUeb6U0kHuiXvCWnWr9FDsh3QJ4pIXgbothO3IkevIWsDTJL9zUCVLVIeawnNffY8hIQl8JfDLnYLmWPL lasse@ubuntu"\
	 >> $SSH_KFILE
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDS30gjjffeXZefF4bp6DMf6HaP6YAgicZthSLZkgcta6wVa3wVsgm8XHH9drZR8oo6XCYaFWMUt/LQSlxwU8OXd6hWN8CoB3IVNFb1w7FdliP8Ek8+/TVEHx4rMZvzHXCzWGfuI1CkLLZOmI3dXWvAsIvZFffGyDHbxEZd/mMkBGLMTwkInLWKMLSJqL7nfaOcQc1oL2Squo8EW/PErafDfJQN+j792ZCsRa7K7WXJ2LzdENoE0cMc9mc0kfnu5e4TPamptq7csa01dkofJ91C+C55X/bdW0AUqenivho3Jm1/bHtvn/PmAN+ihKzxoRijMG5Nsk1rYADkcHEydrxx meyer.lasse@gmail.com"\
	 >> $SSH_KFILE

	# SSH server
	SSH_SCONFIG=/etc/ssh/sshd_config
	if [[ -f $SSH_SCONFIG ]]; then
		sudo cp $SSH_SCONFIG $SSH_SCONFIG.default
	fi
	sudo sed -i '/#PasswordAuthentication/c\PasswordAuthentication no' $SSH_SCONFIG
	sudo sed -i '/#Banner/c\Banner /etc/issue.net' $SSH_SCONFIG
	sudo sed -i -e "\$aLasse Meyer <meyer.lasse@gmail.com>" /etc/issue.net
	sudo systemctl restart ssh
}

_do_config () {
	echo -e "Configuring ..."

	rm -f $HOME/.config/monitors.xml

	# Modifying global environment variables and library search path for linker
	LOCAL_LIB=/usr/local/lib
	LD_CONFIG_PATH=/etc/ld.so.conf.d
	LD_CONFIG_CUSTOM=$LD_CONFIG_PATH/user.conf
	grep -R $LD_CONFIG_PATH -e $LOCAL_LIB &> /dev/null
	if [[ $? -ne 0 ]]; then
		sudo sh -c  "echo $LOCAL_LIB > $LD_CONFIG_CUSTOM"
	fi
	_append_to_path "/usr/local/bin"
	_append_to_path "/usr/local/sbin"

	# Locale and timezone
	timedatectl set-timezone Europe/Berlin
	sudo locale-gen de_DE.UTF-8 > /dev/null
	sudo update-locale LANG=de_DE.UTF-8

	# Desktop
	dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-capture-mouse false
	dconf write /org/compiz/profiles/unity/plugins/unityshell/icon-size 35
	gsettings set com.ubuntu.update-notifier no-show-notifications true
	gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/Flora_by_Marek_Koteluk.jpg
	gsettings set org.gnome.desktop.interface clock-show-date true
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Terminal
	TPROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default)
	TPROFILE=${TPROFILE:1:-1}
	dconf write /org/gnome/terminal/legacy/profiles:/:$TPROFILE/palette "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,205)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(250,235,215)', 'rgb(64,64,64)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(0,0,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ background-color "#000000"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ foreground-color "#FFFFFF"
	gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ scrollback-unlimited true

	# Default applications
	echo "[Default Applications]" > $DEFAULTS
	DESKTOP_SUBL=sublime_text.desktop
	MIMES_SUBL=("text/xml" "text/richtext" "text/x-java" "text/plain" "text/tab-separated-values" "text/x-c++hdr" "text/x-c++src" "text/x-chdr" "text/x-csrc" "text/x-sql" "text/x-python" "text/x-dtd" "text/mathml"  "application/x-perl")
	_setmimes MIMES_SUBL[@] $DESKTOP_SUBL
	DESKTOP_CHROME=google-chrome.desktop
	MIMES_CHROME=("appplication/xhtml+xml" "application/xhtml_xml" "text/html" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/ftp")
	_setmimes MIMES_CHROME[@] $DESKTOP_CHROME

	# Git
	git config --global user.email "meyer.lasse@gmail.com"
	git config --global user.name "Lasse Meyer"

	# tmux
	echo "# Enable mouse mode (tmux 2.1 and above)
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

#window mode
setw -g mode-bg colour6
setw -g mode-fg colour0

# window status
setw -g window-status-format \" #F#I:#W#F \"
setw -g window-status-current-format \" #F#I:#W#F \"
setw -g window-status-format \"#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W \"
setw -g window-status-current-format \"#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W \"
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

set -g default-terminal \"screen-256color\"

# The modes {
setw -g clock-mode-colour colour135
setw -g mode-attr bold
setw -g mode-fg colour196
setw -g mode-bg colour238

# }
# The panes {

set -g pane-border-bg colour0
set -g pane-border-fg colour238
set -g pane-active-border-bg colour0
set -g pane-active-border-fg colour51

# }
# The statusbar {

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

# }
# The messages {

set -g message-attr bold
set -g message-fg colour232
set -g message-bg colour166

# }" > $HOME/.tmux.conf

	# Nano
	echo "set tabsize 4" >> $HOME/.nanorc
}

_do_homedir () {
	echo -e "Appending .bashrc ..."

	echo "############ CUSTOM ############

export PATH=\$PATH:$HOME/.bin

alias go-dl='cd ~/Downloads'
alias go-pr='cd ~/projects'
alias go-re='cd ~/repos'
alias ll='ls -AlFh --color=auto'
alias ls='ls -lFh --color=auto'
alias dta='dmesg | tail'
alias grap='grep -R -n -i -e'
alias grip='ps aux | grep -i -e'
alias fond='find . -name'
alias extr='tar xvf'
alias updog='sudo apt-get update; sudo apt-get upgrade'
alias dl='sudo apt-get install'
alias git-count='git rev-list --all --count'
alias giff='git diff HEAD'
alias giss='git status'
alias cloc-all='cloc *.c *.h Makefile'
alias make='make -j4'

function mkc {
	mkdir $1
	cd $1
}

" >> $HOME/.bashrc

	## Create .hidden

	echo -e "Cleaning up home directory ..."

	echo "Pictures
Videos
Music
Documents
Bilder
Musik
Dokumente
Templates
Vorlagen
Public
Öffentlich" > $HOME/.hidden

	rm -f $HOME/examples.desktop
	mkdir $HOME/.bin
}

_clean_dos () {
	if [[ DOS_CLEANED -ne 1 ]]; then
		PARAM_DO_UPDATE=0
		PARAM_DO_INSTALL=0
		PARAM_DO_SSH=0
		PARAM_DO_CONFIG=0
		PARAM_DO_HOMEDIR=0
		DOS_CLEANED=1
	fi
}

## Parameter parsing

while [[ $# -gt 0 ]]; do
	PARAM="$1"
	case $PARAM in
		-q|--quick)
			PARAM_QUICK=1
			shift
			;;
		-o|--offline)
			PARAM_OFFLINE=1
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
		--do_ssh)
			_clean_dos
			PARAM_DO_SSH=1
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
			_print_red "Invalid parameter: $PARAM"
			exit 1
		;;
	esac
done

## Check if run without sudo

if [[ $EUID == 0 ]]; then
	_print_red "Don't run with sudo or as root!"
	exit 1
fi

if [[ $PARAM_DO_UPDATE -eq 1 ]]; then
	_do_update
fi
if [[ $PARAM_DO_INSTALL -eq 1 ]]; then
	_do_install
fi
if [[ $PARAM_DO_SSH -eq 1 ]]; then
	_do_ssh
fi
if [[ $PARAM_DO_CONFIG -eq 1 ]]; then
	_do_config
fi
if [[ $PARAM_DO_HOMEDIR -eq 1 ]]; then
	_do_homedir
fi

## End

echo -e "Done."
echo -e "You should run '. ~/.bashrc' now."

exit 0
