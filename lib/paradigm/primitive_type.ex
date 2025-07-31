defmodule Paradigm.PrimitiveType do
  @type t :: %__MODULE__{
          name: Paradigm.name()
        }
  defstruct [:name]
end
