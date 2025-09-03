ExUnit.start()

defmodule Paradigm.TestHelper do
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case

      alias Paradigm.Conformance
      alias Paradigm.Graph.MapGraph
      alias Paradigm.Graph.Node
      alias Paradigm.Graph.Node.Ref

    end
  end
end
