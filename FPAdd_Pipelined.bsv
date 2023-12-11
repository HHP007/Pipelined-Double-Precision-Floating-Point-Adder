
// CAD For VLSI (CS6230) Final Project
// Project Title : P2. Pipelined double precision( fp64 ) floating point adder
// Author : HARIHARAN P (EE20B042)  AND  JAWHAR S (EE20B049)
// Date: 10 Dec 2023

// If one of the input is NAN, then the output will always be NAN which will be represented as 64'b0111111111111111111111111111111111111111111111111111111111111110
// In one of the input is -infinity and another is + infinity, the output should ideally throw error for a FPadder 
//      which will be represented as 64'b0111111111111111111111111111111111111111111111111111111111111111
// This FPAdder has 6 stages, so the first output of 1st set of inputs comes at time = 75 and for next subsequent cycle, the outputs of the subsequent inputs arrives.


// Test-bench for providing inputs to the design and getting the output  
(* synthesize *)
module mkTest (Empty);
    FPadd_ifc m <- mkFPadd;

    Reg #(Bit #(10)) rg_y<- mkReg (0); //clock counter

    rule rl_go;   //Each inputs in each clock cycle
        if(rg_y == 'h0) begin 
            m.put_A (64'b0100000001101001000100000000000000000000000000000000000000000000);  // Positive + positive
            m.put_B (64'b0100000000101000010110100001110010101100000010000011000100100111);
        end
        else if(rg_y == 'h1) begin 
            m.put_A (64'b1100000001101001000100000000000000000000000000000000000000000000);  // Negative + negative
            m.put_B (64'b1100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h2) begin
            m.put_A (64'b0100000001101001000100000000000000000000000000000000000000000000);  // Positive + Negative
            m.put_B (64'b1100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h3) begin
            m.put_A (64'b1100000001101001000100000000000000000000000000000000000000000000);  // Negative + Positive
            m.put_B (64'b0100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h4) begin
            m.put_A (64'b1100000001101001000100000000000000000000000000000000000000000000);  // -X + +X
            m.put_B (64'b0100000001101001000100000000000000000000000000000000000000000000);
        end
        else if (rg_y == 'h5) begin
            m.put_A (64'b0111111111110000000000000000000000000000000000000000000000000000);  // +Infinity + X
            m.put_B (64'b1100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h6) begin
            m.put_A (64'b1111111111110000000000000000000000000000000000000000000000000000);  // -Infinity + X
            m.put_B (64'b1100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h7) begin
            m.put_A (64'b1111111111110000000000000000000000000000000000000000000000000001);  // NAN + X
            m.put_B (64'b1100000000101000010110100001110010101100000010000011000100100111);
        end
        else if (rg_y == 'h8) begin
            m.put_A (64'b0111111111110000000000000000000000000000000000000000000000000000);  // +Infinity + -Infinity
            m.put_B (64'b1111111111110000000000000000000000000000000000000000000000000000);
        end
        rg_y <= rg_y+ 1;
    endrule
    rule rl_finish;
        let res = m.get_res();
        $display("\ntime at which it completed - ",$time);
        $display ("\nResult = %b", res);
        if(rg_y == 'h01F) $finish ();     // Ending Clk
    endrule

endmodule: mkTest

// Interface for the design
interface FPadd_ifc;
    method Action put_A(Bit#(64) a_in);
    method Action put_B(Bit#(64) b_in);
    method ActionValue#(Bit#(64)) get_res();    
endinterface: FPadd_ifc


// Design module
(* synthesize *)
module mkFPadd (FPadd_ifc);
    // Inputs
    Reg#(Bit#(64)) a <- mkReg(0);
    Reg#(Bit#(64)) b <- mkReg(0);
	
    // signals for starting the rule after the first set of inputs arrive
    Reg#(Bool) got_A <- mkReg (False);
    Reg#(Bool) got_B <- mkReg (False);
    
    // operation = 0 - Addition ; operation = 1 - Subtraction
    Reg#(Bool) operation <- mkReg(False);
	
    // Registers at Pipeline Stage 0
    Reg#(Bit#(55)) man_A <- mkReg(0);
    Reg#(Bit#(55)) man_B <- mkReg(0);
    Reg#(Bit#(11)) exp <- mkReg(0);
    Reg#(Bit#(11)) exp_diff_b0 <- mkReg(0);
	
    // Registers at Pipeline Stage 1
    Reg#(Bit#(8)) mantissa_1 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_2 <- mkReg(0);
    Reg#(Bit#(55)) man_A_b1 <- mkReg(0);
    Reg#(Bit#(55)) man_B_b1 <- mkReg(0);
    Reg#(Bit#(11)) exp_b1 <- mkReg(0);
    Reg#(Bit#(1)) cout2 <- mkReg(0);
    Reg#(Bit#(11)) exp_diff_b1 <- mkReg(0);
	
    // Registers at Pipeline Stage 2
    Reg#(Bit#(8)) mantissa_1_b2 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_2_b2 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_3 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_4 <- mkReg(0);
    Reg#(Bit#(55)) man_A_b2 <- mkReg(0);
    Reg#(Bit#(55)) man_B_b2 <- mkReg(0);
    Reg#(Bit#(11)) exp_b2 <- mkReg(0);
    Reg#(Bit#(1)) cout4 <- mkReg(0);
    Reg#(Bit#(11)) exp_diff_b2 <- mkReg(0);
	
    // Registers at Pipeline Stage 3
    Reg#(Bit#(8)) mantissa_1_b3 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_2_b3 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_3_b3 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_4_b3 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_5 <- mkReg(0);
    Reg#(Bit#(8)) mantissa_6 <- mkReg(0);
    Reg#(Bit#(55)) man_A_b3 <- mkReg(0);
    Reg#(Bit#(55)) man_B_b3 <- mkReg(0);
    Reg#(Bit#(11)) exp_b3 <- mkReg(0);
    Reg#(Bit#(1)) cout6 <- mkReg(0);
    Reg#(Bit#(11)) exp_diff_b3 <- mkReg(0);

    // Registers at Pipeline Stage 4
    Reg#(Bit#(55)) mantissa_result <- mkReg(0);
    Reg#(Bit#(11)) exp_b4 <- mkReg(0);
    Reg#(Bit#(11)) exp_diff_b4 <- mkReg(0);

    // Registers at Pipeline Stage 5
    Reg#(Bit#(1)) overflow <- mkReg (0);
    Reg#(Bit#(64)) result <- mkReg(0);
    
    // The lines of the form Bit#(N) variable_name are used for declaring or defining variables that are used to compute the pipeline stage outputs

    // One rule to perform the floating point addition or subtraction
    rule rl_do_all(got_A && got_B);

        //Stage 0 - Exponent design (including special cases)
	
	// Get the inputs “a” (64-bits) and “b” (64-bits). Separate the sign, exponent and mantissa bits 
	// of both the inputs and copy the values to 1-bit sign 11-bit exponent and 52-bit mantissa 
	
        Bit#(1) sign_A = a[63];
        Bit#(1) sign_B = b[63];
        Bit#(11) exp_A = a[62:52];
        Bit#(11) exp_B = b[62:52];
        Bit#(52) man_temp_A = a[51:0];
        Bit#(52) man_temp_B = b[51:0];
	
	// Identfiers for handling special cases
        Bit#(3) ref_A = ?;
        Bit#(3) ref_B = ?;

        if (exp_A == 11'b11111111111) 
        begin
            if (man_temp_A == 0) 
            begin
                if (sign_A == 0) ref_A = 3'b001;  // +INF
                else  ref_A = 3'b010;  // -INF
            end 
            else ref_A = 3'b011;  // NAN
        end 
        else ref_A = 3'b100; // NORMAL


        if (exp_B == 11'b11111111111) 
        begin
            if (man_temp_B == 0) 
            begin
                if (sign_B == 0) ref_B = 3'b001; // +INF
                else ref_B = 3'b010;  // -INF
            end 
            else ref_B = 3'b011;    //NAN
        end 
        else ref_B = 3'b100;    //NORMAL
        
        // Compare the exponent bits of the inputs A and B, “exp_A” and “exp_B”. The input with higher 
        // exponent value is stored in “sign_A”, “exp_A” and “man_A”, and the input with lower exponent 
        // value is stored in “sign_B”, “exp_B” and “man_B”.
	
	// Variables for handling the above step
        Bit#(64) temp_A = ?;
        Bit#(64) temp_B = ?;

        if (ref_A == 3'b010) 
        begin
            if (ref_B == 3'b010) 
            begin
                // -INF + -INF
                temp_A = a;
                temp_B = 0;
            end 
            else if (ref_B == 3'b100) 
            begin
                 // -INF + NORMAL
                temp_A = a;
                temp_B = 0;
            end
            else if (ref_B == 3'b001)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111111;  // -INF + +INF = NEW VALUE (NOT NAN)
                temp_B = 0;
            end
            else //if (ref_B == 3'b011)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110;  // -INF + NAN
                temp_B = 0;
            end
        end
        else if (ref_A == 3'b100)
        begin
            if (ref_B == 3'b010) 
            begin
                temp_A = b;                                                                   // NORMAL + -INF
                temp_B = 0;
            end 
            else if (ref_B == 3'b100) 
            begin
                if (exp_A < exp_B) begin
                    temp_A = b;
                    temp_B = a;
                end else begin
                    temp_A = a;
                    temp_B = b;
                end                                                                               // NORMAL + NORMAL
            end
            else if (ref_B == 3'b001)
            begin
                temp_A = b;                                                                    // NORMAL + +INF
                temp_B = 0;
            end
            else //if (ref_B == 3'b011)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; //NORMAL + NAN
                temp_B = 0;
            end
        end
        else if (ref_A == 3'b001)
        begin
            if (ref_B == 3'b010) 
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111111; // +INF + -INF = NEW VALUE (NOT NAN)
                temp_B = 0;
            end 
            else if (ref_B == 3'b100) 
            begin
                temp_A = a;                                                                  // +INF + NORMAL
                temp_B = 0;
            end
            else if (ref_B == 3'b001)
            begin
                temp_A = a;                                                                   // +INF + +INF
                temp_B = 0;
            end
            else //if (ref_B == 3'b011)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; // +INF + NAN
                temp_B = 0;
            end
        end
        else //if (ref_A == 3'b011)
        begin
            if (ref_B == 3'b010) 
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; //NAN + -INF
                temp_B = 0;
            end 
            else if (ref_B == 3'b100) 
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; // NAN + NORMAL
                temp_B = 0;
            end
            else if (ref_B == 3'b001)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; // NAN + +INF
                temp_B = 0;
            end
            else //if (ref_B == 3'b011)
            begin
                temp_A = 64'b0111111111111111111111111111111111111111111111111111111111111110; // NAN + NAN
                temp_B = 0;
            end
        end

	// The values of “sign_A”, “sign_B”, “exp_A”, “exp_B”, “man_A” and “man_B” are stored in 1-bit sign 
	// (“sign_temp_A” and “sign_temp_B”), 11-bit exponent (“exp_temp_A” and “exp_temp_B”) and 52-bit mantissa 
	// (“man_temp_A” and “man_temp_B”), according to double precision IEEE 754 floating point format. 
	
        Bit#(1) sign_temp_A = temp_A[63];
        Bit#(1) sign_temp_B = temp_B[63];
        Bit#(11) exp_temp_A = temp_A[62:52];
        Bit#(11) exp_temp_B = temp_B[62:52];

        Bit#(55) man_temp2_A = ?;
        Bit#(55) man_temp2_B2 = ?;
        
        // Check the value of “exp_temp_A”. If “exp_temp_A” is not equal to zero, then concatenate “man_temp_A” 
        // with leading three bits “001” in front and store the value in “man_temp2_A” (55-bit). If “exp_temp_A” 
        // is equal to zero, then concatenate “man_temp_A” with leading three bits “000” in front and will store 
	// the value in “man_temp2_A” (55-bit). Similarly for B
        
        if (exp_temp_A == 11'b0) begin
            man_temp2_A = {3'b000, temp_A[51:0]};
        end else begin
            man_temp2_A = {3'b001, temp_A[51:0]};
        end
        
        if (exp_temp_B == 11'b0) begin
            man_temp2_B2 = {3'b000, temp_B[51:0]};
        end else begin
            man_temp2_B2 = {3'b001, temp_B[51:0]};
        end
        
        // The value of “exp_temp_B” is subtracted from “exp_temp_A” and the difference value is stored in “exp_diff “(11-bit). 
        // The mantissa bits “man_temp2_B” is right shifted by “exp_diff” places. 

        Bit#(11) exp_diff = exp_temp_A - exp_temp_B;
        Bit#(55) man_temp2_B = man_temp2_B2 >> exp_diff;
        
        // Check the value of “sign_temp_A”. If “sign_temp_A” is equal to one, then the inverted value of “man_temp2_A” 
        // is stored in “man_A” (55-bit). If “sign_temp_A” is equal to zero, then the actual value of “man_temp2_A” is 
	// stored in “man_A” (55-bit). Similarly for B. 

        if (sign_temp_A == 1'b1) begin
            man_A <= -man_temp2_A;
        end else begin
            man_A <= man_temp2_A;
        end
        
        if (sign_temp_B == 1'b1) begin
            man_B <= -man_temp2_B;
        end else begin
            man_B <= man_temp2_B;
        end
    
    	// Forward "exp" and "exp_diff" to be used in Pipeline Stage 5    
        exp <= exp_temp_A;		
        exp_diff_b0 <= exp_diff;
        
        // Stage 1,2,3,4 perform the following function in parts:
	// If the input value of the “operation” is equal to one, then the value of “man_B” is subtracted 
	// from “man_A” and the result is stored in “mantissa_result” (55bit). If the input value of the “operation” 
	// is equal to zero, then the value of “man_temp1_B” is added with “man_temp1_A” and the result is stored in 
	// “mantissa_result” (55-bit). 	

        // Stage 1 - Part 1 Mantissa Design

        Bit#(9) man_temp1_A_1 = {1'b0, man_A[7:0]};
        Bit#(9) man_temp1_B_1 = {1'b0, man_B[7:0]};
        Bit#(9) man_temp2_A_2 = {1'b0, man_A[15:8]};
        Bit#(9) man_temp2_B_2 = {1'b0, man_B[15:8]};
        Bit#(9) cin1_9bit = 9'b0;

        Bit#(9) mantissa_1_raw = ?;
        Bit#(9) mantissa_2_raw = ?;
        Bit#(9) cout1 = ?;

        if (operation) begin
            mantissa_1_raw = man_temp1_A_1 - man_temp1_B_1 - cin1_9bit;
            cout1 = {8'b0, mantissa_1_raw[8]};
            mantissa_2_raw = man_temp2_A_2 - man_temp2_B_2 - cout1;
        end else begin
            mantissa_1_raw = man_temp1_A_1 + man_temp1_B_1 + cin1_9bit;
            cout1 = {8'b0, mantissa_1_raw[8]};
            mantissa_2_raw = man_temp2_A_2 + man_temp2_B_2 + cout1;
        end
        
        // Forward "mantissa_1" and "mantissa_2" to be used in Pipeline Stage 4
        mantissa_1 <= mantissa_1_raw[7:0];
        mantissa_2 <= mantissa_2_raw[7:0];
        
        // Forward carry to be used in Stage 2
        cout2 <= mantissa_2_raw[8];
        
        // Forward "man_A" and "man_B" to be used in Pipeline Stages 2,3,4
        man_A_b1 <= man_A;
        man_B_b1 <= man_B;
        
        // Forward "exp" and "exp_diff" to be used in Pipeline Stage 5 
        exp_b1 <= exp;
        exp_diff_b1 <= exp_diff_b0;

        // Stage 2 - Part 2 Mantissa Design

        Bit#(9) man_temp3_A = {1'b0, man_A_b1[23:16]};
        Bit#(9) man_temp3_B = {1'b0, man_B_b1[23:16]};
        Bit#(9) man_temp4_A = {1'b0, man_A_b1[31:24]};
        Bit#(9) man_temp4_B = {1'b0, man_B_b1[31:24]};
        Bit#(9) cin3_9bit = {8'b0, cout2};

        Bit#(9) mantissa_3_raw = ?;
        Bit#(9) mantissa_4_raw = ?;
        Bit#(9) cout3 = ?;

        if (operation) begin
            mantissa_3_raw = man_temp3_A - man_temp3_B - cin3_9bit;
            cout3 = {8'b0, mantissa_3_raw[8]};
            mantissa_4_raw = man_temp4_A - man_temp4_B - cout3;
        end else begin
            mantissa_3_raw = man_temp3_A + man_temp3_B + cin3_9bit;
            cout3 = {8'b0, mantissa_3_raw[8]};
            mantissa_4_raw = man_temp4_A + man_temp4_B + cout3;
        end
        
        // Forward "mantissa_1", "mantissa_2", "mantissa_3", "mantissa_4" to be used in Pipeline Stage 4
        mantissa_1_b2 <= mantissa_1;
        mantissa_2_b2 <= mantissa_2;
        mantissa_3 <= mantissa_3_raw[7:0];
        mantissa_4 <= mantissa_4_raw[7:0];
        
        // Forward "man_A" and "man_B" to be used in Pipeline Stages 2,3,4
        man_A_b2 <= man_A_b1;
        man_B_b2 <= man_B_b1;
        
        // Forward carry to be used in Pipeline Stage 3
        cout4 <= mantissa_4_raw[8];
        
        // Forward "exp" and "exp_diff" to be used in Pipeline Stage 5 
        exp_b2 <= exp_b1;
        exp_diff_b2 <= exp_diff_b1;

        // Stage 3 - Part 3 Mantissa Design

        Bit#(9) man_temp5_A = {1'b0, man_A_b2[39:32]};
        Bit#(9) man_temp5_B = {1'b0, man_B_b2[39:32]};
        Bit#(9) man_temp6_A = {1'b0, man_A_b2[47:40]};
        Bit#(9) man_temp6_B = {1'b0, man_B_b2[47:40]};
        Bit#(9) cin5_9bit = {8'b0, cout4};

        Bit#(9) mantissa_5_raw = ?;
        Bit#(9) mantissa_6_raw = ?;
        Bit#(9) cout5 = ?;

        if (operation) begin
            mantissa_5_raw = man_temp5_A - man_temp5_B - cin5_9bit;
            cout5 = {8'b0, mantissa_5_raw[8]};
            mantissa_6_raw = man_temp6_A - man_temp6_B - cout5;
        end else begin
            mantissa_5_raw = man_temp5_A + man_temp5_B + cin5_9bit;
            cout5 = {8'b0, mantissa_5_raw[8]};
            mantissa_6_raw = man_temp6_A + man_temp6_B + cout5;
        end
        // Forward "mantissa_1", "mantissa_2", "mantissa_3", "mantissa_4", "mantissa_5", "mantissa_6" to be used in Pipeline Stage 4
        mantissa_1_b3 <= mantissa_1_b2;
        mantissa_2_b3 <= mantissa_2_b2;
        mantissa_3_b3 <= mantissa_3;
        mantissa_4_b3 <= mantissa_4;
        mantissa_5 <= mantissa_5_raw[7:0];
        mantissa_6 <= mantissa_6_raw[7:0];
        
        // Forward "man_A" and "man_B" to be used in Pipeline Stages 2,3,4
        man_A_b3 <= man_A_b2;
        man_B_b3 <= man_B_b2;
        
        // Forward carry to be used in Stage 4
        cout6 <= mantissa_6_raw[8];
        
        // Forward "exp" and "exp_diff" to be used in Pipeline Stage 5 
        exp_b3 <= exp_b2;
        exp_diff_b3 <= exp_diff_b2;

        // Stage 4 - Part 4 Mantissa Design

        Bit#(8) man_temp7_A = {1'b0, man_A_b3[54:48]};
        Bit#(8) man_temp7_B = {1'b0, man_B_b3[54:48]};
        Bit#(8) cin7_8bit = {7'b0, cout6};

        Bit#(8) mantissa_7_raw = ?;
        Bit#(7) mantissa_7 = ?;

        if (operation) begin
            mantissa_7_raw = man_temp7_A - man_temp7_B - cin7_8bit;
        end else begin
            mantissa_7_raw = man_temp7_A + man_temp7_B + cin7_8bit;
        end
        mantissa_7 = mantissa_7_raw[6:0];
        
        // Compute "mantissa_result"
        mantissa_result <= {mantissa_7, mantissa_6, mantissa_5, mantissa_4_b3, mantissa_3_b3, mantissa_2_b3, mantissa_1_b3};
        
        // Forward "exp" and "exp_diff" to be used in Pipeline Stage 5 
        exp_b4 <= exp_b3;
        exp_diff_b4 <= exp_diff_b3;

        // Stage 5 - Overflow and Normalization Design
        
         // The 55th bit of “mantissa_result” is stored in “Sign_Final” (1-bit). If the value of “Sign_Final” 
         // is equal to one, then the inverted value of “mantissa_result” is stored in “mantissa_temp” (55-bit). 
         // If the value of “Sign_Final” is equal to zero, then the actual value of “mantissa_result” is stored in 
         // “mantissa_temp” (55-bit). 

        Bit#(1) sign_final = mantissa_result[54];
        Bit#(55) mantissa_temp = ?;

        if (sign_final == 1'b1) begin
            mantissa_temp = -mantissa_result;      
        end else begin
            mantissa_temp = mantissa_result; 
        end
        
         // Check the value of “mantissa_temp”. If the 54th bit of “mantissa_temp” is equal to one, then overflow 
         // occurs after addition or subtraction. So with “exp_temp_A” add decimal one and store the result in 
         // “exp_temp2_A” (11-bit). The “mantissa_temp” bit is right shifted by one place and least significant 
         // 53 bits are stored in “mantissa_temp_1” (53-bit). 

        Bit#(53) mantissa_temp_1 = ?;
        Bit#(11) exp_temp2_A = ?;
        Bit#(55) mantissa_temp2 = ?;
        
        // If the 54th bit of “mantissa_temp” is equal to zero, then overflow did not occur after addition or 
        // subtraction, so the actual value of “exp_temp_A” is stored in “exp_temp2_A” (11-bit) and the least 
        // significant 53 bits of “mantissa_temp” are stored in “mantissa_temp_1” (53-bit). 

        if (mantissa_temp[53] == 1'b1) begin
            overflow <= 1'b1;
            exp_temp2_A = exp_b4 + 1;
            mantissa_temp2 = mantissa_temp >> 1;
            mantissa_temp_1 = mantissa_temp2[52:0];
        end else begin
            overflow <= 1'b0;
            exp_temp2_A = exp_b4;
            mantissa_temp_1 = mantissa_temp[52:0];
        end
        
        // Check the value of “mantissa_temp_1”. If all the bits in the 53-bit “mantissa_temp_1” are equal to zero, 
        // then the value of “Mantissa_Final” is all 0’s and the value of “Exponent_fianl” is 11’b0. Next check the 
        // value of the 53rd bit of “mantissa_temp_1”. If the value is 1, then the value of “mantissa_temp_1” 
	// is stored in “Mantissa_Final”, and the value of “exp_temp2_A” is stored in “Exponent_final”. Next check 
	// the value of the 52nd bit of “mantissa_temp_1”. If the value is 1, then the value of “mantissa_temp_1” is 
	// left shifted by 1 value and the result is stored in “Mantissa_Final”. The value of “exp_temp2_A” is 
	// subtracted by decimal 1 and the result is stored in “Exponent_final”. Continue this process for all the
	//  bits in “mantissa_temp_1”. 

        Bit#(11) count = ?;
        Bit#(52) mantissa_final = ?;
        Bit#(11) exponent_final = ?;
        
	// 55-bit Barrel Shifter used a Leading One detector
        if (mantissa_temp_1[52] == 1'b1) count = 0;
        else if (mantissa_temp_1[51] == 1'b1) count = 1;
        else if (mantissa_temp_1[50] == 1'b1) count = 2;
        else if (mantissa_temp_1[49] == 1'b1) count = 3;
        else if (mantissa_temp_1[48] == 1'b1) count = 4;
        else if (mantissa_temp_1[47] == 1'b1) count = 5;
        else if (mantissa_temp_1[46] == 1'b1) count = 6;
        else if (mantissa_temp_1[45] == 1'b1) count = 7;
        else if (mantissa_temp_1[44] == 1'b1) count = 8;
        else if (mantissa_temp_1[43] == 1'b1) count = 9;
        else if (mantissa_temp_1[42] == 1'b1) count = 10;
        else if (mantissa_temp_1[41] == 1'b1) count = 11;
        else if (mantissa_temp_1[40] == 1'b1) count = 12;
        else if (mantissa_temp_1[39] == 1'b1) count = 13;
        else if (mantissa_temp_1[38] == 1'b1) count = 14;
        else if (mantissa_temp_1[37] == 1'b1) count = 15;
        else if (mantissa_temp_1[36] == 1'b1) count = 16;
        else if (mantissa_temp_1[35] == 1'b1) count = 17;
        else if (mantissa_temp_1[34] == 1'b1) count = 18;
        else if (mantissa_temp_1[33] == 1'b1) count = 19;
        else if (mantissa_temp_1[32] == 1'b1) count = 20;
        else if (mantissa_temp_1[31] == 1'b1) count = 21;
        else if (mantissa_temp_1[30] == 1'b1) count = 22;
        else if (mantissa_temp_1[29] == 1'b1) count = 23;
        else if (mantissa_temp_1[28] == 1'b1) count = 24;
        else if (mantissa_temp_1[27] == 1'b1) count = 25;
        else if (mantissa_temp_1[26] == 1'b1) count = 26;
        else if (mantissa_temp_1[25] == 1'b1) count = 27;
        else if (mantissa_temp_1[24] == 1'b1) count = 28;
        else if (mantissa_temp_1[23] == 1'b1) count = 29;
        else if (mantissa_temp_1[22] == 1'b1) count = 30;
        else if (mantissa_temp_1[21] == 1'b1) count = 31;
        else if (mantissa_temp_1[20] == 1'b1) count = 32;
        else if (mantissa_temp_1[19] == 1'b1) count = 33;
        else if (mantissa_temp_1[18] == 1'b1) count = 34;
        else if (mantissa_temp_1[17] == 1'b1) count = 35;
        else if (mantissa_temp_1[16] == 1'b1) count = 36;
        else if (mantissa_temp_1[15] == 1'b1) count = 37;
        else if (mantissa_temp_1[14] == 1'b1) count = 38;
        else if (mantissa_temp_1[13] == 1'b1) count = 39;
        else if (mantissa_temp_1[12] == 1'b1) count = 40;
        else if (mantissa_temp_1[11] == 1'b1) count = 41;
        else if (mantissa_temp_1[10] == 1'b1) count = 42;
        else if (mantissa_temp_1[9] == 1'b1) count = 43;
        else if (mantissa_temp_1[8] == 1'b1) count = 44;
        else if (mantissa_temp_1[7] == 1'b1) count = 45;
        else if (mantissa_temp_1[6] == 1'b1) count = 46;
        else if (mantissa_temp_1[5] == 1'b1) count = 47;
        else if (mantissa_temp_1[4] == 1'b1) count = 48;
        else if (mantissa_temp_1[3] == 1'b1) count = 49;
        else if (mantissa_temp_1[2] == 1'b1) count = 50;
        else if (mantissa_temp_1[1] == 1'b1) count = 51;
        else if (mantissa_temp_1[0] == 1'b1) count = 52;
        else if (exp_diff_b4 == 0) count = exp_temp2_A;
        else count = 0;
        mantissa_final = (mantissa_temp_1 << count)[51:0];
        exponent_final = exp_temp2_A - count;
        
        // Now the final values of sign, exponent and mantissa bits are stored in “sign_final”, 
        // “exponent_final” and “mantissa_Final”. Concatenate to get the final result. 
        result <= {sign_final, exponent_final, mantissa_final};

    endrule

    // Input mapping to registers
    method Action put_A(Bit#(64) a_in);
        a <= a_in;
        got_A <= True;
    endmethod

    method Action put_B(Bit#(64) b_in);
        b <= b_in;
        got_B <= True;
    endmethod

    // Output mapping from registers
    method ActionValue#(Bit#(64)) get_res();
        return result;
    endmethod

endmodule
