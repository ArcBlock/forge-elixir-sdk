defprotocol ForgeSdk.Extension do
  @moduledoc """
  State / tx extension protocol for application to extend existing tx or state
  """

  @type t :: ForgeSdk.Extension.t()

  @fallback_to_any true

  @doc """
  Check if application side extended the given data
  """
  @spec check(t(), [String.t()]) :: boolean
  def check(itx, type_url_list)
end

defimpl ForgeSdk.Extension, for: Any do
  def check(item, type_url_list) do
    case item |> Map.get(:data, %{}) |> Map.get(:type_url) do
      nil -> false
      v -> v in type_url_list
    end
  end
end
