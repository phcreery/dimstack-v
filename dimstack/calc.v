module dimstack

import math

pub fn compute_closed(s DimStack) DimBasic {
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
		nom:  nominal
		tol:  tolerance
		name: '${s.name} - Closed Analysis'
		desc: ''
	}
}

// This is a simple WC calculation. This results in a Bilateral dimension with a tolerance that is the sum of the component tolerances.
// It states that in any combination of tolerances, you can be sure the result will be within the this resulting tolerance.
pub fn compute_wc(s DimStack) DimBasic {
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
		nom:  mean
		tol:  tolerance
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
pub fn compute_rss(s DimStack) DimStatistical {
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
		nom:  d_g
		tol:  tolerance
		name: '${s.name} - RSS Analysis'
		desc: '(assuming inputs with Normal Distribution & ± 3σ)'
		dist: Normal{}
	}
}

// Basically RSS with a coefficient modifier to make the tolerance tighter.
pub fn compute_mrss(s DimStack) DimStatistical {
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
		nom:           d_g
		tol:           tolerance
		name:          '${s.name} - RSS Analysis'
		desc:          '(assuming inputs with Normal Distribution & ± 3σ)'
		dist:          Normal{}
		process_sigma: sigma
	}
}

pub fn compute_six_sigma(s DimStack, at f64) DimStatistical {
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
		nom:           d_g
		tol:           tolerance
		name:          "${s.name} - '6 Sigma' Analysis"
		desc:          '(assuming inputs with Normal Distribution)'
		dist:          Normal{}
		process_sigma: at
	}
	dim.assume_normal_dist()
	return dim
}
