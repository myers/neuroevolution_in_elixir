# From 6.1 Simulating A Neuron
defmodule SimpleNeuron do
  require Logger

  # The create function spawns a single neuron, where the weights and the bias
  # are generated randomly to be between -0.5 and 0.5
  def create do
    weights = [:rand.uniform() - 0.5, :rand.uniform() - 0.5, :rand.uniform() - 0.5]
    Process.register(spawn(__MODULE__, :loop, [weights]), :neuron)
  end

  # The spawned neuron process accepts and input vector, prints it and the
  # weight vector to the screen, calculates the output, and then sends the
  # output to the contacting process. The outpu is also a vector of length one.
  def loop(weights) do
    receive do
      {from, input} ->
        Logger.info "**** Processing ****\n Input #{inspect input}\n Using Weigths #{inspect weights}"
        dot_product = dot(input, weights, 0)
        output = [:math.tanh(dot_product)]
        from |> send({:result, output})
        loop(weights)
    end
  end

  # The dot product function that we use works on the assumption that the bias
  # is incorporated into the weight list as the last value in that list.  After
  # calculation the dot product, the input list will empty out while the weight
  # list will still have the single biase value remaining, which we then add to
  # the accumulator.
  def dot([i | input], [w | weights], acc) do
    dot(input, weights, i*w+acc)
  end
  def dot([], [bias], acc) do
    acc + bias
  end

  # We use the sense function to contact the neuron and send it an input vector.
  # The sense function ensures that the signal we are sending is a vector of
  # length 2.
  def sense(signal) do
    case is_list(signal) and (length(signal) == 2) do
      true ->
        send(:neuron, {self(), signal})
        receive do
          {:result, output} ->
            Logger.info " Output #{inspect output}"
        end
      false ->
        Logger.info "The signal must be a list of length 2"
    end
  end
end
