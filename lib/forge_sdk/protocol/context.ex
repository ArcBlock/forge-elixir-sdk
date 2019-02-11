defprotocol ForgeSdk.State.Context do
  @moduledoc """
  State context protocol
  """

  alias ForgeSdk.State.Context

  @type t :: Context.t()

  @doc """
  Create a state context
  """
  @spec create(t(), map()) :: t()
  def create(context, attrs)

  @doc """
  Update a state context
  """
  @spec update(t(), map()) :: t()
  def update(context, attrs)
end
