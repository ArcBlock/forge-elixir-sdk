defprotocol ForgeSdk.StateDb do
  @moduledoc """
  StateDb protocol for interact with kv store
  """
  alias ForgeSdk.StateDb

  @type t :: StateDb.t()

  @doc """
  Open a database for write/read
  """
  @spec open(t()) :: {:ok, map()} | {:error, term()}
  def open(handler)

  @doc """
  Close the database
  """
  @spec close(t()) :: :ok
  def close(handler)

  @doc """
  Retrieve the state from an address
  """
  @spec get(t(), binary()) :: map() | nil
  def get(handler, address)

  @doc """
  Retrieve the state from an address by given height
  """
  @spec get(t(), binary(), non_neg_integer()) :: map() | nil
  def get(handler, address, height)

  @doc """
  Retrieve the raw state (not final) from an address, used internally for migration. No cache is needed.
  """
  @spec get_raw(t(), binary()) :: map() | binary() | nil
  def get_raw(handler, address)

  @doc """
  Put the state into to address in the db. This will lead to a change of root_hash.
  """
  @spec put(t(), binary(), map()) :: {:ok, t()} | {:error, term()}
  def put(handler, address, data)

  @doc """
  When a block is committed, record the last block and the app hash for that block. Then return the app hash.
  """
  @spec commit_block(t(), non_neg_integer()) :: binary()
  def commit_block(handler, height)

  @doc """
  Retrieve the last block height and the app_hash of the states db for a given height
  """
  @spec get_info(t(), non_neg_integer()) :: map()
  def get_info(handler, height \\ 0)

  @doc """
  Travel to different block height. The returned db handler could be used to retrieve old state from the db.
  """
  @spec travel(t(), non_neg_integer() | nil) :: t()
  def travel(handler, height)
end
