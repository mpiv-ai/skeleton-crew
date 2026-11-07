#!/bin/sh
for i in 1 2 3 4 5 6 7 8 9; do
  echo "step $i of 9"
  flock .job.lock sleep 20
done
echo "finished"
