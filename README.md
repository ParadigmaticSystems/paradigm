# Paradigm Overview

**Paradigm** is a framework for the uniform treatment of different objects as **graph** data with **conformance** and **transformation** relationships. It provides mathematically-grounded primitives for protocol interoperability and model-to-code generation.

Your **Universe** of discourse is bootstrapped from a built-in **meta-metamodel** which conforms to itself. Different **Paradigms** are introduced as meta-models for objects under scrutiny, such as filesystem contents or data models of a particular format.

New levels of abstraction are created by introducing transforms at the metamodel level. For example, a schema starts as data of its metamodel, but becomes a model itself in some obvious way. Then we can work with data that conforms to the schema.

Graph data is decoupled from its physical form by the graph protocol. So you can have (for example) an XML file specifying the conformance of filesystem objects, or vice versa.

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

Or if a graph is passed, the module will attempt to extract a paradigm:
```elixir
Paradigm.Conformance.check_graph(embedded_metamodel, embedded_metamodel)
```

### Transform

* **`Paradigm.Transform` Behavior** defines the contract for transform modules
* **`Paradigm.Transform.Identity`** transform provided for demonstration

The transform module requires a target graph which doesn't necessarily need to be empty.
```elixir
target_graph = Paradigm.Graph.MapGraph.new()
{:ok, transformed_graph} = Paradigm.Transform.Identity.transform(embedded_metamodel, target_graph, %{})
embedded_metamodel == transformed_graph
```

## Universe Paradigm
The `Paradigm.Builtin.Universe` paradigm is a system-level model treating `Paradigm.Graph` and `Paradigm.Transform` objects as primitive types. The `Paradigm.Universe` module provides helper functions for working with Universe graphs, including content-addressed (inner) graphs.

* `Paradigm.Universe.bootstrap/0` sets up the builtin metamodel self-realization relationship.
* `Paradigm.Universe.apply_propagate/1` applies the `Paradigm.Transform.Propagate` transform. This looks for places to apply conformance checks or internal transforms.

So all the embedding, conformance checking and transforms above are achieved more ergonomically *internal* to a `Universe`-conformant graph:

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
    {:paradigm, "~> 0.1.0"}
  ]
end
```

Or install directly from GitHub:

```elixir
def deps do
  [
    {:paradigm, github: "roriholm/paradigm"}
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
