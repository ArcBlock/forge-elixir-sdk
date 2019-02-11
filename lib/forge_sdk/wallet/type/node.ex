defmodule ForgeSdk.Wallet.Type.Node do
  @moduledoc """
  Wallet type for node.
  """
  use TypedStruct

  alias ForgeAbi.{EncodingType, HashType, KeyType, RoleType, WalletType}

  typedstruct do
    field :pk, non_neg_integer(), default: KeyType.value(:ed25519)
    field :hash, non_neg_integer(), default: HashType.value(:sha3)
    field :address, non_neg_integer(), default: EncodingType.value(:base58)
    field :role, non_neg_integer(), default: RoleType.value(:role_node)
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Node do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Node
end
