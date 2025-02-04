//Synthesizable Floating Point Multiplier
`timescale 1ns/1ns
module FPMULT2(input clk,rst,input [31:0] inBus,input startFP,output [31:0] resBus,output reg doneFP);
    //states
    parameter 
      idle         = 4'd0,
      init         = 4'd1,
      get_a         = 4'd2,
      get_b         = 4'd3,
      unpack        = 4'd4,
      special_cases = 4'd5,
      normalise_a   = 4'd6,
      normalise_b   = 4'd7,
      multiply_add_0    = 4'd8,
      multiply_1    = 4'd9,
      normalise_1   = 4'd10,
      normalise_2   = 4'd11,
      round         = 4'd12,
      pack          = 4'd13,
      result        = 4'd14;
    reg [3:0] ns,ps;
    reg [31:0] Areg;
    reg [31:0] Breg;
    reg [31:0] z;
    reg [9:0] a_e, b_e, z_e;
    reg a_s, b_s, z_s;
    reg       guard, round_bit, sticky;
    reg       [47:0] product;
    reg       [31:0] s_output_z;
    reg       [23:0] a_m, b_m, z_m;

    always @(*) begin
      ns <= idle;
      case(ps)
        idle : ns <= startFP ? init : idle;
        init : ns <= startFP ? init : get_a;
        get_a: ns <= get_b;
        get_b: ns <= unpack;
        unpack: ns <= special_cases;
        special_cases : ns <= ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) 
                             || (a_e == 128) || (($signed(b_e) == -127) && (b_m == 0)) ||
                             (b_e == 128) || (($signed(a_e) == -127) && (a_m == 0)) ||
                             (($signed(b_e) == -127) && (b_m == 0))
                            ? result : normalise_a;
        normalise_a: ns <= a_m[23] ? normalise_b : normalise_a;
        normalise_b: ns <= b_m[23] ? multiply_add_0 : normalise_b;
        multiply_add_0: ns <= multiply_1;
        multiply_1: ns <= normalise_1;
        normalise_1: ns <= z_m[23] ? normalise_2 : normalise_1;
        normalise_2: ns <= ($signed(z_e) < -126) ? normalise_2 : round;
        round: ns <= pack;
        pack: ns <= result;
        result: ns <= idle;
      endcase
    end

    //Signals to be issued
    always @(*) begin
      doneFP <= 1'b0;
      case(ps)
          idle : begin
            doneFP <= 1'b1;
          end

          get_a:
          begin
            Areg <= inBus;        
          end

          get_b:
          begin
            Breg <= inBus;
          end

          unpack:
          begin
            a_m <= Areg[22 : 0];
            b_m <= Breg[22 : 0];
            a_e <= Areg[30 : 23] - 127;
            b_e <= Breg[30 : 23] - 127;
            a_s <= Areg[31];
            b_s <= Breg[31];
          end

          special_cases:
          begin
            //if a is NaN or b is NaN return NaN 
            if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
              z[31] <= 1;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
            //if a is inf return inf
            end else if (a_e == 128) begin
              z[31] <= a_s ^ b_s;
              z[30:23] <= 255;
              z[22:0] <= 0;
              //if b is zero return NaN
              if (($signed(b_e) == -127) && (b_m == 0)) begin
                z[31] <= 1;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
              end
            //if b is inf return inf
            end else if (b_e == 128) begin
              z[31] <= a_s ^ b_s;
              z[30:23] <= 255;
              z[22:0] <= 0;
              //if a is zero return NaN
              if (($signed(a_e) == -127) && (a_m == 0)) begin
                z[31] <= 1;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
              end
            //if a is zero return zero
            end else if (($signed(a_e) == -127) && (a_m == 0)) begin
              z[31] <= a_s ^ b_s;
              z[30:23] <= 0;
              z[22:0] <= 0;
            //if b is zero return zero
            end else if (($signed(b_e) == -127) && (b_m == 0)) begin
              z[31] <= a_s ^ b_s;
              z[30:23] <= 0;
              z[22:0] <= 0;
            end else begin
              //Denormalised Number
              if ($signed(a_e) == -127) begin
                a_e <= -126;
              end else begin
                a_m[23] <= 1;
              end
              //Denormalised Number
              if ($signed(b_e) == -127) begin
                b_e <= -126;
              end else begin
                b_m[23] <= 1;
              end
            end
          end

          normalise_a:
          begin
            doneFP <= 1'b1;
            if (a_m[23]) begin

            end else begin
              a_m <= a_m << 1;
              a_e <= a_e - 1;
            end
          end

          normalise_b:
          begin
            if (b_m[23]) begin
            end else begin
              b_m <= b_m << 1;
              b_e <= b_e - 1;
            end
          end
          multiply_add_0:
          begin
            z_s <= a_s ^ b_s;
            z_e <= a_e + b_e + 1;
            product <= a_m * b_m;
          end

          multiply_1:
          begin
            z_m <= product[47:24];
            guard <= product[23];
            round_bit <= product[22];
            sticky <= (product[21:0] != 0);
          end

          normalise_1:
          begin
            if (z_m[23] == 0) begin
              z_e <= z_e - 1;
              z_m <= z_m << 1;
              z_m[0] <= guard;
              guard <= round_bit;
              round_bit <= 0;
            end 
            
          end

          normalise_2:
          begin
            if ($signed(z_e) < -126) begin
              z_e <= z_e + 1;
              z_m <= z_m >> 1;
              guard <= z_m[0];
              round_bit <= guard;
              sticky <= sticky | round_bit;
            end
          end

          round:
          begin
            if (guard && (round_bit | sticky | z_m[0])) begin
              z_m <= z_m + 1;
              if (z_m == 24'hffffff) begin
                z_e <=z_e + 1;
              end
            end
          end

          pack:
          begin
            z[22 : 0] <= z_m[22:0];
            z[30 : 23] <= z_e[7:0] + 127;
            z[31] <= z_s;
            if ($signed(z_e) == -126 && z_m[23] == 0) begin
              z[30 : 23] <= 0;
            end
            //if overflow occurs, return inf
            if ($signed(z_e) > 127) begin
              z[22 : 0] <= 0;
              z[30 : 23] <= 255;
              z[31] <= z_s;
            end
          end

          result:
          begin
            s_output_z <= z;
            doneFP <= 1'b1;
          end

        endcase
    end

    //Sequential
    always @(posedge clk,posedge rst) begin
      if(rst)
        ps <= idle;
      else
        ps <= ns;
    end

  assign resBus = s_output_z;
endmodule