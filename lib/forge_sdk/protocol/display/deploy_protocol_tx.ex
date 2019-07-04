defimpl ForgeSdk.Display, for: ForgeAbi.DeployProtocolTx do
  @moduledoc """
  Implementation of `Display` protocol for `DeployProtocolTx`
  """

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)
    group = basic |> Map.get(:tags) |> List.first()

    Map.merge(basic, %{
      group: group || ""
    })
  end
end
