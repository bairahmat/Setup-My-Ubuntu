# Linux-Init
#### A script to install, set and configure basic things that I need for a new Linux setup.
Does currently only work with Ubuntu 16, a version for Raspbian is planned.
<hr>
### Parameters:
- \-q / --quick: Don't do anything that takes a significant amount of time (~ >1 min.)

### Features:

- Update and upgrade
- Install a bunch of tools
- Setting up SSH (keys and authorized_keys file) and openssh-server
- A lot of configuration:
  - Global environment variables
  - Locale and timezone
  - Background picture
  - Terminal colors and schemes
  - Default applications for MIME types
  - Initial git configuration
  - ...
- Creating config files for tmux & nano
- Appending a bunch of aliases to .bashrc
- Cleaning up home directory

<hr>

If you want to use it, you have to **_change the following first_**:
- Public keys that are added to authorized_keys
- Git name and email address</br>

The rest *can* be left unchanged.
