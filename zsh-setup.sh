#!/bin/bash
#
# ZSH Setup Script
# ----------------
# This script installs ZSH, Oh-My-ZSH, and configures ZSH as the default shell
# for all users on an Ubuntu server.
#
# Requirements: 
# - Ubuntu/Debian-based system
# - Root privileges (run with sudo)
#

# Set strict error handling
set -e

# Configuration variables
BACKUP_DIR="/root/zsh_backup_$(date +%Y%m%d%H%M%S)"
LOG_FILE="/var/log/zsh-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Log function
log() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

# Display error message and exit
error_exit() {
    log "ERROR" "$1"
    echo -e "${RED}ERROR:${NC} $1"
    exit 1
}

# Display info message
info() {
    log "INFO" "$1"
    echo -e "${GREEN}INFO:${NC} $1"
}

# Display warning message
warning() {
    log "WARNING" "$1"
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "This script must be run as root or with sudo privileges."
    fi
    info "Root privileges confirmed."
}

# Create backup directory
setup_backup() {
    info "Setting up backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory."
}

# Check if a package is installed
is_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Install a package if it's not already installed
install_package() {
    local package=$1
    
    if is_package_installed "$package"; then
        info "Package $package is already installed."
    else
        info "Installing package: $package"
        apt-get update -qq || error_exit "Failed to update package lists."
        apt-get install -y "$package" || error_exit "Failed to install $package."
        info "Package $package installed successfully."
    fi
}

# Backup existing ZSH configuration files
backup_zsh_config() {
    local user=$1
    local home_dir
    
    if [ "$user" = "root" ]; then
        home_dir="/root"
    else
        home_dir="/home/$user"
    fi
    
    info "Backing up ZSH configuration for user $user"
    
    # Backup .zshrc file if it exists
    if [ -f "$home_dir/.zshrc" ]; then
        cp "$home_dir/.zshrc" "$BACKUP_DIR/${user}_zshrc.bak" || warning "Failed to backup .zshrc for $user"
    fi
    
    # Backup .zsh_history file if it exists
    if [ -f "$home_dir/.zsh_history" ]; then
        cp "$home_dir/.zsh_history" "$BACKUP_DIR/${user}_zsh_history.bak" || warning "Failed to backup .zsh_history for $user"
    fi
    
    # Backup .oh-my-zsh directory if it exists
    if [ -d "$home_dir/.oh-my-zsh" ]; then
        tar -czf "$BACKUP_DIR/${user}_oh-my-zsh.tar.gz" -C "$home_dir" .oh-my-zsh >/dev/null 2>&1 || warning "Failed to backup .oh-my-zsh for $user"
    fi
}

# Install Oh-My-ZSH for a specific user
install_oh_my_zsh_for_user() {
    local user=$1
    local home_dir
    
    if [ "$user" = "root" ]; then
        home_dir="/root"
    else
        home_dir="/home/$user"
    fi
    
    info "Installing Oh-My-ZSH for user $user"
    
    # Backup existing Oh-My-ZSH installation
    backup_zsh_config "$user"
    
    # Remove existing Oh-My-ZSH directory if it exists
    if [ -d "$home_dir/.oh-my-zsh" ]; then
        rm -rf "$home_dir/.oh-my-zsh"
    fi
    
    # Clone Oh-My-ZSH repository
    if [ "$user" = "root" ]; then
        # Install for root user
        git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$home_dir/.oh-my-zsh" || error_exit "Failed to clone Oh-My-ZSH for root user."
    else
        # Install for non-root user
        su - "$user" -c "git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git $home_dir/.oh-my-zsh" || error_exit "Failed to clone Oh-My-ZSH for user $user."
    fi
    
    # Create a new .zshrc file
    cp "$home_dir/.oh-my-zsh/templates/zshrc.zsh-template" "$home_dir/.zshrc" || error_exit "Failed to create .zshrc for user $user."
    
    # Set proper ownership of .zshrc and .oh-my-zsh
    if [ "$user" != "root" ]; then
        chown -R "$user:$user" "$home_dir/.oh-my-zsh" "$home_dir/.zshrc"
    fi
    
    info "Oh-My-ZSH installed successfully for user $user."
}

# Set ZSH as default shell for a user
set_zsh_as_default_shell() {
    local user=$1
    local zsh_path=$(which zsh)
    
    info "Setting ZSH as default shell for user $user"
    
    # Check if user's shell is already ZSH
    local current_shell
    current_shell=$(getent passwd "$user" | cut -d: -f7)
    
    if [ "$current_shell" = "$zsh_path" ]; then
        info "ZSH is already the default shell for user $user."
        return 0
    fi
    
    # Change user's default shell to ZSH
    chsh -s "$zsh_path" "$user" || error_exit "Failed to set ZSH as default shell for user $user."
    info "ZSH set as default shell for user $user."
}

# Configure ZSH as default shell for all users
configure_zsh_for_all_users() {
    info "Configuring ZSH as default shell for all users"
    
    # Add ZSH to /etc/shells if not already present
    if ! grep -q "^$(which zsh)$" /etc/shells; then
        which zsh >> /etc/shells || error_exit "Failed to add ZSH to /etc/shells."
        info "Added ZSH to /etc/shells."
    fi
    
    # Set ZSH as default shell for all existing users with login capability
    for user_info in $(getent passwd); do
        local user
        local home_dir
        local shell
        
        user=$(echo "$user_info" | cut -d: -f1)
        home_dir=$(echo "$user_info" | cut -d: -f6)
        shell=$(echo "$user_info" | cut -d: -f7)
        
        # Skip system users (UID < 1000, except root)
        local uid
        uid=$(id -u "$user" 2>/dev/null || echo "0")
        
        if [ "$uid" -lt 1000 ] && [ "$user" != "root" ]; then
            continue
        fi
        
        # Skip users with nologin or false shells
        if [[ "$shell" == *"nologin"* ]] || [[ "$shell" == *"false"* ]]; then
            continue
        fi
        
        # Skip users without a home directory
        if [ ! -d "$home_dir" ]; then
            continue
        fi
        
        # Install Oh-My-ZSH and set ZSH as default shell
        install_oh_my_zsh_for_user "$user"
        set_zsh_as_default_shell "$user"
    done
    
    info "ZSH configured as default shell for all regular users."
}

# Configure ZSH as default shell for future users
configure_zsh_for_future_users() {
    info "Configuring ZSH as default shell for future users"
    
    # Check if DSHELL line exists in /etc/adduser.conf
    if grep -q "^DSHELL=" /etc/adduser.conf; then
        # Update existing DSHELL line
        sed -i "s|^DSHELL=.*|DSHELL=$(which zsh)|" /etc/adduser.conf || warning "Failed to update DSHELL in /etc/adduser.conf."
    else
        # Add DSHELL line
        echo "DSHELL=$(which zsh)" >> /etc/adduser.conf || warning "Failed to add DSHELL to /etc/adduser.conf."
    fi
    
    # Check if /etc/default/useradd exists
    if [ -f /etc/default/useradd ]; then
        if grep -q "^SHELL=" /etc/default/useradd; then
            # Update existing SHELL line
            sed -i "s|^SHELL=.*|SHELL=$(which zsh)|" /etc/default/useradd || warning "Failed to update SHELL in /etc/default/useradd."
        else
            # Add SHELL line
            echo "SHELL=$(which zsh)" >> /etc/default/useradd || warning "Failed to add SHELL to /etc/default/useradd."
        fi
    fi
    
    info "ZSH configured as default shell for future users."
}

# Verify ZSH installation
verify_installation() {
    info "Verifying ZSH installation"
    
    # Check if ZSH is installed
    if ! command -v zsh >/dev/null 2>&1; then
        error_exit "ZSH is not installed. Installation failed."
    fi
    
    # Check if ZSH is in /etc/shells
    if ! grep -q "^$(which zsh)$" /etc/shells; then
        warning "ZSH is not properly registered in /etc/shells."
    fi
    
    info "ZSH installation verified successfully."
}

# Main function
main() {
    echo "=== ZSH and Oh-My-ZSH Installation Script ==="
    echo "This script will install ZSH and Oh-My-ZSH for all users."
    echo "It requires root privileges and is designed for Ubuntu/Debian-based systems."
    echo "==============================================="
    
    # Initialize log file
    touch "$LOG_FILE" || error_exit "Failed to create log file."
    chown root:root "$LOG_FILE" 
    chmod 644 "$LOG_FILE"
    
    log "INFO" "==============================================="
    log "INFO" "ZSH Setup Script started"
    log "INFO" "==============================================="
    
    # Check if running with root privileges
    check_root
    
    # Setup backup directory
    setup_backup
    
    # Check OS distribution to ensure it's Ubuntu/Debian
    if [ ! -f /etc/debian_version ]; then
        warning "This script is designed for Ubuntu/Debian-based systems. It might not work correctly on this system."
    fi
    
    # Install required packages
    install_package "zsh"
    install_package "git"
    install_package "curl"
    
    # Configure ZSH for all users
    configure_zsh_for_all_users
    
    # Configure ZSH as default shell for future users
    configure_zsh_for_future_users
    
    # Verify installation
    verify_installation
    
    log "INFO" "==============================================="
    log "INFO" "ZSH Setup Script completed successfully"
    log "INFO" "==============================================="
    
    info "ZSH and Oh-My-ZSH have been successfully installed for all users."
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    return 0
}

# Execute main function
main

