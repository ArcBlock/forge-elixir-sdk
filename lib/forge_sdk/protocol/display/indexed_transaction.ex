defimpl ForgeSdk.Display, for: ForgeAbi.IndexedTransaction do
  @moduledoc """
  Implementation of `Display` protocol for `IndexedTransaction`
  """
  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      tx: Display.display(basic.tx),
      code: ForgeAbi.StatusCode.value(basic.code)
    })
  end
end
