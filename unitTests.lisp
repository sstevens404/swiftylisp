((lambda ()
	; this is a comment
	(write "Running tests...") ; this is a comment at the end of a line

	(define null (define dfsjhkfsdjkhfdsjhk 1))
	(define null? (lambda (x) (= x null)))

	(define not (lambda (x) (cond ((= x "true") null) (else "true"))))
	(define and (lambda (x y) (cond ((not x) null) ((not y) null) (else "true"))))
	(define or (lambda (x y) (cond (x "true") (y "true") (else null))))
	(define test (lambda (input expected text)
		(cond 
			((not (= input expected)) 
				(write  " ! Failed:" text "." input "!=" expected)) 
			(else 
				(write "Passed:" text)))))

	(test (- 5 3) 2 "subtraction")
	(test (- 1) 1 "single number subtration")
	(test (/ 3 -2) -1.5 "divison")
	(test (* +3.5 2) 7 "multiplication")
	(test (< 4 93.45) "true" "less than 1")
	(test (not (< 5 2)) "true" "less than 2")

	(define pi 3.14159)
	(test pi 3.14159 "varable assignment")

	(define bloop (lambda (x) 
		((cond ((= x 7) +) (else *)) x 2)))
	(test (bloop 10) 20 "dynamic function name 1")
	(test (bloop 7) 9 "dynamic function name 2")

	(test ((lambda (x) (* x x)) 3) 9 "inline lambda")

	(define nine ((lambda (x) (* x x)) 3))
	(test nine 9.0 "define inline lambda")

	(define cube (lambda (x) (* x x x))) 
	(test 125 (cube 5) "call defined lambda")

	(define factorial 
		(lambda (x) 
			(cond 
				((= x 0) 
					1)
				(else 
					(* x (factorial (- x 1)))))))

	(test 120 (factorial 5) "Recursion")

	(define make-inc (lambda (incBy) (lambda (num) (+ incBy num))))
	(define five (make-inc 5))
	(define seven (make-inc 7))
	(test 8 (five 3) "Closure")
	(test 14 (five 9) "Closure 2")
	(test 10 (seven 3) "Closure 3")

	(define sqrt (lambda (x)
		(define average (lambda (x y) (/ (+ x y) 2)))
		(define abs (lambda (x) (cond ((< x 0) (- 0 x)) (else x)))) 
		(define good-enough? (lambda (guess) (< (abs (- (* guess guess) x)) 0.0001)))
		(define improve (lambda (guess) (average guess (/ x guess))))
		(define sqrt-iter (lambda (guess)
			(cond 
				((good-enough? guess) 
					guess) 
				(else 
					(sqrt-iter (improve guess))))))
		(sqrt-iter 1.0)))

	(write (sqrt 25))

	

	(define alpha (cons "a" "b"))
	(test (car alpha) "a" "car 1")
	(test (cdr alpha) (cons "b") "cdr 1")

	(define beta (cons alpha "c"))
	(test (car (car beta)) "a" "car 2")
	(test (cdr beta) (cons "c") "cdr 2")

	(define index (lambda (items i)
		(cond 
			((= i 0) 
				(car items))
			(else 
				(index (cdr items) (- i 1))))))

	
	(define map (lambda (function items)
		(cond 
			((null? items) null)
			(else 
				(cons 
					(function (car items)) 
					(map function (cdr items)))))))

	(define each (lambda (function items) 
			(cond ((null? items) null)
				(else (function (car items)) (each function (cdr items)))
		)))
	(define write-list (lambda (items) (each (lambda (x) (write x)) items)))

	(define numbers (cons 1 2 3 4))
	(write-list numbers)
	(write-list (map (lambda (x) (* 2 x)) numbers))

	(define filter (lambda (predicate items)
		(cond 
			((null? items) 
				null)
			(else 
				(cond 
					(predicate (car items)) 
						(cons (car items) (filter predicate (cdr items)))
					else 
						(filter predicate (cdr items)))))))

	(write "Tests complete")

	; (define cons (lambda (x y) (lambda (m) (m x y))))
	; (define car (lambda (x) (x (lambda (a b) a))))
	; (define cdr (lambda (x) (x (lambda (a b) b))))
))
