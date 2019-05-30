defmodule ForgeSdk.Application do
  @moduledoc false

  use Application

  alias ForgeSdk.ConnSupervisor

  def start(_type, _args) do
    children = [
      {ConnSupervisor, strategy: :one_for_one, name: ConnSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ForgeSdk.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
