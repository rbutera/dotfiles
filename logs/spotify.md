# Spotify / Spicetify Log

## 2026-04-08 — Initial Spotify + Spicetify setup

**Problem:** No Spotify client installed. Wanted Spotify with Spicetify theming/extensions support.

**Changes:**

- Installed `spotify` 1.2.86 from chaotic-aur (pre-built, no AUR compilation needed)
- `spicetify-cli` 2.43.1 was already installed
- Installed `spicetify-marketplace-bin` — adds a Marketplace tab inside Spotify for browsing themes/extensions
- Fixed `/opt/spotify` and `/opt/spotify/Apps` permissions for spicetify write access
- Configured spicetify: `custom_apps=marketplace`, `inject_css=1`, `replace_colors=1`, `current_theme=marketplace`
- Ran `spicetify backup apply` — all steps succeeded

**Notes:**

- Color scheme `matugen` warning on apply — no scheme set yet, pick one from Marketplace
- After Spotify updates via pacman, run `spicetify backup apply` again to re-patch
- Arch Wiki page: https://wiki.archlinux.org/title/Spotify — no spicetify entry on wiki
