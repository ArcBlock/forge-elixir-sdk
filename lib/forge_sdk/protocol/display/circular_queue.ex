defimpl ForgeSdk.Display, for: ForgeAbi.CircularQueue do
  @moduledoc """
  Implementation of `Display` protocol for `BigSint`
  """
  use ForgeAbi.Unit

  alias ForgeSdk.Display
  alias Google.Protobuf.Any

  def display(data, expand? \\ false) do
    basic = Map.from_struct(data)

    items =
      Enum.map(data.items, fn item ->
        data = ForgeAbi.decode_any!(%Any{type_url: data.type_url, value: item})

        case expand? do
          true -> Display.display(data)
          _ -> data
        end
      end)

    %{basic | items: items}
  end
end
