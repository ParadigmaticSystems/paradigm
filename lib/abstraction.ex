defmodule Paradigm.Abstraction do
  @moduledoc """
  Functions for moving between Paradigm structs and corresponding graph data.
  """

  @doc """
  Takes any `Paradigm` and produces the corresponding `Paradigm.Graph.Instance` that is invariant against the Metamodel paradigm.
  """
  def embed(paradigm, graph_impl) do
    graph =
      graph_impl.new()
      |> add_primitive_types(paradigm, graph_impl)
      |> add_packages(paradigm, graph_impl)
      |> add_classes(paradigm, graph_impl)
      |> add_enumerations(paradigm, graph_impl)
      |> add_properties(paradigm, graph_impl)

    %Paradigm.Graph.Instance{
      impl: graph_impl,
      data: graph,
      name: paradigm.name,
      description: paradigm.description
    }
  end

  defp add_primitive_types(graph, paradigm, graph_impl) do
    Enum.reduce(paradigm.primitive_types, graph, fn {id, primitive_type}, acc ->
      data = %{
        "name" => primitive_type.name
      }

      graph_impl.insert_node(acc, id, "primitive_type", data)
    end)
  end

  defp add_packages(graph, paradigm, graph_impl) do
    Enum.reduce(paradigm.packages, graph, fn {id, package}, acc ->
      data = %{
        "name" => package.name,
        "uri" => package.uri,
        "nested_packages" => package.nested_packages,
        "owned_types" => package.owned_types
      }

      graph_impl.insert_node(acc, id, "package", data)
    end)
  end

  defp add_classes(graph, paradigm, graph_impl) do
    Enum.reduce(paradigm.classes, graph, fn {id, class}, acc ->
      data = %{
        "name" => class.name,
        "is_abstract" => class.is_abstract,
        "owned_attributes" => class.owned_attributes,
        "super_classes" => class.super_classes
      }

      graph_impl.insert_node(acc, id, "class", data)
    end)
  end

  defp add_enumerations(graph, paradigm, graph_impl) do
    Enum.reduce(paradigm.enumerations, graph, fn {id, enum}, acc ->
      data = %{
        "name" => enum.name,
        "literals" => enum.literals
      }

      graph_impl.insert_node(acc, id, "enumeration", data)
    end)
  end

  defp add_properties(graph, paradigm, graph_impl) do
    Enum.reduce(paradigm.properties, graph, fn {id, property}, acc ->
      data = %{
        "name" => property.name,
        "is_ordered" => property.is_ordered,
        "type" => property.type,
        "is_composite" => property.is_composite,
        "lower_bound" => property.lower_bound,
        "upper_bound" => property.upper_bound,
        "default_value" => property.default_value
      }

      graph_impl.insert_node(acc, id, "property", data)
    end)
  end

  @doc """
  Takes a `Paradigm.Graph.Instance` of metamodel type, and returns a top-level `Paradigm` object.
  """
  def extract(%Paradigm.Graph.Instance{
        impl: impl,
        data: data,
        name: name,
        description: description
      }) do
    primitive_types =
      impl.get_all_nodes_of_class(data, "primitive_type")
      |> Enum.map(fn id -> {id, impl.get_node(data, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.PrimitiveType{
           name: node.data["name"]
         }}
      end)
      |> Map.new()

    packages =
      impl.get_all_nodes_of_class(data, "package")
      |> Enum.map(fn id -> {id, impl.get_node(data, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Package{
           name: node.data["name"],
           uri: node.data["uri"],
           nested_packages: node.data["nested_packages"],
           owned_types: node.data["owned_types"]
         }}
      end)
      |> Map.new()

    classes =
      impl.get_all_nodes_of_class(data, "class")
      |> Enum.map(fn id -> {id, impl.get_node(data, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Class{
           name: node.data["name"],
           is_abstract: node.data["is_abstract"],
           owned_attributes: node.data["owned_attributes"],
           super_classes: node.data["super_classes"]
         }}
      end)
      |> Map.new()

    enumerations =
      impl.get_all_nodes_of_class(data, "enumeration")
      |> Enum.map(fn id -> {id, impl.get_node(data, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Enumeration{
           name: node.data["name"],
           literals: node.data["literals"]
         }}
      end)
      |> Map.new()

    properties =
      impl.get_all_nodes_of_class(data, "property")
      |> Enum.map(fn id -> {id, impl.get_node(data, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Property{
           name: node.data["name"],
           is_ordered: node.data["is_ordered"],
           type: node.data["type"],
           is_composite: node.data["is_composite"],
           lower_bound: node.data["lower_bound"],
           upper_bound: node.data["upper_bound"],
           default_value: node.data["default_value"]
         }}
      end)
      |> Map.new()

    %Paradigm{
      name: name,
      description: description,
      primitive_types: primitive_types,
      packages: packages,
      classes: classes,
      enumerations: enumerations,
      properties: properties
    }
  end
end
