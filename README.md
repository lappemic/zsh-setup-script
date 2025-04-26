# ZSH Setup Script

A comprehensive, automated script to install ZSH, Oh-My-ZSH, and configure ZSH as the default shell for all users on Ubuntu/Debian-based servers.

## Overview

This repository contains a shell script that automates the complete installation and configuration of ZSH (Z Shell) with Oh-My-ZSH for all users on an Ubuntu/Debian-based system. It ensures that ZSH is set as the default shell for both existing and future users.

### Features

- Automated installation of ZSH and Oh-My-ZSH
- Configuration of ZSH as the default shell for all existing users
- Ensures future users will have ZSH as their default shell
- Comprehensive backup of existing configurations
- Detailed logging for troubleshooting
- Checks for and handles errors gracefully
- Automated installation of ZSH, Oh-My-ZSH, and popular plugins (zsh-autosuggestions, fzf)
- Adds a quick Vim access alias (`v` for `vim`)

## System Requirements

- Ubuntu or other Debian-based Linux distribution
- Root access or sudo privileges
- Internet connection (to install packages and clone Oh-My-ZSH)
- Basic packages: `git`, `curl` (script will install if not present)

## Installation Instructions

### Quick Start

1. Clone this repository to your server:
   ```bash
   git clone https://github.com/yourusername/zsh-setup-script.git
   cd zsh-setup-script
   ```

2. Make the script executable:
   ```bash
   chmod +x zsh-setup.sh
   ```

3. Run the script with sudo or as root:
   ```bash
   sudo ./zsh-setup.sh
   ```

### What the Script Does

When executed, the script performs the following actions:

1. **Checks for root privileges**
   - Verifies that the script is running with the necessary permissions

2. **Creates backup directory**
   - Creates a timestamped backup directory at `/root/zsh_backup_YYYYMMDDHHMMSS`
   - Backs up any existing ZSH configurations for all users

3. **Installs required packages**
   - Installs ZSH if not already installed
   - Installs Git and curl if not already installed

4. **Configures ZSH for all users**
   - Installs Oh-My-ZSH for each user with a valid home directory
   - Installs and enables plugins: zsh-autosuggestions and fzf (if available)
   - Adds an alias `v` for quick Vim access
   - Sets ZSH as the default shell for each user
   - Configures proper permissions for all files

5. **Sets up ZSH as default for future users**
   - Modifies system configuration to ensure new users get ZSH as their default shell

6. **Verifies the installation**
   - Checks that ZSH is correctly installed and configured

7. **Logs all actions**
   - Creates detailed logs at `/var/log/zsh-setup.log`

## Troubleshooting

### Common Issues

#### Script fails with permission errors
```
ERROR: This script must be run as root or with sudo privileges.
```
**Solution**: Run the script with sudo or as the root user: `sudo ./zsh-setup.sh`

#### Package installation fails
```
ERROR: Failed to update package lists.
ERROR: Failed to install zsh.
```
**Solution**: Check your internet connection and ensure apt is working correctly. Try running `sudo apt-get update` manually to see detailed errors.

#### Oh-My-ZSH installation fails
```
ERROR: Failed to clone Oh-My-ZSH for user username.
```
**Solution**: Verify internet connectivity and access to GitHub. Check if Git is installed correctly.

#### User's shell not changed
```
ERROR: Failed to set ZSH as default shell for user username.
```
**Solution**: Verify that ZSH is in `/etc/shells` and that the user exists. Some systems may require additional permissions to change user shells.

### Log File

All script actions are logged to `/var/log/zsh-setup.log`. This file contains valuable information for troubleshooting, including:
- Timestamp of each action
- Success/failure status of each step
- Error messages for any failed actions

To view the log:
```bash
cat /var/log/zsh-setup.log
```

## Backup and Recovery

### Backup Details

The script automatically creates backups before making any changes:

- Backup location: `/root/zsh_backup_YYYYMMDDHHMMSS` (timestamped)
- Contents backed up:
  - `.zshrc` files
  - `.zsh_history` files
  - `.oh-my-zsh` directories

### Restoring from Backup

If you need to restore a user's previous configuration:

1. Locate the backup directory:
   ```bash
   ls -la /root/ | grep zsh_backup
   ```

2. Restore the files for a specific user:
   ```bash
   # Restore .zshrc
   cp /root/zsh_backup_YYYYMMDDHHMMSS/username_zshrc.bak /home/username/.zshrc
   
   # Restore .zsh_history
   cp /root/zsh_backup_YYYYMMDDHHMMSS/username_zsh_history.bak /home/username/.zsh_history
   
   # Restore .oh-my-zsh directory
   rm -rf /home/username/.oh-my-zsh
   tar -xzf /root/zsh_backup_YYYYMMDDHHMMSS/username_oh-my-zsh.tar.gz -C /home/username/
   
   # Fix permissions
   chown -R username:username /home/username/.zshrc /home/username/.zsh_history /home/username/.oh-my-zsh
   ```

## Customization

After installation, users can customize their ZSH environments:

- Edit `.zshrc` in the user's home directory to change settings
- Explore Oh-My-ZSH themes by modifying the `ZSH_THEME` property in `.zshrc`
- Add plugins by modifying the `plugins` array in `.zshrc` (the script enables `git`, `vi-mode`, `zsh-autosuggestions`, and `fzf` if installed)
- Use the `v` alias for quick access to Vim

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

