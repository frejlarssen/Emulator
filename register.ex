defmodule Register do
  def new() do
    {0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0}
  end

  def read(reg, index) do
    elem(reg, index)
  end

  def write(reg, index, val) do
    put_elem(reg, index, val)
  end
end
