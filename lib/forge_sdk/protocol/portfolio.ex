defprotocol ForgeSdk.Portfolio do
  @moduledoc """
  Protocol for the portfolio for a state
  """
  alias ForgeSdk.Portfolio

  @type t :: Portfolio.t()

  @doc """
  Check if stte has sufficient funds
  """
  @spec sufficient_fund?(t(), non_neg_integer()) :: boolean()
  def sufficient_fund?(state, value)

  @doc """
  get the usable fund that an state can use. For stake, transfer, etc. We shall use this interface.
  """
  @spec get_liquidity(t()) :: non_neg_integer()
  def get_liquidity(state)

  @doc """
  get the total fund that an state can use. This includes the currency staked. For things like asset certificate. We shall use this interface.
  """
  @spec get_total_balance(t()) :: non_neg_integer()
  def get_total_balance(state)
end
