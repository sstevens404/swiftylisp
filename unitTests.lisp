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

	(write Tests complete)
)
