# Linux-Init
#### A script to install, set and configure basic things that I need for a new Linux setup.
Does currently only work with Ubuntu 16, a version for Raspbian is planned.
<hr>
### Parameters:
| Parameter      | Meaning                                                              |   |   |   |
|----------------|----------------------------------------------------------------------|---|---|---|
| -q / --quick   | Don't do anything that takes a significant amount of time (~ >1 min) |   |   |   |
| -o / --offline | Don't do anything that requires an internet connection               |   |   |   |
| --do_update    | Call update function                                                 |   |   |   |
| --do_install   | Call install function                                                |   |   |   |
| --do_ssh       | Call SSH function                                                    |   |   |   |
| --do_config    | Call config function                                                 |   |   |   |
| --do_homedir   | Call homedir function                                                |   |   |   |

If one or more of the *--do_** parameters are used, only the according functions will be called, but not the others. These parameters do not have priority, so if you use both *--offline* and *--do_install*, nothing will happen.

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
- More to come (if you have any suggestions, create an issue to let me know)

<hr>

If you want to use it, you have to **_change the following first_**:
- Public keys that are added to authorized_keys
- Banner for SSH server
- Git name and email address</br>

The rest *can* be left unchanged.
