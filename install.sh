#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Installation Engine
# Version: 1.0.0
# Pure Bash, no external dependencies
################################################################################

set -o pipefail

################################################################################
# GLOBALS & INITIALIZATION
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FUNCTIONS_FILE="$SCRIPT_DIR/functions.sh"
readonly CONFIG_FILE="${1:-$SCRIPT_DIR/config.env}"
readonly GENERATE_SCRIPT="$SCRIPT_DIR/generate.sh"
readonly LOG_FILE="$SCRIPT_DIR/install.log"

# Installation state
INSTALL_STEP=0
INSTALL_TOTAL=0
DISTRO_INSTALLED=0

# Track what was installed
declare -a INSTALLED_PACKAGES=()

################################################################################
# SOURCE DEPENDENCIES
################################################################################

if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "ERROR: functions.sh not found at $FUNCTIONS_FILE" >&2
    exit 1
fi

source "$FUNCTIONS_FILE" || {
    echo "ERROR: Failed to source functions.sh" >&2
    exit 1
}

################################################################################
# INSTALLATION HELPERS
################################################################################

# Log to file and console
log_install() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
    print_info "$message"
}

# Start installation step
start_step() {
    ((INSTALL_STEP++))
    local message="$1"
    show_progress "$INSTALL_STEP" "$INSTALL_TOTAL" "$message"
    log_install "Step $INSTALL_STEP: $message"
}

# Mark step as complete
complete_step() {
    print_success "Complete"
}

# Calculate total steps
calculate_total_steps() {
    INSTALL_TOTAL=0
    
    ((INSTALL_TOTAL++))  # System check
    ((INSTALL_TOTAL++))  # Dependencies
    ((INSTALL_TOTAL++))  # proot-distro
    ((INSTALL_TOTAL++))  # Distro installation
    ((INSTALL_TOTAL++))  # Desktop environment
    ((INSTALL_TOTAL++))  # File manager
    ((INSTALL_TOTAL++))  # Panel/bar
    ((INSTALL_TOTAL++))  # Launcher
    ((INSTALL_TOTAL++))  # Terminal
    ((INSTALL_TOTAL++))  # Final configuration
    ((INSTALL_TOTAL++))  # Generate scripts
}

################################################################################
# CONFIGURATION LOADING
################################################################################

load_installation_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    if ! load_config_file "$CONFIG_FILE"; then
        print_error "Failed to load configuration"
        return 1
    fi
    
    print_success "Configuration loaded"
    return 0
}

################################################################################
# SYSTEM CHECKS
################################################################################

check_installation_environment() {
    start_step "Checking system environment"
    
    # Check Termux
    if ! is_termux; then
        print_error "Not running in Termux"
        return 1
    fi
    
    print_info "Termux version: $(get_termux_version)"
    
    # Check architecture
    local arch
    arch=$(detect_architecture)
    print_info "Architecture: $arch"
    
    if [[ ! "$arch" =~ ^(arm|arm64|amd64|i386)$ ]]; then
        print_error "Unsupported architecture: $arch"
        return 1
    fi
    
    # Check storage
    local storage
    storage=$(get_free_storage "$HOME")
    if [[ "$storage" != "unknown" ]]; then
        print_info "Available storage: ${storage}MB"
        if [ "$storage" -lt 500 ]; then
            print_warning "Low storage space"
        fi
    fi
    
    complete_step
    return 0
}

################################################################################
# DEPENDENCY INSTALLATION
################################################################################

install_termux_dependencies() {
    start_step "Installing required packages"
    
    # Update package list
    print_info "Updating package list..."
    if ! apt update -qq; then
        print_warning "apt update had issues, continuing anyway..."
    fi
    
    # Core dependencies
    local core_packages=(
        "proot-distro"
        "bash"
    )
    
    # Display system packages
    case "${CONFIG_DISPLAY}" in
        termux-x11)
            core_packages+=("x11-repo" "termux-x11-nightly")
            ;;
        vnc)
            core_packages+=("tightvncserver")
            ;;
    esac
    
    # Install packages
    for package in "${core_packages[@]}"; do
        if ! package_installed "$package"; then
            print_info "Installing: $package"
            if apt install -y "$package" > /dev/null 2>&1; then
                INSTALLED_PACKAGES+=("$package")
                print_success "Installed: $package"
            else
                print_warning "Failed to install: $package (may already exist)"
            fi
        else
            print_info "Already installed: $package"
        fi
    done
    
    complete_step
    return 0
}

################################################################################
# PROOT-DISTRO INSTALLATION
################################################################################

check_proot_distro() {
    if ! has_proot_distro; then
        print_error "proot-distro not available"
        return 1
    fi
    
    print_success "proot-distro is available"
    return 0
}

install_linux_distribution() {
    start_step "Installing Linux distribution: ${CONFIG_DISTRO}"
    
    if ! check_proot_distro; then
        print_error "proot-distro not available"
        return 1
    fi
    
    # Check if already installed
    if distro_installed "${CONFIG_DISTRO}"; then
        print_warning "Distribution already installed: ${CONFIG_DISTRO}"
        if ! confirm "Reinstall?" "n"; then
            DISTRO_INSTALLED=1
            complete_step
            return 0
        fi
    fi
    
    print_info "Installing ${CONFIG_DISTRO}..."
    
    if proot-distro install "${CONFIG_DISTRO}"; then
        DISTRO_INSTALLED=1
        print_success "Distribution installed: ${CONFIG_DISTRO}"
    else
        print_error "Failed to install distribution: ${CONFIG_DISTRO}"
        return 1
    fi
    
    complete_step
    return 0
}

################################################################################
# DISTRO ENVIRONMENT SETUP
################################################################################

run_in_distro() {
    local command="$1"
    
    if ! has_proot_distro; then
        print_error "proot-distro not available"
        return 1
    fi
    
    proot-distro login "${CONFIG_DISTRO}" -- bash -c "$command"
}

update_distro_packages() {
    start_step "Updating distribution packages"
    
    print_info "This may take a while..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get update && apt-get upgrade -y" || {
                print_warning "Package update had issues, continuing..."
            }
            ;;
        arch)
            run_in_distro "pacman -Syu --noconfirm" || {
                print_warning "Package update had issues, continuing..."
            }
            ;;
        alpine)
            run_in_distro "apk update && apk upgrade" || {
                print_warning "Package update had issues, continuing..."
            }
            ;;
        void)
            run_in_distro "xbps-install -Su" || {
                print_warning "Package update had issues, continuing..."
            }
            ;;
    esac
    
    complete_step
    return 0
}

################################################################################
# DESKTOP ENVIRONMENT INSTALLATION
################################################################################

install_desktop_environment() {
    start_step "Installing desktop environment: ${CONFIG_DESKTOP_ENV}"
    
    case "${CONFIG_DESKTOP_ENV}" in
        xfce)
            install_xfce
            ;;
        lxqt)
            install_lxqt
            ;;
        kde)
            install_kde
            ;;
        none)
            print_info "No desktop environment selected"
            ;;
        *)
            print_warning "Unknown desktop environment: ${CONFIG_DESKTOP_ENV}"
            ;;
    esac
    
    complete_step
    return 0
}

install_xfce() {
    print_info "Installing XFCE..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y xfce4 xfce4-terminal xfce4-panel xfce4-session xfce4-settings xfdesktop4 xfwm4" || {
                print_error "Failed to install XFCE"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S xfce4 --noconfirm" || {
                print_error "Failed to install XFCE"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add xfce4 xfce4-terminal" || {
                print_error "Failed to install XFCE"
                return 1
            }
            ;;
    esac
    
    print_success "XFCE installed"
    return 0
}

install_lxqt() {
    print_info "Installing LXQt..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y lxqt lxqt-session" || {
                print_error "Failed to install LXQt"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S lxqt --noconfirm" || {
                print_error "Failed to install LXQt"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add lxqt lxqt-session" || {
                print_error "Failed to install LXQt"
                return 1
            }
            ;;
    esac
    
    print_success "LXQt installed"
    return 0
}

install_kde() {
    print_info "Installing KDE Plasma..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y kde-plasma-desktop" || {
                print_error "Failed to install KDE"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S plasma --noconfirm" || {
                print_error "Failed to install KDE"
                return 1
            }
            ;;
    esac
    
    print_success "KDE Plasma installed"
    return 0
}

################################################################################
# WINDOW MANAGER INSTALLATION
################################################################################

install_window_manager() {
    if [[ "${CONFIG_WM}" == "none" ]] || [[ "${CONFIG_WM}" == "${CONFIG_DESKTOP_ENV}" ]]; then
        return 0
    fi
    
    case "${CONFIG_WM}" in
        openbox)
            install_openbox
            ;;
        icewm)
            install_icewm
            ;;
        i3)
            install_i3
            ;;
        bspwm)
            install_bspwm
            ;;
        hyprland)
            install_hyprland
            ;;
    esac
}

install_openbox() {
    print_info "Installing Openbox..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y openbox obconf" || {
                print_warning "Failed to install Openbox"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S openbox --noconfirm" || {
                print_warning "Failed to install Openbox"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add openbox" || {
                print_warning "Failed to install Openbox"
                return 1
            }
            ;;
    esac
    
    print_success "Openbox installed"
    return 0
}

install_icewm() {
    print_info "Installing IceWM..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y icewm" || {
                print_warning "Failed to install IceWM"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S icewm --noconfirm" || {
                print_warning "Failed to install IceWM"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add icewm" || {
                print_warning "Failed to install IceWM"
                return 1
            }
            ;;
    esac
    
    print_success "IceWM installed"
    return 0
}

install_i3() {
    print_info "Installing i3..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y i3 i3-wm i3status" || {
                print_warning "Failed to install i3"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S i3 --noconfirm" || {
                print_warning "Failed to install i3"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add i3wm" || {
                print_warning "Failed to install i3"
                return 1
            }
            ;;
    esac
    
    print_success "i3 installed"
    return 0
}

install_bspwm() {
    print_info "Installing bspwm..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y bspwm sxhkd" || {
                print_warning "Failed to install bspwm"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S bspwm sxhkd --noconfirm" || {
                print_warning "Failed to install bspwm"
                return 1
            }
            ;;
    esac
    
    print_success "bspwm installed"
    return 0
}

install_hyprland() {
    print_info "Installing Hyprland..."
    
    case "${CONFIG_DISTRO}" in
        arch)
            run_in_distro "pacman -S hyprland --noconfirm" || {
                print_warning "Hyprland may not be available"
                return 1
            }
            ;;
        *)
            print_warning "Hyprland may not be available on ${CONFIG_DISTRO}"
            return 1
            ;;
    esac
    
    print_success "Hyprland installed"
    return 0
}

################################################################################
# FILE MANAGER INSTALLATION
################################################################################

install_file_manager() {
    start_step "Installing file manager: ${CONFIG_FILE_MANAGER}"
    
    if [[ "${CONFIG_FILE_MANAGER}" == "none" ]]; then
        print_info "No file manager selected"
        complete_step
        return 0
    fi
    
    case "${CONFIG_FILE_MANAGER}" in
        thunar)
            install_thunar
            ;;
        pcmanfm)
            install_pcmanfm
            ;;
        nemo)
            install_nemo
            ;;
        ranger)
            install_ranger
            ;;
        mc)
            install_mc
            ;;
    esac
    
    complete_step
    return 0
}

install_thunar() {
    print_info "Installing Thunar..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y thunar tumbler" || {
                print_warning "Failed to install Thunar"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S thunar --noconfirm" || {
                print_warning "Failed to install Thunar"
                return 1
            }
            ;;
    esac
    
    print_success "Thunar installed"
    return 0
}

install_pcmanfm() {
    print_info "Installing PCManFM..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y pcmanfm" || {
                print_warning "Failed to install PCManFM"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S pcmanfm --noconfirm" || {
                print_warning "Failed to install PCManFM"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add pcmanfm" || {
                print_warning "Failed to install PCManFM"
                return 1
            }
            ;;
    esac
    
    print_success "PCManFM installed"
    return 0
}

install_nemo() {
    print_info "Installing Nemo..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y nemo" || {
                print_warning "Failed to install Nemo"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S nemo --noconfirm" || {
                print_warning "Failed to install Nemo"
                return 1
            }
            ;;
    esac
    
    print_success "Nemo installed"
    return 0
}

install_ranger() {
    print_info "Installing Ranger..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y ranger" || {
                print_warning "Failed to install Ranger"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S ranger --noconfirm" || {
                print_warning "Failed to install Ranger"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add ranger" || {
                print_warning "Failed to install Ranger"
                return 1
            }
            ;;
    esac
    
    print_success "Ranger installed"
    return 0
}

install_mc() {
    print_info "Installing Midnight Commander..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y mc" || {
                print_warning "Failed to install MC"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S mc --noconfirm" || {
                print_warning "Failed to install MC"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add mc" || {
                print_warning "Failed to install MC"
                return 1
            }
            ;;
    esac
    
    print_success "Midnight Commander installed"
    return 0
}

################################################################################
# PANEL / BAR INSTALLATION
################################################################################

install_panel_bar() {
    start_step "Installing panel/bar: ${CONFIG_BAR}"
    
    if [[ "${CONFIG_BAR}" == "none" ]]; then
        print_info "No panel/bar selected"
        complete_step
        return 0
    fi
    
    case "${CONFIG_BAR}" in
        polybar)
            install_polybar
            ;;
        waybar)
            install_waybar
            ;;
        tint2)
            install_tint2
            ;;
        xfce4-panel)
            install_xfce_panel
            ;;
    esac
    
    complete_step
    return 0
}

install_polybar() {
    print_info "Installing Polybar..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y polybar" || {
                print_warning "Failed to install Polybar"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S polybar --noconfirm" || {
                print_warning "Failed to install Polybar"
                return 1
            }
            ;;
    esac
    
    print_success "Polybar installed"
    return 0
}

install_waybar() {
    print_info "Installing Waybar..."
    
    case "${CONFIG_DISTRO}" in
        arch)
            run_in_distro "pacman -S waybar --noconfirm" || {
                print_warning "Failed to install Waybar"
                return 1
            }
            ;;
        *)
            print_warning "Waybar may not be available on ${CONFIG_DISTRO}"
            return 1
            ;;
    esac
    
    print_success "Waybar installed"
    return 0
}

install_tint2() {
    print_info "Installing Tint2..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y tint2" || {
                print_warning "Failed to install Tint2"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S tint2 --noconfirm" || {
                print_warning "Failed to install Tint2"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add tint2" || {
                print_warning "Failed to install Tint2"
                return 1
            }
            ;;
    esac
    
    print_success "Tint2 installed"
    return 0
}

install_xfce_panel() {
    print_info "Installing XFCE Panel..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y xfce4-panel" || {
                print_warning "Failed to install XFCE Panel"
                return 1
            }
            ;;
    esac
    
    print_success "XFCE Panel installed"
    return 0
}

################################################################################
# APPLICATION LAUNCHER INSTALLATION
################################################################################

install_launcher() {
    start_step "Installing launcher: ${CONFIG_LAUNCHER}"
    
    if [[ "${CONFIG_LAUNCHER}" == "none" ]]; then
        print_info "No launcher selected"
        complete_step
        return 0
    fi
    
    case "${CONFIG_LAUNCHER}" in
        rofi)
            install_rofi
            ;;
        wofi)
            install_wofi
            ;;
        dmenu)
            install_dmenu
            ;;
    esac
    
    complete_step
    return 0
}

install_rofi() {
    print_info "Installing Rofi..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y rofi" || {
                print_warning "Failed to install Rofi"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S rofi --noconfirm" || {
                print_warning "Failed to install Rofi"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add rofi" || {
                print_warning "Failed to install Rofi"
                return 1
            }
            ;;
    esac
    
    print_success "Rofi installed"
    return 0
}

install_wofi() {
    print_info "Installing Wofi..."
    
    case "${CONFIG_DISTRO}" in
        arch)
            run_in_distro "pacman -S wofi --noconfirm" || {
                print_warning "Failed to install Wofi"
                return 1
            }
            ;;
        *)
            print_warning "Wofi may not be available on ${CONFIG_DISTRO}"
            return 1
            ;;
    esac
    
    print_success "Wofi installed"
    return 0
}

install_dmenu() {
    print_info "Installing dmenu..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y dmenu" || {
                print_warning "Failed to install dmenu"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S dmenu --noconfirm" || {
                print_warning "Failed to install dmenu"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add dmenu" || {
                print_warning "Failed to install dmenu"
                return 1
            }
            ;;
    esac
    
    print_success "dmenu installed"
    return 0
}

################################################################################
# TERMINAL INSTALLATION
################################################################################

install_terminal() {
    start_step "Installing terminal: ${CONFIG_TERMINAL}"
    
    if [[ "${CONFIG_TERMINAL}" == "default" ]] || [[ "${CONFIG_TERMINAL}" == "bash" ]]; then
        print_info "Using default/bash terminal"
        complete_step
        return 0
    fi
    
    case "${CONFIG_TERMINAL}" in
        zsh)
            install_zsh
            ;;
        fish)
            install_fish
            ;;
    esac
    
    complete_step
    return 0
}

install_zsh() {
    print_info "Installing Zsh..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y zsh" || {
                print_warning "Failed to install Zsh"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S zsh --noconfirm" || {
                print_warning "Failed to install Zsh"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add zsh" || {
                print_warning "Failed to install Zsh"
                return 1
            }
            ;;
    esac
    
    print_success "Zsh installed"
    return 0
}

install_fish() {
    print_info "Installing Fish..."
    
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y fish" || {
                print_warning "Failed to install Fish"
                return 1
            }
            ;;
        arch)
            run_in_distro "pacman -S fish --noconfirm" || {
                print_warning "Failed to install Fish"
                return 1
            }
            ;;
        alpine)
            run_in_distro "apk add fish" || {
                print_warning "Failed to install Fish"
                return 1
            }
            ;;
    esac
    
    print_success "Fish installed"
    return 0
}

################################################################################
# FINAL CONFIGURATION
################################################################################

final_configuration() {
    start_step "Finalizing configuration"
    
    # Create necessary directories in distro
    run_in_distro "mkdir -p ~/.config ~/.local/share" || {
        print_warning "Failed to create config directories"
    }
    
    # Install essential utilities if not present
    case "${CONFIG_DISTRO}" in
        debian|ubuntu)
            run_in_distro "apt-get install -y curl wget xorg-server xvfb dbus" 2>/dev/null || true
            ;;
        arch)
            run_in_distro "pacman -S curl wget xorg-server --noconfirm" 2>/dev/null || true
            ;;
        alpine)
            run_in_distro "apk add curl wget xvfb dbus" 2>/dev/null || true
            ;;
    esac
    
    print_success "Configuration complete"
    complete_step
    return 0
}

################################################################################
# GENERATE STARTUP SCRIPTS
################################################################################

generate_startup_scripts() {
    start_step "Generating startup scripts"
    
    if [[ ! -f "$GENERATE_SCRIPT" ]]; then
        print_error "Generator script not found: $GENERATE_SCRIPT"
        return 1
    fi
    
    print_info "Running generator..."
    
    if bash "$GENERATE_SCRIPT" "$CONFIG_FILE"; then
        print_success "Startup scripts generated"
    else
        print_error "Failed to generate startup scripts"
        return 1
    fi
    
    complete_step
    return 0
}

################################################################################
# INSTALLATION SUMMARY
################################################################################

show_installation_summary() {
    print_section "Installation Complete"
    
    print_success "Your desktop environment is ready!"
    echo
    
    print_info "Configuration:"
    printf "  Distribution: %s\n" "${CONFIG_DISTRO}"
    printf "  Display: %s\n" "${CONFIG_DISPLAY}"
    printf "  Desktop/WM: %s / %s\n" "${CONFIG_DESKTOP_ENV}" "${CONFIG_WM}"
    printf "  Terminal: %s\n" "${CONFIG_TERMINAL}"
    printf "  File Manager: %s\n" "${CONFIG_FILE_MANAGER}"
    printf "  Launcher: %s\n" "${CONFIG_LAUNCHER}"
    printf "  Panel/Bar: %s\n" "${CONFIG_BAR}"
    echo
    
    print_info "Next steps:"
    echo "  1. Run: bash start.sh"
    echo "  2. Or check status: bash doctor.sh"
    echo "  3. Or remove: bash remove.sh"
    echo
    
    print_info "Log file: $LOG_FILE"
}

################################################################################
# MAIN INSTALLATION FLOW
################################################################################

main() {
    setup_error_handling
    
    print_banner
    
    print_section "Installation Engine"
    
    # Load configuration
    if ! load_installation_config; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    # Calculate total steps
    calculate_total_steps
    
    print_section "Installation Progress"
    
    # Run installation steps
    if ! check_installation_environment; then
        print_error "Environment check failed"
        exit 1
    fi
    
    if ! install_termux_dependencies; then
        print_error "Dependency installation failed"
        exit 1
    fi
    
    if ! install_linux_distribution; then
        print_error "Distribution installation failed"
        exit 1
    fi
    
    if ! update_distro_packages; then
        print_warning "Package update failed, continuing..."
    fi
    
    if ! install_desktop_environment; then
        print_warning "Desktop environment installation failed"
    fi
    
    if ! install_window_manager; then
        print_warning "Window manager installation failed"
    fi
    
    if ! install_file_manager; then
        print_warning "File manager installation failed"
    fi
    
    if ! install_panel_bar; then
        print_warning "Panel/bar installation failed"
    fi
    
    if ! install_launcher; then
        print_warning "Launcher installation failed"
    fi
    
    if ! install_terminal; then
        print_warning "Terminal installation failed"
    fi
    
    if ! final_configuration; then
        print_warning "Final configuration failed"
    fi
    
    if ! generate_startup_scripts; then
        print_error "Failed to generate startup scripts"
        exit 1
    fi
    
    # Show summary
    show_installation_summary
}

# Execute main
main "$@"
