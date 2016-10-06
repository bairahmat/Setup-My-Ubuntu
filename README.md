# Linux-Startup
#### A script to install, set and configure basic things that you need for a new Linux setup.
Does currently only work with Ubuntu 16, a version for Raspbian is planned.
<hr>
## Features

- Update and upgrade
- Install a bunch of tools
- Setting up SSH (keys and authorized_keys file) and openssh-server
- A lot of configuration:
  - Global environment variables
  - Locale and timezone
  - Background picture
  - Terminal colors and schemes
  - Default applications for MIME types
  - Initial Git configuration
  - ...
- Creating config files for tmux & nano
- Creating .customrc for aliases and functions, which is sourced by .bashrc
- Cleaning up home directory
- More to come (if you have any suggestions, create an issue to let me know)

## Usage

1. `wget https://github.com/meyerlasse/Linux-Startup/releases/download/2.0/linux-startup.sh`
2. **Modify USER variables**. They can be found at the very beginning of the script.
3. `bash start.sh`

## Parameters

| Parameter       | Meaning                                                                                                                       |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------|
| -q / --quick    | Don't do anything that takes a significant amount of time (~ >1 min), e.g. `apt-get upgrade`.                                 |
| -l / --long     | Install large software packets that take a while to install. Ignores parameter `-q/--quick`.                                  |
| -i / --important| Only install important programs, e.g. git or tmux.                                                                            |
| -o / --offline  | Don't do anything that requires an internet connection. Overrides parameters `-l/--long`, `-i/--important` and `--do_install`.|
| -r / --restart  | Restart when finished.                                                                                                        |
| -h / --help     | Show help, don't do anything else.                                                                                            |
| --do_homedir    | Call homedir function.                                                                                                        |
| --do_update     | Call update function.                                                                                                         |
| --do_install    | Call install function.                                                                                                        |
| --do_config     | Call config function.                                                                                                         |

#### Additional infos:

- If one or more of the *--do_...* parameters are used, only the according functions will be called, but not the others.
- The order of parameters is irrelevant.

#### Functions:

- homedir: Clean up home directory, create .customrc
- update: Add repositories, update & upgrade
- install: Install software
- config: Configure different things, including SSH, desktop settings, gnome-terminal, git, tmux, etc.

#### USER variables:

- USER_GIT_NAME: the name that will appear in Git commits, etc.
- USER_GIT_EMAIL: the email address that will appear in Git commits, etc.
- USER_SSH_BANNER: the banner you will see if you login remotely via SSH
- USER_SSH_KEYS: your public keys
- USER_DLLOC: the country-specific domain code that will be used to select the download servers for apt-get, like "us" for USA, "fr" for France or "de" for Germany

<hr>

## Contributing
If you have an idea to improve the script, created a version for another Linux distribution or find an error, feel free to create a pull reqeust or an issue, or just send an email to let me know.
