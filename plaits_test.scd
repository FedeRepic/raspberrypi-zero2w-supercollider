// =============================================
// MiPlaits - Ejemplos de prueba
// Port del módulo eurorack Plaits (Mutable Instruments)
// Engines: 0-virtual_analog, 1-waveshaping, 2-fm,
//   3-grain, 4-additive, 5-wavetable, 6-chord,
//   7-speech, 8-swarm, 9-noise, 10-particle,
//   11-string, 12-modal, 13-bass_drum,
//   14-snare_drum, 15-hi_hat
// =============================================

s.boot;


// ---- 1. Basics ----
// Oscilador simple, evaluar línea por línea
x = { MiPlaits.ar(35, 0, harm: 0.252, morph: 0.2, mul: 0.2) }.play;
x.free;


// ---- 2. Engine scan + vibrato ----
// Recorre engines aleatoriamente (puede haber clicks al cambiar)
(
{
	var pit = 50;
	var vib = SinOsc.ar(6, 0, 0.3);
	var e = LFNoise0.kr(0.5, 4, 4);
	MiPlaits.ar(pit + vib, e, mul: 0.2);
}.play;
)


// ---- 3. Virtual Analog (engine 0) ----
(
{
	var sig = MiPlaits.ar(
		pitch: 48, engine: 0,
		harm: 0.5, timbre: 0.5, morph: 0.3,
		mul: 0.5
	);
	sig[0].dup;
}.play;
)


// ---- 4. FM (engine 2) ----
// Timbre modulado con SinOsc lento
(
{
	var sig = MiPlaits.ar(
		pitch: 60, engine: 2,
		harm: 0.3,
		timbre: SinOsc.kr(0.1).range(0.2, 0.8),
		morph: 0.5,
		mul: 0.4
	);
	sig[0].dup;
}.play;
)


// ---- 5. Granular (engine 3) ----
(
{
	var sig = MiPlaits.ar(
		pitch: 55, engine: 3,
		harm: 0.6,
		timbre: LFNoise1.kr(0.3).range(0.1, 0.9),
		morph: LFNoise1.kr(0.2).range(0.0, 1.0),
		mul: 0.4
	);
	sig[0].dup;
}.play;
)


// ---- 6. Wavetable + trigger (engine 5) ----
(
{
	var trigger = Impulse.kr(8);
	var harm = LFNoise2.kr(0.3, 0.25, 0.25);
	var timbre = LFNoise1.kr(0.4, 0.5, 0.5);
	var dec = LFNoise2.kr(0.2).range(0.01, 0.8);
	MiPlaits.ar(44, 5, harm, timbre, 0, trigger, decay: dec, mul: 0.5);
}.play;
)


// ---- 7. Chord estático (engine 6) ----
(
{
	var sig = MiPlaits.ar(
		pitch: 28, engine: 6,
		harm: 0.5, timbre: 0.6, morph: 0.4,
		mul: 0.3
	);
	sig[0].dup;
}.play;
)


// ---- 8. Chords + trigger + mouse (engine 6) ----
// MouseY controla el tipo de acorde
(
{
	var harm = MouseY.kr(0, 1);
	var trigger = Impulse.kr(6);
	var lev = TRand.kr(trig: trigger);
	var out = MiPlaits.ar(
		40, 6, harm, 0.5, 0.5,
		trigger, lev.squared,
		decay: 0.5, timb_mod: 0.4, mul: 0.5
	);
	out[0] ! 2;
}.play;
)


// ---- 9. Chord progression automática (engine 6) ----
// Cambia de acorde cada 8 compases a 135 BPM
// 8 compases (4/4) = 32 beats => 32 / (135/60) ≈ 14.22 seg
(
{
	var bpm = 135;
	var bps = bpm / 60;
	var barDur = 4 / bps;               // duración de 1 compás
	var cycleDur = barDur * 8;           // duración de 8 compases (~14.22s)
	var cycleFreq = 1 / cycleDur;        // ~0.07 Hz

	// LFSaw sube de 0 a 1 en cada ciclo de 8 compases
	var harm = LFSaw.kr(cycleFreq).range(0.0, 1.0);

	// Trigger en negras para darle ritmo al acorde
	var trigger = Impulse.kr(bps);
	var lev = TRand.kr(0.4, 0.9, trigger);

	var out = MiPlaits.ar(
		pitch: 36, engine: 6,
		harm: harm,
		timbre: 0.55,
		morph: 0.5,
		//trigger: trigger,
		//level: lev,
		decay: 0.65,
		lpg_colour: 0.4,
		timb_mod: 0.2,
		mul: 0.45
	);
	out[0].dup;
}.play;
)


// ---- 10. Speech (engine 7) ----
(
{
	var sig = MiPlaits.ar(
		pitch: 28, engine: 7,
		harm: 0.3,
		timbre: LFSaw.kr(0.15).range(0.0, 1.0),
		morph: 0.5,
		mul: 0.5
	);
	sig[0].dup;
}.play;
)


// ---- 11. Speech interactivo (engine 7) ----
// MouseX = harm, MouseY = pitch
{ MiPlaits.ar(MouseY.kr(24, 72), 7, MouseX.kr(0, 1), 0.5, LFSaw.ar(0.11, 0, 0.5, 0.5)) }.play;


// ---- 12. Filtered Noise (engine 9) ----
(
{
	var harm = 0.575;
	var timbre = 0.02;
	var morph = LFNoise1.kr(0.3).range(0.55, 0.9);
	MiPlaits.ar(62, 9, harm, timbre, morph);
}.play;
)


// ---- 13. String (engine 11) + trigger rítmico ----
(
{
	var trig = Impulse.kr(2);
	var sig = MiPlaits.ar(
		pitch: 45, engine: 11,
		harm: 0.4, timbre: 0.6, morph: 0.3,
		trigger: trig, level: 0,
		decay: 0.7, lpg_colour: 0.5,
		mul: 0.5
	);
	sig[0].dup;
}.play;
)


// ---- 14. Modal Resonator + trigger (engine 12) ----
(
{
	var harm = LFNoise2.kr(0.2).range(0, 1);
	var trigger = Impulse.kr(1);
	var lev = TRand.kr(trig: trigger).squared;
	var out = MiPlaits.ar(56, 12, harm, 0.0, 0.85, trigger, lev);
	Mix.new(out) ! 2;
}.play;
)


// ---- 15. Bass Drum (engine 13) ----
(
{
	var trig = Impulse.kr(1.5);
	var sig = MiPlaits.ar(
		pitch: 36, engine: 13,
		harm: 0.3, timbre: 0.5, morph: 0.6,
		trigger: trig,
		decay: 0.6, lpg_colour: 0.3,
		mul: 0.6
	);
	sig[0].dup;
}.play;
)


// ---- 16. Hi-Hat (engine 15) ----
(
{
	var trig = Impulse.kr(4);
	var sig = MiPlaits.ar(
		pitch: 72, engine: 15,
		harm: 0.5, timbre: 0.7, morph: 0.4,
		trigger: trig,
		decay: 0.3, lpg_colour: 0.7,
		mul: 0.3
	);
	sig[0].dup;
}.play;
)


// ---- 17. Mini beat (engines 0 + 13 + 15) ----
(
{
	var bpm = 136;
	var beat = Impulse.kr(bpm / 60);
	var hat = Impulse.kr(bpm / 15);

	var kick = MiPlaits.ar(
		pitch: 36, engine: 13,
		harm: 0.2, timbre: 0.5, morph: 0.7,
		trigger: beat, decay: 0.5, lpg_colour: 0.2,
		mul: 0.6
	)[0];

	var hihat = MiPlaits.ar(
		pitch: 92, engine: 15,
		harm: 0.5, timbre: 0.8, morph: 0.3,
		trigger: hat, decay: 0.1, lpg_colour: 0.8,
		mul: 0.25
	)[0];

	var bass = MiPlaits.ar(
		pitch: 36, engine: 0,
		harm: 0.3, timbre: 0.4, morph: 0.2,
		trigger: beat, decay: 0.6, lpg_colour: 0.3,
		mul: 0.35
	)[0];

	(kick + hihat + bass).dup;
}.play;
)


// Para detener todo:
s.freeAll;
