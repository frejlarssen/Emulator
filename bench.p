set terminal pdf
set output "bench.pdf"
set title ""
set xlabel "adress"
set ylabel "tid i ms"
plot "bench.dat" u 1:2 with lines title "tid write"