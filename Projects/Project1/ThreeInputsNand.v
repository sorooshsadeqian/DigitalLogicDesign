`timescale 1ns/1ns
module ThreeInputsNand(input a,b,c,output w);
	wire g,z;
	supply1 Vdd;
	supply0 Gnd;
	pmos #(5,6,7) T1(w,Vdd,a);
	pmos #(5,6,7) T2(w,Vdd,b);
	pmos #(5,6,7) T3(w,Vdd,c);
	nmos #(3,4,5) T4(w,z,a);
	nmos #(3,4,5) T5(z,g,b);
	nmos #(3,4,5) T6(g,Gnd,c);
endmodule