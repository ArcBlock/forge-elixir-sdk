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
        Map.from_struct(any)

      {type, data} ->
        data
        |> Display.display(expand?)
        |> Map.put(:_type, get_type(any, type))
        |> Map.put(:type_url, any.type_url)
    end
  end

  # TODO(tchen): we shall unify the name of tx (covert things like :confirm to :confirm_tx)
  defp get_type(%{type_url: "fg:t:" <> _}, type), do: :"#{type}_tx"
  defp get_type(_, type), do: type
end
