defmodule Paradigm.Class do
  @type t :: %__MODULE__{
          name: Paradigm.name(),
          is_abstract: boolean(),
          owned_attributes: [Paradigm.id()],
          super_classes: [Paradigm.id()]
        }
  defstruct [
    :name,
    is_abstract: false,
    owned_attributes: [],
    super_classes: []
  ]
end
