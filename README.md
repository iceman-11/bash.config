Bash configuration
==================

Personal bash configuration, split into small plugins that each set up one
tool and skip themselves when the tool is not installed.

Works on **Git Bash** (Windows), **WSL** and **Linux**, with **bash 4.4 or
later**. macOS is not tested. Nothing else needs to be installed: every
plugin checks for its tool first.

Install
-------

Clone the repository into `~/.config/bash` (or `$XDG_CONFIG_HOME/bash`):

```bash
git clone git@github.com:iceman-11/bash.config.git ~/.config/bash
```

Then make `~/.bashrc` load it, with **one** of these:

```bash
# A symbolic link (Linux, WSL; Git Bash with Windows Developer Mode)
ln -s .config/bash/bashrc ~/.bashrc

# Or a one-line ~/.bashrc (works everywhere, no special rights needed)
echo '. ~/.config/bash/bashrc' > ~/.bashrc
```

In Git Bash, `ln -s` silently makes a copy unless
`MSYS=winsymlinks:nativestrict` is set and symbolic links are allowed, so
the one-line `~/.bashrc` is the simpler choice on a company laptop.

Login shells (a new Git Bash window, an SSH session) read `~/.bash_profile`,
not `~/.bashrc`. Git for Windows creates a `~/.bash_profile` that loads
`~/.bashrc`; on Linux, make sure yours contains:

```bash
[ -f ~/.bashrc ] && . ~/.bashrc
```

The configuration only runs in interactive shells: scripts, `scp` and
`rsync` are not affected.

Layout
------

```text
bashrc          Entry point: locale, PATH, plugin loader, shell options
init/           Plugins loaded first (e.g. Homebrew, which changes PATH)
plugin/         Plugins, one per tool
post/           Plugins loaded last (optional)
*/local/        Per-machine plugins, ignored by git
tools/          Development scripts, never loaded by the shell
```

Files ending in `.bash` are loaded in this order: `init`, `init/local`,
`plugin`, `plugin/local`, `post`, `post/local`, and alphabetically within
each directory.

Put anything specific to one machine (work aliases, paths, secrets) in a
`local/` directory: it stays on that machine.

### Plugins

| Plugin            | What it does                                        |
| ----------------- | --------------------------------------------------- |
| `homebrew.bash`   | Loads Linuxbrew into PATH                           |
| `aliases.bash`    | `ls`/`grep` colours and aliases, helper functions   |
| `cargo.bash`      | Loads `~/.cargo/env`                                |
| `fzf.bash`        | fzf key bindings; uses `fd` and `tree` if present   |
| `git.bash`        | `glog` alias                                        |
| `history.bash`    | Large shared history, de-duplicated once a day      |
| `prompt.bash`     | oh-my-posh prompt, or a built-in fallback prompt    |
| `ssh-agent.bash`  | One ssh-agent per host, shared by all shells        |
| `tmux.bash`       | Lists running tmux sessions when a shell starts     |
| `uv.bash`         | uv/uvx completion, `uvreq` alias                    |
| `vim.bash`        | `EDITOR` and `vi` aliases for nvim, vimx or vim     |
| `wsl.bash`        | `cdp` alias to the Windows projects folder (WSL)    |
| `zoxide.bash`     | zoxide (`z`); `cd` is an alias of `z`               |

### Commands

| Command                   | Description                                 |
| ------------------------- | ------------------------------------------- |
| `hgrep PATTERN`           | Search the history                          |
| `where CMD`               | Path of the program run for `CMD`           |
| `dups [DIR...]`           | List duplicate files                        |
| `xtitle TEXT`             | Set the terminal window title               |
| `path`                    | Print PATH, one directory per line          |
| `glog`                    | Git history graph of all branches           |
| `ssh_agent_reset [--all]` | Restart the ssh-agent (`--all`: kill all)   |
| `bash_cache_clear`        | Empty the cache described below             |

### Settings

| Variable                  | Effect                                      |
| ------------------------- | ------------------------------------------- |
| `SSH_AGENT_FORCE_LOCAL=1` | Start a local agent even in an SSH session  |
| `XDG_STATE_HOME`          | ssh-agent socket (`~/.local/state` default) |
| `XDG_CACHE_HOME`          | Where the cache lives (`~/.cache` default)  |

Start-up time and the cache
---------------------------

Starting a process is slow on Git Bash (80 to 200 ms each), so the
configuration avoids external commands while a shell starts.

Tools like fzf, zoxide and uv print shell code that has to be loaded in
every shell. Instead of running them each time, a plugin caches their
output with `__cache_output`:

```bash
if __cache_output fzf fzf --bash; then
    # shellcheck source=/dev/null disable=SC2154 # set by __cache_output
    . "$__cache_file"
fi
```

The output is stored in `~/.cache/bash/NAME.bash` and generated again when
the tool is updated or replaced, or after a week. Run `bash_cache_clear`
to regenerate everything at the next start, for example after changing a
tool's settings.

Writing a plugin
----------------

- Name it `plugin/<tool>.bash`, or put it in `plugin/local/` if it only
  makes sense on one machine.
- Return early when the tool is missing, so the plugin works everywhere:

  ```bash
  if ! type mytool > /dev/null 2>&1; then
      return
  fi
  ```

- Plugins are sourced at the top level: variables and functions they
  define are global. Prefix helpers with `__` and `unset` them at the end.
- Avoid `$(...)` and external commands where a builtin does the job, and
  use `__cache_output` for generated shell code.
- Print nothing on stderr: the load test treats it as a failure.

Development
-----------

```bash
tools/test-load.sh              # syntax check + start a shell in a sandbox
tools/bench-startup.sh          # median start-up time (needs bash 5)
tools/bench-startup.sh --profile  # time per file and slowest lines
shellcheck bashrc init/*.bash plugin/*.bash tools/*.sh
```

`tools/test-load.sh` copies the configuration into a temporary HOME, so it
never touches your history or ssh-agent. Run `tools/bench-startup.sh`
from a real terminal: some settings only apply when a terminal is attached.

GitHub Actions runs ShellCheck and the load test on Linux, Git Bash and
bash 4.4 for every push and pull request.

Changes go on a branch, then through a pull request into `develop`, then
into `master`. Indentation is tabs (see `.editorconfig`); to hide the
whitespace-only commits from `git blame`, run once:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```
