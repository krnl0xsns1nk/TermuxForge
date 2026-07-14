
# TermuxForge

Forge your own Linux desktop environment on Android in minutes.

Choose your Linux distribution. Choose your desktop. Choose your tools. Let TermuxForge handle the rest.

**Status:** Stable | **License:** MIT | **Platform:** Termux on Android

---

## What is TermuxForge?

TermuxForge is a bash-only tool that creates customized Linux desktop environments inside Termux (a terminal emulator for Android). No coding required. Just answer questions, and your desktop is ready.

**Perfect for:**
- Running Linux applications on Android
- Learning Linux in a comfortable environment
- Development work on mobile devices
- Turning old Android phones into useful tools

---

## Features

✅ **Interactive Setup Wizard** - Colorful, beginner-friendly menu system  
✅ **Multiple Linux Distros** - Debian, Ubuntu, Arch, Alpine, Void  
✅ **Desktop Choices** - XFCE, LXQt, KDE, i3, Openbox, IceWM, and more  
✅ **Automatic Configuration** - Installs and configures everything for you  
✅ **Hardware Aware** - Lightweight options for old phones, powerful options for new ones  
✅ **Auto-Generated Scripts** - Start, stop, diagnose, and remove your desktop  
✅ **No Previous Knowledge Required** - All technical details handled automatically  

---

## Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|------------|
| **Android Version** | 7.0+ | 10.0+ |
| **Storage** | 1GB free | 3GB free |
| **RAM (Lightweight)** | 1GB | 2GB+ |
| **RAM (Normal)** | 2GB | 4GB+ |
| **RAM (Modern)** | 3GB | 6GB+ |

**Software:**
- Termux (from F-Droid or GitHub Releases, NOT Google Play)
- termux:x11 "Recommended" (from Github releases)[here](https://github.com/termux/termux-x11/releases)
- Bash (built into Termux)

---

## Installation

### Step 1: Install Termux

Download **Termux** from [F-Droid](https://f-droid.org/en/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases). Do NOT use Google Play Store.

### Step 2: Open Termux and Update

```bash
apt update && apt upgrade -y
```

Press `y` when asked to continue.

### Step 3: Install Required Tools

```bash
apt install -y git 
```

### Step 4: Download TermuxForge

```bash
cd ~
git clone https://github.com/krnl0xsns1nk/termuxforge.git
cd termuxforge
chmod +x *.sh
```

### Step 5: Start the Setup

```bash
bash main.sh
```

Follow the colorful menu. Choose your options. Done!

---

## First Run

When you run `bash main.sh`, you'll see four preset options:

1. **Recommended Desktop** - Debian + XFCE (good for beginners)
2. **Lightweight Desktop** - Alpine + IceWM (for old phones)
3. **Developer Environment** - Debian + i3 + vim (for developers)
4. **Modern Desktop** - Arch + Hyprland (for new phones)

Choose one, customize if you want, and TermuxForge does the rest.

---

## Understanding Your Choices

### Linux Distributions

- **Debian** - Stable, beginner-friendly, most packages available
- **Ubuntu** - Similar to Debian, very popular
- **Arch** - Latest packages, for advanced users
- **Alpine** - Tiny and fast, for weak devices
- **Void** - Minimal and quick

### Desktop Environments
- **XFCE** - Full desktop, looks like Windows, beginner-friendly
- **LXQt** - Lightweight desktop, uses less RAM
- **KDE** - Beautiful but requires more resources

### Window Managers (for advanced users)
- **Openbox** - Floating windows, lightweight
- **IceWM** - Very lightweight, classic look
- **i3** - Keyboard-focused, tiling windows
- **bspwm** - Minimal tiling manager
- **Hyprland** - Modern, requires new devices

### Display Systems
- **Termux:X11** - Better performance (if your device supports it)
- **VNC** - Works on any device (connect from another computer)

---

## Using Your Desktop

After installation, you'll have four new scripts:

```bash
bash start.sh      # Start your desktop
bash stop.sh       # Stop your desktop
bash doctor.sh     # Check if everything works
bash remove.sh     # Remove the desktop
```

---

## Example Setups

### For Old Phones (1-2GB RAM)
```
Alpine + IceWM + Tint2 + PCManFM
```

### For Developers
```
Debian + i3 + Bash + Git + Neovim
```

### For New Devices
```
Arch + Hyprland + Waybar + Rofi
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Desktop won't start** | Run `bash doctor.sh` to see issues. Check Termux:X11 compatibility. |
| **Black screen on VNC** | Make sure X server started. Try restarting with `bash start.sh` |
| **"Not enough storage"** | Delete apps or files. Need at least 1GB free. |
| **Package installation fails** | Run `bash doctor.sh`. Update packages: `apt update` |
| **Too slow** | Use Alpine + IceWM setup. Close other apps. |
| **Distro won't install** | Check internet. Ensure Termux is from F-Droid, not Play Store. |

**Still stuck?** Check `install.log` for detailed error messages.

---

## Safety

- TermuxForge creates isolated Linux environments. It doesn't change Android.
- Your apps and data are safe.
- Backup important files before large installations.
- You can remove everything with `bash remove.sh`

---

## Project Structure

```
termuxforge/
├── main.sh          # Interactive setup menu
├── functions.sh     # Core functions and utilities
├── install.sh       # Installation engine
├── generate.sh      # Script generator
├── test.sh          # Test suite
├── profiles/        # Optional configuration profiles
└── README.md        # This file
```

---

## Contributing

We welcome contributions!

**Report a bug:** Open an issue with device info and error output.  
**Add a feature:** Fork, create a branch, submit a pull request.  
**Test:** Try TermuxForge on different devices and report results.  
**Improve docs:** Help us explain things better for beginners.

---

## License

MIT License - See LICENSE file for details.

---

## Questions?

- Check `doctor.sh` output
- Review `install.log` for detailed information
- See the troubleshooting section above
- Open an issue on GitHub

---

**Made for Android. Built in Bash. Owned by you.**

