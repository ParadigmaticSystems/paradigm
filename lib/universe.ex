defmodule Paradigm.Universe do
  @moduledoc """
    Helpers for working with content-addressed Universe graphs.
  """

  alias Paradigm.Graph
  alias Paradigm.Graph.Node
  alias Paradigm.Graph.Node.Ref

  def generate_graph_id(graph) do
    Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(graph)))
    |> String.slice(-5..-1)
  end

  def insert_graph_with_paradigm_by_name(universe, graph, name, paradigm_name) do
    paradigm_id = find_by_name(universe, paradigm_name)
    insert_graph_with_paradigm(universe, graph, name, paradigm_id)
  end

  def insert_graph_with_paradigm(universe, graph, name, paradigm_id) do
    id = generate_graph_id(graph)

    registered_graph_node = %Node{
      id: id,
      class: "registered_graph",
      data: %{
        graph: graph,
        name: name
      }
    }

    instantiation_node = %Node{
      id: id <> "_" <> paradigm_id,
      class: "instantiation",
      data: %{
        paradigm: %Ref{id: paradigm_id},
        instance: %Ref{id: id},
        conformance_result: nil
      }
    }

    universe
    |> Paradigm.Graph.insert_node(registered_graph_node)
    |> Paradigm.Graph.insert_node(instantiation_node)
  end

  def register_transform(universe, module, from, to) do
    node_id = Module.split(module) |> Enum.join(".")

    transform_node = %Node{
      id: node_id,
      class: "transform",
      data: %{
        name: Module.split(module) |> List.last(),
        module: module,
        source: %Ref{id: from},
        target: %Ref{id: to}
      }
    }

    Paradigm.Graph.insert_node(universe, transform_node)
  end

  def register_transform_by_name(universe, module, from_name, to_name) do
    register_transform(
      universe,
      module,
      find_by_name(universe, from_name),
      find_by_name(universe, to_name)
    )
  end

  def bootstrap(name \\ "universe_model", description \\ "Test universe") do
    metamodel = Paradigm.Builtin.Metamodel.definition()
    metamodel_graph = metamodel |> Paradigm.Abstraction.embed()
    metamodel_id = Paradigm.Universe.generate_graph_id(metamodel_graph)

    Paradigm.Graph.MapGraph.new(name: name, description: description)
    |> Paradigm.Universe.insert_graph_with_paradigm(metamodel_graph, "Metamodel", metamodel_id)
    |> apply_propagate()
  end

  def get_paradigm_for(universe, node_id) do
    instantiations = Graph.get_all_nodes_of_class(universe, "instantiation")

    registered_paradigm_graph =
      Enum.find_value(instantiations, fn inst_node_id ->
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

  def insert_paradigm(universe, paradigm) do
    paradigm_graph = Paradigm.Abstraction.embed(paradigm)
    metamodel_id = find_by_name(universe, "Metamodel")

    universe
    |> Paradigm.Universe.insert_graph_with_paradigm(paradigm_graph, paradigm.name, metamodel_id)
  end

  def find_by_name(universe, name) do
    Paradigm.Graph.get_all_nodes_of_class(universe, "registered_graph")
    |> Enum.find(fn id ->
      Paradigm.Graph.get_node_data(universe, id, "name", "") == name
    end)
  end

  def apply_propagate(universe) do
    {:ok, transformed_universe} = Paradigm.Transform.Propagate.transform(universe, universe, %{})
    transformed_universe
  end

  def all_instantiations_conformant?(universe) do
    universe
    |> Graph.get_all_nodes_of_class("instantiation")
    |> Enum.all?(fn node_id ->
      case Graph.get_node_data(universe, node_id, "conformance_result", nil) do
        nil -> false
        result -> result.issues == []
      end
    end)
  end

  def get_transform_pairs(universe) do
    # Returns tuples of source_id, target_id for all transforms that have occured.
    Paradigm.Graph.get_all_nodes_of_class(universe, "transform_instance")
    |> Enum.map(&Paradigm.Graph.get_node(universe, &1))
    |> Enum.map(fn node -> {node.data["source"].id, node.data["target"].id} end)
  end
end
