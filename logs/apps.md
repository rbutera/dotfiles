## 2026-06-25

**Problem/motivation:** Discord should be installed as part of the managed macOS app set rather than as an unmanaged one-off install.

**Changes:** Added the Homebrew cask `discord` to `raisbrewfile.tmpl`.

## 2026-06-25

**Problem/motivation:** The macOS Tailscale GUI app needs to be replaced with the headless CLI/daemon formula so Tailscale can run before login.

**Changes:** Added the Homebrew formula `tailscale` to `raisbrewfile.tmpl`.
