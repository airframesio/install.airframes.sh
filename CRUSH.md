# Airframes Installer Scripts - Development Guide

## Project Overview
Static website with bash installer scripts for Airframes decoder/feeder software.
Technologies: HTML/CSS website, Bash scripting for cross-platform installers.

## Commands
```bash
# No build system - static files only
# Validate HTML/CSS locally with browser
open index.html  # macOS
xdg-open index.html  # Linux

# Test installer scripts (dry run recommended)
bash -n flight/decoder/acarsdec  # Syntax check
shellcheck flight/**/*.sh  # If shellcheck installed
```

## Code Style Guidelines

### Bash Scripts
- Shebang: `#!/usr/bin/env bash`
- Variables: UPPERCASE for globals (e.g., `OSTYPE`, `ARCH`)
- OS detection: Use `$OSTYPE` pattern matching
- Architecture: Use `uname -m` for detection
- Command checks: Use `command -v <cmd> >/dev/null 2>&1`
- Error handling: Exit with meaningful codes (1 for errors)
- Flag parsing: Support long options (--rtlsdr, --airspy)
- Cross-platform: Support Linux, macOS, Windows (via WSL/Cygwin)

### HTML/CSS
- HTML5 semantic elements preferred
- CSS animations for visual effects
- Responsive units: Use vmin for typography
- Color scheme: Dark backgrounds (#013) with vibrant accents

## Directory Structure
- `/flight/`: Aviation-related installers (decoder/feeder)
- `/balloon/`, `/ship/`: Future expansion (currently empty)
- `/images/`: SVG assets only
- Root: Website files (index.html, style.css)