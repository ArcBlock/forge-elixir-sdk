defmodule ForgeSdk.Util.App do
  @moduledoc """
  Application utility functions
  """
  require Logger

  @spec get_server_opts(String.t()) :: {non_neg_integer(), Keyword.t()} | non_neg_integer()
  def get_server_opts("unix://" <> path) do
    if File.exists?(path) do
      Logger.info("Socket file #{path} exists. Clean it up.")
      File.rm!(path)
    end

    {0, ip: {:local, path}}
  end

  def get_server_opts("tcp://" <> address) do
    [_ip, port] = String.split(address, ":", parts: 2)
    String.to_integer(port)
  end

  def set_ranch_port({0, ip: ip}, app) do
    Application.put_env(app, :ranch_opts, %{
      max_connections: 3,
      socket_opts: [port: 0, ip: ip, buffer: 65_535, sndbuf: 65_535, recbuf: 65_535]
    })
  end

  def set_ranch_port(port, app) do
    Application.put_env(app, :ranch_opts, %{
      max_connections: 3,
      socket_opts: [port: port, buffer: 655_350, sndbuf: 655_350, recbuf: 655_350]
    })
  end

  def get_abi_server(config) do
    backoff = config["sock_backoff"] || 500

    cond do
      Map.get(config, "sock_tcp", "") !== "" ->
        {:socket,
         config["sock_tcp"] |> get_server_opts() |> get_host_port() |> add_backoff(backoff)}

      Map.get(config, "sock_grpc", "") !== "" ->
        {:grpc, {config["sock_grpc"], backoff}}

      true ->
        raise "Invalid configuration for forge app. No socket def for tcp / grpc"
    end
  end

  def get_abi_tcp_server(sock_tcp, backoff),
    do: sock_tcp |> get_server_opts() |> get_host_port() |> add_backoff(backoff)

  def get_abi_grpc_server(sock_grpc, backoff), do: {sock_grpc, backoff, []}

  # private functions

  defp get_host_port({0, ip: {:local, path}}), do: {path, 0, []}
  defp get_host_port(port), do: {"127.0.0.1", port, []}

  defp add_backoff({host, port, opts}, backoff), do: {host, port, backoff, opts}
end
