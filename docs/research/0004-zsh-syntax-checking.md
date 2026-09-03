# Syntax checking the Stow-managed Zsh configuration

Research snapshot: 2026-09-03. Checked with ShellCheck 0.11.0 locally and Zsh
5.9 on the `ubuntu-24.04` GitHub Actions runner image.

## Executive conclusion

ShellCheck cannot check this repository's Zsh files, and `zsh -n` can only be
trusted when it is given exactly one file per invocation. The working
invocation is therefore:

```sh
git ls-files -z 'zsh/.zshrc' 'zsh/*.zsh' | xargs -0 -n1 zsh -n
```

## ShellCheck does not support the Zsh dialect

ShellCheck accepts `--shell=bash` on a `.zshrc`, but it reports valid Zsh as
parse errors rather than checking it. `zsh/.zshrc` line 4 uses a glob
qualifier, which is Zsh syntax with no Bash equivalent:

```sh
for config in "${ZSH_CONFIG_DIR}/"*.zsh(N); do
```

Forcing the Bash dialect on that file produces four errors and exit status 1:

```console
$ shellcheck --shell=bash zsh/.zshrc; echo $?
In zsh/.zshrc line 4:
for config in "${ZSH_CONFIG_DIR}/"*.zsh(N); do
^-- SC1073 (error): Couldn't parse this for loop. Fix to allow more checks.
                                       ^-- SC1036 (error): '(' is invalid here. Did you forget to escape it?
                                       ^-- SC1058 (error): Expected 'do'.
                                       ^-- SC1072 (error): Expected 'do'. Fix any mentioned problems and try again.
1
```

The failure is the dialect, not a defect in the file, so a bash-mode run cannot
distinguish a real mistake from correct Zsh. ShellCheck's `shell` directive
supports `sh`, `bash`, `dash`, and `ksh`; Zsh is not among them.

## `zsh -n` silently ignores every file after the first

`zsh -n` parses a script without executing it, which suits files that source a
framework and set up completions. Its argument handling is the trap: it reads
one script file and binds any further arguments as positional parameters, so a
multi-file invocation reports only on the first file and exits successfully.

Verified against a deliberately broken fragment containing a truncated
`if true; then`:

```console
$ zsh -n broken.zsh; echo $?
broken.zsh:2: parse error near `\n'
1

$ zsh -n zsh/.zshrc broken.zsh; echo $?
0
```

Only the first file is parsed. The exit status reflects that file alone, so an
error anywhere after it goes unreported: the invocation above exits 0 despite
`broken.zsh` being unparseable. Reversing the order makes the same command
fail, which confirms the check is real but covers exactly one file:

```console
$ zsh -n broken.zsh zsh/.zshrc; echo $?
broken.zsh:2: parse error near `\n'
1
```

A multi-file invocation is therefore not a check that always passes, but one
whose coverage stops silently after the first argument. That is worse in
practice than an obvious failure, because appending a file to it looks like
widening the check and is not. `xargs -n1` forces one file per process and
propagates a non-zero status if any single file fails:

```console
$ printf 'zsh/.zshrc\0broken.zsh\0' | xargs -0 -n1 zsh -n; echo $?
broken.zsh:2: parse error near `\n'
1
```

## Zsh is not preinstalled on the GitHub runner

The `ubuntu-24.04` runner image does not ship Zsh. The workflow's install step
reports it as a new package rather than an existing one, so the step is
required and not defensive:

```text
0 upgraded, 2 newly installed, 0 to remove and 37 not upgraded.
Setting up zsh-common (5.9-6ubuntu2) ...
Setting up zsh (5.9-6ubuntu2) ...
```

## File selection

`git ls-files` resolves the list from what is tracked, so a new fragment under
`zsh/.config/zsh/conf.d/` is covered without editing the workflow. A literal
shell glob would also have worked today but would pass an unexpanded pattern to
`zsh -n` if the directory were ever empty. Git's `*` crosses directory
separators, which is what lets `'zsh/*.zsh'` reach the nested fragments:

```console
$ git ls-files 'zsh/.zshrc' 'zsh/*.zsh'
zsh/.config/zsh/conf.d/00-path.zsh
zsh/.config/zsh/conf.d/10-oh-my-zsh.zsh
zsh/.zshrc
```

The same property applies to `'*.sh'`, which is why the ShellCheck step reaches
scripts at any depth rather than only the top level.

## Limitation

`zsh -n` is a parser, not an analyzer. It catches unbalanced constructs and
malformed syntax, but none of the quoting, expansion, or logic problems that
ShellCheck reports for Bash. The Zsh package gains a syntax gate, not a lint.
