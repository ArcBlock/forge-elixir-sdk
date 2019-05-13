defmodule ForgeSdk.Rpc.Conn do
  @moduledoc """
  Persistent gRPC connection to Forge GRPC server.
  """
  use Connection

  require Logger

  alias GRPC.Stub, as: Client

  def start_link(addr, opts) do
    Connection.start_link(__MODULE__, {addr, opts}, name: __MODULE__)
  end

  @spec get_chan() :: GRPC.Channel.t() | {:error, :closed}
  def get_chan do
    Connection.call(__MODULE__, :get_chan)
  end

  @spec close :: any()
  def close, do: Connection.call(__MODULE__, :close)

  @spec child_spec(String.t()) :: map
  def child_spec(addr) do
    %{
      id: __MODULE__,
      start:
        {__MODULE__, :start_link,
         [
           addr,
           [
             adapter_opts: %{
               # turn off keepalive to prevent zombie connections for grpc server
               http2_opts: %{keepalive: :infinity},
               # disable retry on gun's part to prevent undesired zombie connections
               retry: 0
             }
           ]
         ]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # callbacks
  def init({"unix://" <> addr, opts}),
    do: {:connect, :init, %{addr: addr, opts: opts, chan: nil}}

  def init({"tcp://" <> addr, opts}), do: {:connect, :init, %{addr: addr, opts: opts, chan: nil}}

  def connect(_, %{chan: nil, addr: addr, opts: opts} = state) do
    Logger.info("Forge ABI RPC: reconnect to #{addr}...")

    case Client.connect(addr, opts) do
      {:ok, chan} ->
        Process.monitor(chan.adapter_payload.conn_pid)
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

  # callbacks
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
    Logger.info("Forge ABI RPC: connection down with reason #{inspect(reason)}...")
    {:connect, :reconnect, %{state | chan: nil}}
  end

  def handle_info(msg, state) do
    Logger.debug("#{inspect(msg)}")
    {:noreply, state}
  end
end
