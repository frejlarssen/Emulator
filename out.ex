defmodule Out do
  def new() do [] end

  def put(out, elem) do
    [elem | out]
  end

  def close(out) do close(out, []) end
  def close([], reversed) do reversed end
  def close([head | tail], reversed) do
    reversed = [head | reversed]
    close(tail, reversed)
  end
end
