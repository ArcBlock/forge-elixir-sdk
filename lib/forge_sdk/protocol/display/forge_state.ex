defimpl ForgeSdk.Display, for: ForgeAbi.ForgeState do
  @moduledoc """
  Implementation of `Display` protocol for `ForgeState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      consensus: Display.display(basic.consensus),
      data: Display.display(basic.data),
      stake_summary:
        Enum.map(basic.stake_summary, fn {key, value} ->
          %{key: key, value: Display.display(value, expand?)}
        end),
      tasks:
        Enum.map(basic.tasks, fn {key, value} ->
          %{key: key, value: Display.display(value, expand?)}
        end),
      account_config:
        Enum.map(basic.account_config, fn {key, value} ->
          %{key: key, value: Display.display(value, expand?)}
        end),
      tx_config: Display.display(basic.tx_config)
    })
  end
end

defimpl ForgeSdk.Display, for: ForgeAbi.StakeSummary do
  @moduledoc """
  Implementation of `Display` protocol for `StakeSummary`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      context: Display.display(basic.context, expand?),
      total_stakes: Display.display(basic.total_stakes),
      total_unstakes: Display.display(basic.total_unstakes)
    })
  end
end
