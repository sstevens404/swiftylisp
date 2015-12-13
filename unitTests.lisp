(
	(write Running tests...)

	(if (eq? (* 2 5) 10.0) 
		() 
		(write "* 2 5" failed)
	)

	(if (eq? (- 1) 1.0) 
		() 
		(write "- 1" failed)
	)

	(if (eq? (/ 3 2) 1.5) 
		() 
		(write "/ 3 2" failed)
	)

	(if (eq? (* 3.5 2) 7.0) 
		() 
		(write "* 3.5 2" failed)
	)

	(write Tests complete)
)
