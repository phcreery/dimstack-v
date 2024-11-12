module dimstack

import math

// [export: 'DimBasic']
pub struct DimBasic {
pub mut:
	nom  f64        @[required]
	tol  TTolerance @[required]
	a    f64    = 1 // global sensitivity
	name string = 'Dimension'
	desc string = 'Dimension'
}

pub fn (d DimBasic) dir() f64 {
	return direction_int(d.nom) * direction_int(d.a)
}

pub fn (d DimBasic) nom_direction_sign() string {
	if d.nom > 0 {
		return positve
	}
	return negative
}

pub fn (d DimBasic) median() f64 {
	return (d.rel_lower() + d.rel_upper()) / 2
}

// The minimum value of the measurement.
pub fn (d DimBasic) abs_lower() f64 {
	// return d.dir() * (d.nom + d.tol.lower) // / d.a
	return math.min[f64](d.nom + d.tol.lower, d.nom + d.tol.upper)
}

// The maximum value of the measurement.
pub fn (d DimBasic) abs_upper() f64 {
	// return d.dir() * (d.nom + d.tol.upper)
	return math.max[f64](d.nom + d.tol.lower, d.nom + d.tol.upper)
}

// The absolute minimum value of the tolerance.
pub fn (d DimBasic) abs_lower_tol() f64 {
	if d.dir() >= 0 {
		return d.tol.lower
	}
	return -d.tol.upper
}

// The absolute maximum value of the tolerance.
pub fn (d DimBasic) abs_upper_tol() f64 {
	if d.dir() >= 0 {
		return d.tol.upper
	}
	return -d.tol.lower
}

// The minimum value of the measurement. AKA, absolute lower
pub fn (d DimBasic) z_min() f64 {
	return d.abs_lower()
}

// The maximum value of the measurement. AKA, absolute upper
pub fn (d DimBasic) z_max() f64 {
	return d.abs_upper()
}

// The lower relative value of the measurement.
pub fn (d DimBasic) rel_lower() f64 {
	return d.dir() * (math.abs(d.nom) + d.tol.lower)
}

// The upper relative value of the measurement.
pub fn (d DimBasic) rel_upper() f64 {
	return d.dir() * (math.abs(d.nom) + d.tol.upper)
}

pub fn (mut d DimBasic) convert_to_symmetric_bilateral() DimBasic {
	// Convert the tolerance to a TolBilateral tolerance.
	median := (d.rel_upper() + d.rel_lower()) / 2
	tol := d.tol.t() / 2
	// return DimBasic{
	// 	nom: median
	// 	tol: SymmetricTolBilateral{
	// 		tol: tol
	// 	}
	// 	a: d.a
	// 	name: d.name
	// 	desc: d.desc
	// }
	d.nom = median
	d.tol = TolBilateral.symmetric(tol)
	return d
}

// TODO: from_statistical_dimension

pub struct DimStatistical {
	DimBasic
pub mut:
	process_sigma f64 = 6
	// k             f64
	dist IDistribution @[required]
	// distribution string = dist.DIST_NORMAL,
	// data=None,
}

// Convert a basic dimension to a statistical dimension.
pub fn DimStatistical.from_basic_dim(basic DimBasic) DimStatistical {
	mut dim := DimStatistical{
		nom:  basic.dir() * math.abs(basic.nom)
		tol:  basic.tol
		name: basic.name
		desc: basic.desc
		dist: Uniform{
			upper: basic.rel_upper()
			lower: basic.rel_lower()
		}
	}
	// dim.assume_normal_dist()
	return dim
}

// Assume a normal distribution.
pub fn (mut d DimStatistical) assume_normal_dist() DimStatistical {
	mean := d.mean_eff()
	stdev := (d.rel_upper() - d.rel_lower()) / (2 * d.process_sigma)
	dist := Normal{
		mean:  mean
		stdev: stdev
	}
	d.dist = dist
	return d
}

// Assume a normal distribution with a skew
pub fn (mut d DimStatistical) assume_normal_dist_skewed(skew f64) DimStatistical {
	d.assume_normal_dist()
	if mut d.dist is Normal { // which it will be
		d.dist.mean = d.dist.mean() + skew * (d.dist.stdev() * d.process_sigma)
	}
	return d
}

pub fn (d DimStatistical) yield_probability() f64 {
	ul := d.abs_upper()
	ll := d.abs_lower()
	return d.dist.cdf(ul) - d.dist.cdf(ll)
}

pub fn (d DimStatistical) yield_loss_probability() f64 {
	return 1 - d.yield_probability()
}

pub fn (d DimStatistical) mean_eff() f64 {
	// return (d.rel_upper() + d.rel_lower()) / 2
	return d.median()
}

// effective standard deviation
pub fn (d DimStatistical) stdev_eff() f64 {
	// return math.abs(d.tol.t()) / (6 * d.c_pk())
	// or, rearrage the equation
	match d.dist {
		Normal {
			outer_shift := math.min[f64]((d.rel_upper() - d.dist.mean()), (d.dist.mean() - d.rel_lower()))
			return (d.tol.t() * d.dist.stdev()) / (2 * outer_shift)
		}
		else {
			return 0
		}
	}
}

pub fn (d DimStatistical) k() f64 {
	match d.dist {
		Normal {
			ideal_process_stdev := (d.tol.t() / 2) / d.process_sigma
			skew_in_stdevs := (d.dist.mean() - d.mean_eff()) / ideal_process_stdev
			return skew_in_stdevs / d.process_sigma
		}
		else {
			return 0
		}
	}
}

pub fn (d DimStatistical) c_p() f64 {
	match d.dist {
		Normal {
			return calc_c_p(d.rel_upper(), d.rel_lower(), d.dist.stdev())
		}
		else {
			return 0
		}
	}
}

pub fn (d DimStatistical) c_pk() f64 {
	match d.dist {
		Normal {
			return calc_c_pk(d.rel_upper(), d.rel_lower(), d.dist.mean(), d.dist.stdev())
		}
		else {
			return 0
		}
	}
}

pub type TDimension = DimBasic | DimStatistical

// pub interface IDimension {
// 	nom f64
// 	tol ITolerance
// 	dist IDistribution
// 	a f64
// 	dir() f64
// 	// get_absolute_tolerance() TolBilateral
// 	tostring() string
// }

pub struct DimStack {
pub mut:
	dims []TDimension
	name string = 'Stack'
	desc string = 'Stack'
}

pub fn (mut s DimStack) append(d TDimension) {
	s.dims << d
}

pub struct Spec {
pub mut:
	name string
	desc string
	dim  TDimension
	ll   f64
	ul   f64
}

pub fn (s Spec) median() f64 {
	return (s.ll + s.ul) / 2
}

pub fn (s Spec) yield_probability() f64 {
	dim := s.dim
	if dim is DimStatistical {
		return dim.dist.cdf(s.ul) - dim.dist.cdf(s.ll)
	} else {
		return 0
	}
}

pub fn (s Spec) yield_loss_probability() f64 {
	return 1 - s.yield_probability()
}

pub fn (s Spec) r() f64 {
	return s.yield_probability() * 1000000
}
