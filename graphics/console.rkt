#lang racket

(require "../lib/seqs.rkt")
(require "../lib/base.rkt")
(require "../lib/controls.rkt")

(provide (all-defined-out))

(define console-output (make-parameter #t))

(define (set-text-color c)
  (display (string-text-color c)))

(define (string-text-color c)
  (let (
      (colors
        (hash
          'black #"30"
          'red #"31"
          'yellow #"32"
          'green #"33"
          'grey #"34"
          'magenta #"35"
          'blue #"36"
          'white #"37"
          'default #"39"
        )))
    (bytes-append
      #"\x1B"
      #"["
      (hash-ref colors c #"37")
      #"m")))