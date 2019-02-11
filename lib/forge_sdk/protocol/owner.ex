defprotocol ForgeSdk.Owner do
  @moduledoc """
  Owner protocol.
  """

  @type t :: ForgeSdk.Owner.t()

  @fallback_to_any true

  @doc """
  Check if an asset belongs to an address or a list of address
  """
  @spec belongs_to?(t(), String.t() | [String.t()] | map()) :: boolean()
  def belongs_to?(asset, owners)
end

defimpl ForgeSdk.Owner, for: ForgeAbi.AssetState do
  @moduledoc """
  Implementation of `Owner` protocol for `AssetState`.
  """
  alias ForgeSdk.Migration

  def belongs_to?(asset, owner) when is_binary(owner), do: asset.owner === owner

  def belongs_to?(asset, owners) when is_list(owners),
    do: Enum.any?(owners, &belongs_to?(asset, &1))

  def belongs_to?(asset, %{migrated_from: _} = owner) do
    owners = Migration.get_related_addrs(owner)
    belongs_to?(asset, owners)
  end
end

defimpl ForgeSdk.Owner, for: Any do
  @moduledoc """
  Implementation of `Owner` protocol for `Any`.
  """

  def belongs_to?(_asset, _owners), do: false
end
