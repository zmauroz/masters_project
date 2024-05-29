( // Server Config
s.options.outDevice = "ZenTour";
s.options.inDevice = "ZenTour";
s.options.blockSize = 32;
s.options.numOutputBusChannels = 16;
s.options.numInputBusChannels = 0;
s.options.sampleRate = 96e3;
s.options.memSize = 65536*4;
// s.options.numWireBufs = 256;
s.waitForBoot{
	StageLimiter.activate; // Just in case.
	s.meter;
	s.scope(4);
}
)

(
// ~td_reset.();

Ndef(\organic_patterns_b, {
    var sig, fb, pulse;
    var modFreq, modDepth, index, ratio, fb_freq_lfo, fb_freq_depth;
    var osc, freq_fb, n, outPuts, baseFreq, lfoFreq, lfoPhase, q_phase;
	var synth_1, synth_2, synth_3, radio, x, y, synth_f, harm;// synth var
	var synth_fx_low, synth_fx_high;
	var func_1 = { |x, y| sin(x) + cos(y) };
	var func_2 = { |x, y| sin(x) - (sin(y) * log(x * x + 1)) * 0.5 };
	var func_3 = { |x, y| sin( tan(x) * x ) + cos(tan(y))};
	var matrix_rev;
	var div, int, glitches, fq_r;
	var synth, rev, snd_out, clicks; // sound sources & fx

       // Número de osciladores y salidas
    n = 4;
    outPuts = 8;
	q_phase = [0, 0.5, 1, 1.5]*pi;
    // Frecuencia base y frecuencia del LFO para evolución lenta
    baseFreq = \baseFreq.kr(0.1); // Frecuencia base muy baja para evolución lenta
    lfoFreq = \lfoFreq.kr(0.0001); // Frecuencia del LFO muy baja para evolución lenta
	lfoPhase = q_phase * \lfoPhase.kr(1); // Fase del LFO

    // Parámetros de modulación
    modFreq = [2.5, 3.5, 2.0, 3.1] * 0.005;
    modDepth = [1.8, 1.4, 1.7, 1.6] * 0.8;
    index = [1, -1, -1, 1];
    ratio = [1, 3 / (4 * pi), 3 ** (1/3), 2.5] * 8;
	fb_freq_lfo = [1.4, -1.3333, -1.2, 1.1428];
	fb_freq_depth = 1;// \fb_freq_lfo_depth.kr(2);

    fb = LocalIn.ar(outPuts);

/*    freq_fb = SinOsc.kr(
        SinOsc.kr([1.1, 1.05, 0.95, 1.2] * 0.002, q_phase + lfoPhase)
            .range(baseFreq * (21/20), baseFreq * (21/20)) * lfoFreq
    );*/

	fb_freq_lfo = fb_freq_lfo * \fb_freq_lfo_f_scale.kr(1);
	freq_fb = SinOsc.ar(
		SinOsc.ar(fb_freq_lfo * pi).bipolar(fb_freq_depth) + fb_freq_lfo,
	).bipolar( \freq_fb_depth.kr(0.01) ) + \freq_fb_base.kr(0.1);

	index = SinOsc.ar([1.2, 0.965, 1.28, 0.935] * \index_fmod.kr(0.02))
        .range(0.2, 1.3) * index * \index_scale.kr(1.5);

    osc = Array.fill(n, { |i|
        var car, por;
		car = SinOsc.ar(freq_fb[i] * ratio[i], fb[i] * index[i] + q_phase[i], modDepth[i]);
		por = SinOsc.ar(0, modFreq[i] + car + q_phase[i]);
    });

	pulse = Array.fill(n, { |i|
        var car, por;
		car = SinOsc.ar(freq_fb[i] * ratio[i], fb[i+4] * index[i] + (q_phase[i]*0), modDepth[i]).range(0.5, 13);
		por = LFPulse.ar(modFreq[i] + car + (q_phase[i]*0), 0, 0.1);
    });

	osc = LeakDC.ar(osc**2); // la potencia es un parametro a modificar
	// pulse = PulseDivider.ar(osc, 100);
	// pulse = Trig.ar(pulse, 0.1);
	fb = osc ++ pulse;
    // Salida de retroalimentación local
    LocalOut.ar(fb);

	Out.kr(~td_busses[0], fb);

	// --------------------------------- SYNTH ---------------------------------

	synth_f = \freq.kr(36);
	synth_f = LFTri.kr(0.001, 0.5pi).range(synth_f * 16/19, synth_f * 19/16);
	synth_f = synth_f * SinOsc.kr([1, 1.105, 0.97, 1.237] * 0.001, q_phase*0.1).range(0.9803, 1.01943); // slow 1/3t gliss osc

	radio = (osc ** (2/2)) * \radio_s1.kr(4) + 1;
	harm = [1, 0.99, 1.01, 1] * synth_f;
	x = radio * SinOsc.ar( harm + SinOsc.ar([1, 1.01, 0.97, 1.1] * 0.1).range(15/16, 16/15));
	y = radio * SinOsc.ar( harm + SinOsc.ar([1, 0.9804, 1.0294, 0.9403] * 0.1).range(15/16, 16/15), 0.5pi);
	synth_1 = func_1.(x.lag(0.005), y.lag(0.005)).rotate;
	// synth_1 = func_1.(x, y).rotate;
	synth_fx_low = LPF.ar(LPF.ar(synth_1, 300), 300);
	synth_fx_high = HPF.ar(HPF.ar(synth_1, 300), 300);
	synth_fx_low = (AllpassL.ar(OSFold4.ar(synth_fx_low * 4, -1, 1), 0.1, [0.03061, 0.0378, 0.0509, 0.02735], 1)*0.5) + synth_fx_low;
	synth_1 = synth_fx_low + synth_fx_high;
	synth_1 = LPF.ar(LPF.ar(synth_1, 8e3), 8e3);

	radio = osc * \radio_s2.kr(1.3) + 1;
	// harm = [32/9, 8/3, 5, 19/16 /*16/5*/] * synth_f; // 3m 4 3M 3m
	// harm = [9/4, 8/3, 7/2, 12/5] * synth_f; // 2 4 7m
	harm = [8/3, 19/16, 3, 12/5] * synth_f * 4; // 4 3m 5 7m
	x = radio.rotate * SinOsc.ar( (SinOsc.ar([0.992, 1.04, 1.0325, 0.9719] * 0.0029).range(6/7, 7/6)) * harm);
	y = radio.rotate * SinOsc.ar( (SinOsc.ar([1.05, 0.93, 0.97, 1.07] * 0.0032).range(6/7, 7/6)) * harm, 0.5pi);
	synth_2 = LPF.ar(func_2.(x, y), 12e3);
	synth_fx_low = LPF.ar(LPF.ar(synth_2, 600), 600);
	synth_fx_high = HPF.ar(HPF.ar(synth_2, 600), 600);
	synth_fx_low = AllpassL.ar(synth_fx_low, 0.1, [0.0172, 0.0528, 0.0826, 0.06295], 0.7) + synth_fx_low;
	synth_2 = synth_fx_low + synth_fx_high;
	synth_2 = LPF.ar(LPF.ar(synth_2, 18e3), 18e3);

	radio = LPF.ar(pulse, 10) * (osc+1) * \radio_s3.kr(1.3);
	// harm = [32/9, 8/3, 5, 19/16 /*16/5*/] * synth_f; // 3m 4 3M 3m
	// harm = [9/4, 8/3, 7/2, 12/5] * synth_f; // 2 4 7m
	harm = [8/3, 19/16, 3, 12/5] * synth_f * 4; // 4 3m 5 7m
	x = radio.rotate * SinOsc.ar( (SinOsc.ar([0.992, 1.04, 1.0325, 0.9719] * baseFreq).range(14/15, 15/14)) * harm);
	y = radio.rotate * SinOsc.ar( (SinOsc.ar([1.05, 0.93, 0.97, 1.07] * baseFreq).range(14/15, 15/14)) * harm, 0.5pi);
	synth_3 = LPF.ar(func_3.(x.lag(0.015), y.lag(0.015)), 12e3);
/*	div = PulseDivider.kr(LPF.ar(osc, 500), 2);
	div = Trig.ar(div, 0.01);*/
	synth_3 = synth_3 * Env.perc(0.001, 0.01).kr(gate: pulse);
	synth_3 = synth_3.rotate.rotate;

	synth_1 = synth_1 * \synth_1.kr(0.5);
	synth_2 = synth_2 * \synth_2.kr(0.1);
	synth_3 = synth_3 * \synth_3.kr(0.0);
	synth =  synth_1 + synth_2 + synth_3;
	synth = LeakDC.ar(synth);
	synth = (AllpassN.ar(synth.rotate, 0.1, [0.0192037, 0.020181, 0.01899714, 0.0197263], 1) * 0.5) + synth;

	// --------------------------------- NOISE ---------------------------------
	div = PulseDivider.kr(LPF.ar(osc, 100), 2);
	div = Trig.ar(div, 0.01);
	fq_r = Latch.ar(div**2, div);
	fq_r = (fq_r*2000).fold(30, 2500);

	int = Integrator.ar( (fq_r.rotate) * TChoose.kr(div, [-2, 1]), 1) * TRand.kr(0.001, 0.1, div);
	glitches = LPF.ar((OSFold4.ar(int, -1, 1) * 1.5), 16e3) * 2;// * Env.asr(0.01, 0.707, 0.2).kr(gate: aux);
	glitches = LeakDC.ar(glitches);
	glitches = Sanitize.ar(glitches, 0);
	glitches = AllpassN.ar(glitches.rotate, 0.1, 0.08192, 2) * 0.5 + AllpassN.ar(glitches.rotate.rotate, 0.1, 0.05192, 0.7) * 0.2 + glitches;
	glitches = CombN.ar(glitches, 0.1, 0.1, 1) + glitches;
	glitches = glitches * \glitches.kr(0);


	// --------------------------------- PERCs ---------------------------------

	// clicks = PinkNoise.ar(1) * Env.perc(0.001, 0.01).kr(gate: pulse);

	// --------------------------------- REVERB ---------------------------------
	rev = (HPF.ar(LPF.ar(synth_1, 2500), 150) * 0.5 ) + (HPF.ar(synth_2, 800) * 0.5) + (synth_2+synth_1*0.5) + (glitches * 0.5);
	12.do { |i|
		4.do { |j|
			rev[j] = LPF.ar(
				AllpassC.ar(
					rev[j],
					0.02,
					delaytime: LFNoise1.kr(\mod_freq.kr(0.3)).range(\min_dly.kr(0.01),\max_dly.kr(0.02)),
					decaytime: \decay_time.kr(0.1)
				),
				12e3
			);
		}
	};

	matrix_rev = [
		[0, -6, -12, -6],
		[-6, 0, -6, -12],
		[-12, -6, 0, -6],
		[-6, -12, -6, 0]
	] * 1.3;

	matrix_rev = matrix_rev.dbamp;
	rev = matrix_rev.collect{ |m| Mix.ar(rev * m) };

	// --------------------------------- MIXER ----------------------------------

	snd_out = (synth * \synth_amp.kr(1)) + (rev * \rev_amp.kr(0.707)) + (glitches * 0.707); //+ (clicks * 4);
	snd_out = LeakDC.ar(snd_out);
	snd_out = LPF.ar(snd_out, 18e3);
	(snd_out*\amp.kr(0.5)).tanh;
}).play;

)

(
// Sintes mix
Ndef(\organic_patterns_b).set(\synth_1, 0.5, \synth_2, 0.5, \synth_3, 0.3, \radio_s1, 1, \radio_s2, 5, \radio_s3, 10);
Ndef(\organic_patterns_b).set(\freq_fb_base, 0.03, /*\fb_freq_lfo_depth, 1,*/ \freq_fb_depth, 0.01, \fb_freq_lfo_f_scale, 0.1); // timing
Ndef(\organic_patterns_b).set(\index_scale, 1.5, \index_fmod, 100);

Ndef(\organic_patterns_b).set(\synth_1, 0.0, \synth_2, 0.5, \synth_3, 0.8, \radio_s1, 1, \radio_s2, 2, \radio_s3, 150);

Ndef(\organic_patterns_b).set(\synth_1, 0.89, \synth_2, 0.0, \synth_3, 0.0, \radio_s1, 1, \radio_s2, 1, \radio_s3, 1);
Ndef(\organic_patterns_b).set(\synth_1, 0.89, \synth_2, 0.3, \synth_3, 1, \radio_s1, 1, \radio_s2, 2, \radio_s3, 3);
Ndef(\organic_patterns_b).set(\synth_1, 0.1, \synth_2, 0.0, \synth_3, 0.3, \radio_s1, 1, \radio_s2, 20, \radio_s3, 10);
Ndef(\organic_patterns_b).set(\synth_1, 0.0, \synth_2, 0.0, \synth_3, 0.8, \radio_s1, 3, \radio_s2, 3, \radio_s3, 15);
Ndef(\organic_patterns_b).set(\synth_1, 0.89, \synth_2, 0.3,  \synth_3, 0.8, \radio_s1, 2, \radio_s2, 1.8, \radio_s3, 12);
Ndef(\organic_patterns_b).set(\synth_2, 0.5, \synth_1, 0.3, \synth_3, 0, \radio_s2, 15, \radio_s3, 3, \radio_s1, 30, \radio_s2, 1.3);
Ndef(\organic_patterns_b).set(\synth_2, 0.5, \synth_1, 0.4, \synth_3, 0.707, \radio_s1, 1, \radio_s2, 2, \radio_s3, 1);
Ndef(\organic_patterns_b).set(\synth_2, 0.0, \synth_1, 0.9, \synth_3, 0.7, \radio_s1, 5, \radio_s2, 1.5, \radio_s3, 20);
Ndef(\organic_patterns_b).set(\synth_2, 0.05, \synth_1, 0.0, \synth_3, 0.707, \radio_s1, 3, \radio_s2, 10, \radio_s3, 15);
)

(
// P1
Ndef(\organic_patterns_b).set(\baseFreq, 0.001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.01); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 3); // Menos modulación
r.stop;
r = ~td_msg.value;
)

Ndef(\organic_patterns_b).set(\amp, 0.5); // Menos modulación

(// P0
Ndef(\organic_patterns_b).set(\synth_2, 0.3, \synth_1, 0.5); // Sintes mix
Ndef(\organic_patterns_b).set(\baseFreq, 0.1); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.0001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 1); // Menos modulación
)

(// P1
Ndef(\organic_patterns_b).set(\synth_2, 0.3, \synth_1, 0.5); // Sintes mix
Ndef(\organic_patterns_b).set(\baseFreq, 0.001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.01); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 2); // Menos modulación
)

(// P2
Ndef(\organic_patterns_b).set(\synth_2, 0.3, \synth_1, 0.5); // Sintes mix
Ndef(\organic_patterns_b).set(\baseFreq, 0.001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.01); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 9); // Menos modulación
)

(// P3
Ndef(\organic_patterns_b).set(\synth_2, 0.0, \synth_1, 0.5); // Sintes mix
Ndef(\organic_patterns_b).set(\baseFreq, 1); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.1); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 10); // Menos modulación
)

(// P4
Ndef(\organic_patterns_b).set(\synth_2, 0.1, \synth_1, 0.5); // Sintes mix
Ndef(\organic_patterns_b).set(\baseFreq, 0.0001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\lfoFreq, 0.00001); // Evolución aún más lenta
Ndef(\organic_patterns_b).set(\index_scale, 2); // Menos modulación
)