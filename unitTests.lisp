(eval
	(write Running tests...)

	(cond 
		(= (* 2 5) 10.0) (sucess) 
		else (write "* 2 5" failed)
	)

	(cond 
		(= (- 1) 1.0) (sucess) 
		else (write "- 1" failed)
	)

	(cond 
		(= (/ 3 2) 1.5)  (sucess) 
		else (write "/ 3 2" failed)
	)

	(cond 
		(= (* 3.5 2) 7.0) (sucess) 
		else (write "* 3.5 2" failed)
	)

	(define pi 3.14159)

	(cond 
		(= 3.14159 pi) (sucess)
		else (write variable "pi" assignment failed)
	) 

	(cond 
		(= 2 5) (write cond test failed)
		(= 5 5) (sucess)
		else (write cond test failed)
	) 

	(cond 
		(= 2 5) (write cond test 2 failed)
		(= 5 7) (write cond test 2 failed)
		else (sucess)
	) 

	(cond 
		(= 9.0 ((lambda (x) (* x x)) 3)) ()
		else (write inline lamda failed))

	(define nine ((lambda (x) (* x x)) 3))

	(cond 
		(= 9.0 nine) ()
		else (write define assignment of inline lamda failed))

	(define cube (lambda (x) (* x x x))) 

	(cond  
		(= 125.0 (cube 5)) ()
		else (write lamda definition failed))

	(define cons (lambda (x y) (lambda (m) (m x y))))
	(define car (lambda (x) (x (lambda (a b) (a)))))
	(define cdr (lambda (x) (x (lambda (a b) (b)))))

	(write Tests complete)
)
