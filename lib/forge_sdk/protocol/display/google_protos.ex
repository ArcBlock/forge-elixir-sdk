defimpl ForgeSdk.Display, for: Google.Protobuf.Any do
  @moduledoc """
  Implementation of `Display` protocol for `Timestamp`
  """

  alias ForgeAbi.Util.TypeUrl
  alias ForgeSdk.Display

  @spec display(nil | Google.Protobuf.Any.t(), any()) :: {any(), any()} | %{type: atom()}
  def display(any, expand? \\ false) do
    case TypeUrl.decode(any) do
      {:error, _} ->
        case String.valid?(any.value) do
          true -> Map.from_struct(any)
          false -> Map.from_struct(%{any | value: Base.url_encode64(any.value, padding: false)})
        end

      {type, data} ->
        case is_map(data) do
          true ->
            data
            |> Display.display(expand?)
            |> Map.put(:_type, get_type(any, type))
            |> Map.put(:type_url, any.type_url)
            |> Map.put(:encoded_value, Base.url_encode64(any.value, padding: false))

          _ ->
            %{
              _type: get_type(any, type),
              type_url: any.type_url,
              data: Display.display(data, expand?),
              value: Base.url_encode64(any.value, padding: false)
            }
        end
    end
  end

  # TODO(tchen): we shall unify the name of tx (covert things like :confirm to :confirm_tx)
  defp get_type(%{type_url: "fg:t:" <> _}, type), do: :"#{type}_tx"
  defp get_type(_, type), do: type
end
