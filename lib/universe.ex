defmodule Paradigm.Universe do
  @moduledoc """
    Helpers for working with content-addressed Universe graphs.
  """
  def generate_graph_id(graph) do
    Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(graph)))
    |> String.slice(-5..-1)
  end

  def insert_graph_with_paradigm(universe_graph, graph, paradigm_id) do
    id = generate_graph_id(graph)
    universe_graph
    |> Paradigm.Graph.insert_node(
      id,
      "registered_graph",
      %{
        graph: graph})
    |> Paradigm.Graph.insert_node(
     id <> "_" <> paradigm_id,
     "instantiation",
     %{
       paradigm: paradigm_id,
       instance: id,
       conformance_result: nil})
  end

  def register_transform(universe_graph, module, from, to) do
    Paradigm.Graph.insert_node(universe_graph,
      Module.split(module) |> Enum.join("."),
      "transform",
      %{
      name: Module.split(module) |> List.last(),
      module: module,
      source: from,
      target: to
      }
    )
  end

end
