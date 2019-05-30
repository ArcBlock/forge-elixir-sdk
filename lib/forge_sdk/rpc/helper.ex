defmodule ForgeSdk.Rpc.Helper do
  @moduledoc false

  require Logger

  alias ForgeSdk.Rpc.Stub, as: ForgeRpc
  alias GRPC.Stub, as: Client

  @recv_timeout 10_000
  @deadline_expired 4

  @doc """
  Send a single request to GRPC server.
  """
  def send(service, conn, req, opts, fun) do
    grpc_opts = get_grpc_opts(opts)
    data = apply(ForgeRpc, service, [conn.chan, req, grpc_opts])

    case data do
      {:ok, res} ->
        process_response(res, opts, fun)

      {:error, msg} ->
        Logger.warn(
          "Failed to process request for #{inspect(service)}. Error: #{inspect(msg)}, Req is #{
            inspect(req)
          }. "
        )

        {:error, :internal}
    end
  end

  @doc """
  Send multiple requests to GRPC server one by one.
  """
  def send_stream(service, conn, reqs, opts, fun) when is_list(reqs) do
    stream = get_stream(service, conn, opts)
    do_send_stream(stream, reqs, opts, fun)
  end

  def send_stream(service, conn, req, opts, fun) do
    stream = get_stream(service, conn, opts)

    stream
    |> do_send_stream([req], opts, fun)
    |> case do
      [res] -> res
      res -> res
    end
  end

  @doc """
  Support different ways to pass parameters to rpc.

      * %RequestFunction{k1: v1, k2: v2}
      * [k1: v1, k2: v2]
      * [%RequestFunction{k1: v1, k2: v2}, ...]
      * [[k1: v1, k2: v2], ...]
  """
  def to_req(%{__struct__: mod} = req, mod), do: req
  def to_req([{_k, _v} | _] = req, mod), do: mod.new(req)
  def to_req(reqs, mod), do: Enum.map(reqs, &to_req(&1, mod))

  # private function
  defp get_stream(service, conn, opts), do: apply(ForgeRpc, service, [conn.chan, opts])

  defp recv(stream, opts, fun) do
    case Client.recv(stream, timeout: @recv_timeout) do
      {:ok, res} ->
        process_response(res, opts, fun)

      {:error, msg} ->
        Logger.warn(
          "Failed to process request for stream #{inspect(stream)}.  Error: #{inspect(msg)}"
        )

        {:error, :internal}
    end
  end

  defp process_response(%{code: :ok} = res, _opts, fun), do: fun.(res)
  defp process_response(%{code: code}, _opts, _fun), do: {:error, code}

  defp process_response(res_stream, opts, fun) do
    mod = if opts[:stream_mode] == true, do: Stream, else: Enum

    mod.map(res_stream, fn
      {:ok, res} ->
        process_response(res, opts, fun)

      {:error, %{status: @deadline_expired}} ->
        Logger.warn("Deadline expired for the stream.")
        process_response(%{code: :timeout}, opts, fun)

      {:error, msg} ->
        Logger.warn("Failed to process response.  Error: #{inspect(msg)}")
        {:error, :internal}
    end)
  end

  defp do_send_stream(stream, [req], opts, fun) do
    Client.send_request(stream, req, end_stream: true)
    recv(stream, opts, fun)
  end

  defp do_send_stream(stream, [req | rest], opts, fun) do
    Client.send_request(stream, req, end_stream: false)
    do_send_stream(stream, rest, opts, fun)
  end

  defp get_grpc_opts(opts) do
    Keyword.delete(opts, :stream_mode)
  end
end
