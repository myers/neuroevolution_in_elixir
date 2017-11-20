defmodule HillClimber.Neuron do
  defstruct id: nil, cx_id: nil, af: nil, input_id_ps: [], output_ids: []

  @doc ~S"""
  When gen/1 is executed it spawns the neuron element and immediately begins to
  wait for its initial state message.
  """
  def gen(exoself_pid) do
    spawn(fn -> loop(exoself_pid) end)
  end

  def loop(exoself_pid) do
    receive do
      {^exoself_pid, {id, cortex_pid, af, input_id_ps, output_pids}} ->
        loop(id, cortex_pid, af, {input_id_ps, input_id_ps}, output_pids, 0)
    end
  end

  @doc ~S"""
  The neuron process waits for vector signals from all the processes that it's
  connected from, taking the dot product of the input and weight vectors, and
  then adding it to the accumulator. Once all the signals from input_pids are
  received, the accumulator contains the dot product to which the neuron then
  adds the bias and executes the activation function on. After fanning out the
  output signal, the neuron again returns to waiting for incoming signals. When
  the neuron receives the {cortex_pid, get_backup} message, it forwards to the
  cortex its full m_input_id_ps list, and its Id. Once the training/learning
  algorithm is added to the system, the m_input_id_ps would contain a full set of
  the most recent and updated version of the weights.
  """
  def loop(id, cortex_pid, af, {[{input_pid, weights}|input_id_ps], m_input_id_ps}, output_pids, acc) do
    receive do
      {^input_pid, :forward, input} ->
        result = dot(input, weights, 0)
        loop(id, cortex_pid, af, {input_id_ps, m_input_id_ps}, output_pids, result+acc)
      {^cortex_pid, :get_backup} ->
        send(cortex_pid, {self(), id, m_input_id_ps})
        loop(id, cortex_pid, af, {[{input_pid, weights}|input_id_ps], m_input_id_ps}, output_pids, acc)
      {^cortex_pid, :terminate} ->
        :ok
    end
  end
  def loop(id, cortex_pid, af, {[bias], m_input_id_ps}, output_pids, acc) do
    output = apply(af, [acc+bias])
    for output_pid <- output_pids, do: send(output_pid, {self(), :forward, [output]})
    loop(id, cortex_pid, af, {m_input_id_ps, m_input_id_ps}, output_pids, 0)
  end
  def loop(id, cortex_pid, af, {[], m_input_id_ps}, output_pids, acc) do
    output = apply(af, [acc])
    for output_pid <- output_pids, do: send(output_pid, {self(), :forward, [output]})
    loop(id, cortex_pid, af, {m_input_id_ps, m_input_id_ps}, output_pids, 0)
  end

  def dot([i|input], [w|weights], acc), do: dot(input, weights, i*w+acc)
  def dot([], [], acc), do: acc

  @doc ~S"""
  Though in this current implementation the neuron has only the tanh/1 function
  available to it, we will later extend the system to allow different neurons to
  use different activation functions.
  """
  def tanh(val), do: :math.tanh(val)

end
