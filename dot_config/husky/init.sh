# Husky global init - sourced by .husky/_/h before every hook on this machine.
#
# Fix for the repo-root src/ duplicate bug in linked git worktrees.
#
# When git runs a hook in a LINKED worktree it exports GIT_DIR (pointing at
# .git/worktrees/<name>) but NOT GIT_WORK_TREE. If a hook then `cd`s into a
# subdirectory (e.g. the Fusion pre-commit does `cd apps/fusion-frontend` to run
# biome) and runs `git add "<absolute-path>"`, git - with GIT_DIR set and no
# GIT_WORK_TREE - treats the *current directory* as the worktree root. The
# absolute path is relativised against that wrong root, so a file like
# apps/fusion-frontend/src/App.tsx also gets staged at the prefix-stripped path
# src/App.tsx (index-only, never the working dir). Primary clones don't hit this
# because git leaves GIT_DIR empty for their hooks; only linked worktrees do.
#
# Pinning GIT_WORK_TREE to the actual top-level makes git relativise correctly
# regardless of the hook's cwd, eliminating the duplicate. Harmless everywhere
# else (it's just the real worktree root).
if [ -z "${GIT_WORK_TREE:-}" ]; then
	_hk_top=$(git rev-parse --show-toplevel 2>/dev/null) || _hk_top=""
	if [ -n "$_hk_top" ]; then
		GIT_WORK_TREE="$_hk_top"
		export GIT_WORK_TREE
	fi
	unset _hk_top
fi
