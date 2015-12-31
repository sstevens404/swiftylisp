(
	(write Running tests...)

	(cond 
		(= (* 2 5) 10.0) () 
		else (write "* 2 5" failed)
	)

	(cond 
		(= (- 1) 1.0) () 
		else (write "- 1" failed)
	)

	(cond 
		(= (/ 3 2) 1.5)  () 
		else (write "/ 3 2" failed)
	)

	(cond 
		(= (* 3.5 2) 7.0) () 
		else (write "* 3.5 2" failed)
	)

	(let pi 3.14159)

	(cond 
		(= 3.14159 pi) ()
		else (write variable "pi" assignment failed)
	) 

	(cond 
		(= 2 5) (write cond test failed)
		(= 5 5) ()
		else (write cond test failed)
	) 

	(cond 
		(= 2 5) (write cond test 2 failed)
		(= 5 7) (write cond test 2 failed)
		else ()
	) 

	(let nine ((lambda (x) (* x x)) 3))
	(write nine)
	(cond 
		(= 9.0 ((lambda (x) (* x x)) 3)) ()
		else (write inline lamda failed))

	(let cube (lambda (x) (* x x x))) 

	(cond 
		(= 125.0 (cube 5)) ()
		else (write lamda definition failed))

	(write Tests complete)
)
