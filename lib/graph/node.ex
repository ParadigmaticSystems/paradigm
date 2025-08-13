defmodule Paradigm.Graph.Node do
  @moduledoc """
  A standardized node structure to be targeted by graph data adapters.
  """

  defmodule Ref do
    @moduledoc """
    A reference to another node in the graph.
    """
    @type t :: %__MODULE__{
      id: Paradigm.id()
    }

    defstruct [:id]
  end

  @type t :: %__MODULE__{
          class: Paradigm.id(),
          data: map()
        }
  defstruct [:class, :data]
end
