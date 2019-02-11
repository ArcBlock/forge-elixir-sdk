defmodule ForgeSdk.Wallet.Type.Forge do
  @moduledoc """
  Eth wallet. Just for defimpl
  """
  use TypedStruct

  alias ForgeAbi.{EncodingType, HashType, KeyType, WalletType}

  typedstruct do
    field :pk, non_neg_integer(), default: KeyType.value(:ed25519)
    field :hash, non_neg_integer(), default: HashType.value(:sha3)
    field :address, non_neg_integer(), default: EncodingType.value(:base58)
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Forge do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Forge
end
