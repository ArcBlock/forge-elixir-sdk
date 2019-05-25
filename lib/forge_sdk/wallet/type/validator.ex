defmodule ForgeSdk.Wallet.Type.Validator do
  @moduledoc """
  Wallet type for validator
  """
  use TypedStruct

  typedstruct do
    field :pk, atom(), default: :ed25519
    field :hash, atom(), default: :sha2
    field :address, atom(), default: :base58
    field :role, atom(), default: :role_validator
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Validator do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Validator
end
