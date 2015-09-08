# Elixir Git CLI [![Build Status](https://travis-ci.org/tuvistavie/elixir-git-cli.svg?branch=master)](https://travis-ci.org/tuvistavie/elixir-git-cli)

Simple wrapper of git CLI for Elixir.

## Installation

Add the dependency to your `mix.exs` deps:

```
  defp deps do
    [{:git_cli, "~> 0.1.0"}]
  end
```

## Usage

The usage is basically `Git.COMMAND REPO, ARGS`, where `REPO` is a
`Git.Repository` and `ARGS` is either a string or a list of strings.
So for example, `git pull --rebase origin master` would translate to
`Git.pull repo, ~w(--rebase origin master)`.

The only exceptions are `Git.clone` and `Git.init`, which do not take a repository as first argument.

Here are a few examples.

```elixir
repo = Git.clone "https://github.com/tuvistavie/elixir-git-cli"
Git.remote repo, ~w(add upstream https://git.example.com)
Git.pull repo, ~w(--rebase upstream master)
Git.diff repo, "HEAD~1"
Git.add repo, "."
Git.commit repo, ["-m" "my message"]
Git.push repo
IO.puts Git.log!(repo)
```

Note that all functions return `:ok` or `{:ok, result}`, and come with their
bang version which only returns `result` when relevant.
On error, the normal version returns `{:error, Git.Error}` and the bang version
simply raises the exception.

## Note

As this is a wrapper for `git`, you need to have the `git` command available on your path.

The commands are generated from [git-commands.txt](./git-commands.txt),
except for `init` and `clone` which return a `Git.Repository` struct and not
the git process `stdout`.
The `apply` command is not generated as it conflicts with elixir Kernel function.
The commands with dashes have their function equivalent with dashes replaced by underscores, so for example, `git ls-files` become `Git.ls_files`.

## TODO

* Write more tests
* Parse `git log`, `git diff` etc into `struct`
