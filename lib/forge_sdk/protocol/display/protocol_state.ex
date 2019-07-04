defimpl ForgeSdk.Display, for: ForgeAbi.ProtocolState do
  @moduledoc """
  Implementation of `Display` protocol for `ProtocolState`
  """
  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)
    group = basic.itx |> Map.get(:tags) |> List.first()

    Map.merge(basic, %{
      group: group || "",
      status: Display.display(basic.status),
      itx: Display.display(basic.itx, expand?)
    })
  end
end
