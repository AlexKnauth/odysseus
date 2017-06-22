#lang racket

(require "base.rkt")
(require "seqs.rkt")

(provide (all-defined-out))

(define (re? x)
  (or (regexp? x) (pregexp? x)))

(define (->re x)
  (cond
    ((re? x) x)
    ((string? x) (pregexp x))
    (else (pregexp (str x)))))

(define (re-matches? re astr)
  (true? (regexp-match (->re re) astr)))

(define (get-matches re astr)
  (let ((re (->re re)))
    (for/fold
      ((res (list)))
      ((match-position (regexp-match-positions* re astr)))
      (pushr
        res
        (regexp-match
          re
          astr
          (car match-position))))))

(define (re-substitute astr re repstr)
  (cond
    ((and (list? re) (list? repstr))
      (if (or (null? (cdr re)) (null? (cdr repstr)))
        (re-substitute astr (car re) (car repstr))
        (re-substitute (re-substitute astr (car re) (car repstr)) (cdr re) (cdr repstr))))
    (else
      (string-replace astr (->re re) repstr))))