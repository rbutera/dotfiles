# Matt Pocock skills

The complete skill directories from `mattpocock/skills` are vendored as ordinary
files in `dot_agents/skills`. Chezmoi deploys them to `~/.agents/skills`, shared by
Codex and other agents that discover that location. No plugin or upstream fetch
runs during deployment. All four upstream collections are included, including
`in-progress` and `misc`.

`manifest.json` records the upstream commit, source paths, and imported file
hashes. `matt-pocock.LICENSE` preserves the upstream MIT license. Only `tdd` and
`teach` are renamed to `matt-tdd` and `matt-teach`, including invocation references
and Codex display names, to coexist with Rai's custom skills. Other contents are
copied unchanged. Executables use chezmoi's `executable_` source prefix.

## Refresh

From the chezmoi source directory, run:

```sh
python3 docs/matt-pocock-skills/refresh.py <upstream-commit-or-tag>
python3 docs/matt-pocock-skills/refresh.py <upstream-commit-or-tag> --check
git diff -- dot_agents/skills docs/matt-pocock-skills
```

The importer refuses to overwrite modified imported files or unowned destination
files. Reconcile local customizations explicitly before refreshing. Review skill
name collisions when adding new upstream skills. If upstream removes a file,
review whether its old deployed copy also needs removing through `.chezmoiremove`.
Update `logs/agents.md`, commit, and push after review.

## Deploy on each machine

```sh
git -C "$(chezmoi source-path)" pull --ff-only
chezmoi apply --include files,dirs ~/.agents/skills
chezmoi status --include files,dirs ~/.agents/skills
```

This targeted apply copies skill resources without running bootstrap scripts or
rendering unrelated secret templates. It preserves other installed skills.
The refresh helper requires Python 3 and Git only on the machine doing imports;
other machines need only chezmoi. Bundled skill scripts retain their upstream
runtime requirements, including Bash where applicable.

The skills are available to Codex on the next turn. Repository-specific setup is
separate: invoke `setup-matt-pocock-skills` when configuring a project's issue
tracker and document conventions.
