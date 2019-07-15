defmodule Git do
  @type error :: {:error, Git.Error}
  @type cli_arg :: String.t | [String.t]
  @type path :: String.t

  defp get_repo_path(args) when not is_list(args), do: get_repo_path([args])
  defp get_repo_path(args) when is_list(args) do
    {_options, positional, _rest} = OptionParser.parse(args, strict: [])
    case positional do
      [_url, path] -> path
      [url] -> url |> Path.basename |> Path.rootname
      _ -> raise "invalid arguments for clones: #{inspect(args)}"
    end
  end

  @doc """
  Clones the repository. The first argument can be `url` or `[url, path]`.
  Returns `{:ok, repository}` on success and `{:error, reason}` on failure.
  """
  @spec clone(cli_arg) ::  {:ok, Git.Repository.t} | error
  def clone(args) do
    execute_command nil, "clone", args, fn _ ->
      path = args |> get_repo_path() |> Path.expand
      {:ok, %Git.Repository{path: path}}
    end
  end

  @doc """
  Same as clone/1 but raise an exception on failure.
  """
  @spec clone!(cli_arg) :: Git.Repository.t
  def clone!(args), do: result_or_fail(clone(args))

  @spec init() :: {:ok, Git.Repository.t} | error
  @spec init(Git.Repository.t) :: {:ok, Git.Repository.t} | error
  @spec init(cli_arg) :: {:ok, Git.Repository.t} | error
  def init(), do: init([])
  def init(args) when is_list args do
    execute_command nil, "init", args, fn _ ->
      args = if is_list(args), do: args, else: [args]
      path = (Enum.at(args, 0) || ".") |> Path.expand
      {:ok, %Git.Repository{path: path}}
    end
  end
  def init(repo = %Git.Repository{}) do
    Git.execute_command repo, "init", [], (fn _ -> {:ok, repo} end)
  end

  @doc """
  Run `git init` in the given directory
  Returns `{:ok, repository}` on success and `{:error, reason}` on failure.
  """
  @spec init!(cli_arg) :: Git.Repository.t
  @spec init!() :: Git.Repository.t
  def init!(args \\ []), do: result_or_fail(init(args))

  commands = File.read!(Path.join(__DIR__, "../git-commands.txt"))
  |> String.split("\n")
  |> Enum.filter(fn x ->
    trim = if function_exported?(String, :trim, 1), do: :trim, else: :strip
    x = apply(String, trim, [x])
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
    @spec unquote(bang_name)(Git.Repository.t, cli_arg) :: binary | no_return
    def unquote(bang_name)(repository, args \\ []) do
      result_or_fail(unquote(normalized_name)(repository, args))
    end
  end

  @doc """
  Return a Git.Repository struct with the specified or defaulted path.
  For use with an existing repo (when Git.init and Git.clone would not be appropriate).
  """
  @spec new(path) :: Git.Repository.t
  def new(path \\ "."), do: %Git.Repository{path: path}

  @doc """
  Execute the git command in the given repository.
  """
  @spec execute_command(Git.Repository.t | nil, String.t, cli_arg, (String.t -> {:ok, any} | error)) :: {:ok, any} | {:error, any}
  def execute_command(repo, command, args, callback) when is_list(args) do
    options = case repo do
      nil -> [stderr_to_stdout: true]
      _ ->   [stderr_to_stdout: true, cd: repo.path]
    end

    case System.cmd "git", [command|args], options do
      {output, 0} -> callback.(output)
      {err, code} -> {:error, %Git.Error{message: err, command: command, args: args, code: code}}
    end
  end

  def execute_command(repo, command, args, callback) do
    execute_command(repo, command, [args], callback)
  end

  @spec result_or_fail({:ok, t}) :: t  when t: Git.Repository.t | String.t
  defp result_or_fail({:ok, res}), do: res
  defp result_or_fail({:error, res}), do: raise res
end
