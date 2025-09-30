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
    {:ok, transformed_universe} = Paradigm.Transform.transform(propagate(), universe, universe)
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

  def propagate() do
    Paradigm.ClassBasedTransform.new()
    |> Paradigm.ClassBasedTransform.for_class(
      "instantiation",
      &update_conformance_check_if_needed/2
    )
    |> Paradigm.ClassBasedTransform.for_class("transform", &apply_missing_transforms/2)
  end

  defp update_conformance_check_if_needed(instantiation_node, %{graph: universe}) do
    case instantiation_node.data["conformance_result"] do
      nil ->
        conformance_result = do_conformance_check(universe, instantiation_node)
        updated_data = Map.put(instantiation_node.data, "conformance_result", conformance_result)
        %Node{instantiation_node | data: updated_data}

      _ ->
        []
    end
  end

  defp do_conformance_check(universe, instantiation_node) do
    paradigm_graph_node =
      Paradigm.Graph.get_node(universe, instantiation_node.data["paradigm"].id)

    instance_graph_node =
      Paradigm.Graph.get_node(universe, instantiation_node.data["instance"].id)

    paradigm = paradigm_graph_node.data["graph"]
    instance_graph = instance_graph_node.data["graph"]
    Paradigm.Conformance.check_graph(instance_graph, paradigm)
  end

  defp apply_missing_transforms(transform_node, %{graph: universe}) do
    universe
    |> find_valid_instantiations_of(transform_node.data["source"].id)
    |> Enum.flat_map(fn instance_id ->
      case find_existing_transform_instance(universe, transform_node.id, instance_id) do
        nil ->
          create_transform_instance(universe, transform_node.id, instance_id)

        _existing ->
          []
      end
    end)
  end

  defp find_valid_instantiations_of(universe, paradigm_id) do
    instantiation_node_ids = Paradigm.Graph.get_all_nodes_of_class(universe, "instantiation")
    instantiation_nodes = Enum.map(instantiation_node_ids, &Paradigm.Graph.get_node(universe, &1))

    Enum.filter(instantiation_nodes, fn instantiation_node ->
      paradigm_id == instantiation_node.data["paradigm"].id and
        instantiation_node.data["conformance_result"] == %Paradigm.Conformance.Result{
          issues: []
        }
    end)
    |> Enum.map(fn instantiation_node -> instantiation_node.data["instance"].id end)
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

    target_graph = Paradigm.Graph.MapGraph.new(source_graph.metadata)
    {:ok, result_graph} = Paradigm.Transform.transform(transform, source_graph, target_graph)
    target_id = Paradigm.Universe.generate_graph_id(result_graph)

    [
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
          name: registered_graph.data["name"]
        }
      },
      %Node{
        id: target_id <> "_" <> transform_target.id,
        class: "instantiation",
        data: %{
          paradigm: %Ref{id: transform_target.id},
          instance: %Ref{id: target_id},
          conformance_result: nil
        }
      }
    ]
  end
end
