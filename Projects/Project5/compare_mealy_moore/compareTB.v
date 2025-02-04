`timescale 1 ns/ 1 ps
module moore10010TB();
	reg cclk = 0,jj,rrst;
	wire m1;
	wire m2;
	moore10010 MOORE(cclk,rrst,jj,m1);
	mealy10010 MEALY(cclk,rrst,jj,m2);
	always #50 cclk = ~cclk;
	initial begin
		#1 rrst = 1;
		#10 rrst = 0;
		#20 jj = 1;
		#30 jj = 0;
		#200 jj = 1;
		#100 jj = 0;
		#110 jj = 0;
		#110 jj = 1;
		#110 jj = 0;

		#200 $stop;
	end
endmodule
