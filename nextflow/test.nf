#!/usr/bin/env nextflow

n = 10

process split {
  output:
    path 'chunk_*'

  """
  for i in {1..$n}; do
      echo "\$i" > "chunk_\$i"
  done
  """
}

process work {
  input:
    path x
  output:
    path y

  """
  cat $x > y
  """
}

workflow {
  split | flatten | work
}
