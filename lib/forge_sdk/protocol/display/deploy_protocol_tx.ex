defimpl ForgeSdk.Display, for: ForgeAbi.DeployProtocolTx do
  @moduledoc """
  Implementation of `Display` protocol for `DeployProtocolTx`
  """

  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)
    group = basic |> Map.get(:tags) |> List.first()

    Map.merge(basic, %{
      group: group || "",
      code: Display.display(basic.code, expand?),
      data: Display.display(basic.data, expand?),
      installed_at: Display.display(basic.installed_at)
    })
  end
end
