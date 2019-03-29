defimpl ForgeSdk.Display, for: ForgeAbi.StateContext do
  @moduledoc """
  Implementation of `Display` protocol for `StateContext`
  """
  alias ForgeAbi.RequestGetTx
  alias ForgeSdk.{Display, Rpc}

  def display(data, expand? \\ false)
  def display(data, false), do: data

  def display(data, true) do
    basic = Map.from_struct(data)

    genesis_tx =
      case basic.genesis_tx do
        "" -> nil
        _ -> Display.display(Rpc.get_tx(RequestGetTx.new(hash: basic.genesis_tx)))
      end

    renaissance_tx =
      case basic.renaissance_tx do
        "" -> nil
        _ -> Display.display(Rpc.get_tx(RequestGetTx.new(hash: basic.renaissance_tx)))
      end

    Map.merge(basic, %{
      genesis_time: Display.display(basic.genesis_time),
      renaissance_time: Display.display(basic.renaissance_time),
      genesis_tx: genesis_tx,
      renaissance_tx: renaissance_tx
    })
  end
end
