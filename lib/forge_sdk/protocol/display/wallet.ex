defimpl ForgeSdk.Display, for: ForgeAbi.WalletType do
  @moduledoc """
  Implementation of `Display` protocol for `WalletType`
  """

  def display(%{pk: pk, hash: hash, address: address, role: role} = type, expand? \\ false) do
    case expand? do
      true -> "#(#{pk}, #{hash}, #{address}, #{role})"
      _ -> type
    end
  end
end
