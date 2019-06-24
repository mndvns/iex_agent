defmodule IExAgent do
  defmacro __using__(opts) do
    envs = Keyword.get(opts, :envs, [:dev, :test])
    force = Keyword.get(opts, :force, nil)
    using = if is_nil(force), do: Mix.env() in envs, else: force
    if using do
      only = [
        x: 0, x: 1,
        r: 0, r: 1,
        z: 0, z: 1,
        iex_list: 0,
        iex_clean: 0,
        iex_reset: 0,
        iex_shift: 0,
        iex_pop: 0,
        iex_set: 1,
        iex_unshift: 1,
        iex_push: 1,
        iex_prepend: 1,
        iex_append: 1,
        iex_add: 1,
        iex_delete: 1,
        iex_remove: 1
      ]

      quote do
        unquote(__MODULE__).start()

        import IEx.Helpers, except: [r: 1]

        import unquote(__MODULE__), only: unquote(only)

        import_file_if_available(".iex.local.exs")
      end
    end
  end

  # convenience shorthands

  defdelegate x(), to: IEx.Helpers, as: :clear
  defdelegate x(modules), to: __MODULE__, as: :clear
  defdelegate r(), to: __MODULE__, as: :reload
  defdelegate r(modules), to: __MODULE__, as: :reload
  defdelegate z(), to: __MODULE__, as: :reload_clear
  defdelegate z(modules), to: __MODULE__, as: :reload_clear

  # state convenience functions

  defdelegate iex_list(), to: __MODULE__, as: :list
  defdelegate iex_clean(), to: __MODULE__, as: :clean
  defdelegate iex_reset(), to: __MODULE__, as: :reset
  defdelegate iex_shift(), to: __MODULE__, as: :shift
  defdelegate iex_pop(), to: __MODULE__, as: :pop
  defdelegate iex_set(module), to: __MODULE__, as: :set
  defdelegate iex_unshift(module), to: __MODULE__, as: :unshift
  defdelegate iex_push(module), to: __MODULE__, as: :push
  defdelegate iex_prepend(module), to: __MODULE__, as: :prepend
  defdelegate iex_append(module), to: __MODULE__, as: :append
  defdelegate iex_add(module), to: __MODULE__, as: :push
  defdelegate iex_delete(module), to: __MODULE__, as: :delete
  defdelegate iex_remove(module), to: __MODULE__, as: :delete

  # reloading and clearing wrappers

  def clear(output) do
    IEx.Helpers.clear()
    output
  end

  def reload() do
    reload(list())
  end

  def reload(modules) when is_list(modules) do
    return(Enum.map(modules, &reload/1))
  end

  def reload(module) do
    IEx.Helpers.r(module)
  catch
    :error, %ArgumentError{message: message} -> {:error, module, message}
    _kind, error -> raise error
  else
    value -> return(value)
  end

  def reload_clear() do
    reload_clear(list())
  end

  def reload_clear(modules) do
    clear(reload(modules))
  end

  defp return([msg]) do
    return(msg)
  end

  defp return(msg) do
    msg
  end

  # state management

  use Agent

  def start() do
    Agent.start_link(&read/0, name: __MODULE__)
  end

  def stop() do
    Agent.stop(__MODULE__)
  end

  def list(), do: Agent.get(__MODULE__, & &1)

  def set(module), do: update(module)

  def reset(), do: update([])

  def shift(), do: update(&List.pop_at(&1, 0))

  def pop(), do: update(&List.pop_at(&1, :erlang.max(0, length(&1) - 1)))

  def unshift(module), do: update(module, &(&2 ++ (&1 -- &2)))

  def push(module), do: update(module, &((&1 -- &2) ++ &2))

  def prepend(module), do: update(module, &(&2 ++ &1))

  def append(module), do: update(module, &(&1 ++ &2))

  def delete(module), do: update(module, &(&1 -- &2))

  defp update(modules, fun \\ nil)
  defp update(modules, nil) do
    update(modules, fn _, _ -> modules end)
  end
  defp update(fun, _) when is_function(fun) do
    update([], fun)
  end
  defp update(module, fun) when is_function(fun, 1) do
    update(module, fn oldstate, _ -> fun.(oldstate) end)
  end
  defp update(module, fun) when is_atom(module) do
    update([module], fun)
  end
  defp update(modules, fun) when is_list(modules) do
    Agent.get_and_update(__MODULE__, fn oldstate ->
      case fun.(oldstate, modules) do
        {return, newstate} ->
          newstate = Enum.uniq(newstate)
          {{return, newstate}, write(newstate)}
        newstate ->
          newstate = Enum.uniq(newstate)
          {newstate, write(newstate)}
      end
    end)
  end

  def clean() do
    reload()
    |> Enum.filter(&match?({:error, _module, _msg}, &1))
    |> Enum.map(&elem(&1, 1))
    |> delete()
    |> clear()
  end

  # persistent storage

  @dir_path System.tmp_dir!() <> "/iex_agent/" <> String.replace(File.cwd!(), System.user_home!(), "")
  @file_path "#{@dir_path}/state.term"

  defp read() do
    unless File.exists?(@dir_path) do
      File.mkdir_p!(@dir_path)
    end

    case File.exists?(@file_path) do
      true -> File.read!(@file_path) |> :erlang.binary_to_term()
      false -> write([])
    end
  end

  defp write(modules) do
    File.write!(@file_path, :erlang.term_to_binary(modules))
    modules
  end
end
