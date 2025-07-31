defmodule Paradigm.Graph.Instance do
  @moduledoc """
  A wrapper object with everything required to access graph data.
  """

  @type t :: %__MODULE__{
          impl: module(),
          data: any(),
          name: String.t(),
          description: String.t()
        }

  defstruct [:impl, :data, :name, :description]

  def new(impl, data, name \\ nil, description \\ nil) do
    %__MODULE__{impl: impl, data: data, name: name, description: description}
  end
end
