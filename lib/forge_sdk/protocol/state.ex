defprotocol ForgeSdk.State do
  @moduledoc """
  State protocol for creating or updating a state in state db
  """
  alias ForgeAbi.AbciContext
  alias ForgeSdk.State

  @type t :: State.t()

  @doc """
  Create a state
  """
  @spec create(t(), map(), AbciContext.t() | nil) :: map()
  def create(state, attrs, context)

  @doc """
  update a state with the give attributes and context.
  """
  @spec update(t(), map(), AbciContext.t()) :: map()
  def update(state, attrs, context)

  @doc """
  update a state with the forge app returned data.
  """
  @spec update_app_data(t(), map(), AbciContext.t()) :: map()
  def update_app_data(state, data, context)
end
