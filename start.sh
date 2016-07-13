# Update

apt-get update
apt-get upgrade

# Install tools

apt-get install git
apt-get install google-chrome-stable
apt-get install tmux
apt-get install cloc
apt-get install build-essential

apt-get autoremove

SUBL_PACKAGE=sublime-text_build-3114_amd64.deb
wget --tries=3 https://download.sublimetext.com/$SUBL_PACKAGE
dpkg -i $SUBL_PACKAGE
rm $SUBL_PACKAGE

# Append .bashrc

echo "
############ CUSTOM ############

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

alias ll='ls -AlFh'
alias ls='ls -lFh --color'
alias git-count='git rev-list --all --count'
alias giff='git diff HEAD'
alias cloc-all='cloc *.c *.h Makefile'
alias make='make -j4'

function mkc {
        mkdir $1
        cd $1
}

function dta {
        dmesg | tail
}

function grap {
        grep -R -n -i -e $1
}

function grip {
        ps aux | grep -i -e $1
}

function fond {
        find . -name $1
}
" >> ~/.bashrc
