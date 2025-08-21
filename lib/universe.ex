defmodule Paradigm.Universe do
  @moduledoc """
    Helpers for working with content-addressed Universe graphs.
  """

  alias Paradigm.Graph
  alias Paradigm.Graph.Node.Ref

  def generate_graph_id(graph) do
    Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(graph)))
    |> String.slice(-5..-1)
  end

  def insert_graph_with_paradigm(universe_graph, graph, name, paradigm_id) do
    id = generate_graph_id(graph)
    universe_graph
    |> Paradigm.Graph.insert_node(
      id,
      "registered_graph",
      %{
        graph: graph,
        name: name})
    |> Paradigm.Graph.insert_node(
     id <> "_" <> paradigm_id,
     "instantiation",
     %{
       paradigm: %Ref{id: paradigm_id},
       instance: %Ref{id: id},
       conformance_result: nil})
  end

  def register_transform(universe_graph, module, from, to) do
    Paradigm.Graph.insert_node(universe_graph,
      Module.split(module) |> Enum.join("."),
      "transform",
      %{
      name: Module.split(module) |> List.last(),
      module: module,
      source: %Ref{id: from},
      target: %Ref{id: to}
      }
    )
  end

  def bootstrap(name \\ "universe_model", description \\ "Test universe") do
    metamodel = Paradigm.Canonical.Metamodel.definition()
    metamodel_graph = metamodel |> Paradigm.Abstraction.embed()
    metamodel_id = Paradigm.Universe.generate_graph_id(metamodel_graph)
    Paradigm.Graph.MapGraph.new(name: name, description: description)
    |> Paradigm.Universe.insert_graph_with_paradigm(metamodel_graph, "Metamodel", metamodel_id)
  end

  def get_paradigm_for(universe, node_id) do
    instantiations = Graph.get_all_nodes_of_class(universe, "instantiation")
    registered_paradigm_graph = Enum.find_value(instantiations, fn inst_node_id ->
      inst_node = Graph.get_node(universe, inst_node_id)
      if inst_node.data["instance"].id == node_id do
        Graph.get_node(universe, inst_node.data["paradigm"].id)
      end
    end)

    if registered_paradigm_graph do
      Paradigm.Abstraction.extract(registered_paradigm_graph.data["graph"])
    else
      false
    end
  end

  def insert_paradigm(universe_graph, paradigm) do
    paradigm_graph = Paradigm.Abstraction.embed(paradigm)
    metamodel_id = find_by_name(universe_graph, "Metamodel")

    universe_graph
    |> Paradigm.Universe.insert_graph_with_paradigm(paradigm_graph, paradigm.name, metamodel_id)
  end

  def find_by_name(universe_graph, name) do
    Paradigm.Graph.get_all_nodes_of_class(universe_graph, "registered_graph")
    |> Enum.find(fn id ->
      Paradigm.Graph.get_node_data(universe_graph, id, "name", "") == name
    end)
  end

  def apply_propagate(universe_graph) do
    {:ok, transformed_universe} = Paradigm.Transform.Propagate.transform(universe_graph, universe_graph, %{})
    transformed_universe
  end

  def all_instantiations_conformant?(universe_graph) do
    universe_graph
    |> Graph.get_all_nodes_of_class("instantiation")
    |> Enum.all?(fn node_id ->
      case Graph.get_node_data(universe_graph, node_id, "conformance_result", nil) do
        nil -> false
        result -> result.issues == []
      end
    end)
  end

end
