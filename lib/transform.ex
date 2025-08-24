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
    Enum.reduce_while(node_ids, {:ok, target}, fn node_id, {:ok, acc} ->
      case Paradigm.Graph.get_node(source, node_id) do
        nil ->
          {:halt, {:error, "Node #{node_id} not found"}}

        node ->
          case transform_fn.(node_id, node.data) do
            {:ok, {new_id, new_class, new_data}} ->
              {:cont, {:ok, Paradigm.Graph.insert_node(acc, new_id, new_class, new_data)}}

            {:skip} ->
              {:cont, {:ok, acc}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
      end
    end)
  end
end
