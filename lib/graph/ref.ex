defmodule Paradigm.Graph.Node.Ref do
  @moduledoc """
  A reference to another node in the graph.
  """
  @type t :: %__MODULE__{
    id: Paradigm.id(),
    composite: boolean()
  }

  defstruct [:id, composite: false]

  def from_map(%{"id" => id} = map) do
    %__MODULE__{
      id: id,
      composite: parse_boolean(Map.get(map, "composite", false))
    }
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean(bool) when is_boolean(bool), do: bool
end
