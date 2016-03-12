defmodule Git do
  @type error :: {:error, Git.Error}
  @type cli_arg :: bitstring | list

  @doc """
  Clones the repository. The first argument can be `url` or `[url, path]`.
  Returns `{:ok, repository}` on success and `{:error, reason}` on failure.
  """
  @spec clone(cli_arg) :: {:ok, Git.Repository.t} | error
  def clone(args) do
    execute_command nil, "clone", args, fn _ ->
      args = if is_list(args), do: args, else: [args]
      path = (Enum.at(args, 1) || args |> Enum.at(0) |> Path.basename |> Path.rootname) |> Path.expand
      {:ok, %Git.Repository{path: path}}
    end
  end

  @doc """
  Same as clone/1 but raise an exception on failure.
  """
  @spec clone!(cli_arg) :: {:ok, Git.Repository.t} | error
  def clone!(args), do: result_or_fail(clone(args))

  @spec init(cli_arg) :: {:ok, Git.Repository.t} | error
  def init(args \\ []) do
    execute_command nil, "init", args, fn _ ->
      args = if is_list(args), do: args, else: [args]
      path = (Enum.at(args, 0) || ".") |> Path.expand
      {:ok, %Git.Repository{path: path}}
    end
  end

  @doc """
  Run `git init` in the given directory
  Returns `{:ok, repository}` on success and `{:error, reason}` on failure.
  """
  @spec init!(cli_arg) :: {:ok, Git.Repository.t} | error
  def init!(args \\ []), do: result_or_fail(init(args))

  commands = File.read!(Path.join(__DIR__, "../git-commands.txt"))
  |> String.split("\n")
  |> Enum.filter(fn x ->
    x = String.strip(x)
    not (String.length(x) == 0 or String.starts_with?(x, "#"))
  end)

  Enum.each commands, fn name ->
    normalized_name = String.to_atom(String.replace(name, "-", "_"))
    bang_name = String.to_atom("#{normalized_name}!")

    @doc """
    Run `git #{name}` in the given repository
    Returns `{:ok, output}` on success and `{:error, reason}` on failure.
    """
    @spec unquote(normalized_name)(Git.Repository.t, cli_arg) :: {:ok, binary} | error
    def unquote(normalized_name)(repository, args \\ []) do
      execute_command repository, unquote(name), args, fn n -> {:ok, n} end
    end

    @doc """
    Same as `#{normalized_name}/2` but raises an exception on error.
    """
    @spec unquote(bang_name)(Git.Repository.t, cli_arg) :: binary
    def unquote(bang_name)(repository, args \\ []) do
      result_or_fail(unquote(normalized_name)(repository, args))
    end
  end

  @doc """
  Execute the git command in the given repository.
  """
  @spec execute_command(Repository.t, bitstring, list, (bitstring -> any)) :: :ok | {:error, any}
  def execute_command(repo, command, args, callback) do
    unless is_list(args), do: args = [args]
    options = [stderr_to_stdout: true]
    if repo, do: options = Dict.put(options, :cd, repo.path)
    case System.cmd "git", [command|args], options do
      {output, 0} -> callback.(output)
      {err, code} -> {:error, %Git.Error{message: err, command: command, args: args, code: code}}
    end
  end

  defp result_or_fail(result) do
    case result do
      {:ok, res} -> res
      {:error, err} -> raise err
    end
  end
end
