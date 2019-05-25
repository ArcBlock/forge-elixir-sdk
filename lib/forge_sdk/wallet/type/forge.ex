defmodule ForgeSdk.Wallet.Type.Forge do
  @moduledoc """
  Eth wallet. Just for defimpl
  """
  use TypedStruct

  typedstruct do
    field :pk, atom(), default: :ed25519
    field :hash, atom(), default: :sha3
    field :address, atom(), default: :base58
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Forge do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Forge
end
