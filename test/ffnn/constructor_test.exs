defmodule FFNN.ConstructorTest do
  use ExUnit.Case

  test "example from book" do
    FFNN.Constructor.construct_genotype(Path.join(__DIR__, "ffnn.terms"), :rng, :pts, [1,3])
  end
end
