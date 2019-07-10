defimpl ForgeSdk.Display, for: ForgeAbi.AccountState do
  @moduledoc """
  Implementation of `Display` protocol for `AccountStste`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      pk: Display.display(basic.pk),
      balance: Display.display(basic.balance),
      gas_balance: Display.display(basic.gas_balance),
      data: Display.display(basic.data),
      stake: Display.display(basic.stake),
      type: Display.display(basic.type),
      context: Display.display(basic.context, expand?)
    })
  end
end
