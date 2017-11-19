defmodule FFNN.ExoselfTest do
  use ExUnit.Case

  test "load example genome file" do
    tmp_path = Temp.mkdir! "ExoselfTest"
    genome_path = Path.join(tmp_path, "ffnn.terms")
    File.cp Path.join(__DIR__, "example_ffnn.terms"), genome_path
    assert FFNN.Exoself.map(genome_path) == :ok
  end
end
