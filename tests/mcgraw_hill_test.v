module test

import dimstack
import math

// # this test is a copy Dimensioning and Tolerancing Handbook by McGraw Hill, Chapter 9

fn test_mcgrawhill() {
	mut m1 := dimstack.DimBasic{
		nom: -0.375
		tol: dimstack.TolBilateral.unequal(0, -0.031)
		name: 'A'
		desc: 'Screw thread length'
	}
	mut m2 := dimstack.DimBasic{
		nom: 0.032
		tol: dimstack.TolBilateral.symmetric(0.002)
		name: 'B'
		desc: 'Washer Length'
	}
	mut m3 := dimstack.DimBasic{
		nom: 0.06
		tol: dimstack.TolBilateral.symmetric(0.003)
		name: 'C'
		desc: 'Inner bearing cap turned length'
	}
	mut m4 := dimstack.DimBasic{
		nom: 0.438
		tol: dimstack.TolBilateral.unequal(0, -0.015)
		name: 'D'
		desc: 'Bearing length'
	}
	mut m5 := dimstack.DimBasic{
		nom: 0.12
		tol: dimstack.TolBilateral.symmetric(0.005)
		name: 'E'
		desc: 'Spacer turned length'
	}
	mut m6 := dimstack.DimBasic{
		nom: 1.5
		tol: dimstack.TolBilateral.unequal(0.01, -0.004)
		name: 'F'
		desc: 'Rotor Length'
	}
	mut m7 := dimstack.DimBasic{
		...m5
	}
	m7.name = 'G'
	mut m8 := dimstack.DimBasic{
		...m4
	}
	m8.name = 'H'
	mut m9 := dimstack.DimBasic{
		nom: 0.450
		tol: dimstack.TolBilateral.symmetric(0.007)
		name: 'I'
		desc: 'Pulley casting length'
	}
	mut m10 := dimstack.DimBasic{
		nom: -3.019
		tol: dimstack.TolBilateral.unequal(0.012, 0)
		name: 'J'
		desc: 'Shaft turned length'
	}
	mut m11 := dimstack.DimBasic{
		nom: 0.3
		tol: dimstack.TolBilateral.symmetric(0.03)
		name: 'K'
		desc: 'Tapped hole depth'
	}

	mut items := []dimstack.TDimension{}
	items << [m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11]
	stack := dimstack.DimStack{
		name: 'stacks on stacks'
		dims: items
	}
	println(stack)

	test_wc := fn [stack] () {
		assert dimstack.nround(stack.compute_wc().nom) == 0.0615
		assert dimstack.nround(stack.compute_wc().tol.t() / 2) == 0.0955 // note, python impl has it at 0.0915
		assert dimstack.nround(stack.compute_wc().z_min()) == -0.034 // python impl has it at -0.03
		assert dimstack.nround(stack.compute_wc().z_max()) == 0.157 // python impl has it at 0.153
	}
	test_wc()

	test_rss := fn [stack] () {
		assert dimstack.nround(stack.compute_rss().nom) == 0.0615
		assert math.round_sig(stack.compute_rss().tol.t() / 2, 3) == 0.038 // python impl has it at 0.0381
		assert math.round_sig(stack.compute_rss().z_min(), 4) == 0.0234 // python impl at 0.02395
		assert math.round_sig(stack.compute_rss().z_max(), 4) == 0.0996 // python impl at 0.09905
	}
	test_rss()

	test_mrss := fn [stack] () {
		assert dimstack.nround(stack.compute_mrss().nom) == 0.0615
		assert math.round_sig(stack.compute_mrss().tol.t() / 2, 4) == 0.0505 // python impl at 0.04919
		assert math.round_sig(stack.compute_mrss().z_min(), 4) == 0.0110 // python impl at 0.012
		assert math.round_sig(stack.compute_mrss().z_max(), 4) == 0.1120 // python impl at 0.111
	}
	test_mrss()
}

// # this test is a copy Dimensioning and Tolerancing Handbook by McGraw Hill, Chaper 12-12

// class McGrawHill_2(unittest.TestCase):
//     m1 = dimstack.dim.Basic(nom=0.875, tol=dimstack.tolerance.SymmetricBilateral(0.010), a=-0.5146, name="A")
//     m2 = dimstack.dim.Basic(nom=1.625, tol=dimstack.tolerance.SymmetricBilateral(0.020), a=0.1567, name="B")
//     m3 = dimstack.dim.Basic(nom=1.700, tol=dimstack.tolerance.SymmetricBilateral(0.012), a=0.4180, name="C")
//     m4 = dimstack.dim.Basic(nom=0.875, tol=dimstack.tolerance.SymmetricBilateral(0.010), a=-1.000, name="D")
//     m5 = dimstack.dim.Basic(nom=2.625, tol=dimstack.tolerance.SymmetricBilateral(0.020), a=-0.0540, name="E")
//     m6 = dimstack.dim.Basic(nom=7.875, tol=dimstack.tolerance.SymmetricBilateral(0.030), a=0.4372, name="F")
//     m7 = dimstack.dim.Basic(nom=4.125, tol=dimstack.tolerance.SymmetricBilateral(0.010), a=1.000, name="G")
//     m8 = dimstack.dim.Basic(nom=1.125, tol=dimstack.tolerance.SymmetricBilateral(0.020), a=-0.9956, name="H")
//     m9 = dimstack.dim.Basic(nom=3.625, tol=dimstack.tolerance.SymmetricBilateral(0.015), a=-0.7530, name="J")
//     m10 = dimstack.dim.Basic(nom=5.125, tol=dimstack.tolerance.SymmetricBilateral(0.020), a=-0.4006, name="K")
//     m11 = dimstack.dim.Basic(nom=1.000, tol=dimstack.tolerance.SymmetricBilateral(0.010), a=-1.0914, name="M")
//     items = [m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11]

//     stack = dimstack.dim.Stack(title="stacks on stacks", items=items)

//     def test_WC(self):
//         self.assertEqual(dimstack.utils.nround(McGrawHill_2.stack.WC.nominal), 0.07201)  # 0.0719
//         self.assertEqual(dimstack.utils.nround(McGrawHill_2.stack.WC.tolerance.T / 2), 0.09763)  # 0.0967
//         self.assertEqual(dimstack.utils.nround(McGrawHill_2.stack.WC.Z_min, 5), -0.02561)  # -0.0248

// 3.2 1365
// 5.7 1700
