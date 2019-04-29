defmodule ForgeSdk.Rpc.Tx.Helper do
  @moduledoc """
  Helper function for building tx rpc.
  """
  alias ForgeAbi.{RequestCreateTx, RequestSendTx, Transaction}
  alias ForgeSdk.Rpc
  alias ForgeSdk.Wallet.Util, as: WalletUtil

  # credo:disable-for-lines:40
  def build(itx, opts) do
    type_url = ForgeAbi.get_type_url(itx.__struct__)
    any = ForgeAbi.encode_any!(itx, type_url)

    wallet = opts[:wallet]
    token = Keyword.get(opts, :token, "")

    sign? = Keyword.get(opts, :sign, true)
    chan = opts[:chan]

    if wallet === nil do
      raise "wallet shall be provided in opts"
    end

    if wallet.sk === "" and token === "" and sign? do
      raise "Tx requires signature but no sk or valid token found"
    end

    # TODO: here we need to rethink this
    nonce =
      case type_url in ["fg:t:poke", "fg:t:deploy_protocol"] do
        true -> 0
        false -> Enum.random(1..10_000_000_000)
      end

    case sign? do
      true ->
        case create_tx(any, nonce, wallet, token) do
          {:error, _} = error ->
            error

          tx ->
            case Keyword.get(opts, :send, :broadcast) do
              :broadcast -> send_tx(RequestSendTx.new(tx: tx), chan)
              :commit -> send_tx(RequestSendTx.new(tx: tx, commit: true), chan)
              :nosend -> tx
            end
        end

      false ->
        create_unsigned_tx(any, nonce, wallet)
    end
  end

  def preprocess_deploy_protocol(itx, _) do
    address = ForgeSdk.Util.to_tx_address(itx)
    %{itx | address: address}
  end

  def preprocess_account_migrate(itx, _) do
    case itx.address === "" and itx.pk !== "" and itx.type !== nil do
      true -> %{itx | address: ForgeSdk.Wallet.Util.to_address(itx.pk, itx.type)}
      false -> itx
    end
  end

  # private functions
  defp create_unsigned_tx(any, nonce, wallet),
    do:
      Transaction.new(
        itx: any,
        from: wallet.address,
        nonce: nonce,
        chain_id: ForgeSdk.get_env(:chain_id),
        pk: wallet.pk
      )

  defp create_tx(any, nonce, %{sk: ""} = wallet, token) do
    req =
      RequestCreateTx.new(
        itx: any,
        from: wallet.address,
        nonce: nonce,
        wallet: wallet,
        token: token
      )

    Rpc.create_tx(req)
  end

  defp create_tx(any, nonce, wallet, _token) do
    tx =
      Transaction.new(
        itx: any,
        from: wallet.address,
        nonce: nonce,
        chain_id: ForgeSdk.get_env(:chain_id),
        pk: wallet.pk
      )

    tx = %Transaction{tx | signature: <<>>}
    signature = WalletUtil.sign!(wallet, Transaction.encode(tx))
    %Transaction{tx | signature: signature}
  end

  defp send_tx(req, chan) do
    case ForgeSdk.Rpc.send_tx(req, chan) do
      {:error, _} = error -> error
      res -> res
    end
  end
end
