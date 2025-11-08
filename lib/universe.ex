defmodule Paradigm.Universe do
  @moduledoc """
    Helpers for working with content-addressed Universe graphs.
  """

  alias Paradigm.Graph
  alias Paradigm.Graph.Node
  alias Paradigm.Graph.Node.Ref

  def insert_graph_with_paradigm_by_name(universe, graph, name, paradigm_name) do
    paradigm_id = find_by_name(universe, paradigm_name)
    insert_graph_with_paradigm(universe, graph, name, paradigm_id)
  end

  def insert_graph_with_paradigm(universe, graph, name, paradigm_id) do
    id = Paradigm.Graph.get_content_hash(graph)

    registered_graph_node = %Node{
      id: id,
      class: "registered_graph",
      data: %{
        graph: graph,
        name: name,
        paradigm: %Ref{id: paradigm_id},
        conformance_result: nil
      }
    }

    universe
    |> Paradigm.Graph.insert_node(registered_graph_node)
  end

  def register_transform(universe, transform, from, to) do
    id = "transform_#{:erlang.unique_integer([:positive])}"

    transform_node = %Node{
      id: id,
      class: "transform",
      data: %{
        name: id,
        transform: transform,
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
    Paradigm.Graph.MapGraph.new(name: name, description: description)
    |> add_metamodel()
  end

  def add_metamodel(universe) do
    metamodel = Paradigm.Builtin.Metamodel.definition()
    metamodel_graph = metamodel |> Paradigm.Abstraction.embed()
    metamodel_id = Paradigm.Graph.get_content_hash(metamodel_graph)

    universe
    |> Paradigm.Universe.insert_graph_with_paradigm(metamodel_graph, "Metamodel", metamodel_id)
    |> apply_propagate()
  end

  def get_instantiation_node_for(universe, node_id) do
    Graph.get_node(universe, node_id)
  end

  def get_paradigm_for(universe, node_id) do
    registered_graph = Graph.get_node(universe, node_id)

    if registered_graph && registered_graph.data["paradigm"] do
      paradigm_id = registered_graph.data["paradigm"].id
      paradigm_graph = Graph.get_node(universe, paradigm_id).data["graph"]
      Paradigm.Abstraction.extract(paradigm_graph)
    end
  end

  def insert_paradigm(universe, paradigm) do
    paradigm_graph = Paradigm.Abstraction.embed(paradigm)
    metamodel_id = find_by_name(universe, "Metamodel")

    universe
    |> Paradigm.Universe.insert_graph_with_paradigm(paradigm_graph, paradigm.name, metamodel_id)
  end

  def find_by_name(universe, name) do
    Paradigm.nodes_of_type(universe, "registered_graph")
    |> Enum.find(fn node ->
      node.data["name"] == name
    end)
    |> case do
      nil -> nil
      node -> node.id
    end
  end

  def apply_propagate(universe) do
    {:ok, transformed_universe} = Paradigm.Transform.transform(propagate(), universe, universe)
    transformed_universe
  end

  def all_instantiations_conformant?(universe) do
    universe
    |> Paradigm.nodes_of_type("registered_graph")
    |> Enum.all?(fn node ->
      case node.data["conformance_result"] do
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

  def propagate() do
    Paradigm.Transform.ClassBasedTransform.new()
    |> Paradigm.Transform.ClassBasedTransform.with_default(fn node -> node end)
    |> Paradigm.Transform.ClassBasedTransform.for_class(
      "registered_graph",
      &update_conformance_check_if_needed/2
    )
    |> Paradigm.Transform.ClassBasedTransform.for_class("transform", &apply_missing_transforms/2)
  end

  defp update_conformance_check_if_needed(registered_graph_node, %{graph: universe}) do
    case registered_graph_node.data["conformance_result"] do
      nil ->
        conformance_result = do_conformance_check(universe, registered_graph_node)

        updated_data =
          Map.put(registered_graph_node.data, "conformance_result", conformance_result)

        %Node{registered_graph_node | data: updated_data}

      _ ->
        registered_graph_node
    end
  end

  defp do_conformance_check(universe, registered_graph_node) do
    if registered_graph_node.data["paradigm"] do
      paradigm_graph_node =
        Paradigm.Graph.get_node(universe, registered_graph_node.data["paradigm"].id)

      paradigm = paradigm_graph_node.data["graph"]
      instance_graph = registered_graph_node.data["graph"]
      Paradigm.Conformance.check_graph(instance_graph, paradigm)
    else
      %Paradigm.Conformance.Result{issues: []}
    end
  end

  defp apply_missing_transforms(transform_node, %{graph: universe}) do
    [transform_node] ++
      (universe
       |> find_valid_instantiations_of(transform_node.data["source"].id)
       |> Enum.flat_map(fn instance_id ->
         case find_existing_transform_instance(universe, transform_node.id, instance_id) do
           nil ->
             create_transform_instance(universe, transform_node.id, instance_id)

           _existing ->
             []
         end
       end))
  end

  defp find_valid_instantiations_of(universe, paradigm_id) do
    registered_graph_node_ids =
      Paradigm.Graph.get_all_nodes_of_class(universe, "registered_graph")

    registered_graph_nodes =
      Enum.map(registered_graph_node_ids, &Paradigm.Graph.get_node(universe, &1))

    Enum.filter(registered_graph_nodes, fn registered_graph_node ->
      (registered_graph_node.data["paradigm"] &&
         paradigm_id == registered_graph_node.data["paradigm"].id) and
        registered_graph_node.data["conformance_result"] == %Paradigm.Conformance.Result{
          issues: []
        }
    end)
    |> Enum.map(fn registered_graph_node -> registered_graph_node.id end)
  end

  defp find_existing_transform_instance(universe, transform_node_id, source_instance_id) do
    transform_instances = Paradigm.Graph.get_all_nodes_of_class(universe, "transform_instance")

    Enum.find(transform_instances, fn transform_instance_id ->
      transform_instance_node = Paradigm.Graph.get_node(universe, transform_instance_id)
      %Ref{id: transform_id} = transform_instance_node.data["transform"]
      %Ref{id: source_id} = transform_instance_node.data["source"]
      transform_id == transform_node_id && source_id == source_instance_id
    end)
  end

  defp create_transform_instance(universe, transform_node_id, source_graph_id) do
    transform_node = Paradigm.Graph.get_node(universe, transform_node_id)
    registered_graph = Paradigm.Graph.get_node(universe, source_graph_id)
    source_graph = registered_graph.data["graph"]

    %{"transform" => transform, "name" => transform_name, "target" => transform_target} =
      transform_node.data

    target_graph = Paradigm.Graph.MapGraph.new()
    {:ok, result_graph} = Paradigm.Transform.transform(transform, source_graph, target_graph)
    target_id = Paradigm.Graph.get_content_hash(result_graph)

    [
      transform_node,
      %Node{
        id: "#{transform_name}_from_#{source_graph_id}_to_#{target_id}",
        class: "transform_instance",
        data: %{
          "transform" => %Ref{id: transform_node_id},
          "source" => %Ref{id: source_graph_id},
          "target" => %Ref{id: target_id},
          "errors" => [],
          "warnings" => []
        }
      },
      %Node{
        id: target_id,
        class: "registered_graph",
        data: %{
          graph: result_graph,
          name: registered_graph.data["name"],
          paradigm: %Ref{id: transform_target.id},
          conformance_result: nil
        }
      }
    ]
  end
end
