module dimstack

import math

pub type TTolerance = TolBilateral

// interface ITolerance {
// 	upper f64
// 	lower f64
// 	tostring() string
// 	t() f64
// }

pub struct TolBilateral {
pub mut:
	upper f64 @[required]
	lower f64 @[required]
}

pub fn TolBilateral.symmetric(tol f64) TolBilateral {
	return TolBilateral{
		upper: tol
		lower: -tol
	}
}

pub fn TolBilateral.asymmetric(upper f64, lower f64) TolBilateral {
	if upper < lower {
		return TolBilateral{
			upper: lower
			lower: upper
		}
	}
	return TolBilateral{
		upper: upper
		lower: lower
	}
}

pub fn TolBilateral.unequal(upper f64, lower f64) TolBilateral {
	if upper < lower {
		return TolBilateral{
			upper: lower
			lower: upper
		}
	}
	return TolBilateral{
		upper: upper
		lower: lower
	}
}

pub fn (t TolBilateral) tostring() string {
	if t.upper == t.lower {
		return '[TolBilateral Tolerance] ± ${t.upper}'
	}
	return '[TolBilateral Tolerance] ${direction_symbol(t.upper)} ${t.upper} / ${direction_symbol(t.lower)} ${t.lower}'
}

pub fn (t TolBilateral) t() f64 {
	return f64(t.upper - t.lower)
}

// // TODO: convert_to_symmetric
// fn (t UnequalTolBilateral) convert_to_symmetric() SymmetricTolBilateral {
// 	// Convert the tolerance to a TolBilateral tolerance.
// 	median := (t.upper() + t.lower()) / 2
// 	tol := t.t()
// }
