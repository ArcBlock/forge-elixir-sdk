defmodule ForgeSdk.ConnSupervisor do
  @moduledoc """
  Supervise the expiration worker for different cache table.
  """
  use DynamicSupervisor
  alias ForgeSdk.RpcConn

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add(name, addr, callback \\ nil) do
    child_spec = %{
      id: name,
      # disable retry on gun's part to prevent undesired zombie connections
      start: {RpcConn, :start_link, [name, addr, [adapter_opts: %{retry: 0}], callback]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def remove(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
