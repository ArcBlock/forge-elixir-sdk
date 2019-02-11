defimpl ForgeSdk.Display, for: ForgeAbi.WalletType do
  @moduledoc """
  Implementation of `Display` protocol for `WalletType`
  """

  alias ForgeAbi.{KeyType, HashType, EncodingType}

  def display(%{pk: pk, hash: hash, address: address} = type, expand? \\ false) do
    case expand? do
      true -> "#(#{KeyType.key(pk)}, #{HashType.key(hash)}, #{EncodingType.key(address)})"
      _ -> type
    end
  end
end
