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
  @spec create(t(), String.t()) :: WalletInfo.t() | {:error, term()}
  def create(type, passphrase \\ "")

  @doc """
  Load a saved account into memory
  """
  @spec load(t(), String.t(), String.t()) :: WalletInfo.t() | {:error, term()}
  def load(type, address, passphrase)

  @doc """
  Recover an account from a secret key or a set of seed words
  """
  @spec recover(t(), binary(), String.t()) :: WalletInfo.t() | {:error, term()}
  def recover(type, sk, passphrase)

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
