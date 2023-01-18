(set-logic HORN)
(declare-fun X (Int) Bool)
;;(define-fun X ((x Int)) Bool (= (mod x 2) 0))
(assert (forall ((x Int)) (=> true (or (X x) (X (+ 1 x))))))
(assert (forall ((x Int)) (=> (and (X x) (X (+ x 1))) false)))
(check-sat)
(get-model)