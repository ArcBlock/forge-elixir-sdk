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
    field :decimal, non_neg_integer()
    field :gas, map(), default: %{}
    field :pid, pid(), default: nil
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

  @timeout 60000

  # ------------------------------------------------------------------
  # api
  # ------------------------------------------------------------------

  @doc """
  The parameters for start_link/3 are:

  * `endpoint` - the address of gRPC server in `host:port` format
  * `opts` - the options for gRPC http2 client `gun`
  * `callback` - the 0 arity function to be called when gRPC connection is established
  """
  @spec start_link(list()) :: GenServer.on_start()
  def start_link(args) do
    Connection.start_link(
      __MODULE__,
      {args[:endpoint], args[:name], args[:opts], args[:callback]}
    )
  end

  @spec get_conn(atom()) :: ForgeSdk.Conn.t() | {:error, :closed}
  def get_conn(name) do
    do_checkout_and_call(name, :get_conn)
  end

  @spec get_conn_state(atom()) :: ForgeSdk.Conn.t() | {:error, :closed}
  def get_conn_state(name) do
    do_call(name, :get_conn)
  end

  @spec get_config(atom()) :: String.t() | {:error, :closed}
  def get_config(name) do
    do_call(name, :get_config)
  end

  @spec update_config(pid(), String.t()) :: any()
  def update_config(pid, config) do
    Connection.call(pid, {:update_config, config})
  end

  @spec update_gas(pid(), map()) :: any()
  def update_gas(pid, gas) do
    Connection.call(pid, {:update_gas, gas})
  end

  @spec close(pid()) :: any()
  def close(pid), do: Connection.call(pid, :close)

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
    me = self()

    case Client.connect(endpoint, opts) do
      {:ok, chan} ->
        Process.monitor(chan.adapter_payload.conn_pid)

        callback &&
          spawn(fn ->
            :timer.sleep(100)
            callback.(conn.name, me)
          end)

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
    {:reply, %{conn | pid: self()}, state}
  end

  def handle_call(:get_config, _from, %{config: config} = state) do
    {:reply, config, state}
  end

  def handle_call(:close, from, state) do
    {:disconnect, {:close, from}, state}
  end

  def handle_call({:update_config, config}, _from, %{conn: conn} = state) do
    config = Jason.decode!(config)
    chain_id = Map.get(config, "chain_id")
    decimal = Map.get(config, "decimal")
    {:reply, :ok, %{state | conn: %{conn | chain_id: chain_id, decimal: decimal}, config: config}}
  end

  def handle_call({:update_gas, gas}, _from, %{conn: conn} = state) do
    {:reply, :ok, %{state | conn: %{conn | gas: gas}}}
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

  # private functions

  defp do_call(name, msg) do
    :poolboy.transaction(
      name,
      fn pid ->
        Connection.call(pid, msg)
      end,
      @timeout
    )
  end

  defp do_checkout_and_call(name, msg) do
    worker = :poolboy.checkout(name)
    Connection.call(worker, msg)
  end
end
