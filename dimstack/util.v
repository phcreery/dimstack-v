module dimstack

import math

const positve = '+'
const negative = '-'

// TODO: use math.sign
// Return the sign of x, i.e. -1, 0 or 1.
fn direction_int(x f64) f64 {
	if x > 0 {
		return 1
	} else if x < 0 {
		return -1
	}
	return 0
}

fn direction_symbol(x f64) string {
	if x >= 0 {
		return positve
	}
	return negative
}

fn nround(d f64) f64 {
	n := 5
	return f64(math.round_sig(d, n))
}

// Root sum square.

// >>> RSS_func(1, 2, 3)
// 3.7416573867739413
fn rss(args []f64) f64 {
	mut val := f64(0)
	for arg in args {
		val += f64(arg * arg)
	}
	val = f64(math.sqrt(val))
	return val
}
