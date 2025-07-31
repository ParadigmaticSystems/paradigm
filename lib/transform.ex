defmodule Paradigm.Transform do
  @moduledoc """
  Defines transformation behavior for converting graph data from one paradigm to another
  """

  alias Paradigm.Graph.Instance
  @type transform_opts :: keyword()
  @type transform_result :: {:ok, Instance.t()} | {:error, String.t()}

  @callback transform(
              source :: Instance.t(),
              target_impl :: module(),
              opts :: transform_opts()
            ) :: transform_result
end
