# qqquaint
Multi-tuning playable quantizer for Monome Norns, Crow and Grid

qqquaint is a playable quantizer inspired for Monome Norns, Crow and Grid. It supports multiple tuning/tempering systems.
qqquaint doesn't make any sound on its own. It requires Monome Crow to interface with a modular synthesizer. Monome Grid is not required, but strongly recommended for maximum playability.

Crow input [1] takes in control voltage. Voltage range can be changed.
Crow input [2] takes in clock or trigger. On every rising edge (over 3V) input 1 voltage is quantized.
Crow output [1] puts out quantized root voltage.
Crow output [2] puts out an interval of root voltage (1-7 steps)
Crow output [3] puts out another interval of root voltage (1-7 steps)
Crow output [4] puts out pulse on every selected step of qqquaints step generator (requires Grid to change)

Scales are inside the code in an array, within an array. Maximum length of an octave is 24 intervals. 
qqquaint can take in custom scales as long as every tone within a scale is represented by mathematical formula from the root. Scales are put in an array with following format: 1. Scale name 2. How many intervals in an octave 3. Which interval number represents reference (A4 = 440 in regular 12TET).
12-tone equal temperament as an example: {"12TET", 12, 10, 1, 2^(1/12), 2^(2/12), 2^(3/12), 2^(4/12), 2^(5/12), 2^(6/12), 2^(7/12), 2^(8/12), 2^(9/12), 2^(10/12), 2^(11/12)}
Be careful with the format. Otherwise it will not work.

With Grid attached, there are many controls to play with.
1. Selecting notes that can play within the scale - represented with lights on Grid area from x2y2-x13y3.
2. Selecting steps for the step generator - represented with lights on x5y1-x10y1.
3. Looping last 10 quantized voltages - on/off on x1y6.
4. Transposition of quantized notes - represented with lights on x1y7-x13y7.
5. Octave selection - represented with lights on x1y8-x5y8. 
6. Drift of quantization - amount can be changed with Grid x9y7-x10y7.
7. Scale/tuning selection - changed with x15y1-x16y1.
8. Intervals of output [2] and [3] - represented with lights on x15y8-x16y2


