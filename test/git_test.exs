defmodule GitTest do
  use ExUnit.Case

  setup do
    Temp.track!
    dir = Temp.mkdir! "elixir-git-cli"
    {:ok, %{dir: dir}}
  end

  test :clone, %{dir: dir} do
    repo_path = Path.join(dir, "cloned_repo")
    repo = Git.clone! [Path.dirname(__DIR__), "--depth=1", repo_path]

    assert repo.path == repo_path

    assert File.exists?(repo.path)
    assert File.exists?(Path.join(repo.path, ".git"))
    Temp.cleanup
  end

  test :init, %{dir: dir} do
    repo = Git.init! dir
    assert File.exists?(repo.path)
    assert File.exists?(Path.join(repo.path, ".git"))
    Temp.cleanup
  end

  # Verify :new allows use of a pre-existing repo
  test :new, %{dir: dir} do
    Git.init! dir

    repo = Git.new dir
    assert File.exists?(repo.path)
    assert File.exists?(Path.join(repo.path, ".git"))
    Temp.cleanup
  end

  test :add, %{dir: dir} do
    repo = Git.init! dir
    assert String.length(Git.status! repo, ~w(-s)) == 0
    File.write(Path.join(repo.path, "file"), "foobar")
    assert String.length(Git.status! repo, ~w(-s)) > 0
    assert String.starts_with?(Git.status!(repo, ~w(-s)), "?")
    Git.add! repo, "."
    assert String.starts_with?(Git.status!(repo, ~w(-s)), "A")
    Temp.cleanup
  end

  test :shortlog, %{dir: dir} do
    repo_path = Path.join(dir, "cloned_repo")
    repo = Git.clone! [Path.dirname(__DIR__), "--depth=1", repo_path]
    assert {:ok, _log} = Git.shortlog(repo)
    assert Git.shortlog!(repo) != Git.shortlog!(repo, ["HEAD~1"])
    Temp.cleanup
  end
end
