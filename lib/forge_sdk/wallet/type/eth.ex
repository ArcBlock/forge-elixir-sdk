defmodule ForgeSdk.Wallet.Type.Eth do
  @moduledoc """
  Eth wallet. Just for defimpl
  """
  use TypedStruct

  typedstruct do
    field :pk, atom(), default: :secp256k1
    field :hash, atom(), default: :keccak
    field :address, atom(), default: :base16
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Eth do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Eth
end
