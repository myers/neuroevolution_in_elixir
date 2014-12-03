defmodule FFNN.ConstructorTest do
  use ExUnit.Case


  test "example from book" do
    FFNN.Constructor.construct_genotype("/tmp/ffnn.terms", :rng, :pts, [1,3])
  end
end
