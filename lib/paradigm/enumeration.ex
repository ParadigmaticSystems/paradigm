defmodule Paradigm.Enumeration do
  @type t :: %__MODULE__{
          name: Paradigm.name(),
          literals: [String.t()]
        }
  defstruct [:name, literals: []]
end
