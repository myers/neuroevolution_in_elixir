defmodule FFNN.Actuator do
  defstruct id: nil, cx_id: nil, name: nil, vl: nil, fanin_ids: []

  @doc ~S"""
  When `gen/1` is executed it spawns the actuator element and immediately begins
  to wait for its initial state message.
  """
  def gen(exoself_pid) do
    spawn(fn() -> loop(exoself_pid) end)
  end

  def loop(exoself_pid) do
    receive do
      {exoself_pid, {id, cortex_pid, actuator_name, fanin_pids}} ->
        loop(Id, cortex_pid, actuator_name, {fanin_pids, fanin_pids}, [])
    end
  end

  @doc ~S"""
  The actuator process gathers the control signals from the neurons, appending
  them to the accumulator. The order in which the signals are accumulated into
  a vector is in the same order as the neuron ids are stored within NIds. Once
  all the signals have been gathered, the actuator sends cortex the sync signal,
  executes its function, and then again begins to wait for the neural signals
  from the output layer by reseting the fanin_pids from the second copy of the
  list.
  """
  def loop(id, cortex_pid, actuator_name, {[from_pid|fanin_pids], m_fanin_pids}, acc) do
    receive do
      {from_pid, forward, input} ->
        loop(Id, cortex_pid, actuator_name, {fanin_pids, m_fanin_pids}, List.flatten([input, acc]))
      {cortex_pid, terminate} ->
        :ok
    end
  end
  def loop(Id, cortex_pid, actuator_name, {[], m_fanin_pids}, acc) do
    apply(__MODULE__, actuator_name, [Enum.reverse(acc)])
    {self(), :sync} |> cortex_pid.send
    loop(Id, cortex_pid, actuator_name, {m_fanin_pids, m_fanin_pids}, [])
  end



  @doc ~S"""
  The pts actuation function simply prints to screen the vector passed to it.
  """
  def pts(result) do
    IO.puts "actuator:pts(result): #{inspect(result)}"
  end
end
