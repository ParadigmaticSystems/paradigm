# Paradigm Overview

**Paradigm** is an experimental modeling framework that focuses on the formal abstraction relationship between a model and its data. This allows for creation and manipulation of multi-layered structures working at the level of:

* meta-model (data interoperability, schema translation)
* model (database migration, schema versioning)
* data (entity analysis, data validation)

The end goal is to characterize complex heterogeneous systems across multi-step transformation pipelines including schema uptake, code generation, and integration tests. First-class treatment of arbitrary Filesystem objects and Shell operations allow for:

* flexible levels of descriptive granularity
* quick integration of existing tools
* traceability and provenance by default

This provides an ergonomic core for next-generation MBSE tooling.

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

## Paradigm Operations
For these examples we'll use the provided Metamodel paradigm:
```elixir
metamodel_paradigm = Paradigm.Canonical.Metamodel.definition()
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
Paradigm.Conformance.check_graph(metamodel_paradigm, embedded_metamodel)
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
`Paradigm.Canonical.Universe` is a system-level model treating `Paradigm.Graph` and `Paradigm.Transform` objects as primitive types. Then the actual built-in operations can be used in transform modules. The `Paradigm.Universe` module supports content-addressed graphs, which is useful for round-tripping and equality checks on transforms.

### Propagate
The `Paradigm.Transform.Propagate` transform module takes `Universe`->`Universe` where any potential conformance checks or transformations are applied. So all the stuff we did in the above section can be achieved *internally* in a `Universe`-conformant graph:

* Paradigm conformance is checked by `Paradigm.Abstraction.extract/1` and `Paradigm.Conformance.check_graph/2`. The Universe does not contain Paradigms- only Graphs, with all relationships bootstrapped by the metamodel's self-relationship.
* Transforms, registered against source and target paradigms, leave `TransformInstance` elements for tracing the flow of data. So we see, for example, that `Paradigm.Transform.Identity` leaves a `TransformInstance` with the same source and target id - indicating equality.

```elixir
metamodel_graph = Paradigm.Canonical.Metamodel.definition()
|> Paradigm.Abstraction.embed()
metamodel_id = Paradigm.Universe.generate_graph_id(metamodel_graph)
universe_instance = Paradigm.Graph.MapGraph.new()
|> Paradigm.Universe.insert_graph_with_paradigm(metamodel_graph, metamodel_id)
|> Paradigm.Universe.register_transform(Paradigm.Transform.Identity, metamodel_id, metamodel_id)

{:ok, transformed_universe} = Paradigm.Transform.Propagate.transform(universe_instance, universe_instance, %{})
```

Conformance checks and transform results can be observed in `transformed_universe`.
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

Here's a basic example using the canonical metamodel:

```elixir
# Get the metamodel paradigm
paradigm = Paradigm.Canonical.Metamodel.definition()

# Embed it into a graph for manipulation
graph_instance = Paradigm.Abstraction.embed(paradigm)

# Validate that the embedded graph conforms to the metamodel
Paradigm.Conformance.check_graph(paradigm, graph_instance)
# => %Paradigm.Conformance.Result{issues: []}

# Extract back to a Paradigm struct
extracted = Paradigm.Abstraction.extract(graph_instance)
# extracted == paradigm
```
