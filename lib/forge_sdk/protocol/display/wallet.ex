defimpl ForgeSdk.Display, for: ForgeAbi.WalletType do
  @moduledoc """
  Implementation of `Display` protocol for `WalletType`
  """

  def display(%{pk: pk, hash: hash, address: address, role: role} = type, expand? \\ false) do
    case expand? do
      true ->
        "#(#{pk}, #{hash}, #{address}, #{role})"

      _ ->
        basic = Map.from_struct(type)

        Map.merge(basic, %{
          address: ForgeAbi.EncodingType.value(address),
          pk: ForgeAbi.KeyType.value(pk),
          hash: ForgeAbi.HashType.value(hash),
          role: ForgeAbi.RoleType.value(role)
        })
    end
  end
end
