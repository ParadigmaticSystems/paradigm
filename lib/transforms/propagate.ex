defmodule Paradigm.Transform.Propagate do
  @moduledoc """
  Takes a Universe graph and extends it where possible through execution of conformance checks and transforms. Source and target are the same graph so that we can reuse data and avoid copying all nodes.

  """
  @behaviour Paradigm.Transform

  alias Paradigm.Graph.Node.Ref

  @impl true
  def transform(universe, universe, _opts) do
    instantiation_nodes = Paradigm.Graph.get_all_nodes_of_class(universe, "instantiation")

    result_after_conformance =
      Enum.reduce(instantiation_nodes, universe, fn instantiation_node_id, acc_graph ->
        update_conformance_check_if_needed(acc_graph, instantiation_node_id)
      end)

    transform_nodes = Paradigm.Graph.get_all_nodes_of_class(result_after_conformance, "transform")

    result =
      Enum.reduce(transform_nodes, result_after_conformance, fn transform_node_id, acc_graph ->
        apply_transform_if_needed(acc_graph, transform_node_id)
      end)

    {:ok, result}
  end

  defp update_conformance_check_if_needed(universe, instantiation_node_id) do
    instantiation_node = Paradigm.Graph.get_node(universe, instantiation_node_id)
    case instantiation_node.data["conformance_result"] do
      nil ->
        conformance_result = do_conformance_check(universe, instantiation_node_id)
        Paradigm.Graph.insert_node(
          universe,
          instantiation_node_id,
          "instantiation",
          Map.put(instantiation_node.data, "conformance_result", conformance_result)
        )
      _ ->
        universe
    end
  end

  defp do_conformance_check(universe, instantiation_node_id) do
    paradigm_graph_node = Paradigm.Graph.follow_reference(universe, instantiation_node_id, "paradigm")
    instance_graph_node = Paradigm.Graph.follow_reference(universe, instantiation_node_id, "instance")
    paradigm = paradigm_graph_node.data["graph"]
    |> Paradigm.Abstraction.extract()
    instance_graph = instance_graph_node.data["graph"]
    Paradigm.Conformance.check_graph(paradigm, instance_graph)
  end

  defp apply_transform_if_needed(universe, transform_node_id) do
    transform_node = Paradigm.Graph.get_node(universe, transform_node_id)
    %Ref{id: source_paradigm_id} = transform_node.data["source"]
    # Find registered_graph_instance nodes that have this transform's source as their paradigm
    instantiation_node_ids = Paradigm.Graph.get_all_nodes_of_class(universe, "instantiation")
    instantiation_nodes = Enum.map(instantiation_node_ids, &Paradigm.Graph.get_node(universe, &1))
    matching_instance_ids = Enum.filter(instantiation_nodes, fn instantiation_node ->
      %Ref{id: paradigm_id} = instantiation_node.data["paradigm"]
      paradigm_id == source_paradigm_id and instantiation_node.data["conformance_result"] == %Paradigm.Conformance.Result{issues: []}
    end)
    |> Enum.map(fn instantiation_node ->
      %Ref{id: instance_id} = instantiation_node.data["instance"]
      instance_id
    end)

    Enum.reduce(matching_instance_ids, universe, fn instance_id, acc_graph ->
      case find_existing_transform_instance(acc_graph, transform_node_id, instance_id) do
        nil ->
          create_transform_instance(acc_graph, transform_node_id, instance_id)
        _existing ->
          acc_graph
      end
    end)
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
    result_graph = apply_transform(universe, transform_node, source_graph_id)
    target_id = Paradigm.Universe.generate_graph_id(result_graph)

    Paradigm.Graph.insert_node(universe, "#{transform_node.data["name"]}_from_#{source_graph_id}_to_#{target_id}", "transform_instance", %{
      "transform" => %Ref{id: transform_node_id},
      "source" => %Ref{id: source_graph_id},
      "target" => %Ref{id: target_id},
      "errors" => [],
      "warnings" => []
    })
    |> Paradigm.Graph.insert_node(target_id, "registered_graph",
    %{
      graph: result_graph
    })
  end

  defp apply_transform(universe, transform_node, source_graph_id) do
    source_graph = Paradigm.Graph.get_node(universe, source_graph_id).data["graph"]
    {:ok, result_graph} = apply(transform_node.data["module"], :transform, [source_graph, Paradigm.Graph.MapGraph.new(source_graph.metadata), %{}])
    result_graph
  end
end
