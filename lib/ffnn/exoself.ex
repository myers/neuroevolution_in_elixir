defmodule FFNN.Exoself do

  @doc ~S"""
  The map/1 function maps the tuple encoded genotype into a process based
  phenotype. The map function expects for the cortex record to be the leading tuple
  in the tuple list it reads from the file_name. We create an ets table to map
  Ids to PIds and back again. Since the Cortex element contains all the Sensor
  Actuator, and Neuron Ids, we are able to spawn each neuron using its own gen
  function, and in the process construct a map from Ids to PIds. We then use
  link_cerebral_units to link all non Cortex elements to each other by sending
  each spawned pro- cess the information contained in its record, but with Ids
  converted to Pids where appropriate. Finally, we provide the Cortex process
  with all the PIds in the NN system by executing the link_cortex/2 function.
  Once the NN is up and running, exoself starts its wait until the NN has
  finished its job and is ready to backup. When the cortex initiates the backup
  process it sends exoself the updated Input_p_id_ps from its neurons. Exoself
  uses the update_genotype/3 function to update the old genotype with new
  weights, and then stores the updated version back to its file.
  """
  def map() do
    map(:ffnn)
  end
  def map(file_name) do
    {ok, genotype} = :file.consult(file_name)
    spawn(fn -> map(file_name, genotype) end)
  end
  def map(file_name, genotype) do
    ids_n_pids = :ets.new(:ids_n_pids, [:set, :private])
    [cortex|cerebral_units] = genotype
    sensor_ids = cortex.sensor_ids
    actuator_ids = cortex.actuator_ids
    n_ids = cortex.n_ids
    spawn_cerebral_units(ids_n_pids, cortex, [cortex.id])
    spawn_cerebral_units(ids_n_pids, sensor, sensor_ids)
    spawn_cerebral_units(ids_n_pids, actuator, actuator_ids)
    spawn_cerebral_units(ids_n_pids, neuron, n_ids)
    link_cerebral_units(cerebral_units, ids_n_pids)
    link_cortex(cortex, ids_n_pids)
    cortex_pid = :ets.lookup_element(ids_n_pids, cortex.id, 2)

    receive do
      {cortex_pid, :backup, neuron_ids_n_weights}->
        u_genotype = update_genotype(ids_n_pids, genotype, neuron_ids_n_weights)
        {:ok, file} = :file.open(file_name, :write)
        :lists.foreach(fn(X) -> :io.format(file, "~p.~n", [X]) end, u_genotype)
        :file.close(file)
        :io.format("Finished updating to file:~p~n", [file_name])
    end
  end


  @doc ~S"""
  We spawn the process for each element based on its type: cerebral_unit_type, and
  the gen function that belongs to the cerebral_unit_type module. We then enter
  the {Id, PId} tuple into our ETS table for later use.
  """
  def spawn_cerebral_units(ids_n_pids, cerebral_unit_type, [id|ids]) do
    pid = apply(cerebral_unit_type, :gen, [self()])
    :ets.insert(ids_n_pids, {id, pid})
    :ets.insert(ids_n_pids, {pid, id})
    spawn_cerebral_units(ids_n_pids, cerebral_unit_type, Ids)
  end
  def spawn_cerebral_units(_ids_n_pids, _cerebral_unit_type, [])
    true
  end

  @doc ~S"""
  The link_cerebral_units/2 converts the Ids to PIds using the created IdsNPids
  ETS table. At this point all the elements are spawned, and the processes are
  waiting for their initial states.
  """

  def link_cerebral_units([%Sensor{} = sensor|cerebral_units], ids_n_pids) do
    sensor_pid = :ets.lookup_element(ids_n_pids, sensor.id, 2)
    cortex_pid = :ets.lookup_element(ids_n_pids, sensor.cx_id, 2)
    fanout_pids = for id <- sensor.fanout_ids, do: :ets.lookup_element(ids_n_pids, id, 2)
    {self(), {sensor.id, cortex_pid, sensor.name, sensor.vl, fanout_pids}} |> sensor_pid.send
    link_cerebral_units(cerebral_units, ids_n_pids)
  end
  def link_cerebral_units([%Actuator{} = actuator|cerebral_units], ids_n_pids) do
    actuator_pid = :ets.lookup_element(ids_n_pids, actuator_id, 2)
    cortex_pid = :ets.lookup_element(ids_n_pids, actuator.cx_id, 2)
    fanin_pids = for id <- actuator.fanin_ids, do: :ets.lookup_element(ids_n_pids, Id, 2)
    {self, {actuator.id, cortex_pid, actuator.name, fanin_pids}} |> actuator_pid.send
    link_cerebral_units(cerebral_units, ids_n_pids)
  end
  def link_cerebral_units([%Neuron{} = neuron|cerebral_units], ids_n_pids) do
    neuron_pid = :ets.lookup_element(ids_n_pids, neuron.id, 2)
    cortex_pid = :ets.lookup_element(ids_n_pids, neuron.cx_id, 2)
    input_pid_ps = convert_id_ps2pid_ps(ids_n_pids, neuron.input_id_ps, [])
    output_pids = for id <- output_ids, do: :ets.lookup_element(ids_n_pids, id, 2)
    {self(), {neuron.id, cortex_pid, neuron.af, input_pid_ps, output_pids}} |> neuron_pid.send
    link_cerebral_units(cerebral_units, ids_n_pids)
  end
  def link_cerebral_units([], _ids_n_pids), do: :ok



  @doc ~S"""
  convert_id_ps2pid_ps/3 converts the IdPs
  tuples into tuples that use PIds instead of Ids, such that the Neuron will
  know which weights are to be associated with which incoming vector signals.
  The last element is the bias, which is added to the list in a non tuple form.
  Afterwards, the list is reversed to take its proper order.
  """
  def convert_id_ps2pid_ps(_ids_n_pids, [{:bias, bias}], acc) do
    Enum.reverse([bias|acc])
  end
  def convert_id_ps2pid_ps(ids_n_pids, [{id, weights}|fanin_id_ps], acc) do
    convert_id_ps2pid_ps(ids_n_pids, fanin_id_ps, [{:ets.lookup_element(ids_n_pids, id, 2), weights}|acc])
  end

  @doc ~S"""
  The cortex is initialized to its proper state just as other elements. Because
  we have not yet implemented a learning algorithm for our NN system, we need to
  specify when the NN should shutdown. We do this by specifying the total number
  of cycles the NN should execute before terminating, which is 1000 in this
  case.
  """
  def link_cortex(cortex, ids_n_pids) do
    cortex_pid = :ets.lookup_element(ids_n_pids, cortex.id, 2)
    SIds = cortex.sensor_ids
    AIds = cortex.actuator_ids
    n_ids = cortex.n_ids
    sensor_pids = for id <- cortex.sensor_ids, do: :ets.lookup_element(ids_n_pids, id, 2)
    actuator_pids = for id <- cortex.actuator_ids, do: :ets.lookup_element(ids_n_pids, id, 2)
    neuron_pids = for id <- cortex.n_ids, do: :ets.lookup_element(ids_n_pids, id, 2)
    {self(), {cortex.id, sensor_pids, actuator_pids, neuron_pids}, 1000} |> cortex_pid.send
  end

  @doc ~S"""
  For every {neuron_id, p_id_ps} tuple the update_genotype/3 function extracts the
  neuron with the id: neuron_id, and updates its weights. The convert_p_id_ps2id_ps/3
  performs the conversion from PIds to Ids of every {PId, Weights} tuple in the
  Input_p_id_ps list. The updated genotype is then returned back to the caller.
  """
  def update_genotype(ids_n_pids, genotype, [{neuron_id, p_id_ps}|weight_ps]) do
    neuron = :lists.keyfind(neuron_id, 2, genotype)
    :io.format("p_id_ps:~p~n", [p_id_ps])
    input_id_ps = convert_p_id_ps2id_ps(ids_n_pids, p_id_ps, [])
    updated_neuron = %Neuron{n | input_id_ps: input_id_ps}
    updated_genotype = :lists.keyreplace(neuron_id, 2, genotype, updated_neuron)
    :io.format("neuron:~p~n updated_neuron:~p~n genotype:~p~n updated_genotype:~p~n", [neuron, updated_neuron, genotype, updated_genotype])
    update_genotype(ids_n_pids, updated_genotype, weight_ps)
  end
  def update_genotype(_ids_n_pids, genotype, []) do
    genotype
  end

  def convert_p_id_ps2id_ps(ids_n_pids, [{pid, weights}|input_id_ps], acc) do
    convert_p_id_ps2id_ps(ids_n_pids, input_id_ps, [{:ets.lookup_element(ids_n_pids, pid, 2), weights}|acc])
  end
  def convert_p_id_ps2id_ps(_ids_n_pids, [bias], acc) do
    :lists.reverse([{:bias, bias}|acc]).
  end
end