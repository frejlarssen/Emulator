defmodule Test do
  def test(x) do
    y =
    if x == 0 do
      5
    else
      4
    end
    y
  end

  def ctest(x) do
    y = 3
    case x do
      0 -> y = 5
      _ -> y = 4
    end
    y
  end
end
