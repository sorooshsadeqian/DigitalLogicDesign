`timescale 1ns/1ns
module MyMUX2(
	input s0,s1,a,b,c,d,
	output y
);
	wire s0_not,s1_not,g,z;
	MyInverter inverter_gate1(s0,s0_not);
	MyInverter inverter_gate2(s1,s1_not);

	MyTriStateBuffer not_buffer1(a,s0_not,g);
	MyTriStateBuffer not_buffer2(b,s0,g);
	MyTriStateBuffer not_buffer3(c,s0_not,z);
	MyTriStateBuffer not_buffer4(d,s0,z);

	MyTriStateBuffer not_buffer5(g,s1_not,y);
	MyTriStateBuffer not_buffer6(z,s1,y);
endmodule