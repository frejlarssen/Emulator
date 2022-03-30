defmodule Emulator do

    def bench(l) do
      {:ok, file} = File.open("bench.dat", [:write, :list])
      seq = [0,1000000,2000000,3000000,4000000,5000000,6000000,7000000,8000000,9999996]
      :io.format(file, "# Emulator\n", [])
      :io.format(file, "# n\ttime\n", [])
      Enum.each(seq, fn n -> bench(l, n, file) end)
      File.close(file)
    end

    def bench(l, n, file) do
      {t, _} = :timer.tc(fn -> loop(l, n) end)
      :io.format(file, "~w\t~.2f\n", [n, t/l])
    end

    def loop(0,_) do :ok end
    def loop(l,n) do
      write(n)
      loop(l-1, n)
    end

    def time(l) do
      {t, _} = :timer.tc(fn -> loop(l, 1) end)
      t / l
    end

  def pdftest() do
    code = [
      {:addi, 1, 0, 5}, # $1 <- 5
      {:lw, 2, 0, :arg}, # $2 <- data[:arg]
      {:add, 4, 2, 1}, # $4 <- $2 + $1
      {:addi, 5, 0, 1}, # $5 <- 1
      {:label, :loop},
      {:sub, 4, 4, 5}, # $4 <- $4 - $5
      {:out, 4}, # out $4
      {:bne, 4, 0, :loop}, # branch if not equal
      :halt
    ]

    data = [
      {:label, :arg},
      {:word, 12}
    ]
    prgm = {code, data}
    run(prgm)
  end

  def test2() do
    code = [
      {:addi, 1, 0, 5},
      {:addi, 8, 0, 4},
      {:beq, 1, 8, :skip},
      {:addi, 9, 0, 12},
      {:out, 1},
      {:sw, 1, 0, 9},
      {:lw, 2, 4, 8},
      {:out, 2},
      {:label, :skip},
      :halt
    ]

    data = [
      {:label, :arg},
      {:word, 12},
      {:label, :arg2},
      {:word, 14},
      {:label, :arg3},
      {:word, 15}
    ]
    prgm = {code, data}
    run(prgm)
  end

  def memtest() do
    code = [
      {:addi, 1, 0, 76},
      {:addi, 2, 0, 128000000},
      {:sw, 1, 0, 2},
      {:lw, 3, 0, 2},
      {:out, 3},
      :halt
    ]

    data = [
    ]
    prgm = {code, data}
    run(prgm)
  end

  def dummy() do
    :ok
  end

  def create() do
    code = [:halt]
    data = []
    prgm = {code, data}
    run(prgm)
  end

  def write(n) do
    code = [
      {:addi, 1, 0, n},
      {:sw, 2, 0, 1},
      :halt
    ]
    data = []
    prgm = {code, data}
    run(prgm)
  end

  def run(prgm) do
    {code, mem} = Program.load(prgm)
    out = Out.new()
    reg = Register.new()
    run(0, code, reg, mem, out)
  end

  def run(pc, code, reg, mem, out) do
    next = Program.read_instruction(code, pc)
    case next do
      :halt -> Out.close(out)
      {:out, i} ->
        pc = pc + 4
        e = Register.read(reg, i)
        IO.puts(e)
        out = Out.put(out, e)
        run(pc, code, reg, mem, out)
      {:add, rd, rs, rt} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        t = Register.read(reg, rt)
        reg = Register.write(reg, rd, s + t)
        run(pc, code, reg, mem, out)
      {:sub, rd, rs, rt} ->
        pc = pc + 4
        s = Register.read(reg, rs)
        t = Register.read(reg, rt)
        reg = Register.write(reg, rd, s - t)
        run(pc, code, reg, mem, out)
      {:addi, rd, rt, imm} ->
        pc = pc + 4
        t = Register.read(reg, rt)
        reg = Register.write(reg, rd, t + imm)
        run(pc, code, reg, mem, out)
      {:lw, rd, offset, rt} ->
        pc = pc + 4
        {data, labels} = mem
        addr =
          if is_atom(rt) do
            getAddr(rt, labels)
          else
            Register.read(reg, rt)
          end
        addr = addr + offset
        reg = Register.write(reg, rd, loadWord(addr, data))
        run(pc, code, reg, mem, out)
      {:sw, rs, offset, rt} ->
        pc = pc + 4
        {data, labels} = mem
        addr =
          if is_atom(rt) do
            getAddr(rt, labels)
          else
            Register.read(reg, rt)
          end
        addr = addr + offset
        data = storeWord(addr, Register.read(reg, rs), data)
        mem = {data, labels}
        run(pc, code, reg, mem, out)
      {:beq, rt, rs, offset} ->
        pc = pc + 4
        pc =
          if (Register.read(reg, rt) == Register.read(reg, rs)) do
            if is_atom(offset) do
              findLabel(offset, code)
            else
              pc + offset
            end
          else
            pc
          end
        run(pc, code, reg, mem, out)
      {:bne, rt, rs, offset} ->
        pc = pc + 4
        pc =
          if (Register.read(reg, rt) != Register.read(reg, rs)) do
            if is_atom(offset) do
              findLabel(offset, code)
            else
              pc + offset
            end
          else
            pc
          end
        run(pc, code, reg, mem, out)
      {:label, _label} ->
        pc = pc + 4
        run(pc, code, reg, mem, out)
    end
  end

  def getAddr(_label, []) do
    {:error, "Label not found"}
  end
  def getAddr(label, [{label, val} | _tail]) do val end
  def getAddr(label, [_head | tail]) do getAddr(label, tail) end

  def loadWord(0, [head | _tail]) do head end #TODO: lite felhantering här
  def loadWord(addr, [_head | tail]) do loadWord(addr - 4, tail) end

  def storeWord(0, word, [_head | tail]) do [word | tail] end #TODO: Kan jag göra den svansrekursiv?
  def storeWord(addr, word, [head | tail]) do
    [head | storeWord(addr - 4, word, tail)]
  end

  def findLabel(label, code) do findLabel(label, code, 0) * 4 end
  def findLabel(_label, [], _index) do {:error, "Label not found"} end
  def findLabel(label, [{:label, label} | _tail], index) do index end
  def findLabel(label, [_head | tail], index) do
    findLabel(label, tail, index + 1)
  end
end
