defimpl ForgeSdk.Display, for: ForgeAbi.SwapStatistics do
  @moduledoc """
  Implementation of `Display` protocol for `SwapState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      locked_value_in: Display.display(basic.locked_value_in),
      locked_value_out: Display.display(basic.locked_value_out)
    })
  end
end
