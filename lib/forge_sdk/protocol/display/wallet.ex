defimpl ForgeSdk.Display, for: ForgeAbi.WalletType do
  @moduledoc """
  Implementation of `Display` protocol for `WalletType`
  """

  alias ForgeAbi.{EncodingType, HashType, KeyType, RoleType}

  def display(%{pk: pk, hash: hash, address: address} = type, expand? \\ false) do
    case expand? do
      true ->
        "#(#{KeyType.key(pk)}, #{HashType.key(hash)}, #{EncodingType.key(address)}, #{
          RoleType.key(type.role)
        })"

      _ ->
        type
    end
  end
end
