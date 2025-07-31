defmodule Paradigm.Package do
  @type t :: %__MODULE__{
          name: Paradigm.name(),
          uri: Paradigm.id(),
          nested_packages: [Paradigm.id()],
          owned_types: [Paradigm.id()]
        }
  defstruct [:name, :uri, nested_packages: [], owned_types: []]
end
