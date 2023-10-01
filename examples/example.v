module main

import dimstack

fn main() {
	println('')
	t1 := dimstack.TolBilateral.symmetric(0.1)
	println(t1.tostring())
	d1 := dimstack.DimBasic{
		name: 's1'
		nom: 1.0
		tol: t1
	}
	println(d1.tostring())

	t2 := dimstack.TolBilateral{
		upper: 0.1
		lower: 0.2
	}
	println(t2.tostring())
	d2 := dimstack.DimBasic{
		nom: 1.0
		tol: t2
	}
	println(d2.tostring())

	t3 := dimstack.TolBilateral{
		upper: 0.1
		lower: -0.2
	}
	println(t3.tostring())

	dist1 := dimstack.Normal{
		mean: 1.0
		stdev: 0.02
	}
	println(dist1.tostring())
	d3 := dimstack.DimStatistical{
		nom: 1.0
		tol: t3
		process_sigma: 6
		dist: dist1
	}
	println(d3.tostring())

	// println(d1.get_absolute_tolerance())
	// println(d2.get_absolute_tolerance())
	// println(d3.get_absolute_tolerance())

	s1 := dimstack.DimStack{
		dims: [
			d1,
			d2,
			d3,
		]
	}
	println('')
	println(s1.tostring())
	println(s1.compute_closed().tostring())
}
