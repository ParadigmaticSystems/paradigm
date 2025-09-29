defmodule Paradigm.Transform do
  @moduledoc """
  Defines transformation behavior for converting graph data using only Graph protocol operations.
  """

  @type transform_result :: {:ok, any()} | {:error, String.t()}

  @callback transform(
              source :: any(),
              target :: any(),
              opts :: keyword()
            ) :: transform_result

  ## Helper functions for common transformation patterns
  #
  def apply_class_transforms(source, target, transformations) do
    Enum.reduce_while(transformations, {:ok, target}, fn {class, transform_fn}, {:ok, acc} ->
      case transform_nodes_of_class(source, acc, class, transform_fn) do
        {:ok, result} -> {:cont, {:ok, result}}
        error -> {:halt, error}
      end
    end)
  end

  @doc "Transform all nodes of a specific class"
  def transform_nodes_of_class(source, target, class_id, transform_fn) do
    source
    |> Paradigm.Graph.get_all_nodes_of_class(class_id)
    |> transform_nodes(source, target, transform_fn)
  end

  @doc "Transform specific nodes by ID"
  def transform_nodes(node_ids, source, target, transform_fn) do
    node_ids
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, target}, fn {node_id, index}, {:ok, acc} ->
      case Paradigm.Graph.get_node(source, node_id) do
        nil ->
          {:halt, {:error, "Node #{node_id} not found"}}

        node ->
          context = %{
            index: index,
            total_count: length(node_ids),
            source_graph: source,
            current_target: acc
          }

          case call_transform_fn(transform_fn, node_id, node.data, context) do
            # Single node result
            {:ok, %Paradigm.Graph.Node{} = new_node} ->
              {:cont, {:ok, Paradigm.Graph.insert_node(acc, new_node)}}

            # Multiple nodes result - list of Node structs
            {:ok, node_list} when is_list(node_list) ->
              case insert_node_list(acc, node_list) do
                {:ok, updated_acc} -> {:cont, {:ok, updated_acc}}
                error -> {:halt, error}
              end

            {:skip} ->
              {:cont, {:ok, acc}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp call_transform_fn(transform_fn, node_id, node_data, context) do
    case :erlang.fun_info(transform_fn, :arity) do
      {:arity, 2} ->
        transform_fn.(node_id, node_data)

      {:arity, 3} ->
        transform_fn.(node_id, node_data, context)

      {:arity, arity} ->
        {:error, "Unsupported transform function arity: #{arity}. Expected 2 or 3."}
    end
  end

  defp insert_node_list(graph, node_list) do
    Enum.reduce_while(node_list, {:ok, graph}, fn
      %Paradigm.Graph.Node{} = node, {:ok, acc} ->
        {:cont, {:ok, Paradigm.Graph.insert_node(acc, node)}}

      invalid, _acc ->
        {:halt, {:error, "Invalid node: #{inspect(invalid)}. Expected %Paradigm.Graph.Node{}"}}
    end)
  end
end
