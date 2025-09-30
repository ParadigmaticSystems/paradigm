defmodule Paradigm.PipelineTransform do
  defstruct [:steps]

  def new(steps \\ []) when is_list(steps) do
    %__MODULE__{steps: steps}
  end

  def add_step(%__MODULE__{steps: steps} = pipeline, transformer) do
    %{pipeline | steps: steps ++ [transformer]}
  end
end

defimpl Paradigm.Transform, for: Paradigm.PipelineTransform do
  def transform(%Paradigm.PipelineTransform{steps: steps}, source, target, opts) do
    steps_with_index = Enum.with_index(steps)
    last_index = length(steps) - 1

    Enum.reduce_while(steps_with_index, {:ok, source}, fn {step, index}, {:ok, current_source} ->
      step_target =
        if index == last_index do
          # Final step writes to actual target
          target
        else
          # Intermediate step
          Paradigm.Graph.MapGraph.new()
        end

      case Paradigm.Transform.transform(step, current_source, step_target, opts) do
        {:ok, result} ->
          {:cont, {:ok, result}}

        error ->
          {:halt, error}
      end
    end)
  end
end
