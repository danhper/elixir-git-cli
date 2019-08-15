defmodule Git.Repository do
  defstruct path: nil
  @type t :: %__MODULE__{path: nil | Git.path()}
end
