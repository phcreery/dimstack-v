module test

import dimstack
import math

// this test is a copy of MITCalc User Interface diagram

fn test_mitcalc() {
	mut m1 := dimstack.DimStatistical{
		nom: 208
		tol: dimstack.TolBilateral.symmetric(0.036)
		dist: dimstack.Normal{}
		process_sigma: 6
		name: 'a'
		desc: 'Shaft'
	}
	m1.assume_normal_dist_skewed(0.25)
	mut m2 := dimstack.DimStatistical{
		nom: -1.75
		tol: dimstack.TolBilateral.unequal(0, -0.06)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'b'
		desc: 'Retainer ring'
	}
	m2.assume_normal_dist()
	mut m3 := dimstack.DimStatistical{
		nom: -23
		tol: dimstack.TolBilateral.unequal(0, -0.12)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'c'
		desc: 'Bearing'
	}
	m3.assume_normal_dist()
	mut m4 := dimstack.DimStatistical{
		nom: 20
		tol: dimstack.TolBilateral.symmetric(0.026)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'd'
		desc: 'Bearing Sleeve'
	}
	m4.assume_normal_dist()
	mut m5 := dimstack.DimStatistical{
		nom: -200
		tol: dimstack.TolBilateral.symmetric(0.145)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'e'
		desc: 'Case'
	}
	m5.assume_normal_dist()
	mut m6 := dimstack.DimStatistical{
		nom: 20
		tol: dimstack.TolBilateral.symmetric(0.026)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'f'
		desc: 'Bearing Sleeve'
	}
	m6.assume_normal_dist()
	mut m7 := dimstack.DimStatistical{
		nom: -23
		tol: dimstack.TolBilateral.unequal(0, -0.12)
		dist: dimstack.Normal{}
		process_sigma: 3
		name: 'g'
		desc: 'Bearing'
	}
	m7.assume_normal_dist()

	mut items := []dimstack.TDimension{}
	items << [m1, m2, m3, m4, m5, m6, m7]
	stack := dimstack.DimStack{
		// name: "stacks on stacks"
		// desc: items
		dims: items
	}
	println(stack)

	test_input := fn [stack] () {
		assert stack.dims.len == 7
		assert stack.dims[0].nom == 208
		assert stack.dims[0].tol.upper == 0.036
		assert stack.dims[0].tol.lower == -0.036
	}
	test_input()

	test_closed := fn [stack] () {
		assert stack.compute_closed().nom == 0.25
		assert dimstack.nround(stack.compute_closed().tol.upper) == 0.533
		assert dimstack.nround(stack.compute_closed().tol.lower) == -0.233
	}
	test_closed()

	test_wc := fn [stack] () {
		assert dimstack.nround(stack.compute_wc().nom) == 0.4
		assert dimstack.nround(stack.compute_wc().tol.t() / 2) == 0.383
		assert dimstack.nround(stack.compute_wc().z_min()) == 0.017
		assert dimstack.nround(stack.compute_wc().z_max()) == 0.783
	}
	test_wc()

	test_rss := fn [stack] () {
		// # self.assertEqual(dimstack.utils.nround(stack.RSS.mean), 0.4)
		assert dimstack.nround(stack.compute_rss().nom) == 0.4
		assert dimstack.nround(stack.compute_rss().tol.t() / 2) == 0.17825
		// # self.assertEqual(dimstack.utils.nround(stack.RSS.stdev, 6), 0.059417)
	}
	test_rss()

	test_rss_assembly := fn [stack] () {
		eval := stack.compute_rss()
		spec := dimstack.Spec{
			name: 'spec'
			desc: ''
			dim: eval
			ll: 0.05
			ul: 0.8
		}

		assert math.round_sig(spec.r(), 1) == 0.0
	}
	test_rss_assembly()

	// # def test_MRSS(self):
	// #     self.assertEqual(dimstack.utils.nround(stack.MRSS.mean), 0.4)
	// #     self.assertEqual(dimstack.utils.nround(stack.MRSS.nominal), 0.4)
	// #     # self.assertEqual(dimstack.utils.nround(stack.MRSS.tolerance.T / 2), 0.17825)
	// #     self.assertEqual(dimstack.utils.nround(stack.MRSS.tolerance.T / 2), 0.2405)
	// #     self.assertEqual(dimstack.utils.nround(stack.MRSS.stdev, 6), 0.059417)

	test_sixsigma := fn [stack] () {
		dim := stack.dims[0] as dimstack.DimStatistical
		println(dim.tostring())
		assert dimstack.nround(dim.c_p()) == 2
		assert math.round_sig(dim.k(), 2) == 0.25 // TODO: why is the accuraccy on thses bad?
		assert math.round_sig(dim.c_pk(), 3) == 1.5 // TODO: why is the accuraccy on thses bad?
		assert dimstack.nround(dim.mean_eff()) == 208.0
		assert dimstack.nround(dim.stdev_eff()) == 0.008

		// assert dimstack.nround(stack.compute_six_sigma(4.5).mean_eff()) == 0.4
		assert dimstack.nround(stack.compute_six_sigma(4.5).nom) == 0.4
		assert dimstack.nround(stack.compute_six_sigma(4.5).tol.t() / 2) == 0.26433
		assert dimstack.nround(stack.compute_six_sigma(4.5).stdev_eff()) == 0.05874
		assert dimstack.nround(stack.compute_six_sigma(4.5).z_min()) == 0.13567
		assert dimstack.nround(stack.compute_six_sigma(4.5).z_max()) == 0.66433
	}
	test_sixsigma()

	test_sixsigma_assembly := fn [stack] () {
		eval := stack.compute_six_sigma(4.5)
		spec := dimstack.Spec{
			name: 'spec'
			desc: ''
			dim: eval
			ll: 0.05
			ul: 0.8
		}

		// 	# self.assertEqual(dimstack.utils.nround(spec.C_p), 2.12804) # temporarily removed 20230623
		// 	# self.assertEqual(dimstack.utils.nround(spec.C_pk), 1.98617) # temporarily removed 20230623
		assert math.round_sig(spec.r(), 1) == 0.0
	}
}
