# chezmoi config changes log

## 2026-03-28 — Fix empty bash function bodies crashing chezmoi apply on macOS

### Problem
`chezmoi apply` failed on macOS with:
```
bash: line 32: syntax error near unexpected token `}'
```

The root cause: `install_linux_dependencies()` and `install_wsl_clipboard()` were defined unconditionally in `run_once_03_install-packages.sh.tmpl`, but their entire bodies were wrapped in `{{ if eq .chezmoi.os "linux" }}`. On macOS, the template rendered these as empty-body functions (just whitespace), which is invalid bash syntax.

Previous commits (c6bffbe, d8e65a6) had fixed a related issue — `.osRelease.id` being evaluated inside `and`/`or` function calls on macOS — but did not address the empty-body problem.

### Fix
Moved both Linux-only function definitions inside a top-level `{{ if eq .chezmoi.os "linux" }}` block in `run_once_03_install-packages.sh.tmpl`. The functions are only called on Linux (already guarded), so this is safe. The rendered bash on macOS no longer contains these functions at all.

## 2026-03-28 — Guard Cargo env sourcing in zshenv

### Problem
Shell startup emitted:
```
/Users/rai/.zshenv:.:55: no such file or directory: /Users/rai/.cargo/env
```
because `dot_zshenv.tmpl` always sourced `$HOME/.cargo/env`, even when Rust/Cargo was not installed yet.

### Fix
Wrapped the source line in a file-existence check in `dot_zshenv.tmpl`:
```
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
```
This keeps shell startup clean on machines where Cargo has not been initialized.
