defmodule Paradigm.Graph.Node do
  @moduledoc """
  A standardized node structure to be targeted by graph data adapters.
  """

  @type t :: %__MODULE__{
          id: Paradigm.id(),
          class: Paradigm.id(),
          data: map(),
          owned_by: Paradigm.id() | nil
        }
  defstruct [:id, :class, :data, owned_by: nil]
end
