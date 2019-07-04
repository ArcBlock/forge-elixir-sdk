defimpl ForgeSdk.Display, for: ForgeAbi.ProtocolState do
  @moduledoc """
  Implementation of `Display` protocol for `ProtocolState`
  """

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)
    group = basic.itx |> Map.get(:tags) |> List.first()

    Map.merge(basic, %{
      group: group || ""
    })
  end
end
