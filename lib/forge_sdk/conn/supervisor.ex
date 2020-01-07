defmodule ForgeSdk.ConnSupervisor do
  @moduledoc """
  Supervise the connections.
  """
  use DynamicSupervisor
  alias ForgeSdk.RpcConn

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # def add(name, addr, callback \\ nil) do
  #   child_spec = %{
  #     id: name,
  #     # disable retry on gun's part to prevent undesired zombie connections
  #     start: {RpcConn, :start_link, [name, addr, [adapter_opts: %{retry: 0}], callback]},
  #     type: :worker,
  #     restart: :permanent,
  #     shutdown: 500
  #   }

  #   DynamicSupervisor.start_child(__MODULE__, child_spec)
  # end

  def add_pool(name, addr, callback \\ nil, size \\ 20, overflow \\ 0) do
    config = [
      {:name, {:local, name}},
      {:worker_module, RpcConn},
      {:size, size},
      {:max_overflow, overflow}
    ]

    args = [name: name, endpoint: addr, opts: [adapter_opts: %{retry: 0}], callback: callback]

    DynamicSupervisor.start_child(
      __MODULE__,
      :poolboy.child_spec(:worker, config, args)
    )
  end

  def remove(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def get_names do
    Enum.map(children(), fn {_, p, _, _} -> p |> Process.info(:registered_name) |> elem(1) end)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
