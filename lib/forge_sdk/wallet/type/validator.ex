defmodule ForgeSdk.Wallet.Type.Validator do
  @moduledoc """
  Wallet type for validator
  """
  use TypedStruct

  alias ForgeAbi.{EncodingType, HashType, KeyType, RoleType, WalletType}

  typedstruct do
    field :pk, non_neg_integer(), default: KeyType.value(:ed25519)
    field :hash, non_neg_integer(), default: HashType.value(:sha2)
    field :address, non_neg_integer(), default: EncodingType.value(:base58)
    field :role, non_neg_integer(), default: RoleType.value(:role_validator)
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Validator do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Validator
end
