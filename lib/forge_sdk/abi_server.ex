defmodule ForgeSdk.AbiServer do
  @moduledoc """
  TCP listener for Forge ABI, using ranch
  """
  use GenServer

  require Logger

  alias ForgeAbi.{
    Request,
    Response,
    ResponseInfo,
    ResponseUpdateState,
    ResponseVerifyTx,
    StatusCode
  }

  alias ForgeAbi.Util.TypeUrl

  alias ForgeSdk.Tx
  alias ForgeSdk.Util.SocketData

  @behaviour :ranch_protocol

  @spec start_link(reference(), any(), atom(), list()) :: {:ok, pid}
  def start_link(ref, socket, transport, _opts) do
    {:ok, :proc_lib.spawn_link(__MODULE__, :init, [{ref, socket, transport}])}
  end

  @spec start_listener(Keyword.t()) :: :supervisor.startchild_ret()
  def start_listener(opts),
    do: apply(:ranch, :start_listener, gen_ranch_args(opts))

  @spec child_spec(Keyword.t()) :: :supervisor.child_spec()
  def child_spec(opts),
    do: apply(:ranch, :child_spec, gen_ranch_args(opts))

  @spec stop_listener() :: :ok | {:error, any()}
  def stop_listener(), do: :ranch.stop_listener(__MODULE__)

  # GenServer callbacks
  def init({ref, socket, transport}) do
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, active: :once)

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      buffered: <<>>
    })
  end

  def handle_call(_request, _from, state), do: {:reply, :ignored, state}

  def handle_cast(_msg, state), do: {:noreply, state}

  def handle_info({:tcp, socket, data}, %{buffered: buffered} = state) do
    Logger.debug(fn -> "Received data from #{inspect(socket)}" end)

    {requests, rest} = SocketData.decode(<<buffered::binary, data::binary>>, Request)

    new_state = handle_requests(requests, %{state | buffered: rest})
    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.warn("Socket closed. Socket: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info(fn -> "Received unkown message: #{inspect(msg)}" end)
    {:noreply, state}
  end

  def terminate(_reason, _state), do: :ok

  def code_change(_oldvsn, state, _extra), do: {:ok, state}

  @spec handle_requests(list(Request.t()), map()) :: map()
  def handle_requests([], state), do: state

  def handle_requests([%{value: {:verify_tx, value}} | rest_requests], state) do
    Logger.debug(fn -> "Received verify tx request #{inspect(value)}" end)

    %{tx: tx, states: states, context: context} = value

    sender = Enum.find(states, fn state -> state.address === tx.from end)
    {_type, itx} = ForgeAbi.decode_any(tx.itx)
    response = Tx.verify(itx, tx, sender, context, value)
    :ok = send_response(%Response{value: {:verify_tx, response}}, state)

    handle_requests(rest_requests, state)
  rescue
    e ->
      Logger.warn("Failed to verify request: Error: #{inspect(e)}. Request: #{inspect(value)}. ")
      resp = ResponseVerifyTx.new(code: StatusCode.value(:invalid_tx))
      :ok = send_response(%Response{value: {:verify_tx, resp}}, state)

      handle_requests(rest_requests, state)
  end

  def handle_requests([%{value: {:update_state, value}} | rest_requests], state) do
    Logger.debug(fn -> "Received update state request #{inspect(value)}" end)

    %{tx: tx, states: states, context: context} = value

    sender = Enum.find(states, fn state -> state.address === tx.from end)
    {_type, itx} = ForgeAbi.decode_any(tx.itx)

    response = Tx.update(itx, tx, sender, context, value)
    :ok = send_response(%Response{value: {:update_state, response}}, state)

    handle_requests(rest_requests, state)
  rescue
    e ->
      Logger.warn("Failed to update states: Error: #{inspect(e)}. Request: #{inspect(value)}. ")
      resp = ResponseUpdateState.new(states: [])
      :ok = send_response(%Response{value: {:update_state, resp}}, state)

      handle_requests(rest_requests, state)
  end

  def handle_requests([%{value: {:info, value}} | rest_requests], state) do
    Logger.debug(fn -> "Received get application info request #{inspect(value)}" end)
    %{forge_version: _forge_version} = value
    app_hash = Application.get_env(:forge_sdk, :forge_app_hash, "")

    type_urls = TypeUrl.get_extended() |> Enum.map(fn {_, url, _} -> url end)

    response = ResponseInfo.new(type_urls: type_urls, app_hash: app_hash)
    :ok = send_response(%Response{value: {:info, response}}, state)

    handle_requests(rest_requests, state)
  end

  @spec send_response(any(), map()) :: :ok
  def send_response(data, %{socket: socket, transport: transport}) do
    full_response = SocketData.encode(data, Response)

    Logger.debug(fn ->
      "Response (#{byte_size(full_response)}): #{inspect(data)} #{inspect(full_response)}"
    end)

    _ = transport.setopts(socket, active: :once)
    transport.send(socket, full_response)
  end

  # private functions

  @spec gen_ranch_args(Keyword.t()) :: term()
  def gen_ranch_args(args) do
    default = %{max_connections: 1, socket_opts: [buffer: 65535, sndbuf: 65535, recbuf: 65535]}
    opts = Map.update!(default, :socket_opts, &Keyword.merge(&1, args))

    [__MODULE__, :ranch_tcp, opts, __MODULE__, []]
  end
end
