# Paradigm Overview

Paradigm is an experimental modeling framework that focuses on the formal abstraction relationship between a model and its data. This allows for creation and manipulation of multi-layered structures. The goal is to provide a common core for integration tooling that works at the level of

* Metamodel (data interoperability, schema translation)
* Model (database migration, schema versioning)
* Data (entity analysis, data validation)

## Structure
### Paradigms
- **`Paradigm`** - Top-level data model container
- **`Paradigm.Package`** - Namespace organization
- **`Paradigm.Class`** - Entity definitions
- **`Paradigm.Property`** - Typed attributes and references
- **`Paradigm.PrimitiveType`** - Basic data types
- **`Paradigm.Enumeration`** - Constrained sets

### Graph (Data)
- **`Paradigm.Graph` Behaviour** - Pluggable graph adapters (including a simple map implementation `Paradigm.Graph.MapImpl` for in-memory work)
- **`Paradigm.Graph.Instance`** - Runtime graph object including data and implementation
- **`Paradigm.Graph.Node`** - Standardized form for individual entity instances

## Paradigm Operations
For these examples we'll use the provided Metamodel paradigm:
```elixir
metamodel_paradigm = Paradigm.Canonical.Metamodel.definition()
```
### Abstraction
`Paradigm.Abstraction` allows movement between paradigm definitions and their graph representations.

* [embed](`Paradigm.Abstraction.embed/2`) - Converts a `Paradigm` struct into a `Paradigm.Graph.Instance` that can be stored, queried, and manipulated using any graph backend
* [extract](`Paradigm.Abstraction.extract/1`) - Reconstructs a Paradigm struct from metamodel-conformant graph data

```elixir
embedded_metamodel = Paradigm.Abstraction.embed(metamodel_paradigm, Paradigm.Graph.MapImpl)
extracted_metamodel_paradigm = Paradigm.Abstraction.extract(embedded_metamodel)
extracted_metamodel_paradigm == metamodel_paradigm
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

* **`Paradigm.Transform` Behavior** defines the contract for transforms
* **`Paradigm.Transform.Identity`** transform provided for demonstration
```elixir
{:ok, transformed_graph} = Paradigm.Transform.Identity.transform(embedded_metamodel, Paradigm.Graph.MapImpl, %{})
embedded_metamodel == transformed_graph
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

Here's a basic example using the canonical metamodel:

```elixir
# Get the metamodel paradigm
paradigm = Paradigm.Canonical.Metamodel.definition()

# Embed it into a graph for manipulation
graph_instance = Paradigm.Abstraction.embed(paradigm, Paradigm.Graph.MapImpl)

# Validate that the embedded graph conforms to the metamodel
Paradigm.Conformance.check_graph(paradigm, graph_instance)
# => %Paradigm.Conformance.Result{type: :correct, problems: nil}

# Extract back to a Paradigm struct
extracted = Paradigm.Abstraction.extract(graph_instance)
# extracted == paradigm
```
