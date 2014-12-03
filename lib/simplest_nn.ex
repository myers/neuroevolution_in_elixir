# From 6.2 A One Neuron Neural Network
defmodule SimplestNN do
  # The create function first generates 3 weights, with the 3rd weigth being the
  # bias. The neuron is spawed first, and is then sent the pids of the sensor
  # and actuator that it's connected with.  Then the cortex element is
  # registered and provided with the pids of all the elements in the NN system.
  def create do
    weights = [:random.uniform() - 0.5, :random.uniform() - 0.5, :random.uniform() - 0.5]
    n_pid = spawn __MODULE__, :neuron, [weights, nil, nil]
    s_pid = spawn __MODULE__, :sensor, [n_pid]
    a_pid = spawn __MODULE__, :actuator, [n_pid]
    n_pid |> send({:init, s_pid, a_pid})
    Process.register(spawn(__MODULE__, :cortex, [s_pid, n_pid, a_pid]), :cortex)
  end

  # After the neuron finishes setting its s_pid and a_pid to that of the senor
  # and actuator respectively, it starts waiting for the incoming signals.  The
  # neuron expects a vector of length 2 as input, and as soon as the input
  # arrives, the neuron processes the signal and passes the output vector to the
  # outgoing a_pid
  def neuron(weights, _s_pid, a_pid) do
    receive do
      {_s_pid, :forward, input} ->
        IO.puts "**** Thinking ****\n Input: #{inspect input}\n with weights: #{inspect weights}"
        dot_product = dot(input, weights, 0)
        output = [:math.tanh(dot_product)]
        a_pid |> send({self, :forward, output})
        neuron(weights, _s_pid, a_pid)
      {:init, new_s_pid, new_a_pid} ->
        neuron(weights, new_s_pid, new_a_pid)
      :terminate ->
        :ok
    end
  end

  # The dot function take a dot product of two vectors, it can operate on a
  # weight vector with and without a bias.  When there is no bias in the weight
  # list, both the input vector and the weight vector are of the same length.
  # When bias is present, then when the input list empties out, the weights list
  # still has 1 value remaining, its bias.
  def dot([i | input], [w | weights], acc) do
    dot(input, weights, i*w+acc)
  end
  def dot([], [bias], acc) do
    acc + bias
  end

  # The sensor function waits to be triggered by the cortex element, and then
  # produces a random vector of length 2, which it passes to the connected
  # neuron.  In a proper system the sensory signal would not be a random vector
  # but instead would be produced by a function associated with the sensor, a
  # function that for example reads and vector-encodes a signal coming from a
  # GPS attached to a robot
  def sensor(n_pid) do
    receive do
      :sync ->
        sensory_signal = [:random.uniform, :random.uniform]
        IO.puts "**** Sensing ****\n Signal from the env #{inspect sensory_signal}"
        n_pid |> send({self, :forward, sensory_signal})
      :terminate ->
        :ok
    end
  end

  # The actuator function waits for a control signal coming from a neuron.  As
  # soon as the signal arrives, the actuator executes its function pts/1, which
  # prints the value to the screen.
  def actuator(_n_pid) do
    receive do
      {_n_pid, :forward, control_signal} ->
        pts(control_signal)
        actuator(_n_pid)
      :terminate ->
        :ok
    end
  end

  def pts(control_signal) do
    IO.puts "**** Acting ****\n Using: #{inspect control_signal} to act on env"
  end

  # The cortex function triggers the sensor to action when commanded by the
  # user.  This process also has all the pids of the elements in the NN system,
  # so that it can terminate the whole system when requested.
  def cortex(s_pid, n_pid, a_pid) do
    receive do
      :sense_think_act ->
        s_pid |> send(:sync)
        cortex(s_pid, n_pid, a_pid)
      :terminate ->
        s_pid |> send(:terminate)
        n_pid |> send(:terminate)
        a_pid |> send(:terminate)
        :ok
    end
  end
end