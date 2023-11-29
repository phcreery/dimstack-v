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

pub fn (d DimBasic) tostring() string {
	return '[Basic Dimension] ${d.name}: ${d.nom_direction_sign()}${d.nom} ${d.tol.tostring()} [${d.rel_lower()}, ${d.rel_upper()}]'
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
	return d.dir() * (d.nom + d.tol.lower) // / d.a
}

// The maximum value of the measurement.
pub fn (d DimBasic) abs_upper() f64 {
	return d.dir() * (d.nom + d.tol.upper)
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

pub fn (d DimStatistical) tostring() string {
	return '[Statistical Dimension] ${d.name}: ${d.nom_direction_sign()}${d.nom} ${d.tol.tostring()} [${d.rel_lower()}, ${d.rel_upper()}] @ ${d.dist.tostring()} (C_p = ${d.c_p()}, C_pk = ${d.c_pk()}, k = ${d.k()}) (stdev_eff = ${d.stdev_eff()}, mean_eff = ${d.mean_eff()})'
}

// Convert a basic dimension to a statistical dimension.
pub fn DimStatistical.from_basic_dim(basic DimBasic) DimStatistical {
	mut dim := DimStatistical{
		nom: basic.dir() * math.abs(basic.nom)
		tol: basic.tol
		name: basic.name
		desc: basic.desc
		dist: Normal{}
	}
	dim.assume_normal_dist()
	return dim
}

// Assume a normal distribution.
pub fn (mut d DimStatistical) assume_normal_dist() DimStatistical {
	mean := d.mean_eff()
	stdev := (d.rel_upper() - d.rel_lower()) / (2 * d.process_sigma)
	dist := Normal{
		mean: mean
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
	ul := d.rel_upper()
	ll := d.rel_lower()
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

pub fn (s DimStack) tostring() string {
	return '[Stack] ${s.name}: ${s.dims.len} dimensions'
}

pub fn (mut s DimStack) append(d TDimension) {
	s.dims << d
}

pub fn (s DimStack) compute_closed() DimBasic {
	// Compute the closed dimension of the stack.
	mut nominal := f64(0)
	mut upper := f64(0)
	mut lower := f64(0)
	for dim in s.dims {
		// d = dim as DimBasic
		match dim {
			DimBasic {
				nominal += dim.dir() * math.abs(dim.nom) * dim.a
				upper += dim.abs_upper_tol()
				lower += dim.abs_lower_tol()
			}
			DimStatistical {
				nominal += dim.dir() * math.abs(dim.nom) * dim.a
				upper += dim.abs_upper_tol()
				lower += dim.abs_lower_tol()
			}
			// else {}
		}
	}
	tolerance := TolBilateral{
		lower: lower
		upper: upper
	}
	return DimBasic{
		nom: nominal
		tol: tolerance
		name: '${s.name} - Closed Analysis'
		desc: ''
	}
}

// This is a simple WC calculation. This results in a Bilateral dimension with a tolerance that is the sum of the component tolerances.
// It states that in any combination of tolerances, you can be sure the result will be within the this resulting tolerance.
pub fn (s DimStack) compute_wc() DimBasic {
	mut mean := f64(0)
	mut t_wc := f64(0)
	for dim in s.dims {
		match dim {
			DimBasic {
				mean += dim.dir() * math.abs(dim.median()) * dim.a
				t_wc += math.abs(dim.a * (dim.tol.t() / 2))
			}
			DimStatistical {
				mean += dim.dir() * math.abs(dim.median()) * dim.a
				t_wc += math.abs(dim.a * (dim.tol.t() / 2))
			}
			// else {}
		}
	}
	tolerance := TolBilateral.symmetric(t_wc)
	return DimBasic{
		nom: mean
		tol: tolerance
		name: '${s.name} - WC Analysis'
		desc: ''
	}
}

// This is a simple RSS calculation. This is uses the RSS calculation method in the Dimensioning and Tolerancing Handbook, McGraw Hill.
// It is really only useful for a Bilateral stack of same process-stdev items. The RSS result has the same uncertainty as the measurements.
// Historically, Eq. (9.11) assumed that all of the component tolerances (t_i) represent a 3si value for their
// manufacturing processes. Thus, if all the component distributions are assumed to be normal, then the
// probability that a dimension is between ±t_i is 99.73%. If this is true, then the assembly gap distribution is
// normal and the probability that it is ±t_rss between is 99.73%.
// Although most people have assumed a value of ±3s for piecepart tolerances, the RSS equation works
// for “equal s” values. If the designer assumed that the input tolerances were ±4s values for the piecepart
// manufacturing processes, then the probability that the assembly is between ±t_rss is 99.9937 (4s).
// The 3s process limits using the RSS Model are similar to the Worst Case Model. The minimum gap is
// equal to the mean value minus the RSS variation at the gap. The maximum gap is equal to the mean value
// plus the RSS variation at the gap.
// See:
//  - Dimensioning and Tolerancing Handbook, McGraw Hill
//  - http://files.engineering.com/getfile.aspx?folder=69759f43-e81a-4801-9090-a0c95402bfc0&file=RSS_explanation.GIF
pub fn (s DimStack) compute_rss() DimStatistical {
	mut dims := []DimStatistical{}
	for dim in s.dims {
		match dim {
			DimBasic {
				dims << DimStatistical.from_basic_dim(dim)
			}
			DimStatistical {
				dims << dim
			}
			// else {}
		}
	}

	mut d_g := f64(0)
	mut t_rss_vals := []f64{}
	for dim in dims {
		d_g += dim.dir() * math.abs(dim.mean_eff()) * dim.a
		t_rss_vals << dim.dir() * (dim.tol.t() / 2) * dim.a
	}
	t_rss := rss(t_rss_vals)

	tolerance := TolBilateral.symmetric(t_rss)
	return DimStatistical{
		nom: d_g
		tol: tolerance
		name: '${s.name} - RSS Analysis'
		desc: '(assuming inputs with Normal Distribution & ± 3σ)'
		dist: Normal{}
	}
}

// Basically RSS with a coefficient modifier to make the tolerance tighter.
pub fn (s DimStack) compute_mrss() DimStatistical {
	mut dims := []DimStatistical{}
	for dim in s.dims {
		match dim {
			DimBasic {
				dims << DimStatistical.from_basic_dim(dim)
			}
			DimStatistical {
				dims << dim
			}
			// else {}
		}
	}

	mut d_g := f64(0)
	mut t_wc := f64(0)
	mut t_rss_vals := []f64{}
	n := dims.len
	for dim in dims {
		d_g += dim.dir() * math.abs(dim.mean_eff()) * dim.a
		t_wc += math.abs(dim.dir() * (dim.tol.t() / 2) * dim.a)
		t_rss_vals << dim.dir() * (dim.tol.t() / 2) * dim.a
	}
	t_rss := rss(t_rss_vals)

	c_f := (0.5 * (t_wc - t_rss)) / (t_rss * (math.sqrt(n) - 1)) + 1
	t_mrss := f64(c_f * t_rss)

	stdev := t_wc / 6
	sigma := f64(t_mrss / stdev)

	tolerance := TolBilateral.symmetric(t_mrss)
	return DimStatistical{
		nom: d_g
		tol: tolerance
		name: '${s.name} - RSS Analysis'
		desc: '(assuming inputs with Normal Distribution & ± 3σ)'
		dist: Normal{}
		process_sigma: sigma
	}
}

pub fn (s DimStack) compute_six_sigma(at f64) DimStatistical {
	mut dims := []DimStatistical{}
	for dim in s.dims {
		match dim {
			DimBasic {
				dims << DimStatistical.from_basic_dim(dim)
			}
			DimStatistical {
				dims << dim
			}
			// else {}
		}
	}

	mut d_g := f64(0)
	mut stdev_vals := []f64{}
	for dim in dims {
		d_g += dim.dir() * math.abs(dim.mean_eff()) * dim.a
		stdev_vals << dim.stdev_eff()
	}
	stdev := rss(stdev_vals)

	tolerance := TolBilateral.symmetric(stdev * at)
	mut dim := DimStatistical{
		nom: d_g
		tol: tolerance
		name: "${s.name} - '6 Sigma' Analysis"
		desc: '(assuming inputs with Normal Distribution)'
		dist: Normal{}
		process_sigma: at
	}
	dim.assume_normal_dist()
	return dim
}

pub struct Spec {
pub mut:
	name string
	desc string
	dim  TDimension
	ll   f64
	ul   f64
}

pub fn (s Spec) tostring() string {
	dim := s.dim as DimStatistical
	return '[Spec] ${s.name}: ${dim.tostring()} [${s.ll} ${s.ul}]'
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
