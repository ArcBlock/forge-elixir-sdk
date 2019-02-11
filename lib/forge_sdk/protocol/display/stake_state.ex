defimpl ForgeSdk.Display, for: ForgeAbi.StakeState do
  @moduledoc """
  Implementation of `Display` protocol for `StakeState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      balance: Display.display(basic.balance),
      data: Display.display(basic.data),
      context: Display.display(basic.context, expand?)
    })
  end
end
