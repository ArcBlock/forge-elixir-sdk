defmodule ForgeSdk.Conn do
  @moduledoc """
  Wrapper for ForgeSdk gRPC connection
  """
  use TypedStruct

  typedstruct do
    field :name, String.t()
    field :endpoint, String.t()
    field :chan, GRPC.Channel.t() | nil, default: nil
    field :chain_id, String.t(), default: ""
  end
end

defmodule ForgeSdk.RpcConn do
  @moduledoc """
  Persistent gRPC connection to Forge GRPC server.
  """
  use Connection

  require Logger

  alias ForgeSdk.Conn

  alias GRPC.Stub, as: Client

  # ------------------------------------------------------------------
  # api
  # ------------------------------------------------------------------

  @doc """
  The parameters for start_link/3 are:

  * `endpoint` - the address of gRPC server in `host:port` format
  * `opts` - the options for gRPC http2 client `gun`
  * `callback` - the 0 arity function to be called when gRPC connection is established
  """
  @spec start_link(atom(), String.t(), Keyword.t(), (() -> any) | nil) :: GenServer.on_start()
  def start_link(name, endpoint, opts, callback) do
    Connection.start_link(__MODULE__, {endpoint, name, opts, callback}, name: name)
  end

  @spec get_conn(atom()) :: GRPC.Channel.t() | {:error, :closed}
  def get_conn(name) do
    Connection.call(name, :get_conn)
  end

  @spec update_config(atom(), String.t()) :: GRPC.Channel.t() | {:error, :closed}
  def update_config(name, config) do
    Connection.cast(name, {:update_config, config})
  end

  @spec close(atom()) :: any()
  def close(name), do: Connection.call(name, :close)

  # ------------------------------------------------------------------
  # callbacks
  # ------------------------------------------------------------------

  def init({"unix://" <> endpoint, name, opts, callback}),
    do:
      {:connect, :init,
       %{opts: opts, callback: callback, config: %{}, conn: %Conn{name: name, endpoint: endpoint}}}

  def init({"tcp://" <> endpoint, name, opts, callback}),
    do:
      {:connect, :init,
       %{opts: opts, callback: callback, config: %{}, conn: %Conn{name: name, endpoint: endpoint}}}

  def connect(
        _,
        %{conn: %{chan: nil, endpoint: endpoint} = conn, opts: opts, callback: callback} = state
      ) do
    Logger.info("Forge ABI RPC: reconnect to #{endpoint}...")

    case Client.connect(endpoint, opts) do
      {:ok, chan} ->
        Process.monitor(chan.adapter_payload.conn_pid)
        # send(self(), :get_config)
        callback && spawn(fn -> callback.(conn.name) end)
        {:ok, %{state | conn: %{conn | chan: chan}}}

      {:error, _} ->
        {:backoff, 5000, state}
    end
  end

  def disconnect(info, %{conn: %{chan: chan} = conn} = state) do
    {:ok, _} = Client.disconnect(chan)

    case info do
      {:close, from} -> Connection.reply(from, :ok)
      {:error, :closed} -> Logger.error("Forge SDK RPC connection closed")
      {:error, reason} -> Logger.error("Forge SDK RPC connection error: #{inspect(reason)}")
    end

    {:connect, :reconnect, %{state | conn: %{conn | chan: nil}}}
  end

  # call

  def handle_call(_, _, %{chan: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call(:get_conn, _from, %{conn: conn} = state) do
    {:reply, conn, state}
  end

  def handle_call(:close, from, state) do
    {:disconnect, {:close, from}, state}
  end

  # cast

  def handle_cast({:update_config, config}, %{conn: conn} = state) do
    config = Jason.decode!(config)
    chain_id = Map.get(config, "chain_id")
    {:noreply, %{state | conn: %{conn | chain_id: chain_id}, config: config}}
  end

  # info

  def handle_info(
        {:DOWN, _ref, :process, pid, reason},
        %{conn: %{chan: %{adapter_payload: %{conn_pid: pid}}} = conn} = state
      ) do
    Logger.debug("Forge ABI RPC: connection down with reason #{inspect(reason)}...")
    {:connect, :reconnect, %{state | conn: %{conn | chan: nil}}}
  end

  def handle_info(msg, state) do
    Logger.debug("Got unexpected info message: #{inspect(msg)}")
    {:noreply, state}
  end
end
