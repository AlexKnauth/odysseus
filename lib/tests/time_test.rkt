#lang racket

(module+ test

  (require rackunit)
  (require "../time.rkt")

  (check-equal? (time->seconds "05") 5)
  (check-equal? (time->seconds "45") 45)
  (check-equal? (time->seconds "2:45") 165)
  (check-equal? (time->seconds "02:45") 165)
  (check-equal? (time->seconds "3:02:45") 10965)
  (check-equal? (time->seconds "03:02:45") 10965)

  (check-equal? (seconds->minutes 165) 2)
  (check-equal? (seconds->minutes 60) 1)
  (check-equal? (seconds->minutes 10) 0)

  (check-equal? (seconds->hours 10) 0)
  (check-equal? (seconds->hours 285) 0)
  (check-equal? (seconds->hours 3600) 1)
  (check-equal? (seconds->hours 10985) 3)

  (check-equal? (seconds->days 285) 0)
  (check-equal? (seconds->days 86400) 1)
  (check-equal? (seconds->days 34560010) 400)

  (check-equal? (seconds->time 10965) "03:02:45")

  (check-equal? (time-diff "1:56:48" "4:12:50") "02:16:02")
  (check-equal? (time-diff "01:00:48" "00:12:50") "47:58")
  (check-equal? (time-diff "04:12:50" "01:56:48") "02:16:02")

  (check-equal? (date-diff "15.03.2017" "07.04.2017") 23)
  (check-equal? (date-diff "28.08.1979" "07.04.2017") 13737)

  (check-false (d> "28.08.1979" "07.04.2017"))
  (check-true (d< "28.08.1979" "07.04.2017"))

  (check-true (d> "07.04.2017" "28.08.1979"))
  (check-false (d< "07.04.2017" "28.08.1979"))

  (check-false (d= "07.04.2017" "28.08.1979"))
  (check-true (d= "7.04.2017" "07.04.2017")) 

  ;(check-equal? (datetime-diff "15.03.2017 1:56:48" "07.04.2017 4:12:50") ...)
)