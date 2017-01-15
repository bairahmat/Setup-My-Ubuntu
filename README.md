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

1. `wget https://raw.githubusercontent.com/meyerlasse/Linux-Startup/master/linux-startup.sh`
2. **Modify USER variables** or use --user_* parameters to override them
3. `bash start.sh`

## Parameters

| Parameter       | Meaning                                                                                                                       |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------|
| -q / --quick    | Don't do anything that takes a significant amount of time (~ >1 min), e.g. `apt-get upgrade`.                                 |
| -l / --long     | Install large software packets that take a while to install. Ignores parameter `-q/--quick`.                                  |
| -i / --important| Only install important programs, e.g. git or tmux.                                                                            |
| --4K            | Configure desktop to be more usuable with a 4K resolution                                                                     |
| -o / --offline  | Don't do anything that requires an internet connection. Overrides parameters `-l/--long`, `-i/--important` and `--do_install`.|
| -f / --force    | Ignore all warnings.                                                                                                          |
| -r / --restart  | Restart when finished.                                                                                                        |
| -h / --help     | Show help, don't do anything else.                                                                                            |
| --rewrite_config| Rewrite configuration files.                                                                                                  |
| --do_homedir    | Call homedir function.                                                                                                        |
| --do_update     | Call update function.                                                                                                         |
| --do_install    | Call install function.                                                                                                        |
| --do_config     | Call config function.                                                                                                         |
| --user_*        | Override USER variables. See section below for more information.                                                              |

#### Additional infos:

- If one or more of the *--do_...* parameters are used, only the according functions will be called, but not the others.
- The order of parameters is irrelevant.

#### Functions:

- homedir: Clean up home directory, create .customrc
- update: Add repositories, update & upgrade
- install: Install software
- config: Configure different things, including SSH, desktop settings, gnome-terminal, git, tmux, etc.

#### USER variables:

All the USER variables are used when configuring certain software, including the download location for apt-get. You can manually set the user variables before starting the script (find them at the very beginning of the script) or use the --user_* parameters to override them (e.g. `--user_git_name "Your Name"` or `--user_dlloc "US"`).

- USER_GIT_NAME: the name that will appear in Git commits, etc.
- USER_GIT_EMAIL: the email address that will appear in Git commits, etc.
- USER_SSH_BANNER: the banner you will see if you login remotely via SSH
- USER_SSH_KEYS: your public keys
- USER_DLLOC: the country-specific domain code that will be used to select the download servers for apt-get, like "us" for USA, "fr" for France or "de" for Germany

<hr>

## Contributing
If you have an idea to improve the script, created a version for another Linux distribution or find an error, feel free to create a pull reqeust or an issue, or just send an email to let me know.
