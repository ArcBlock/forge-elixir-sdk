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
        {type, data} = ForgeAbi.decode_any(%Any{type_url: data.type_url, value: item})

        # TODO (tchen): once did is merged we shall be able to tell if this address is an account or asset, etc.
        case type === :address and expand? do
          true -> Display.display(data)
          _ -> Display.display(data)
        end
      end)

    %{basic | items: items}
  end
end
