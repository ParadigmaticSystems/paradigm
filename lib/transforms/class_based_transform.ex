defmodule Paradigm.ClassBasedTransform do
  defstruct transforms: %{}, default_transform: nil

  def new(opts \\ []) do
    default = Keyword.get(opts, :default, fn _node -> [] end)
    %__MODULE__{default_transform: default}
  end

  def for_class(%__MODULE__{} = builder, class, transform_fn) do
    put_in(builder.transforms[class], transform_fn)
  end

  def skip_class(%__MODULE__{} = builder, class) do
    for_class(builder, class, fn _node -> [] end)
  end

  def rename_class(%__MODULE__{} = builder, class, new_name) do
    for_class(builder, class, fn node ->
      %{node | class: new_name}
    end)
  end

  def copy_class(%__MODULE__{} = builder, class) do
    for_class(builder, class, fn node ->
      node
    end)
  end

  def with_default(%__MODULE__{} = builder, transform_fn) do
    %{builder | default_transform: transform_fn}
  end
end

defimpl Paradigm.Transform, for: Paradigm.ClassBasedTransform do
  def transform(%Paradigm.ClassBasedTransform{} = transformer, source, target, _opts) do
    source
    |> Paradigm.Graph.stream_all_nodes()
    |> Enum.reduce_while({:ok, target}, fn node, {:ok, acc} ->
      transform_fn = Map.get(transformer.transforms, node.class, transformer.default_transform)

      result =
        case :erlang.fun_info(transform_fn, :arity) do
          {:arity, 1} -> transform_fn.(node)
          {:arity, 2} -> transform_fn.(node, %{graph: source})
        end

      case result do
        [] -> {:cont, {:ok, acc}}
        nodes when is_list(nodes) -> insert_nodes_result(acc, nodes)
        %Paradigm.Graph.Node{} = single -> {:cont, {:ok, Paradigm.Graph.insert_node(acc, single)}}
        {:skip} -> {:cont, {:ok, acc}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp insert_nodes_result(acc, nodes) do
    case insert_node_list(acc, nodes) do
      {:ok, updated} -> {:cont, {:ok, updated}}
      error -> {:halt, error}
    end
  end

  defp insert_node_list(graph, node_list) do
    Enum.reduce_while(node_list, {:ok, graph}, fn
      %Paradigm.Graph.Node{} = node, {:ok, acc} ->
        {:cont, {:ok, Paradigm.Graph.insert_node(acc, node)}}

      invalid, _acc ->
        {:halt, {:error, "Invalid node: #{inspect(invalid)}"}}
    end)
  end
end
