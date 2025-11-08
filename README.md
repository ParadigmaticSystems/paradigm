# Paradigm Overview

**Paradigm** is a model management framework supporting uniform treatment of heterogeneous resources as **graph** data with **conformance** and **transformation** relationships. It provides mathematically-grounded primitives supporting protocol interoperability, model-to-code generation, and rapid integration.

Your **Universe** of discourse is bootstrapped from a built-in **metamodel** which conforms to itself. Different **Paradigms** are introduced as models for objects under scrutiny, such as filesystem contents or data models of a particular format. Graph data is decoupled from its physical form by the graph protocol. So you can have (for example) an XML file specifying the conformance of filesystem objects, or vice versa.

New levels of abstraction are created by introducing transforms at the metamodel level. For example, a schema starts as data of its metamodel, but becomes a model itself in some (hopefully obvious) way. Then we can work with data that conforms to the schema. Some illustrative demos are available at [paradigmpro.live](https://paradigmpro.live/).

## Structure

### Paradigms
- **`Paradigm`** - Top-level data model container
- **`Paradigm.Package`** - Namespace organization
- **`Paradigm.Class`** - Entity definitions
- **`Paradigm.Property`** - Typed attributes and references
- **`Paradigm.PrimitiveType`** - Basic data types
- **`Paradigm.Enumeration`** - Constrained sets

### Graph (Data)
- **`Paradigm.Graph` Protocol** - A set of functions for accessing graph nodes
- **`Paradigm.Graph.Node`** - Standardized form for individual entity instances
- **`Paradigm.Graph.MapGraph`** - An in-memory graph implementation
- **`Paradigm.Graph.FilesystemGraph`** - Provides folder and file nodes from local storage
- **`Paradigm.Graph.Canonical`** - Provides methods for switching between Elixir structs and Graphs.

## Paradigm Operations
For these examples we'll use the provided Metamodel paradigm:
```elixir
metamodel_paradigm = Paradigm.Builtin.Metamodel.definition()
```
### Abstraction
`Paradigm.Abstraction` allows movement between paradigm definitions and their graph representations.

* [embed](`Paradigm.Abstraction.embed/2`) - Embeds a `Paradigm` struct into a `Paradigm.Graph` (an empty MapGraph by default)
* [extract](`Paradigm.Abstraction.extract/1`) - Reconstructs a Paradigm struct from metamodel-conformant graph data

Any valid `Paradigm` struct should round-trip:
```elixir
embedded_metamodel = Paradigm.Abstraction.embed(metamodel_paradigm)
Paradigm.Abstraction.extract(embedded_metamodel) == metamodel_paradigm
```

### Conformance
`Paradigm.Conformance.check_graph/2` validates that graph data conforms to its paradigm definition. The conformance checker ensures data integrity by validating:

* Class validity - All nodes reference defined classes
* Property completeness - Required properties are present, unknown properties flagged
* Cardinality constraints - List/single value requirements met
* Reference integrity - All references point to existing nodes of correct classes
* Enumeration values - Values match defined enum options

The embedded metamodel validates against itself:
```elixir
Paradigm.Conformance.check_graph(embedded_metamodel, metamodel_paradigm)
```

Or if 2 graph objects are passed, the module will attempt to use the `Abstraction` module to produce a paradigm from the 2nd one:
```elixir
Paradigm.Conformance.check_graph(embedded_metamodel, embedded_metamodel)
```

## Transforms

The `Paradigm.Transform` protocol defines how transforms are handled.

They are invoked with `transform(transformer, source, target, opts)`.
* transformer implements the transform protocol
* source is a graph
* target is a graph (not necessarily different or empty, just where new nodes will be added)
* opts allows configuration.

A simple helper function handles the configuration-free transform case holding the results in memory:
```elixir
  def transform(transformer, source) do
    target = Paradigm.Graph.MapGraph.new()
    Paradigm.Transform.transform(transformer, source, target, [])
  end
```

### Function transforms
The transform protocol is implemented for `Function` in the obvious way so that anonymous functions may be used. Here's a simple injection function:
```elixir
fn source, target ->
  {:ok,
    Paradigm.Graph.stream_all_nodes(source)
    |> Enum.reduce(target, fn node, acc_target ->
      Paradigm.Graph.insert_node(acc_target, node)
    end)
  }
end
```

### Class-based transforms
`Paradigm.Transform.ClassBasedTransform` encapsulates a common pattern:
1) Select all nodes of a given type
2) For each one, produce 1 or more resulting nodes
3) Reduce across the target graph, inserting them all
We can get rid of a lot of repeated code with a builder pattern:
```elixir
import Paradigm.Transform.ClassBasedTransform
new()
|> with_default(fn node -> node end) # Copy all by default
|> rename_class("class1", "class2")  # A simple rename helper
|> for_class("strange_type",
  fn node ->
    %{node | data: %{}}              # Copy over with blanked data
  end)
|> for_class("multi_type",           # Return a list of nodes
  fn node ->
    [
      %Node{id: node.id <> "_1", ...},
      %Node{id: node.id <> "_2", ...}
    ]
  end)
|> for_class("insufficient_context_type",
  fn node, graph ->                 # Function can take 2 args
    #Pull in additional information to build the node
  end
  )
```
Here you can see the flexibility, as the class-based transform function has access to the node and the full graph, and returns an arbitrary list of nodes.

### Pipeline Transforms
`Paradigm.Transform.PipelineTransform` allows transforms to be composed arbitrarily.

```elixir
PipelineTransform.new([transform1, transform2, transform3])
```

Note that intermediate steps automatically target a `MapGraph.new()`.
This means memory should be considered, and "cumulative" effects need to be explicitly carried forward by each step.

## Universe Paradigm
The `Paradigm.Builtin.Universe` paradigm is a system-level model treating `Paradigm.Graph` and `Paradigm.Transform` objects as primitive types. The `Paradigm.Universe` module provides helper functions for working with Universe graphs, including content-addressed (inner) graphs.

* `Paradigm.Universe.bootstrap/0` sets up the builtin metamodel self-realization relationship.
* `Paradigm.Universe.apply_propagate/1` applies a propagation transform that looks for places to apply conformance checks or internal transforms.

The result is all the embedding, conformance checking and transforms above are achieved more ergonomically *internal* to a `Universe`-conformant graph:

```elixir
Paradigm.Universe.bootstrap()
|> Paradigm.Universe.register_transform_by_name(Paradigm.Transform.Identity, "Metamodel", "Metamodel")
|> Paradigm.Universe.apply_propagate()
|> Paradigm.Conformance.conforms?(Paradigm.Builtin.Universe.definition())
```

## Installation

If available in [Hex](https://hex.pm/docs/publish), add `paradigm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paradigm, "~> 0.3.0"}
  ]
end
```

Or install directly from GitHub:

```elixir
def deps do
  [
    {:paradigm, github: "ParadigmaticSystems/paradigm"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

Here's a basic example using the builtin metamodel:

```elixir
# Get the metamodel paradigm
paradigm = Paradigm.Builtin.Metamodel.definition()

# Embed it into a graph for manipulation
graph = Paradigm.Abstraction.embed(paradigm)

# Validate that the embedded graph conforms to the metamodel
Paradigm.Conformance.check_graph(graph, paradigm)
# => %Paradigm.Conformance.Result{issues: []}

# Extract back to a Paradigm struct
extracted_paradigm = Paradigm.Abstraction.extract(graph)
# extracted_paradigm == paradigm
```
