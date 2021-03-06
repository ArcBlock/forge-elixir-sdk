defimpl ForgeSdk.Display, for: ForgeAbi.IndexedTransaction do
  @moduledoc """
  Implementation of `Display` protocol for `IndexedTransaction`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      tx: Display.display(basic.tx, expand?),
      code: ForgeAbi.StatusCode.value(basic.code)
    })
  end
end
