defmodule Paradigm.Property do
  @type t :: %__MODULE__{
          name: Paradigm.name(),
          type: Paradigm.id(),
          is_ordered: boolean(),
          is_composite: boolean(),
          lower_bound: non_neg_integer(),
          upper_bound: non_neg_integer() | :infinity,
          default_value: term() | nil,
          position: non_neg_integer()
        }
  defstruct name: nil,
            type: nil,
            is_ordered: false,
            is_composite: false,
            lower_bound: 1,
            upper_bound: 1,
            default_value: nil,
            position: 0
end
