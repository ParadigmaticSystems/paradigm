defmodule Paradigm.Transform do
  @moduledoc """
  Defines transformation behavior for converting graph data using only Graph protocol operations.
  """

  @type transform_result :: {:ok, any()} | {:error, String.t()}

  @callback transform(
              source :: any(),
              target :: any(),
              opts :: keyword()
            ) :: transform_result
end
