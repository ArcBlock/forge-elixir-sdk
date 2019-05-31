defprotocol ForgeSdk.Wallet do
  @moduledoc """
  Wallet protocol for manipulate wallet
  """
  alias ForgeSdk.Wallet

  @type t :: Wallet.t()

  alias ForgeAbi.{WalletInfo, WalletType}

  @doc """
  Create a wallet
  """
  @spec create(t()) :: WalletInfo.t() | {:error, term()}
  def create(type)

  @doc """
  Sign the data with wallet
  """
  @spec sign!(t(), WalletInfo.t(), binary()) :: binary()
  def sign!(type, wallet, data)

  @doc """
  Verify the signature of the transaction with a given wallet
  """
  @spec verify(t(), WalletInfo.t(), binary(), binary()) :: boolean()
  def verify(type, wallet, data, signature)

  @doc """
  Convert the wallet type to forge abi wallet type
  """
  @spec get_type(t()) :: WalletType.t()
  def get_type(type)
end
