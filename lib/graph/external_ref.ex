defmodule Paradigm.Graph.Node.ExternalRef do
  @moduledoc """
  A reference to an element outside the current graph/model.
  """
  @type t :: %__MODULE__{
    href: String.t(),
    type: String.t() | nil
  }

  defstruct [:href, :type]

  def from_map(%{"href" => href} = map) do
    %__MODULE__{
      href: href,
      type: Map.get(map, "type")
    }
  end
end
