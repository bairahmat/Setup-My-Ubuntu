#!/bin/bash

# Variables

DL_PREFIX=/tmp
RED='\e[31m'
NC='\e[0m'

export DEBIAN_FRONTEND=noninteractive

# Functions

_print_red () {
	echo -e "${RED}${1}${NC}"
}

_install_fail () {
	_print_red "Installing $1 failed"
}

_install_start () {
	echo -e "Installing $1 ..."
}

_install () {
	_install_start $1
	if [[ $(sudo apt-get -y -qq install $1 > /dev/null) -ne 0 ]] ; then
		_install_fail $1;
	fi
}

# $1 = Name of software
# $2 = Download prefix (without file name, without / at the end)
# $3 = File name to download and install
_install_dpkg () {
	_install_start $1
	wget --tries=3 $2/$3 -P $DL_PREFIX -q
	if [ $? -eq 0 ]; then
		sudo dpkg -i -G $DL_PREFIX/$3 > /dev/null
		if [ $? -ne 0 ]; then
			_install_fail $1
		fi
		rm $DL_PREFIX/$3
	else
		_install_fail $1
	fi
}

# Check if run without sudo
if [[ $EUID == 0 ]]; then
	_print_red "Don't run with sudo or as root!"
	exit 1
fi

# Update

echo "Updating ..."
if [[ $(sudo apt-get -qq update) -ne 0 ]] ; then
	_print_red "Update failed"
fi
echo "Upgrading ... (this could take a while)"
if [[ $(sudo apt-get -y -qq upgrade > /dev/null) -ne 0 ]] ; then
	_print_red "Upgrade failed"
fi

# Install tools

_install git
_install tmux
_install cloc
_install build-essential
_install unity-tweak-tool
_install ubuntu-restricted-extras

SUBL3_NAME="Sublime_Text_3"
SUBL3_SITE="https://download.sublimetext.com"
SUBL3_FILE="sublime-text_build-3114_amd64.deb"
_install_dpkg $SUBL3_NAME $SUBL3_SITE $SUBL3_FILE

_install libindicator7
_install libappindicator1

CHROME_NAME="Google_Chrome"
CHROME_SITE="https://dl.google.com/linux/direct"
CHROME_FILE="google-chrome-stable_current_amd64.deb"
_install_dpkg $CHROME_NAME $CHROME_SITE $CHROME_FILE

sudo apt-get autoremove > /dev/null

# SSH

echo -e "Setting up SSH ..."

SSH_DIR=$HOME/.ssh
SSH_FILE=$SSH_DIR/id_rsa
SSH_PFILE=$SSH_FILE.pub
AKFILE=$SSH_DIR/authorized_keys

mkdir -p $SSH_DIR
chmod 700 $SSH_DIR
if [[ -f $SSH_FILE ]]; then
	mv $SSH_FILE $SSH_DIR/old_id_rsa
	echo -e "SSH key files already existed, renamed to old_id_rsa"
fi
if [[ -f $SSH_PFILE ]]; then
	mv $SSH_PFILE $SSH_DIR/old_id_rsa.pub
fi
ssh-keygen -q -t rsa -N "" -f $SSH_FILE
touch $AKFILE
chmod 600 $AKFILE

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUMuxgGk1fje/hwY7TGC6cF+9AndEo6mryQ7VYKCOlBk8kVgLDRYG7uK8iotzFo/czIFzIi30smYh4B9XPAhYS6viPlhd4pSlob7OPK6eL8goO3mSU4mWzCOPW7ceRXlmQcLU1Q6q+zGts4Cw4anWVQNx9VhTxth0AyZMaKGXMerFG6Abwycsm1QncNZpQtghfCDa1f332LagZQnd1ds5TtAHoPBuwLbk6gYeLit6OJgqXW+bLK27IT2NoNOTkeDob5IzJUeb6U0kHuiXvCWnWr9FDsh3QJ4pIXgbothO3IkevIWsDTJL9zUCVLVIeawnNffY8hIQl8JfDLnYLmWPL lasse@ubuntu" >> $AKFILE
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDS30gjjffeXZefF4bp6DMf6HaP6YAgicZthSLZkgcta6wVa3wVsgm8XHH9drZR8oo6XCYaFWMUt/LQSlxwU8OXd6hWN8CoB3IVNFb1w7FdliP8Ek8+/TVEHx4rMZvzHXCzWGfuI1CkLLZOmI3dXWvAsIvZFffGyDHbxEZd/mMkBGLMTwkInLWKMLSJqL7nfaOcQc1oL2Squo8EW/PErafDfJQN+j792ZCsRa7K7WXJ2LzdENoE0cMc9mc0kfnu5e4TPamptq7csa01dkofJ91C+C55X/bdW0AUqenivho3Jm1/bHtvn/PmAN+ihKzxoRijMG5Nsk1rYADkcHEydrxx meyer.lasse@gmail.com" >> $AKFILE

# Configuration

echo -e "Configuring ..."

timedatectl set-timezone Europe/Berlin
sudo locale-gen de_DE.UTF-8 > /dev/null
sudo update-locale LANG=de_DE.UTF-8

dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-capture-mouse false
gsettings set com.ubuntu.update-notifier no-show-notifications true
gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/Flora_by_Marek_Koteluk.jpg
gsettings set org.gnome.desktop.interface clock-show-date true
TPROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default)
TPROFILE=${TPROFILE:1:-1}
dconf write /org/gnome/terminal/legacy/profiles:/:$TPROFILE/palette "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,205)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(250,235,215)', 'rgb(64,64,64)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(0,0,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ background-color "#000000"
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ foreground-color "#FFFFFF"
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TPROFILE/ scrollback-unlimited true

git config --global user.email "meyer.lasse@gmail.com"
git config --global user.name "Lasse Meyer"

# Append .bashrc

echo -e "Appending .bashrc ..."

echo "
############ CUSTOM ############

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

alias ll='ls -AlFh --color=auto'
alias ls='ls -lFh --color=auto'
alias dta='dmesg | tail'
alias grap='grep -R -n -i -e'
alias grip='ps aux | grep -i -e'
alias fond='find . -name'
alias git-count='git rev-list --all --count'
alias giff='git diff HEAD'
alias giss='git status'
alias cloc-all='cloc *.c *.h Makefile'
alias make='make -j4'
alias updog='sudo apt-get update; sudo apt-get upgrade'
alias dl='sudo apt-get install'

function mkc {
        mkdir $1
        cd $1
}

" >> $HOME/.bashrc

# Create .hidden

echo -e "Creating .hidden ..."

echo "
Pictures
Videos
Music
Documents
Bilder
Musik
Dokumente" > $HOME/.hidden

# End

echo -e "Done."
echo -e "You should run '. ~/.bashrc' now."

exit 0
