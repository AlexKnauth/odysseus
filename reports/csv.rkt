#lang racket

(require compatibility/defmacro)
(require "../lib/load/all.rkt")

(provide (all-defined-out))

(define (write-csv-file headers data filename (divisor ","))
  (let* ( (res-header (implode headers divisor))
          (res-body (implode
                      (map
                        (λ (row)
                          (implode
                            (cond
                              ((hash? row)
                                (hash-refs row headers ""))
                              ((list? row)
                                row)
                              (else
                                row))
                            divisor))
                        data)
                      "\n"))
          (res (str res-header "\n" res-body)))
    (write-file filename res)))
