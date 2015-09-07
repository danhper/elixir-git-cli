defmodule Git.Error do
  defexception message: "Could not execute command", command: nil, code: 1, args: []
end
