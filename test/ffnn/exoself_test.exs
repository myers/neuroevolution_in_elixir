defmodule FFNN.ExoselfTest do
  use ExUnit.Case

  test "example from book" do
    assert FFNN.Constructor.construct_genotype(Path.join(__DIR__, "ffnn.terms"), :rng, :pts, [1,3]) == :ok
    #FFNN.Exoself.map(Path.join(__DIR__, "ffnn.terms"))
  end
end
