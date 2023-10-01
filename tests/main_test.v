module test

// module dimstack
import dimstack
// import math

fn test_dimension() {
	tol := dimstack.TolBilateral{
		upper: 0.1
		lower: -0.2
	}
	println(tol.t())
	assert tol.upper == 0.1
	assert tol.lower == -0.2
	assert dimstack.nround(tol.t()) == 0.3
}

fn test_dimension_symmetric() {
	tol := dimstack.TolBilateral.symmetric(0.1)
	assert tol.upper == 0.1
	assert tol.lower == -0.1
	assert tol.t() == 0.2
}
