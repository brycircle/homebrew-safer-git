# homebrew-safer-git

A Homebrew tap providing `safer-git` — a build of Git 2.54.0 with hook execution permanently disabled at compile time.

## What it does

Git hooks (`pre-commit`, `post-commit`, `pre-push`, etc.) are silenced at the source level by patching `run_hooks_opt()` in `hook.c`, the single choke point through which all hook execution passes. No hook will ever run, regardless of what scripts exist in `.git/hooks/` or what is configured via `git config`.

## Install

```bash
brew tap brycircle/safer-git
brew install safer-git
```

## Build locally

To test before pushing to GitHub, tap the local directory directly:

```bash
brew tap brycircle/safer-git .
brew install --build-from-source safer-git
```

## Upgrade

```bash
brew update
brew upgrade safer-git
```

## Why

Git hooks are a common vector for supply-chain attacks and accidental execution of untrusted code when cloning or working across repositories. This build eliminates that surface entirely.

## Caveats

- Hooks are disabled unconditionally — there is no override flag or environment variable.
- This formula sets `NO_PERL`, `NO_PYTHON`, and `NO_TCLTK`, so `git svn`, `git add -p` (Perl path), and `gitk` are not included.
- Pin after install if you want to prevent `brew upgrade` from pulling in an unpatched upstream formula: `brew pin safer-git`
