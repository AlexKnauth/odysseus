#lang racket

(require "../lib/hash.rkt")

(provide (all-defined-out))

(define @base-properties
    (@
        ; fonts
        'font-family "Arial"
        'font-size 10
        'font-style "normal"
        ;colors
        'fill "black"
    )
)

(define (@base-property property-name)
  (hash-ref @base-properties property-name #f))