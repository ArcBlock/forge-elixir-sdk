defprotocol ForgeSdk.Stake do
  @moduledoc """
  Stake protocol for state
  """
  alias ForgeAbi.StakeState
  alias ForgeSdk.State

  @type t :: State.t()

  @doc """
  get the total fund that an state staked.
  """
  @spec sent_value(t()) :: non_neg_integer()
  def sent_value(state)

  @doc """
  Get the list of the stakes this state carried out
  """
  @spec sent_list(t()) :: [StakeState.t()]
  def sent_list(state)

  @doc """
  Get the list of the stakes this state received
  """
  @spec received_list(t()) :: [StakeState.t()]
  def received_list(state)

  @doc """
  Get total received stakes for this state
  """
  @spec received_value(t()) :: non_neg_integer()
  def received_value(state)
end
