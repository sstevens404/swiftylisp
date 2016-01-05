((lambda ()
	(write "Running tests...")

	(define not (lambda (x) (cond ((= x "true") 0) (else "true"))))
	(define test (lambda (input expected text)
		(cond 
			((not (= input expected)) 
				(write  "Failed:" text "." input "!=" expected)) 
			(else 
				(write "Passed:" text)))))

	(test (- 5 3) 2 "subtraction")
	(test (- 1) 1 "single number subtration")
	(test (/ 3 -2) -1.5 "divison")
	(test (* +3.5 2) 7 "multiplication")

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

	(define cons (lambda (x y) (lambda (m) (m x y))))
	(define car (lambda (x) (x (lambda (a b) (a)))))
	(define cdr (lambda (x) (x (lambda (a b) (b)))))
	
	(define index 
		(lambda (items i)
			(cond 
				((= i 0) 
					(car items))
				(else 
					(index (cdr items) (- i 1))))))

	(define map 
		(lambda (function items)
			(cond 
				((null? items) 
					null)
				(else 
					(cons 
						(function (car items)) 
						(map function (cdr items)))))))

	(define filter 
		(lambda (predicate items)
			(cond 
				((null? items) 
					null
				)
				(else 
					(cond 
						(predicate (car items)) 
							(cons (car items) (filter predicate (cdr items)))
						else 
							(filter predicate (cdr items))
					)
				)
			)
		)
	)

	(define thingy 
		(lambda (input)
			(define square (lambda (a) (* input a)))
			(define double (lambda (a) (* a a)))

			(cond 
				((= i 0) (car items))
				(else (index (cdr items) (- i 1)))
			)
		)
	)

	(write "Tests complete")
))
