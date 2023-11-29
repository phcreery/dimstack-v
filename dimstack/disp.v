module dimstack

import math
import arrays
import serkonda7.termtable

fn gettable(data [][]string) string {
	table := termtable.Table{
		data: data
		style: .pretty
		orientation: .column
		padding: 1
		header_style: .plain
	}
	return table.str()
}

pub fn (t TolBilateral) tostring() string {
	if t.upper == -t.lower {
		return '± ${t.upper}'
	}
	return '${direction_symbol(t.upper)} ${math.abs(t.upper)} / ${direction_symbol(t.lower)} ${math.abs(t.lower)}'
}

pub fn (d DimBasic) tostring() string {
	return '[Basic Dimension] ${d.name}: ${d.nom_direction_sign()}${d.nom} ${d.tol.tostring()} [${d.rel_lower()}, ${d.rel_upper()}]'
}

pub fn (d DimBasic) totable() string {
	data := [
		['Name', '${d.name}'],
		['Desc.', '${d.desc}'],
		['Nom.', '${d.nom_direction_sign()}${math.abs(d.nom)}'],
		['Tol.', '${d.tol.tostring()}'],
		['Relative Bounds', '[${d.rel_lower()} ${d.rel_upper()}]'],
		// ['', ''],
	]
	return gettable(data)
}

pub fn (d DimStatistical) tostring() string {
	return '[Statistical Dimension] ${d.name}: ${d.nom_direction_sign()}${d.nom} ${d.tol.tostring()} [${d.rel_lower()}, ${d.rel_upper()}] @ ${d.dist.tostring()} (C_p = ${d.c_p()}, C_pk = ${d.c_pk()}, k = ${d.k()}) (stdev_eff = ${d.stdev_eff()}, mean_eff = ${d.mean_eff()})'
}

pub fn (d DimStatistical) totable() string {
	data := [
		['Name', '${d.name}'],
		['Desc.', '${d.desc}'],
		['Nom.', '${d.nom_direction_sign()}${math.abs(d.nom)}'],
		['Tol.', '${d.tol.tostring()}'],
		['Sens. (a)', '${d.a}'],
		['Relative Bounds', '[${d.rel_lower()} ${d.rel_upper()}]'],
		['Distribution', '${d.dist.tostring()}'],
		['Process Sigma', '± ${d.process_sigma}σ'],
		['Skew (k)', '${math.round_sig(d.k(), 4)}'],
		['C_p', '${math.round_sig(d.c_p(), 4)}'],
		['C_pk', '${math.round_sig(d.c_pk(), 4)}'],
		['μ_eff', '${math.round_sig(d.mean_eff(), 4)}'],
		['σ_eff', '${math.round_sig(d.stdev_eff(), 4)}'],
	]
	return gettable(data)
}

pub fn (s DimStack) tostring() string {
	return '[Stack] ${s.name}: ${s.dims.len} dimensions'
}

pub fn (s DimStack) totable() string {
	mut data := [
		[
			'Name',
			'Desc.',
			'Nominal',
			'Tol.',
			'Sens. (a)',
			'Relative Bounds',
			'Distribution',
			'Process Sigma',
			'Skew (k)',
			'C_p',
			'C_pk',
			'μ_eff',
			'σ_eff',
			'Yield Probability',
			'Reject PPM',
		],
	]

	for d in s.dims {
		match d {
			DimBasic {
				data = arrays.concat(data, [
					'${d.name}',
					'${d.desc}',
					'${d.nom_direction_sign()}${math.abs(d.nom)}',
					'${d.tol.tostring()}',
					'${d.a}',
					'[${d.rel_lower()} ${d.rel_upper()}]',
					'',
					'',
					'',
					'',
					'',
					'',
					'',
					'',
					'',
				])
			}
			DimStatistical {
				data = arrays.concat(data, [
					'${d.name}',
					'${d.desc}',
					'${d.nom_direction_sign()}${math.abs(d.nom)}',
					'${d.tol.tostring()}',
					'${d.a}',
					'[${d.rel_lower()} ${d.rel_upper()}]',
					'${d.dist.tostring()}',
					'± ${d.process_sigma}σ',
					'${math.round_sig(d.k(), 4)}',
					'${math.round_sig(d.c_p(), 4)}',
					'${math.round_sig(d.c_pk(), 4)}',
					'${math.round_sig(d.mean_eff(), 4)}',
					'${math.round_sig(d.stdev_eff(), 4)}',
					'${math.round_sig(d.yield_probability() * 100, 6)}',
					'${math.round_sig(d.yield_loss_probability() * 1_000_000, 2)}',
				])
			}
			// else {}
		}
	}
	table := termtable.Table{
		data: data
		style: .pretty
		orientation: .row
		padding: 1
		header_style: .plain
	}
	return table.str()
}


pub fn (s Spec) tostring() string {
	dim := s.dim as DimStatistical
	return '[Spec] ${s.name}: ${dim.tostring()} [${s.ll} ${s.ul}]'
}

pub fn (s Spec) totable() string {
	dim := match s.dim {
		DimBasic {
			DimStatistical.from_basic_dim(s.dim)
		}
		DimStatistical {
			s.dim
		}
	}
	data := [
		['Name', '${s.name}'],
		['Desc.', '${s.desc}'],
		['Dimension', '${dim.tostring()}'],
		['Median', '${s.median}'],
		['Spec. Limits', '[${s.ll}, ${s.ul}]'],
		['Yield Probability', '${math.round_sig(dim.yield_probability() * 100, 6)}'],
		['Reject PPM', '${math.round_sig(dim.yield_loss_probability() * 1_000_000, 2)}'],
	]
	return gettable(data)
}
