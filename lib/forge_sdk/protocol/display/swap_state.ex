defimpl ForgeSdk.Display, for: ForgeAbi.SwapState do
  @moduledoc """
  Implementation of `Display` protocol for `SwapState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      value: Display.display(basic.value),
      hashkey: Base.encode16(basic.hashkey),
      hashlock: Base.encode16(basic.hashlock),
      context: Display.display(basic.context, expand?)
    })
  end
end
