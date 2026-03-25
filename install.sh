#!/bin/bash

#Pop Shell Install in Debian 13

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' #Null color

# Output functions
log(){
    echo -e "${BLUE}[INFO]${NC} $1"
}

error(){
    echo -e "${RED}[ERROR]${NC} $1"
}

success(){
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Directories
WORK_DIR="/tmp/popshell_install_work"
INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions/pop-shell@system76.com"

# Dependencies (runtime)
RUNTIME_DEPS="git libssl-dev libglib2.0-bin gnome-shell-extension-prefs"

# Dependencies (build only - will be removed after)
BUILD_DEPS="node-typescript make cargo rustc"

install_build_deps(){
    log "Installing build dependencies..."
    sudo apt update
    sudo apt install -y $RUNTIME_DEPS $BUILD_DEPS
    
    if ! command -v rustup >/dev/null; then
        log "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        source "$HOME/.cargo/env"
    fi
    
    rustup default stable
    
    if ! command -v just >/dev/null; then
        log "Installing just..."
        cargo install just
    fi
}

remove_build_deps(){
    log "Removing build tools to keep system clean..."
    sudo apt remove -y $BUILD_DEPS 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
}

# Install Pop Launcher
install_pop_launcher() {
    log "Installing Pop Launcher..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    if [ -d "pop-launcher" ]; then
        rm -rf pop-launcher
    fi

    git clone https://github.com/pop-os/launcher.git pop-launcher
    cd pop-launcher
    
    log "Building Pop Launcher (this may take a while)..."
    just build-release

    log "Installing Pop Launcher..."
    just install

    success "Pop Launcher installed."
}

# Install Pop Shell
install_pop_shell() {
    log "Installing Pop Shell..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    if [ -d "shell" ]; then
        rm -rf shell
    fi

    # Clone the repo
    git clone --branch master_noble https://github.com/pop-os/shell.git pop-shell-src
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
        # Sometimes a shell restart is needed before enabling
        gnome-extensions enable pop-shell@system76.com || log "Could not enable extension immediately. You may need to restart GNOME Shell first."
    else
        error "gnome-extensions not found. Please enable the extension manually."
    fi

    success "Pop Shell installed."
}

apply_schema() {
    log "Applying Debian 13 schema..."

    SCHEMA_FILE="org.gnome.shell.extensions.pop-shell.gschema.xml"
    LOCAL_SCHEMA="$INSTALL_DIR/schemas/$SCHEMA_FILE"
    SYSTEM_SCHEMA_DIR="/usr/share/glib-2.0/schemas"

    if [ -f "$LOCAL_SCHEMA" ]; then
        log "Copying schema to system directory..."
        sudo cp "$LOCAL_SCHEMA" "$SYSTEM_SCHEMA_DIR/"
        
        log "Compiling system schemas..."
        sudo glib-compile-schemas "$SYSTEM_SCHEMA_DIR"
        
        log "Compiling local schemas..."
        glib-compile-schemas "$INSTALL_DIR/schemas"
        
        log "Setting launcher shortcut to Super + /"
        gsettings set org.gnome.shell.extensions.pop-shell activate-launcher "['<Super>slash']" || true
        
        success "Schema fixes applied."
    else
        error "Schema file not found in build directory."
    fi
}

# Configure shortcuts
configure_shortcuts() {
    read -p "Do you want to apply Pop Shell keyboard shortcuts? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Applying shortcuts..."
        # Using the configure script from the repo
        sh "$WORK_DIR/pop-shell-src/scripts/configure.sh"
    fi
}

cleanup() {
    log "Cleaning up..."
    rm -rf "$WORK_DIR"
}

configure_autostart() {
    log "Configuring pop-launcher autostart..."
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/pop-launcher.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Pop Launcher
Comment=Starts the pop-launcher daemon
Exec=bash -c "sleep 3 && pop-launcher"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=3
EOF
    success "Autostart configured."
}

# Main execution
install_build_deps
install_pop_launcher
install_pop_shell
configure_autostart
remove_build_deps
apply_schema
configure_shortcuts
cleanup

success "Installation complete! Please restart GNOME Shell (Log out and Log in) for changes to take full effect."
