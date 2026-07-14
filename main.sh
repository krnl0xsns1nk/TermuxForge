#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Main CLI Interface
# Version: 1.0.0
# Pure Bash, no external dependencies
################################################################################

set -o pipefail

################################################################################
# GLOBALS & INITIALIZATION
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FUNCTIONS_FILE="$SCRIPT_DIR/functions.sh"
readonly CONFIG_FILE="$SCRIPT_DIR/config.env"
readonly BACKUP_DIR="$SCRIPT_DIR/.backup"

# Default selections
declare -A CONFIG=(
    [DISTRO]=""
    [DISPLAY]=""
    [DESKTOP_ENV]=""
    [WM]=""
    [TERMINAL]=""
    [FILE_MANAGER]=""
    [BAR]=""
    [LAUNCHER]=""
    [EXTRAS]=""
)

# Preset profiles (built-in, no file needed)
declare -A PRESETS=(
    [recommended]="debian|termux-x11|xfce|xfce|bash|thunar|xfce4-panel|rofi"
    [lightweight]="alpine|vnc|openbox|openbox|bash|pcmanfm|none|none"
    [developer]="debian|termux-x11|i3|i3|bash|pcmanfm|polybar|rofi"
    [modern]="arch|termux-x11|hyprland|hyprland|zsh|thunar|waybar|wofi"
)

################################################################################
# SOURCE DEPENDENCIES
################################################################################

if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "ERROR: functions.sh not found at $FUNCTIONS_FILE" >&2
    echo "Make sure functions.sh is in the same directory as main.sh" >&2
    exit 1
fi

source "$FUNCTIONS_FILE" || {
    echo "ERROR: Failed to source functions.sh" >&2
    exit 1
}

################################################################################
# MAIN MENU
################################################################################

show_main_menu() {
    print_banner
    
    local options=(
        "Recommended Desktop (Stable, beginner-friendly)"
        "Lightweight Desktop (For old phones, low RAM)"
        "Developer Environment (Terminal-focused)"
        "Modern Desktop (Beautiful, customizable)"
        "Custom Setup (Choose every component)"
        "Exit"
    )
    
    print_subsection "Choose Installation Type"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            load_preset "recommended"
            ;;
        2)
            load_preset "lightweight"
            ;;
        3)
            load_preset "developer"
            ;;
        4)
            load_preset "modern"
            ;;
        5)
            custom_setup
            ;;
        6)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            show_main_menu
            ;;
    esac
}

################################################################################
# PRESET LOADING
################################################################################

load_preset() {
    local preset="$1"
    
    if [[ -z "${PRESETS[$preset]}" ]]; then
        print_error "Preset not found: $preset"
        return 1
    fi
    
    print_info "Loading preset: $preset..."
    
    local preset_values="${PRESETS[$preset]}"
    IFS='|' read -r distro display desktop wm terminal fm bar launcher <<< "$preset_values"
    
    CONFIG[DISTRO]="$distro"
    CONFIG[DISPLAY]="$display"
    CONFIG[DESKTOP_ENV]="$desktop"
    CONFIG[WM]="$wm"
    CONFIG[TERMINAL]="$terminal"
    CONFIG[FILE_MANAGER]="$fm"
    CONFIG[BAR]="$bar"
    CONFIG[LAUNCHER]="$launcher"
    
    print_success "Preset loaded: $preset"
    
    show_customization_menu "$preset"
}

################################################################################
# CUSTOMIZATION MENU (FOR PRESETS)
################################################################################

show_customization_menu() {
    local preset="$1"
    
    print_section "Customize $preset"
    
    echo "You can customize the preset or keep defaults."
    echo
    
    local options=(
        "Keep all defaults"
        "Change distribution"
        "Change display system"
        "Change desktop/window manager"
        "Change terminal"
        "Change file manager"
        "Change panel/bar"
        "Change launcher"
        "Review and install"
    )
    
    print_subsection "Customization Options"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice (or press Enter to review): " choice
    
    case "$choice" in
        1)
            review_config
            ;;
        2)
            choose_distribution
            show_customization_menu "$preset"
            ;;
        3)
            choose_display
            show_customization_menu "$preset"
            ;;
        4)
            choose_desktop_wm
            show_customization_menu "$preset"
            ;;
        5)
            choose_terminal
            show_customization_menu "$preset"
            ;;
        6)
            choose_file_manager
            show_customization_menu "$preset"
            ;;
        7)
            choose_bar
            show_customization_menu "$preset"
            ;;
        8)
            choose_launcher
            show_customization_menu "$preset"
            ;;
        9|"")
            review_config
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            show_customization_menu "$preset"
            ;;
    esac
}

################################################################################
# CUSTOM SETUP FLOW
################################################################################

custom_setup() {
    print_section "Custom Setup"
    
    echo "Let's build your setup step by step."
    echo
    
    choose_distribution || return 1
    choose_display || return 1
    choose_desktop_wm || return 1
    choose_terminal || return 1
    choose_file_manager || return 1
    choose_bar || return 1
    choose_launcher || return 1
    
    review_config
}

################################################################################
# DISTRIBUTION SELECTION
################################################################################

choose_distribution() {
    print_section "Choose Linux Distribution"
    
    local options=(
        "Debian (Stable, most compatible)"
        "Ubuntu (Beginner-friendly, popular)"
        "Arch Linux (Latest packages, advanced)"
        "Alpine Linux (Extremely lightweight)"
        "Void Linux (Fast, minimal)"
    )
    
    print_subsection "Linux Distributions"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[DISTRO]="debian"
            print_success "Selected: Debian"
            ;;
        2)
            CONFIG[DISTRO]="ubuntu"
            print_success "Selected: Ubuntu"
            ;;
        3)
            CONFIG[DISTRO]="arch"
            print_success "Selected: Arch Linux"
            ;;
        4)
            CONFIG[DISTRO]="alpine"
            print_success "Selected: Alpine Linux"
            ;;
        5)
            CONFIG[DISTRO]="void"
            print_success "Selected: Void Linux"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_distribution
            ;;
    esac
}

################################################################################
# DISPLAY SYSTEM SELECTION
################################################################################

choose_display() {
    print_section "Choose Display System"
    
    local options=(
        "Termux:X11 (Better performance, requires compatible device)"
        "VNC (Better compatibility, older devices)"
        "Skip display configuration"
    )
    
    print_subsection "Display Systems"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[DISPLAY]="termux-x11"
            print_success "Selected: Termux:X11"
            ;;
        2)
            CONFIG[DISPLAY]="vnc"
            print_success "Selected: VNC"
            ;;
        3)
            CONFIG[DISPLAY]="none"
            print_success "Skipped display configuration"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_display
            ;;
    esac
}

################################################################################
# DESKTOP ENVIRONMENT / WINDOW MANAGER SELECTION
################################################################################

choose_desktop_wm() {
    print_section "Choose Desktop Environment or Window Manager"
    
    local options=(
        "XFCE (Complete, beginner-friendly desktop)"
        "LXQt (Lightweight desktop)"
        "KDE Plasma (Beautiful, feature-rich)"
        "Openbox (Simple, floating windows)"
        "IceWM (Very lightweight, classic)"
        "i3 (Keyboard-focused tiling)"
        "bspwm (Minimal tiling manager)"
        "Hyprland (Modern Wayland compositor)"
        "None (Minimal setup, no DE/WM)"
    )
    
    print_subsection "Desktop Environments & Window Managers"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[DESKTOP_ENV]="xfce"
            CONFIG[WM]="xfce"
            print_success "Selected: XFCE"
            ;;
        2)
            CONFIG[DESKTOP_ENV]="lxqt"
            CONFIG[WM]="lxqt"
            print_success "Selected: LXQt"
            ;;
        3)
            CONFIG[DESKTOP_ENV]="kde"
            CONFIG[WM]="kde"
            print_success "Selected: KDE Plasma"
            ;;
        4)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="openbox"
            print_success "Selected: Openbox"
            ;;
        5)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="icewm"
            print_success "Selected: IceWM"
            ;;
        6)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="i3"
            print_success "Selected: i3"
            ;;
        7)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="bspwm"
            print_success "Selected: bspwm"
            ;;
        8)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="hyprland"
            print_success "Selected: Hyprland"
            ;;
        9)
            CONFIG[DESKTOP_ENV]="none"
            CONFIG[WM]="none"
            print_success "Selected: None"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_desktop_wm
            ;;
    esac
}

################################################################################
# TERMINAL SELECTION
################################################################################

choose_terminal() {
    print_section "Choose Terminal Emulator"
    
    local options=(
        "Bash (Standard, always available)"
        "Zsh (Feature-rich, customizable)"
        "Fish (Friendly interactive shell)"
        "Use system default"
    )
    
    print_subsection "Terminal Emulators"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[TERMINAL]="bash"
            print_success "Selected: Bash"
            ;;
        2)
            CONFIG[TERMINAL]="zsh"
            print_success "Selected: Zsh"
            ;;
        3)
            CONFIG[TERMINAL]="fish"
            print_success "Selected: Fish"
            ;;
        4)
            CONFIG[TERMINAL]="default"
            print_success "Selected: System default"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_terminal
            ;;
    esac
}

################################################################################
# FILE MANAGER SELECTION
################################################################################

choose_file_manager() {
    print_section "Choose File Manager"
    
    local options=(
        "Thunar (Lightweight, XFCE default)"
        "PCManFM (Very lightweight)"
        "Nemo (Feature-rich)"
        "Ranger (Terminal-based)"
        "Midnight Commander (Classic terminal)"
        "None (Command-line only)"
    )
    
    print_subsection "File Managers"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[FILE_MANAGER]="thunar"
            print_success "Selected: Thunar"
            ;;
        2)
            CONFIG[FILE_MANAGER]="pcmanfm"
            print_success "Selected: PCManFM"
            ;;
        3)
            CONFIG[FILE_MANAGER]="nemo"
            print_success "Selected: Nemo"
            ;;
        4)
            CONFIG[FILE_MANAGER]="ranger"
            print_success "Selected: Ranger"
            ;;
        5)
            CONFIG[FILE_MANAGER]="mc"
            print_success "Selected: Midnight Commander"
            ;;
        6)
            CONFIG[FILE_MANAGER]="none"
            print_success "Selected: None"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_file_manager
            ;;
    esac
}

################################################################################
# PANEL / BAR SELECTION
################################################################################

choose_bar() {
    print_section "Choose Panel or Bar"
    
    local options=(
        "Polybar (Highly customizable)"
        "Waybar (Wayland-native)"
        "Tint2 (Lightweight panel)"
        "XFCE Panel (XFCE default)"
        "None (No panel)"
    )
    
    print_subsection "Panels & Bars"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[BAR]="polybar"
            print_success "Selected: Polybar"
            ;;
        2)
            CONFIG[BAR]="waybar"
            print_success "Selected: Waybar"
            ;;
        3)
            CONFIG[BAR]="tint2"
            print_success "Selected: Tint2"
            ;;
        4)
            CONFIG[BAR]="xfce4-panel"
            print_success "Selected: XFCE Panel"
            ;;
        5)
            CONFIG[BAR]="none"
            print_success "Selected: None"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_bar
            ;;
    esac
}

################################################################################
# LAUNCHER SELECTION
################################################################################

choose_launcher() {
    print_section "Choose Application Launcher"
    
    local options=(
        "Rofi (Powerful, highly customizable)"
        "Wofi (Wayland-native)"
        "dmenu (Minimal, lightweight)"
        "None (No launcher)"
    )
    
    print_subsection "Application Launchers"
    
    for i in "${!options[@]}"; do
        printf "[%d] %s\n" $((i + 1)) "${options[$i]}"
    done
    
    echo
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            CONFIG[LAUNCHER]="rofi"
            print_success "Selected: Rofi"
            ;;
        2)
            CONFIG[LAUNCHER]="wofi"
            print_success "Selected: Wofi"
            ;;
        3)
            CONFIG[LAUNCHER]="dmenu"
            print_success "Selected: dmenu"
            ;;
        4)
            CONFIG[LAUNCHER]="none"
            print_success "Selected: None"
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            choose_launcher
            ;;
    esac
}

################################################################################
# CONFIGURATION REVIEW
################################################################################

review_config() {
    print_section "Configuration Summary"
    
    printf "%-20s: %s\n" "Distribution" "${CONFIG[DISTRO]}"
    printf "%-20s: %s\n" "Display System" "${CONFIG[DISPLAY]}"
    printf "%-20s: %s\n" "Desktop/WM" "${CONFIG[DESKTOP_ENV]} / ${CONFIG[WM]}"
    printf "%-20s: %s\n" "Terminal" "${CONFIG[TERMINAL]}"
    printf "%-20s: %s\n" "File Manager" "${CONFIG[FILE_MANAGER]}"
    printf "%-20s: %s\n" "Panel/Bar" "${CONFIG[BAR]}"
    printf "%-20s: %s\n" "Launcher" "${CONFIG[LAUNCHER]}"
    
    echo
    
    if confirm "Continue with installation?" "y"; then
        save_config
        proceed_to_install
    else
        print_info "Returning to main menu..."
        sleep 1
        show_main_menu
    fi
}

################################################################################
# CONFIGURATION SAVE
################################################################################

save_config() {
    print_section "Saving Configuration"
    
    local content="#!/bin/bash
# TERMUX DESKTOP FORGE - Configuration
# Generated: $(date)
# Do not edit manually

"
    
    for key in "${!CONFIG[@]}"; do
        content+="export CONFIG_${key}=\"${CONFIG[$key]}\"
"
    done
    
    if safe_write "$CONFIG_FILE" "$content" 755; then
        print_success "Configuration saved to: $CONFIG_FILE"
        return 0
    else
        print_error "Failed to save configuration"
        return 1
    fi
}

################################################################################
# INSTALLATION FLOW
################################################################################

proceed_to_install() {
    print_section "Ready to Install"
    
    print_info "Your desktop environment will be installed now."
    print_info "This may take several minutes depending on your device."
    echo
    
    if confirm "Start installation?" "y"; then
        print_info "Launching installer..."
        sleep 2
        
        local installer="$SCRIPT_DIR/install.sh"
        
        if [[ ! -f "$installer" ]]; then
            print_error "Installer not found: $installer"
            return 1
        fi
        
        bash "$installer" "$CONFIG_FILE"
        return $?
    else
        print_info "Installation cancelled"
        return 1
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    setup_error_handling
    
    # Check Termux environment
    if ! is_termux; then
        print_error "This tool only works in Termux"
        exit 1
    fi
    
    # Check system requirements
    if ! check_system_requirements; then
        print_warning "System requirements check failed"
        if ! confirm "Continue anyway?" "n"; then
            exit 1
        fi
    fi
    
    # Show main menu
    show_main_menu
}

# Run main
main "$@"
