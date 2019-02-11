defimpl ForgeSdk.Display, for: ForgeAbi.ForgeStatistics do
  @moduledoc """
  Implementation of `Display` protocol for `ForgeStatistics`
  """
  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      num_stakes: Enum.map(basic.num_stakes, fn num_stake -> Display.display(num_stake) end)
    })
  end
end
