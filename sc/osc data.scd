(
OSCdef(\fromTD_freq_fb_depth, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\freq_fb_depth, val); // timing
}, \freq_fb_depth);

OSCdef(\fromTD_freq_fb_base, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\freq_fb_base, val); // timing
}, \freq_fb_base);

OSCdef(\fromTD_index_scale, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\index_scale, val); // timing
}, \index_scale);

OSCdef(\fromTD_index_fmod, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\index_fmod, val); // timing
}, \index_fmod);

//////////////////////
OSCdef(\fromTD_synth_1, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\synth_1, val); // timing
}, \synth_1);

OSCdef(\fromTD_synth_2, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\synth_2, val); // timing
}, \synth_2);

OSCdef(\fromTD_synth_3, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\synth_3, val); // timing
}, \synth_3);
////
OSCdef(\fromTD_rad_s1, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\radio_s1, val); // timing
}, \synth_1_rad);

OSCdef(\fromTD_rad_s2, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\radio_s2, val); // timing
}, \synth_2_rad);

OSCdef(\fromTD_rad_s3, { |i|
	var val;
	val = i[1];
	// val.postln;
	Ndef(\organic_patterns_b).set(\radio_s3, val); // timing
}, \synth_3_rad);
)