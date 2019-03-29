defimpl ForgeSdk.Display, for: ForgeAbi.AssetState do
  @moduledoc """
  Implementation of `Display` protocol for `AssetState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    Map.merge(basic, %{
      data: Display.display(basic.data),
      stake: Display.display(basic.stake),
      consumed_time: Display.display(basic.consumed_time),
      context: Display.display(basic.context, expand?)
    })
  end
end
