defmodule ForgeSdk.Rpc.Tx.Helper do
  @moduledoc """
  Helper function for building tx rpc.
  """
  alias ForgeAbi.{RequestCreateTx, RequestSendTx, Transaction}
  alias ForgeSdk.Rpc

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
    nonce = Rpc.get_nonce(address, chan)

    if nonce === 0 and type !== :declare do
      raise "There's no valid state for this wallet address. Please declare this wallet first."
    end

    nonce =
      case type === :poke do
        true -> 0
        false -> nonce
      end

    case sign? do
      true ->
        req = build_sign(any, nonce, wallet, address, token)

        case Rpc.create_tx(req, chan) do
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

  defp build_sign(any, nonce, wallet, address, token),
    do:
      RequestCreateTx.new(
        itx: any,
        from: address,
        nonce: nonce,
        wallet: wallet,
        token: token
      )

  defp send_tx(req, chan) do
    case ForgeSdk.send_tx(req, chan) do
      {:error, _} = error -> error
      res -> res
    end
  end
end
