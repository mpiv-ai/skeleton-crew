# Prefix each line of stdin with the seconds since this started, so gaps show how long the agent blocked.
import sys, time
t0 = time.time()
for line in sys.stdin:
    sys.stdout.write(f"{time.time() - t0:.1f}\t{line}")
    sys.stdout.flush()
