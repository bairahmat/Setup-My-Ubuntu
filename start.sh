#!/bin/sh

# Variables

DL_PREFIX=/tmp
RED='\033[0;31m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

# Functions

_print_red () {
	echo "${RED}${1}${NC}"
}

_install_success () {
	echo "Installed $1"
}

_install_fail () {
	_print_red "Installing $1 failed"
}

_install () {
	if apt-get -y -q install $1 ; then
		_install_success $1
	else
		_install_fail $1
	fi
}

# $1 = Name of software
# $2 = Download prefix (without file name, without / at the end)
# $3 = File name to download and install
_install_dpkg () {
	wget --tries=3 $2/$3 -P $DL_PREFIX
	if [ $? -eq 0 ]; then
		dpkg -i -G $DL_PREFIX/$3
		if [ $? -ne 0 ]; then
			_install_fail $1
		else
			_install_success $1
		fi
		rm $DL_PREFIX/$3
	else
		_install_fail $1
	fi
}

# Check if run with sudo

if [ ($EUID -ne 0) || ($UID -eq 0) ]; then
	_print_red "Must be run with sudo"
	exit 1
fi

# More variables

USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
DR=sudo --user=#$UID

# Update

if apt-get update ; then
	echo "Updated"
else
	_print_red "Update failed"
fi
if apt-get upgrade ; then
	echo "Upgraded"
else
	_print_red "Upgrade failed"
fi

# Install tools

_install git
_install google-chrome-stable
_install tmux
_install cloc
_install build-essential
_install unity-tweak-tool
_install ubuntu-restricted-extras

SUBL3_NAME="Sublime Text 3" 
SUBL3_SITE="https://download.sublimetext.com"
SUBL3_FILE="sublime-text_build-3114_amd64.deb"
_install_dpkg $SUBL3_NAME $SUBL3_SITE $SUBL3_FILE

apt-get autoremove

# SSH

$DR mkdir -p $USER_HOME/.ssh
$DR chmod 700 $USER_HOME/.ssh
$DR ssh-keygen -q -t rsa -N "" -f $USER_HOME/.ssh/id_rsa
$DR touch $USER_HOME/.ssh/authorized_keys
$DR chmod 600 USER_HOME/.ssh/authorized_keys

# TODO: Add my public keys to authorized_keys

# Append .bashrc

echo "
############ CUSTOM ############

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

alias ll='ls -AlFh'
alias ls='ls -lFh --color'
alias dta='dmesg | tail'
alias grap='grep -R -n -i -e'
alias grip='ps aux | grep -i -e'
alias fond='find . -name'
alias git-count='git rev-list --all --count'
alias giff='git diff HEAD'
alias giss='git status'
alias cloc-all='cloc *.c *.h Makefile'
alias make='make -j4'

function mkc {
        mkdir $1
        cd $1
}

" >> $USER_HOME/.bashrc

# Create .hidden

echo "
Pictures
Videos
Music
Documents
Bilder
Musik
Dokumente" > $USER_HOME/.hidden

# End

echo "You should run '. ~/.bashrc' now."

exit 0
