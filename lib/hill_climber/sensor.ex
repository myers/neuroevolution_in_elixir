defmodule HillClimber.Sensor do
  defstruct id: nil, cx_id: nil, name: nil, scape: nil, vl: nil, fanout_ids: []

  @doc ~S"""
  When `gen/1` is executed it spawns the sensor element and immediately begins
  to wait for its initial state message.
  """
  def gen(exoself_pid) do
    spawn(fn() -> loop(exoself_pid) end)
  end

  def loop(exoself_pid) do
    receive do
      {^exoself_pid, {id, cortex_pid, sensor_name, vl, fanout_pids}} ->
        loop(id, cortex_pid, sensor_name, vl, fanout_pids)
    end
  end

  @doc ~S"""
  The sensor process accepts only 2 types of messages, both from the cortex. The
  sensor can either be triggered to begin gathering sensory data based on its
  sensory role, or terminate if the cortex requests so.
  """
  def loop(id, cortex_pid, sensor_name, vl, fanout_pids) do
    receive do
      {^cortex_pid, :sync} ->
        sensory_vector = apply(sensor_name, [vl])
        for pid <- fanout_pids, do: send(pid, {self(), :forward, sensory_vector})
        loop(id, cortex_pid, sensor_name, vl, fanout_pids)
      {^cortex_pid, :terminate} ->
        :ok
    end
  end

  @doc ~S"""
  `rng` is a simple random number generator that produces a vector of random
  values, each between 0 and 1. The length of the vector is defined by the vl,
  which itself is specified within the sensor record.
  """
  def rng(vl), do: rng(vl, [])
  def rng(0, acc), do: acc
  def rng(vl, acc), do: rng(vl-1, [:rand.uniform()|acc])
end
