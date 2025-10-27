defmodule Paradigm.Class do
  @type t :: %__MODULE__{
          name: Paradigm.name(),
          is_abstract: boolean(),
          properties: %{Paradigm.name() => Paradigm.Property.t()},
          super_classes: [Paradigm.id()]
        }
  defstruct [
    :name,
    is_abstract: false,
    properties: %{},
    super_classes: []
  ]
end
