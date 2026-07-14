#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Script Generator
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
readonly OUTPUT_DIR="$SCRIPT_DIR"

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
# CONFIGURATION LOADING
################################################################################

load_generation_config() {
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
# START.SH GENERATION
################################################################################

generate_start_script() {
    print_section "Generating start.sh"
    
    local start_script="$OUTPUT_DIR/start.sh"
    local content
    
    content="#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Start Script
# Generated: $(date)
# Configuration: ${CONFIG_DISTRO}
################################################################################

set -o pipefail

SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
CONFIG_FILE=\"\$SCRIPT_DIR/config.env\"

# Source configuration
if [[ ! -f \"\$CONFIG_FILE\" ]]; then
    echo \"ERROR: Configuration file not found: \$CONFIG_FILE\" >&2
    exit 1
fi

source \"\$CONFIG_FILE\"

################################################################################
# HELPER FUNCTIONS
################################################################################

log_msg() {
    echo \"[DESKTOP] \$1\"
}

error_msg() {
    echo \"[ERROR] \$1\" >&2
}

# Check if process is running
is_running() {
    local process=\"\$1\"
    pgrep -f \"\$process\" > /dev/null 2>&1
}

# Wait for service to start
wait_for_service() {
    local timeout=30
    local elapsed=0
    
    while [ \$elapsed -lt \$timeout ]; do
        if \"\$@\"; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    return 1
}

################################################################################
# DISPLAY SETUP
################################################################################

setup_display() {
    case \"\${CONFIG_DISPLAY}\" in
        termux-x11)
            log_msg \"Starting Termux:X11...\"
            
            if ! command -v termux-x11 &>/dev/null; then
                error_msg \"Termux:X11 not installed\"
                return 1
            fi
            
            # Start X11 server in background
            termux-x11 :0 -xstartup \"bash \$SCRIPT_DIR/run_wm.sh\" &
            DISPLAY_PID=\$!
            
            sleep 2
            export DISPLAY=:0
            ;;
            
        vnc)
            log_msg \"Starting VNC server...\"
            
            if ! command -v vncserver &>/dev/null && ! command -v tightvncserver &>/dev/null; then
                error_msg \"VNC server not installed\"
                return 1
            fi
            
            # Start VNC server
            if command -v tightvncserver &>/dev/null; then
                tightvncserver :1 -geometry 1280x720 -depth 16
            else
                vncserver :1 -geometry 1280x720 -depth 16
            fi
            
            if [ \$? -eq 0 ]; then
                log_msg \"VNC started on :1\"
                log_msg \"Connect with: vncviewer localhost:5901\"
            else
                error_msg \"Failed to start VNC\"
                return 1
            fi
            ;;
            
        none)
            log_msg \"No display configured\"
            ;;
    esac
    
    return 0
}

################################################################################
# DESKTOP ENVIRONMENT STARTUP
################################################################################

start_desktop() {
    log_msg \"Starting desktop environment...\"
    
    case \"\${CONFIG_WM}\" in
        xfce)
            log_msg \"Starting XFCE...\"
            proot-distro login ${CONFIG_DISTRO} -- startxfce4
            ;;
            
        i3)
            log_msg \"Starting i3...\"
            proot-distro login ${CONFIG_DISTRO} -- i3
            ;;
            
        openbox)
            log_msg \"Starting Openbox...\"
            proot-distro login ${CONFIG_DISTRO} -- openbox
            ;;
            
        icewm)
            log_msg \"Starting IceWM...\"
            proot-distro login ${CONFIG_DISTRO} -- icewm
            ;;
            
        bspwm)
            log_msg \"Starting bspwm...\"
            proot-distro login ${CONFIG_DISTRO} -- bspwm
            ;;
            
        hyprland)
            log_msg \"Starting Hyprland...\"
            proot-distro login ${CONFIG_DISTRO} -- hyprland
            ;;
            
        lxqt)
            log_msg \"Starting LXQt...\"
            proot-distro login ${CONFIG_DISTRO} -- startlxqt
            ;;
            
        kde)
            log_msg \"Starting KDE Plasma...\"
            proot-distro login ${CONFIG_DISTRO} -- startplasma-x11
            ;;
            
        *)
            log_msg \"Starting generic X session...\"
            proot-distro login ${CONFIG_DISTRO} -- startx
            ;;
    esac
}

################################################################################
# CLEANUP
################################################################################

cleanup() {
    log_msg \"Cleaning up...\"
    
    if [[ -n \"\$DISPLAY_PID\" ]]; then
        kill \$DISPLAY_PID 2>/dev/null
    fi
    
    case \"\${CONFIG_DISPLAY}\" in
        vnc)
            log_msg \"Stopping VNC server...\"
            vncserver -kill :1 2>/dev/null || tightvncserver -kill :1 2>/dev/null
            ;;
    esac
}

################################################################################
# MAIN EXECUTION
################################################################################

trap cleanup EXIT

log_msg \"========================================\"
log_msg \"TERMUX DESKTOP FORGE\"
log_msg \"========================================\"
log_msg \"\"
log_msg \"Configuration:\"
log_msg \"  Distribution: \${CONFIG_DISTRO}\"
log_msg \"  Display: \${CONFIG_DISPLAY}\"
log_msg \"  Window Manager: \${CONFIG_WM}\"
log_msg \"\"

# Check if distro is installed
if ! proot-distro list --installed 2>/dev/null | grep -q \"\${CONFIG_DISTRO}\"; then
    error_msg \"Distribution not installed: \${CONFIG_DISTRO}\"
    error_msg \"Run install.sh first\"
    exit 1
fi

# Setup display
if ! setup_display; then
    error_msg \"Failed to setup display\"
    exit 1
fi

# Start desktop
start_desktop
"
    
    if safe_write "$start_script" "$content" 755; then
        print_success "Generated: start.sh"
        return 0
    else
        print_error "Failed to generate start.sh"
        return 1
    fi
}

################################################################################
# STOP.SH GENERATION
################################################################################

generate_stop_script() {
    print_section "Generating stop.sh"
    
    local stop_script="$OUTPUT_DIR/stop.sh"
    local content
    
    content="#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Stop Script
# Generated: $(date)
################################################################################

set -o pipefail

SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
CONFIG_FILE=\"\$SCRIPT_DIR/config.env\"

# Source configuration
if [[ ! -f \"\$CONFIG_FILE\" ]]; then
    echo \"ERROR: Configuration file not found\" >&2
    exit 1
fi

source \"\$CONFIG_FILE\"

echo \"[STOP] Stopping desktop environment...\"

# Stop X11 server
pkill -f \"termux-x11\" 2>/dev/null
pkill -f \"X11\" 2>/dev/null

# Stop VNC server
if command -v vncserver &>/dev/null; then
    vncserver -kill :1 2>/dev/null
fi

if command -v tightvncserver &>/dev/null; then
    tightvncserver -kill :1 2>/dev/null
fi

# Stop window manager processes
pkill -f \"xfce\" 2>/dev/null
pkill -f \"i3\" 2>/dev/null
pkill -f \"openbox\" 2>/dev/null
pkill -f \"icewm\" 2>/dev/null
pkill -f \"bspwm\" 2>/dev/null
pkill -f \"hyprland\" 2>/dev/null
pkill -f \"lxqt\" 2>/dev/null
pkill -f \"plasma\" 2>/dev/null

# Stop panel/bar processes
pkill -f \"polybar\" 2>/dev/null
pkill -f \"waybar\" 2>/dev/null
pkill -f \"tint2\" 2>/dev/null
pkill -f \"xfce4-panel\" 2>/dev/null

# Stop launcher processes
pkill -f \"rofi\" 2>/dev/null
pkill -f \"wofi\" 2>/dev/null
pkill -f \"dmenu\" 2>/dev/null

echo \"[STOP] Desktop environment stopped\"
echo \"[STOP] Run 'bash start.sh' to restart\"
"
    
    if safe_write "$stop_script" "$content" 755; then
        print_success "Generated: stop.sh"
        return 0
    else
        print_error "Failed to generate stop.sh"
        return 1
    fi
}

################################################################################
# DOCTOR.SH GENERATION
################################################################################

generate_doctor_script() {
    print_section "Generating doctor.sh"
    
    local doctor_script="$OUTPUT_DIR/doctor.sh"
    local content
    
    content="#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Diagnostic Tool
# Generated: $(date)
################################################################################

set -o pipefail

SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
CONFIG_FILE=\"\$SCRIPT_DIR/config.env\"

# Colors
readonly RED='\\033[0;31m'
readonly GREEN='\\033[0;32m'
readonly YELLOW='\\033[1;33m'
readonly BLUE='\\033[0;34m'
readonly RESET='\\033[0m'

check_mark() { echo -e \"\${GREEN}✓\${RESET}\"; }
cross_mark() { echo -e \"\${RED}✗\${RESET}\"; }
warn_mark() { echo -e \"\${YELLOW}⚠\${RESET}\"; }

echo \"========================================\"
echo -e \"\${BLUE}TERMUX DESKTOP FORGE - Doctor\${RESET}\"
echo \"========================================\"
echo

# Load configuration
if [[ ! -f \"\$CONFIG_FILE\" ]]; then
    echo \"$(cross_mark) Configuration file not found\"
    exit 1
fi

source \"\$CONFIG_FILE\"

echo -e \"\${BLUE}System Information\${RESET}\"
echo \"──────────────────────────────────────\"

# Termux version
if [[ -f \"\$PREFIX/etc/termux-release\" ]]; then
    echo \"$(check_mark) Termux version: \$(grep TERMUX_VERSION \$PREFIX/etc/termux-release | cut -d= -f2)\"
else
    echo \"$(cross_mark) Termux release file not found\"
fi

# Architecture
ARCH=\$(uname -m)
echo \"$(check_mark) Architecture: \$ARCH\"

# Android API level
if [[ -f \"\$PREFIX/etc/os-release\" ]]; then
    echo \"$(check_mark) System detected\"
fi

echo
echo -e \"\${BLUE}Termux Dependencies\${RESET}\"
echo \"──────────────────────────────────────\"

# Check proot-distro
if command -v proot-distro &>/dev/null; then
    echo \"$(check_mark) proot-distro installed\"
else
    echo \"$(cross_mark) proot-distro not installed\"
fi

# Check distro
if proot-distro list --installed 2>/dev/null | grep -q \"\${CONFIG_DISTRO}\"; then
    echo \"$(check_mark) Distribution installed: \${CONFIG_DISTRO}\"
else
    echo \"$(cross_mark) Distribution not installed: \${CONFIG_DISTRO}\"
fi

echo
echo -e \"\${BLUE}Display System\${RESET}\"
echo \"──────────────────────────────────────\"

case \"\${CONFIG_DISPLAY}\" in
    termux-x11)
        if command -v termux-x11 &>/dev/null; then
            echo \"$(check_mark) Termux:X11 installed\"
        else
            echo \"$(cross_mark) Termux:X11 not installed\"
        fi
        ;;
    vnc)
        if command -v vncserver &>/dev/null || command -v tightvncserver &>/dev/null; then
            echo \"$(check_mark) VNC server installed\"
        else
            echo \"$(cross_mark) VNC server not installed\"
        fi
        ;;
    none)
        echo \"$(warn_mark) No display system configured\"
        ;;
esac

echo
echo -e \"\${BLUE}Storage & Performance\${RESET}\"
echo \"──────────────────────────────────────\"

# Free storage
if command -v df &>/dev/null; then
    FREE=\$(df \$HOME | awk 'NR==2 {print int(\$4/1024)}')
    echo \"$(check_mark) Free storage: \${FREE}MB\"
    
    if [ \$FREE -lt 500 ]; then
        echo \"$(warn_mark) Low storage space (< 500MB)\"
    fi
fi

# Available RAM
if [[ -f /proc/meminfo ]]; then
    RAM=\$(awk '/MemAvailable/ {print int(\$2/1024)}' /proc/meminfo)
    echo \"$(check_mark) Available RAM: \${RAM}MB\"
    
    if [ \$RAM -lt 256 ]; then
        echo \"$(warn_mark) Low RAM (< 256MB)\"
    fi
fi

echo
echo -e \"\${BLUE}Desktop Components\${RESET}\"
echo \"──────────────────────────────────────\"

echo \"Configured:\"
printf \"  Window Manager: %s\\n\" \"\${CONFIG_WM}\"
printf \"  File Manager: %s\\n\" \"\${CONFIG_FILE_MANAGER}\"
printf \"  Panel/Bar: %s\\n\" \"\${CONFIG_BAR}\"
printf \"  Launcher: %s\\n\" \"\${CONFIG_LAUNCHER}\"
printf \"  Terminal: %s\\n\" \"\${CONFIG_TERMINAL}\"

echo
echo -e \"\${BLUE}Troubleshooting Tips\${RESET}\"
echo \"──────────────────────────────────────\"
echo \"1. If display doesn't work: check device support for Termux:X11\"
echo \"2. If slow: try lightweight preset (Alpine + IceWM)\"
echo \"3. If packages missing: ensure distro is fully updated\"
echo \"4. For more help: check install.log\"
echo

echo \"$(check_mark) Diagnostic complete\"
"
    
    if safe_write "$doctor_script" "$content" 755; then
        print_success "Generated: doctor.sh"
        return 0
    else
        print_error "Failed to generate doctor.sh"
        return 1
    fi
}

################################################################################
# REMOVE.SH GENERATION
################################################################################

generate_remove_script() {
    print_section "Generating remove.sh"
    
    local remove_script="$OUTPUT_DIR/remove.sh"
    local content
    
    content="#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Removal Script
# Generated: $(date)
################################################################################

set -o pipefail

SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
CONFIG_FILE=\"\$SCRIPT_DIR/config.env\"

# Colors
readonly RED='\\033[0;31m'
readonly GREEN='\\033[0;32m'
readonly YELLOW='\\033[1;33m'
readonly BLUE='\\033[0;34m'
readonly RESET='\\033[0m'

echo -e \"\${BLUE}========================================\${RESET}\"
echo -e \"\${RED}TERMUX DESKTOP FORGE - Removal\${RESET}\"
echo -e \"\${BLUE}========================================\${RESET}\"
echo

# Load configuration
if [[ ! -f \"\$CONFIG_FILE\" ]]; then
    echo \"$(cross_mark) Configuration file not found\"
    exit 1
fi

source \"\$CONFIG_FILE\"

echo -e \"\${YELLOW}⚠ WARNING: This will remove your desktop environment!\${RESET}\"
echo \"The following will be removed:\"
echo \"  - Distribution: \${CONFIG_DISTRO}\"
echo \"  - All installed components\"
echo \"  - All configuration files\"
echo
echo -e \"\${RED}This action cannot be undone!\${RESET}\"
echo

# Confirm removal
read -p \"Type 'yes' to confirm removal: \" confirm

if [[ \"\$confirm\" != \"yes\" ]]; then
    echo \"Removal cancelled\"
    exit 0
fi

echo
echo \"Removing desktop environment...\"

# Stop running processes
echo \"[1/3] Stopping processes...\"
bash \"\$SCRIPT_DIR/stop.sh\" > /dev/null 2>&1

# Remove distribution
echo \"[2/3] Removing distribution...\"
if proot-distro remove \"\${CONFIG_DISTRO}\"; then
    echo \"✓ Distribution removed\"
else
    echo \"✗ Failed to remove distribution\"
fi

# Clean up generated scripts
echo \"[3/3] Cleaning up...\"
rm -f \"\$SCRIPT_DIR/start.sh\"
rm -f \"\$SCRIPT_DIR/stop.sh\"
rm -f \"\$SCRIPT_DIR/doctor.sh\"
rm -f \"\$SCRIPT_DIR/remove.sh\"

echo
echo -e \"\${GREEN}✓ Desktop environment removed\${RESET}\"
echo \"Configuration saved at: \$CONFIG_FILE\"
echo \"To reinstall, run: bash main.sh\"
"
    
    if safe_write "$remove_script" "$content" 755; then
        print_success "Generated: remove.sh"
        return 0
    else
        print_error "Failed to generate remove.sh"
        return 1
    fi
}

################################################################################
# X11 STARTUP HELPER GENERATION
################################################################################

generate_x11_startup_helper() {
    print_section "Generating X11 startup helper"
    
    local helper_script="$OUTPUT_DIR/run_wm.sh"
    local content
    
    content="#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - X11 Startup Helper
# Generated: $(date)
################################################################################

SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
CONFIG_FILE=\"\$SCRIPT_DIR/config.env\"

# Source configuration
if [[ ! -f \"\$CONFIG_FILE\" ]]; then
    echo \"ERROR: Configuration file not found\" >&2
    exit 1
fi

source \"\$CONFIG_FILE\"

export DISPLAY=:0

# Wait for X server
sleep 2

# Enter distro and start window manager
case \"\${CONFIG_WM}\" in
    xfce)
        proot-distro login \${CONFIG_DISTRO} -- startxfce4
        ;;
    i3)
        proot-distro login \${CONFIG_DISTRO} -- i3
        ;;
    openbox)
        proot-distro login \${CONFIG_DISTRO} -- openbox
        ;;
    icewm)
        proot-distro login \${CONFIG_DISTRO} -- icewm
        ;;
    bspwm)
        proot-distro login \${CONFIG_DISTRO} -- bspwm
        ;;
    hyprland)
        proot-distro login \${CONFIG_DISTRO} -- hyprland
        ;;
    lxqt)
        proot-distro login \${CONFIG_DISTRO} -- startlxqt
        ;;
    kde)
        proot-distro login \${CONFIG_DISTRO} -- startplasma-x11
        ;;
    *)
        proot-distro login \${CONFIG_DISTRO} -- startx
        ;;
esac
"
    
    if safe_write "$helper_script" "$content" 755; then
        print_success "Generated: run_wm.sh"
        return 0
    else
        print_error "Failed to generate run_wm.sh"
        return 1
    fi
}

################################################################################
# README GENERATION
################################################################################

generate_readme() {
    print_section "Generating README.md"
    
    local readme="$OUTPUT_DIR/README.md"
    local content
    
    content="# TERMUX DESKTOP FORGE

Your desktop environment is ready!

## Quick Start

### Start the desktop
\`\`\`bash
bash start.sh
\`\`\`

### Stop the desktop
\`\`\`bash
bash stop.sh
\`\`\`

### Check system status
\`\`\`bash
bash doctor.sh
\`\`\`

### Remove the desktop
\`\`\`bash
bash remove.sh
\`\`\`

## Configuration

Your setup:
- **Distribution**: ${CONFIG_DISTRO}
- **Display**: ${CONFIG_DISPLAY}
- **Desktop/WM**: ${CONFIG_DESKTOP_ENV} / ${CONFIG_WM}
- **Terminal**: ${CONFIG_TERMINAL}
- **File Manager**: ${CONFIG_FILE_MANAGER}
- **Launcher**: ${CONFIG_LAUNCHER}
- **Panel/Bar**: ${CONFIG_BAR}

## Display Options

### Termux:X11
Best for modern devices. Requires compatible Android version.

### VNC
Better compatibility. Connect with:
\`\`\`
vncviewer localhost:5901
\`\`\`

## Troubleshooting

### Display not working
- Check device compatibility with Termux:X11
- Try VNC instead
- Run \`bash doctor.sh\`

### Performance issues
- Use lighter desktop (IceWM, Openbox)
- Use Alpine Linux instead of Debian
- Close background apps
- Increase available RAM

### Missing packages
Run inside the desktop:
\`\`\`
apt update && apt install <package>
\`\`\`

## Files

- **start.sh** - Start the desktop environment
- **stop.sh** - Stop running processes
- **doctor.sh** - Diagnostic tool
- **remove.sh** - Remove the installation
- **config.env** - Configuration file
- **run_wm.sh** - X11 startup helper
- **install.log** - Installation log

## Support

For issues or questions, check:
1. doctor.sh output
2. install.log
3. Run \`bash main.sh\` to reconfigure

---
Generated by TERMUX DESKTOP FORGE
"
    
    if safe_write "$readme" "$content" 644; then
        print_success "Generated: README.md"
        return 0
    else
        print_error "Failed to generate README.md"
        return 1
    fi
}

################################################################################
# MAIN GENERATION FLOW
################################################################################

main() {
    setup_error_handling
    
    print_banner
    
    print_section "Script Generator"
    
    # Load configuration
    if ! load_generation_config; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    # Generate all scripts
    if ! generate_start_script; then
        print_error "Failed to generate start.sh"
        exit 1
    fi
    
    if ! generate_stop_script; then
        print_error "Failed to generate stop.sh"
        exit 1
    fi
    
    if ! generate_doctor_script; then
        print_error "Failed to generate doctor.sh"
        exit 1
    fi
    
    if ! generate_remove_script; then
        print_error "Failed to generate remove.sh"
        exit 1
    fi
    
    if ! generate_x11_startup_helper; then
        print_error "Failed to generate run_wm.sh"
        exit 1
    fi
    
    if ! generate_readme; then
        print_error "Failed to generate README.md"
        exit 1
    fi
    
    # Summary
    print_section "Generation Complete"
    
    print_success "All scripts generated successfully!"
    echo
    print_info "Generated files:"
    echo "  - start.sh (Start the desktop)"
    echo "  - stop.sh (Stop the desktop)"
    echo "  - doctor.sh (Diagnostic tool)"
    echo "  - remove.sh (Remove installation)"
    echo "  - run_wm.sh (X11 startup helper)"
    echo "  - README.md (Documentation)"
    echo
    print_info "Next step:"
    echo "  Run: bash start.sh"
    echo
}

# Execute main
main "$@"
