defmodule ForgeSdk.Rpc.Conn do
  @moduledoc """
  Persistent gRPC connection to Forge GRPC server.
  """
  use Connection

  require Logger

  alias GRPC.Stub, as: Client

  # ------------------------------------------------------------------
  # api
  # ------------------------------------------------------------------

  @doc """
  The parameters for start_link/3 are:

  * `addr` - the address of gRPC server in `host:port` format
  * `opts` - the options for gRPC http2 client `gun`
  * `callback` - the function to be called when gRPC connection is established
  """
  @spec start_link(String.t(), Keyword.t(), (() -> any)) :: GenServer.on_start()
  def start_link(addr, opts, callback) do
    Connection.start_link(__MODULE__, {addr, opts, callback}, name: __MODULE__)
  end

  @spec get_chan() :: GRPC.Channel.t() | {:error, :closed}
  def get_chan do
    Connection.call(__MODULE__, :get_chan)
  end

  @spec close :: any()
  def close, do: Connection.call(__MODULE__, :close)

  @spec child_spec(Keyword.t()) :: map
  def child_spec(args) do
    addr = Keyword.get(args, :addr)
    callback = Keyword.get(args, :callback)

    %{
      id: __MODULE__,
      # disable retry on gun's part to prevent undesired zombie connections
      start: {__MODULE__, :start_link, [addr, [adapter_opts: %{retry: 0}], callback]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # ------------------------------------------------------------------
  # callbacks
  # ------------------------------------------------------------------

  def init({"unix://" <> addr, opts, callback}),
    do: {:connect, :init, %{addr: addr, opts: opts, chan: nil, callback: callback}}

  def init({"tcp://" <> addr, opts, callback}),
    do: {:connect, :init, %{addr: addr, opts: opts, chan: nil, callback: callback}}

  def connect(_, %{chan: nil, addr: addr, opts: opts, callback: callback} = state) do
    Logger.info("Forge ABI RPC: reconnect to #{addr}...")

    case Client.connect(addr, opts) do
      {:ok, chan} ->
        Process.monitor(chan.adapter_payload.conn_pid)
        callback && spawn(callback)
        {:ok, %{state | chan: chan}}

      {:error, _} ->
        {:backoff, 5000, state}
    end
  end

  def disconnect(info, %{chan: chan} = state) do
    {:ok, _} = Client.disconnect(chan)

    case info do
      {:close, from} -> Connection.reply(from, :ok)
      {:error, :closed} -> Logger.error("Forge SDK RPC connection closed")
      {:error, reason} -> Logger.error("Forge SDK RPC connection error: #{inspect(reason)}")
    end

    {:connect, :reconnect, %{state | chan: nil}}
  end

  def handle_call(_, _, %{chan: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call(:get_chan, _from, %{chan: chan} = state) do
    {:reply, chan, state}
  end

  def handle_call(:close, from, state) do
    {:disconnect, {:close, from}, state}
  end

  def handle_info(
        {:DOWN, _ref, :process, pid, reason},
        %{chan: %{adapter_payload: %{conn_pid: pid}}} = state
      ) do
    Logger.debug("Forge ABI RPC: connection down with reason #{inspect(reason)}...")
    {:connect, :reconnect, %{state | chan: nil}}
  end

  def handle_info(msg, state) do
    Logger.debug("#{inspect(msg)}")
    {:noreply, state}
  end
end
