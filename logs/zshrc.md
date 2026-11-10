# zshrc changelog

## 2026-11-10: drop OpenClaw completion, carry the Unity CLI block

OpenClaw was unhooked at runtime on 8 Nov 2026 (bead workspace-f91d6). Commit
0fd06c41 removed the two-line "OpenClaw Completion" block from dot_zshrc.tmpl
and added the "# Unity CLI" block (`. "/Users/rai/.unity/env"`) that the
deployed ~/.zshrc already carried but the source lacked.

`chezmoi apply ~/.zshrc` refused with "has changed since chezmoi last wrote it"
(no TTY), so the same removal was made by hand in ~/.zshrc. `chezmoi diff` is
empty afterwards, but chezmoi's recorded state may still be stale: the next
apply of .zshrc may prompt once. Answering "overwrite" is safe while diff is empty.
