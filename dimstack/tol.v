module dimstack

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

pub fn (t TolBilateral) t() f64 {
	return f64(t.upper - t.lower)
}
