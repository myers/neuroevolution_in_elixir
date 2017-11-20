defmodule HillClimber.Trainer do
  alias HillClimber.Exoself
  alias HillClimber.Genotype
  require Logger
  
  @max_attempts 5
  @eval_limit :inf
  @fitness_target :inf

  @doc ~S"""
  The function `go/2` is executed to start the training process based on the
  morphology and hidden_layer_densities specified. `go/2` uses the default values
  for the Max_Attempts, Eval_Limit, and Fitness_Target, which makes the training
  be based purely on the Max_Attempts value. `go/5` allows for all the stopping
  conditions to be specified.
  """
  def go(morphology, hidden_layer_densities) do
    go(morphology, hidden_layer_densities, @max_attempts, @eval_limit, @fitness_target)
  end

  def go(morphology, hidden_layer_densities, max_attempts, eval_limit, fitness_target) do
    pid = spawn(fn -> loop(morphology, hidden_layer_densities, fitness_target, {1, max_attempts}, {0, eval_limit}, {0, :best}, :experimental, 0, 0) end)
    Process.register(:trainer, pid)
    pid
  end

  @doc ~S"""
  `loop/7` generates new NNs and trains them until a stopping condition is
  reached. Once a stopping condition is reached, the trainer prints to screen
  the genotype, the morphological name of the organism being trained, the best
  fitness scored achieved, and the number of evaluations taken to find the this
  fitness score.
  """
  def loop(morphology, _hidden_layer_densities, fitness_target, {attempt_acc, max_attempts}, {eval_acc, eval_limit}, {best_fitness, best_g}, _file_name, cycle_acc, time_acc) when (attempt_acc >= max_attempts) or (eval_acc >= eval_limit) or (best_fitness >= fitness_target) do
    Genotype.print(best_g)
    Logger.info(" morphology:#{inspect(morphology)} best_fitness:#{inspect(best_fitness)} eval_acc:#{inspect(eval_acc)}")
    Process.unregister(:trainer)
    case Process.whereis(:benchmarker) do
      :undefined ->
        :ok
      pid ->
        send(pid, {self(), best_fitness, eval_acc, cycle_acc, time_acc})
    end
  end
  def loop(morphology, hidden_layer_densities, fitness_target, {attempt_acc, max_attempts}, {eval_acc, eval_limit}, {best_fitness, best_g}, file_name, cycle_acc, time_acc) do
    Genotype.construct_genotype(file_name, morphology, hidden_layer_densities)
    agent_pid = Exoself.map(file_name)
    receive do
      {^agent_pid, fitness, evals, cycles, time} ->
        eval_acc = eval_acc + evals
        cycle_acc = cycle_acc + cycles
        time_acc = time_acc + time
        case fitness > best_fitness do
          true ->
            :file.rename(file_name, :best_g)
            loop(morphology, hidden_layer_densities, fitness_target, {1, max_attempts}, {eval_acc, eval_limit}, {fitness, best_g}, file_name, cycle_acc, time_acc)
          false ->
            loop(morphology, hidden_layer_densities, fitness_target, {attempt_acc+1, max_attempts}, {eval_acc, eval_limit}, {best_fitness, best_g}, file_name, cycle_acc, time_acc)
        end
      :terminate ->
        Logger.info("Trainer Terminated:")
        Genotype.print(best_g)
        Logger.info(" morphology:#{inspect(morphology)} Best Fitness:#{inspect(best_fitness)} eval_acc:#{inspect(eval_acc)}")
    end
  end
end
