defmodule ForgeSdk.Wallet.Type.Node do
  @moduledoc """
  Wallet type for node.
  """
  use TypedStruct

  typedstruct do
    field :pk, atom(), default: :ed25519
    field :hash, atom(), default: :sha2
    field :address, atom(), default: :base58
    field :role, atom(), default: :role_node
  end
end

defimpl ForgeSdk.Wallet, for: ForgeSdk.Wallet.Type.Node do
  use ForgeSdk.Wallet.Builder, mod: ForgeSdk.Wallet.Type.Node
end
