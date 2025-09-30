defprotocol Paradigm.Transform do
  @doc """
  Transform a source graph into a target graph.
  """
  @spec transform(t(), source :: any(), target :: any(), opts :: keyword()) ::
          {:ok, any()} | {:error, String.t()}
  def transform(transformer, source, target, opts \\ [])
end

defimpl Paradigm.Transform, for: Function do
  def transform(fun, source, target, opts) when is_function(fun, 3) do
    fun.(source, target, opts)
  end

  def transform(fun, source, target, _opts) when is_function(fun, 2) do
    fun.(source, target)
  end
end
