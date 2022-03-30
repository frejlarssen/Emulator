defmodule Program do
  def load({code, inData}) do
    #newData = {raw datalist, [{labelName1, addr1}, {labelName2, addr2}]}
    case newData = data(inData, 10000000) do #We set the capacity of the memory in bytes
      {:error, _} -> newData
      _ -> {code, newData}
    end
  end

  def data(data, capacity) do
    {newData, labels, counter} = data(data, [], [], 0)
    if (capacity >= counter) do
      zeroes = zeroes(div((capacity - counter),4))
      newData = append(newData, zeroes)
      {newData, labels}
    else
      {:error, "Not enough memory capacity"}
    end
    #IO.write(labels)

  end
  #(dataAndLabels, data, labels, counter)
  def data([], data, labels, counter) do {data, labels, counter} end
  def data([{:label, labelName}, {:word, dataPiece} | tail], data, labels, counter) do
    data = [dataPiece | data]
    labels = [{labelName, counter} | labels] #Does not matter what order the labels are in so we can add them the quickest way.
    data(tail, data, labels, counter + 4)
  end

  #Returns a list of amount number zeroes
  def zeroes(amount) do zeroes(amount, []) end
  def zeroes(0, list) do list end
  def zeroes(amount, list) do
    list = [0 | list]
    zeroes(amount - 1, list)
  end

  def append([], res) do res end
  def append([head | tail], res) do
    res = [head | res]
    append(tail, res)
  end

  def read_instruction([], _pc) do :error end
  def read_instruction([head | _tail], 0) do head end
  def read_instruction([_head | tail], pc) do
    read_instruction(tail, pc - 4)
  end
end
