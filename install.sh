#!/bin/bash

# Pop Shell Installer for Debian 13
# Installs Pop Shell and Pop Launcher on a clean Debian 13 system.

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Directories
WORK_DIR="/tmp/popshell_installer_work"
INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions/pop-shell@system76.com"

# Check dependencies
check_dependencies() {
    log "Checking system dependencies..."
    # libglib2.0-bin provides glib-compile-schemas
    DEPENDENCIES="git node-typescript make cargo rustc libssl-dev libglib2.0-bin gnome-shell-extension-prefs"
    
    MISSING_DEPS=""
    for dep in $DEPENDENCIES; do
        if ! dpkg -s $dep >/dev/null 2>&1; then
            MISSING_DEPS="$MISSING_DEPS $dep"
        fi
    done

    if [ ! -z "$MISSING_DEPS" ]; then
        log "Installing missing dependencies: $MISSING_DEPS"
        sudo apt update
        sudo apt install -y $MISSING_DEPS
    else
        success "All dependencies are installed."
    fi
}

install_pop_launcher() {
    log "Installing Pop Launcher..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    if [ -d "pop-launcher" ]; then
        rm -rf pop-launcher
    fi

    git clone https://github.com/pop-os/pop-launcher.git
    cd pop-launcher
    
    log "Building Pop Launcher (this may take a while)..."
    cargo build --release

    log "Installing Pop Launcher binaries and plugins..."
    
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share/pop-launcher/plugins
    mkdir -p ~/.local/share/pop-launcher/scripts

    cp target/release/pop-launcher-bin ~/.local/bin/pop-launcher
    
    # Plugins
    PLUGINS="calc desktop_entries files find pop_shell pulse recent scripts terminal web"
    for plugin in $PLUGINS; do
        mkdir -p ~/.local/share/pop-launcher/plugins/$plugin
        cp plugins/src/$plugin/*.ron ~/.local/share/pop-launcher/plugins/$plugin/
        
        # Create symlink with correct name (replace _ with -)
        LINK_NAME=$(echo $plugin | sed 's/_/-/')
        ln -sf ~/.local/bin/pop-launcher ~/.local/share/pop-launcher/plugins/$plugin/$LINK_NAME
    done

    # Scripts
    cp -r scripts/* ~/.local/share/pop-launcher/scripts/

    success "Pop Launcher installed."
}

install_pop_shell() {
    log "Installing Pop Shell..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    if [ -d "shell" ]; then
        rm -rf shell
    fi

    # Clone the repo
    git clone https://github.com/pop-os/shell.git pop-shell-src
    cd pop-shell-src

    log "Compiling Pop Shell..."
    make compile

    log "Installing Pop Shell extension..."
    
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cp -r _build/* "$INSTALL_DIR/"

    # Enable extension
    if command -v gnome-extensions >/dev/null; then
        log "Enabling Pop Shell extension..."
        # Sometimes a shell restart is needed before enabling, but we try anyway
        gnome-extensions enable pop-shell@system76.com || log "Could not enable extension immediately. You may need to restart GNOME Shell first."
    else
        error "gnome-extensions not found. Please enable the extension manually."
    fi

    success "Pop Shell installed."
}

configure_shortcuts() {
    read -p "Do you want to apply Pop Shell keyboard shortcuts? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Applying shortcuts..."
        # We can run the configure script from the repo
        sh "$WORK_DIR/pop-shell-src/scripts/configure.sh"
    fi
}

cleanup() {
    log "Cleaning up..."
    rm -rf "$WORK_DIR"
}

# Main execution
check_dependencies
install_pop_launcher
install_pop_shell
configure_shortcuts
cleanup

success "Installation complete! Please restart GNOME Shell (Log out and Log in) for changes to take full effect."