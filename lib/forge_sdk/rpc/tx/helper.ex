defmodule ForgeSdk.Rpc.Tx.Helper do
  @moduledoc """
  Helper function for building tx rpc.
  """
  alias ForgeAbi.{RequestCreateTx, RequestSendTx, Transaction}
  alias ForgeSdk.Rpc
  alias ForgeSdk.Wallet.Util, as: WalletUtil

  # credo:disable-for-lines:40
  def build(type, itx, opts) do
    any = ForgeAbi.encode_any!(type, itx)

    wallet = opts[:wallet]
    address = opts[:address]
    token = Keyword.get(opts, :token, "")

    sign? = Keyword.get(opts, :sign, true)
    chan = opts[:chan]

    if (wallet === nil or wallet.sk === "") and token === "" and sign? do
      raise "Tx requires signature but no sk or valid token found"
    end

    if wallet === nil and (address === "" or address === nil) do
      raise "either wallet or address shall be provided in opts"
    end

    address = address || wallet.address

    nonce =
      case type === :poke do
        true -> 0
        false -> Enum.random(1..10_000_000_000)
      end

    case sign? do
      true ->
        case create_tx(any, nonce, wallet, address, token) do
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
        create_unsigned_tx(any, nonce, address)
    end
  end

  defp create_unsigned_tx(any, nonce, address),
    do:
      Transaction.new(
        itx: any,
        chain_id: ForgeSdk.get_env(:chain_id),
        from: address,
        nonce: nonce
      )

  defp create_tx(any, nonce, %{sk: ""} = wallet, address, token) do
    req =
      RequestCreateTx.new(
        itx: any,
        from: address,
        nonce: nonce,
        wallet: wallet,
        token: token
      )

    Rpc.create_tx(req)
  end

  defp create_tx(any, nonce, wallet, address, _token) do
    chain_id = ForgeSdk.get_env(:chain_id)

    tx =
      Transaction.new(
        itx: any,
        from: address,
        nonce: nonce,
        chain_id: chain_id
      )

    tx = %Transaction{tx | signature: <<>>}
    signature = WalletUtil.sign!(wallet, Transaction.encode(tx))
    %Transaction{tx | signature: signature}
  end

  defp send_tx(req, chan) do
    case ForgeSdk.send_tx(req, chan) do
      {:error, _} = error -> error
      res -> res
    end
  end
end
