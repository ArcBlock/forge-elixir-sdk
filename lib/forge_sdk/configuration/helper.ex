defmodule ForgeSdk.Configuration.Helper do
  @moduledoc """
  Functions to make configuration parse easy.
  """

  @doc """
  Expand the path and normalize the given paths and sockets.
  """
  def parse_config(config, paths_to_normalize) do
    path = config |> Map.get("path") |> Path.expand()
    :ok = File.mkdir_p!(path)

    config
    |> Map.put("path", path)
    |> normalize_paths(paths_to_normalize, path)
    |> normalize_socks(path)
  end

  @spec add_paths(nil | keyword() | map(), any()) :: any()
  def add_paths(config, paths) do
    path = config["path"]

    Enum.reduce(paths, config, fn {k, v}, acc ->
      Map.put(acc, k, Path.join(path, v))
    end)
  end

  def put_env(name, config) do
    otp_app =
      case :application.get_application() do
        # in test cases, current pid would be incorrect
        :undefined ->
          case name do
            :tendermint -> :consensus
            :ipfs -> :storage
            _ -> Application.get_env(:forge_sdk, :otp_app, :undefined)
          end

        {:ok, v} ->
          v
      end

    Application.put_env(otp_app, name, config)
  end

  def get_env(key) do
    otp_app =
      case Application.get_env(:forge_sdk, :otp_app, :undefined) do
        :undefined ->
          case :application.get_application() do
            :undefined -> :undefined
            {:ok, v} -> v
          end

        v ->
          v
      end

    Application.get_env(otp_app, key)
  end

  # private functions

  defp normalize_paths(config, keys, path) do
    Enum.reduce(keys, config, fn key, acc ->
      case acc[key] do
        "" ->
          acc

        nil ->
          acc

        v ->
          full_path = Path.join(path, v)
          :ok = File.mkdir_p!(Path.dirname(full_path))
          Map.put(acc, key, full_path)
      end
    end)
  end

  defp normalize_socks(config, path) do
    config
    |> Map.keys()
    |> Stream.filter(&String.starts_with?(&1, "sock_"))
    |> Enum.reduce(config, fn name, acc ->
      addr = Map.get(acc, name)
      Map.put(acc, name, expand_unix_socket(addr, path))
    end)
  end

  defp expand_unix_socket("unix://" <> file, path) do
    sock_path = Path.join(path, file)
    :ok = File.mkdir_p!(Path.dirname(sock_path))
    "unix://#{sock_path}"
  end

  defp expand_unix_socket(addr, _), do: addr
end
