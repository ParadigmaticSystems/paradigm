defmodule Paradigm.Graph.Node.Ref do
  @moduledoc """
  A reference to another node in the graph.
  """
  @type t :: %__MODULE__{
    id: Paradigm.id(),
    composite: boolean()
  }

  defstruct [:id, composite: false]
end
