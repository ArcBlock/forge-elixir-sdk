defprotocol ForgeSdk.Configuration do
  @doc """
  Parse configuration (mainly expand the path and normalize things)
  """
  @spec parse(map(), map()) :: map()
  def parse(parser, config)
end
