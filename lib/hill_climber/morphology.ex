defmodule HillClimber.Morphology do
  alias HillClimber.Sensor
  alias HillClimber.Actuator

  def get_init_sensor(morphology) do
    sensors = apply(morphology, [:sensors])
    sensors[0]
  end

  def get_init_actuator(morphology) do
    actuators = apply(morphology, [:actuators])
    actuators[0]
  end

  def get_sensors(morphology) do
    apply(morphology, [:sensors])
  end

  def get_actuators(morphology) do
    apply(morphology, [:actuators])
  end

  # MORPHOLOGIES

  @doc """
  Every sensor and actuator uses some kind of function associated with it. A
  function that either polls the environment for sensory signals (in the case of
  a sensor) or acts upon the environment (in the case of an actuator). It is a
  function that we need to define and program before it is used, and the name of
  the function is the same as the name of the sensor or actuator it self. For
  example, the create_Sensor/1 has specified only the rng sensor, because that
  is the only sensor function we've finished developing. The rng function has
  its own vl specification, which will determine the number of weights that a
  neuron will need to allocate if it is to accept this sensor's output vector.
  The same principles apply to the create_Actuator function. Both, create_Sensor
  and create_Actuator function, given the name of the sensor or actuator, will
  return a record with all the specifications of that element, each with its own
  unique Id.
  """
  def xor_mimic(:sensors) do
    [
      %Sensor{id: {:sensor, generate_id()}, name: :xor_get_input, scape: {:private, :xor_sim}, vl: 2}
    ]
  end
  def xor_mimic(:actuators) do
    [
      %Actuator{id: {:actuator, generate_id()}, name: :xor_send_output, scape: {:private, :xor_sim}, vl: 1}
    ]
  end

  def generate_id() do
    {mega_seconds, seconds, micro_seconds} = :os.timestamp()
    1/(mega_seconds*1000000 + seconds + micro_seconds/1000000)
  end
end