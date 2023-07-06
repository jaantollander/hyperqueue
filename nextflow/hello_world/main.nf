#!/usr/bin/env nextflow

params.str = 'Hello world!'

process splitLetters {
  output:
    path 'chunk_*'

  """
  printf '${params.str}' > params
  cat params | split -b 6 - chunk_
  """
}

process convertToUpper {
  input:
    path x
  output:
    path y

  """
  cat $x | tr '[a-z]' '[A-Z]' > y
  """
}

workflow {
  splitLetters | flatten | convertToUpper
}
