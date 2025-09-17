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

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      class: Map.get(map, "class"),
      data: parse_data(Map.get(map, "data", %{})),
      owned_by: Map.get(map, "owned_by")
    }
  end

  # Recursively parse data to handle nested refs
  defp parse_data(data) when is_map(data) do
    data
    |> Enum.map(&parse_data_entry/1)
    |> Enum.into(%{})
  end

  defp parse_data(data), do: data

  defp parse_data_entry({key, value}) when is_list(value) do
    {key, Enum.map(value, &parse_ref_or_data/1)}
  end

  defp parse_data_entry({key, value}), do: {key, parse_ref_or_data(value)}

  defp parse_ref_or_data(%{"id" => id} = map) when is_map(map) and map_size(map) <= 2 do
    # This looks like a ref if it only has id and optionally composite
    case Map.get(map, "composite") do
      composite when composite in [true, false, "true", "false"] ->
        %Paradigm.Graph.Node.Ref{
          id: id,
          composite: parse_boolean(composite)
        }
      nil ->
        %Paradigm.Graph.Node.Ref{id: id}
      _ ->
        map
    end
  end

  defp parse_ref_or_data(value), do: value

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean(bool) when is_boolean(bool), do: bool
end
