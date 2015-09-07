defmodule GitTest do
  use ExUnit.Case

  setup do
    tracker = Temp.track!
    dir = Temp.mkdir! "elixir-git-cli", tracker
    {:ok, dir: dir, tracker: tracker}
  end

  test :clone, context do
    repo = Git.clone! [Path.dirname(__DIR__), Path.join(context[:dir], "cloned_repo")]

    assert File.exists?(repo.path)
    assert File.exists?(Path.join(repo.path, ".git"))

    Temp.cleanup context[:tracker]
  end

  test :init, context do
    repo = Git.init! context[:dir]
    assert File.exists?(repo.path)
    assert File.exists?(Path.join(repo.path, ".git"))

    Temp.cleanup context[:tracker]
  end

  test :add, context do
    repo = Git.init! context[:dir]
    assert String.length(Git.status! repo, ~w(-s)) == 0
    File.write(Path.join(repo.path, "file"), "foobar")
    assert String.length(Git.status! repo, ~w(-s)) > 0
    assert String.starts_with?(Git.status!(repo, ~w(-s)), "?")
    Git.add! repo, "."
    assert String.starts_with?(Git.status!(repo, ~w(-s)), "A")

    Temp.cleanup context[:tracker]
  end
end
