defprotocol ForgeSdk.Migration do
  @moduledoc """
  State migration protocol for recursively find the right state
  """
  alias ForgeSdk.{State, StateDb}

  @type t :: State.t()

  @fallback_to_any true

  @doc """
  Check if a state is migrated
  """
  @spec migrated?(t()) :: boolean()
  def migrated?(state)

  @spec get_related_addrs(t()) :: [t()]
  def get_related_addrs(state)

  @spec get_final_state(t(), StateDb.t() | nil) :: t()
  def get_final_state(state, db \\ nil)
end

defimpl ForgeSdk.Migration, for: Any do
  def migrated?(_), do: false
  def get_related_addrs(state), do: [state]
  def get_final_state(state, _), do: state
end
