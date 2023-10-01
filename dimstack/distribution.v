module dimstack

import math

// Process capability index.
// restricted to biletaral tolerances.
fn calc_c_p(ul f64, ll f64, stdev f64) f64 {
	return (ul - ll) / (6 * stdev)
}

// Process capability index. adjusted for centering.
fn calc_c_pk(ul f64, ll f64, mean f64, stdev f64) f64 {
	return math.min[f64]((ul - mean) / (3 * stdev), (mean - ll) / (3 * stdev))
	// return (1 - k) * C_p
}

fn uniform_pdf(x f64, lower f64, upper f64) f64 {
	if x < lower || x > upper {
		return 0
	}
	return 1 / (upper - lower)
}

fn uniform_cdf(x f64, lower f64, upper f64) f64 {
	if x < lower {
		return 0
	} else if x > upper {
		return 1
	}
	return (x - lower) / (upper - lower)
}

// https://people.sc.fsu.edu/~jburkardt/c_src/prob/prob.c
fn normal_pdf(x f64, mean f64, stdev f64) f64 {
	return f64((1 / (stdev * math.sqrt(2 * math.pi))) * math.exp(-0.5 * math.pow((x - mean) / stdev,
		2)))
}

fn normal_cdf(x f64, mean f64, stdev f64) f64 {
	return f64(0.5 * (1 + math.erf((x - mean) / (stdev * math.sqrt(2)))))
}

type TDistribution = Normal | Uniform

pub interface IDistribution {
	tostring() string
	// mean() f64
	// stdev() f64
	pdf(x f64) f64
	cdf(x f64) f64
}

// Uniform Distrubution
pub struct Uniform {
pub mut:
	upper f64 [required]
	lower f64 [required]
}

pub fn (u Uniform) tostring() string {
	return '[Uniform Distribution]'
}

pub fn (u Uniform) pdf(x f64) f64 {
	return uniform_pdf(x, u.lower, u.upper)
}

pub fn (u Uniform) cdf(x f64) f64 {
	return uniform_cdf(x, u.lower, u.upper)
}

pub fn (u Uniform) mean() f64 {
	return (u.upper + u.lower) / 2
}

pub fn (u Uniform) stdev() f64 {
	return f64(math.sqrt(math.pow(u.upper - u.lower, 2) / 12))
}

pub struct Normal {
pub mut:
	mean  f64
	stdev f64
}

pub fn (n Normal) tostring() string {
	// return 'Normal Distribution ± ${d.process_sigma}σ & k = ${d.k}'
	return '[Normal Distribution] μ = ${n.mean}, σ = ${n.stdev}'
}

pub fn (n Normal) mean() f64 {
	return n.mean
}

pub fn (n Normal) stdev() f64 {
	return n.stdev
}

pub fn (n Normal) pdf(x f64) f64 {
	return normal_pdf(x, n.mean, n.stdev)
}

pub fn (n Normal) cdf(x f64) f64 {
	return normal_cdf(x, n.mean, n.stdev)
}
