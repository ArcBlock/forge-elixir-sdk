defmodule ForgeSdk.Wallet.Type.Eth do
  @moduledoc """
  Eth wallet. Just for defimpl
  """
  use TypedStruct

  alias ForgeAbi.{EncodingType, HashType, KeyType, WalletType}

  typedstruct do
    field :pk, non_neg_integer(), default: KeyType.value(:secp256k1)
    field :hash, non_neg_integer(), default: HashType.value(:keccak)
    field :address, non_neg_integer(), default: EncodingType.value(:base16)
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Eth do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Eth
end
