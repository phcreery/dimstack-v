import dimstack
import math

fn test_c_p() {
	assert dimstack.calc_c_p(1, 0, 1) == 0.16666666666666666
	assert dimstack.calc_c_p(6, -6, 1) == 2
}

fn test_c_pk() {
	assert math.round_sig(dimstack.calc_c_pk(208.036, 207.964, 208.009, 0.006), 3) == 1.5
	assert dimstack.calc_c_p(6, -6, 1) == 2
}
