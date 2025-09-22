ExUnit.start()
Code.require_file("support/conformance_test_suite.ex", __DIR__)
for file <- Path.wildcard(Path.join([__DIR__, "support/conformance_test_suite/*.ex"])) do
  Code.require_file(file)
end

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
