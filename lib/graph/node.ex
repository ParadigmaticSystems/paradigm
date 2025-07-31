defmodule Paradigm.Graph.Node do
  @moduledoc """
  A standardized node structure to be targeted by graph data adapters.
  """
  @type t :: %__MODULE__{
          class: Paradigm.id(),
          data: map()
        }
  defstruct [:class, :data]
end
