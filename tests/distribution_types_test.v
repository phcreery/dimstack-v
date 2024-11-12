module test

import dimstack
import math

fn test_postitive() {
	dist1 := dimstack.Normal{
		mean:  1.0
		stdev: 0.1
	}

	print(dist1.tostring())

	tol := dimstack.TolBilateral.symmetric(0.3)

	dim1 := dimstack.DimStatistical{
		nom:  1.0
		tol:  tol
		dist: dist1
	}

	print(dim1.tostring())
	assert dim1.nom == 1.0
	assert dim1.abs_upper() == 1.3
	assert dim1.abs_lower() == 0.7

	assert dist1.mean == 1.0
	assert dist1.stdev == 0.1

	assert math.round_sig(dim1.yield_probability(), 4) == 0.9973
}

fn test_negative() {
	dist1 := dimstack.Normal{
		mean:  -1.0
		stdev: 0.1
	}

	// print(dist1.tostring())
	tol := dimstack.TolBilateral.symmetric(0.3)

	dim1 := dimstack.DimStatistical{
		nom:  -1.0
		tol:  tol
		dist: dist1
	}

	print(dim1.tostring())
	assert dim1.nom == -1.0
	assert dim1.abs_upper() == -0.7
	assert dim1.abs_lower() == -1.3

	assert dist1.mean == -1.0
	assert dist1.stdev == 0.1

	assert math.round_sig(dim1.yield_probability(), 4) == 0.9973
}
