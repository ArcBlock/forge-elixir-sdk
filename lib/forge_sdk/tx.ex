defprotocol ForgeSdk.Tx do
  @moduledoc """
  Tx protocol for manipulate inner transaction. Application could implement this interface for easy interacting with Forge SDK.
  """
  alias ForgeSdk.Tx

  alias ForgeAbi.{
    AbciContext,
    AccountState,
    RequestUpdateState,
    RequestVerifyTx,
    ResponseUpdateState,
    ResponseVerifyTx,
    Transaction
  }

  @type t :: Tx.t()

  @doc """
  Verify an inner transaction
  """
  @spec verify(t(), Transaction.t(), AccountState.t(), AbciContext.t(), RequestVerifyTx.t()) ::
          ResponseVerifyTx.t()
  def verify(itx, tx, sender, context, req)

  @doc """
  Update state after applying the transaction
  """
  @spec update(t(), Transaction.t(), AccountState.t(), AbciContext.t(), RequestUpdateState.t()) ::
          ResponseUpdateState.t()
  def update(itx, tx, sender, context, req)
end
