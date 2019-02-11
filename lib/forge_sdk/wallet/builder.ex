defmodule ForgeSdk.Wallet.Builder do
  @moduledoc """
  Macro to create wallet implementations
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias ForgeSdk.Util.Validator
      alias ForgeSdk.Wallet.Util
      alias ForgeAbi.{WalletType, WalletInfo}

      @type t :: unquote(opts[:mod]).t()

      @spec create(t(), String.t()) :: WalletInfo.t() | {:error, term()}
      def create(type, passphrase \\ "") do
        type = WalletType.new(Map.from_struct(type))
        Util.create(type, passphrase)
      end

      @spec load(t(), String.t(), String.t()) :: WalletInfo.t() | {:error, term()}
      def load(_type, address, passphrase) do
        Util.load(address, passphrase)
      end

      @spec recover(t(), binary(), String.t()) :: WalletInfo.t() | {:error, term()}
      def recover(type, sk, passphrase) do
        type = WalletType.new(Map.from_struct(type))
        Util.recover(type, sk, passphrase)
      end

      @spec sign!(t(), WalletInfo.t(), binary()) :: binary()
      def sign!(_type, wallet, data) do
        Util.sign!(wallet, data)
      end

      @spec verify(t(), WalletInfo.t(), binary(), binary()) :: boolean()
      def verify(_type, wallet, data, signature) do
        Util.verify(wallet, data, signature)
      end

      @doc """
      Convert the wallet type to forge abi wallet type
      """
      @spec get_type(t()) :: WalletType.t()
      def get_type(type), do: type |> Map.from_struct() |> WalletType.new()
    end
  end
end
