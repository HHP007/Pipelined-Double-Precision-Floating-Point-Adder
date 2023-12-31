# Pipelined-Double-Precision-Floating-Point-Adder

This repository contains the bluespec code for the pipelined double precision floating point adder, done as a part of the course CS6230 CAD For VLSI, IIT Madras.
* Authors : [HARIHARAN P](https://github.com/HHP007) (EE20B042)  AND  [JAWHAR S](https://github.com/Jawhar-S) (EE20B049)
* Date: 10 Dec 2023

### **Project Structure :**
* This project contains one bsv file which contains both testbench and the FP adder.
* Each of them are designed as different module, inwhich the top module is the test bench which gives the inputs to the interface of the FP Adder module for each clock cycles.
* The test bench then collects the output from the interface and prints them.
* The test bench runs for 31 clock cycles. You can change that by changing the condition to activate $finish ().
* The test cases used in the test bench are included in the FPAdd_Test_Cases.pdf for the readers convenience. 

### **How to run the code :**
* Download the FPAdd_Pipelined.bsv file in the repository you wish and open the repository in the terminal.
* Type the following commands:

		bsc -verilog FPAdd_Pipelined.bsv
		bsc -o sim -e mkTest mkTest.v
		./sim
		./sim +bscvcd

* The first command creates two verilog files : mkFPadd.v and mkTest.v
* The second command creates the simulation file : sim
* The third command prints the outputs vs clock time. Each 10 clock time corrosponds to 1 clock cycle as per the Bluespec compiler.
* The fourth command prints the waveform in GTKWaves.


### **Design Decisions :**

* The pipelined hardware architecture for a double precision floating point adder consists of six functional stages. We made sure that the hardware complexity is equal for each stage.
* Giving equal hardware complexity in each stage helps in improving throughput of the adder.
* We made sure that each stage as 1 calculation part and a buffer(shifting values through registers.)

### **Verification methodology :**

* The test bench has 9 sets of inputs comprising all types of possibilities and the output is printed for each clock cycle.
* Since the first clock cycle is taken to give the inputs from testbench to the FP Adder, the final output of the 1st set of inputs is printed at 7th Clock cycle. 
* While printing the simulation using ./sim , clock cycles are mentioned as 5, 15, 25, 35 in bluespec compiler (Each 10 corrosponds to a clock cycle).
* The first output comes at 75, and the second output comes at 85, and so on. The outputs arrive at each subsquent clock cycles.
* The simulation completes at 31st clock cycle because we have set $finish () if the clock counter hits 31. You can run any number times by increasing the clock counter represented as " rg_y " register in the testbench. ()Test bench is the top module in the bsv script.
* Since we have given 9 set of inputs, the final output for the 9th set of inputs arrive at 15th clock cycle represented by 155 while printing the simulation results. The same result is printed for the clock cycles following this, because the FP adder runs till 31st clock cycle. You can stop at 15th clock cycle by setting the $ finish () condition to activate at 15th clock cycle.
* Check out the FPAdd_Test_Cases.pdf to verify the results.
* Note: The results are printed in the IEE754 format inwhich the exponents are subtrated from its base value 1023. Usual online calculators don't Subtract this base value.

	
### **Floating-Point representation:** 

The floating-point representation allows the depiction of extremely large or small fractions, with the flexibility of placing the decimal point anywhere in relation to a number's significant digits. This positioning is determined by the exponent component. 

Floating-point numbers can be expressed in the following manner: X = (-1)^S * (1 + Fraction) * 2^(E - B). In this expression, S denotes the sign bit (indicating positivity or negativity), E represents the exponent bits, and B denotes the bias value. For single precision floating-point numbers, the bias value is 127, while for double precision floating-point numbers, the bias value is 1023.
	
### **Special Numbers :** 

In floating-point number, if the value of the exponent field is all 0s and all 1s,then these fields are reserved to denote the special values in the floating-point scheme according to the IEEE format.
* Zero: In a floating-point number, if the value of the exponent is all 0s and the value of a mantissa is all 0s, then the resultant value will be 0.5
* De-normalized: In a floating-point number, if the value of the exponent is all 0s and the value of a mantissa is non-zero, then the resultant value will be a de-normalized number
* Infinity: In a floating-point number if the value of the exponent is all 1s and the value of a mantissa is all 0s, then the resultant value will be an infinite number and it will be represented by a special value called Infinity. Depending on the value of the sign bit (1-bit) we can specify if the value obtained is positive infinity or negative infinity.
* Not a Number: In a floating-point number if the value of the exponent is all 1’s and the value of a mantissa is non-zero, then the resultant value will not be a number and it will be represented by a special value called Not a Number (NaN).

### **Hardware Architecture :**

In this design, the double-precision floating-point inputs A and B undergo addition. The primary components influencing the performance of this operation include a 55-bit binary adder, a Leading One Predictor, and a barrel shifter.

The hardware architecture for this double-precision floating-point adder/subtractor comprises six functional stages, incorporating buffers between stages to temporarily store each stage's output.

**Exponent Design - Stage Zero**

The Zeroth stage involves comparing the exponent bits of inputs A and B. The higher exponent value between A and B is stored in "sign_A," "exp_A," and "man_A," while the lower exponent value is stored in "sign_B," "exp_B," and "man_B." Based on the exponent value, A and B mantissa bits are concatenated with either "000" or "001."

In this stage, if B has a smaller amplitude number, the mantissa bits of input B are shifted using a barrel shifter to equalize the exponents before adding or subtracting the mantissa. Depending on the sign bits in A and B, the actual or inverted values of "man_temp2_A" and "man_temp2_B" are stored in "man_A" and "man_B."

**Mantissa Design - Stage One to Four** 

Stages one to four perform the addition of the mantissa bits (55-bit).

Stages 1-3 adds 16 bits each and the stage 4 adds 7 bits.

These stages use multiple blocks to add sections of the mantissa successively. The results from each block are stored temporarily and concatenated to form the final "mantissa_result" (55-bit).


**Overflow and Normalization Design - Stage Five** 

The final stage contains overflow and normalization blocks. This stage determines overflow based on the 53rd bit of "mantissa_temp" and calculates the number of shifts required to normalize the obtained "mantissa_result." The output of this stage yields the final floating-point addition result.

Normalization of the result uses the Leading One Detector (LOD) method, which counts preceding ones in the "mantissa_temp_1" result. The value is left-shifted to achieve the final normalized result, but its operation awaits the completion of the result computation.

A 55-bit Barrel Shifter is implemented to shift the generated "mantissa_result" by the count value obtained from the Leading One Detector. This digital circuit performs shifts by a specified number of bits using pure combinational logic, storing the final result in a buffer for pipeline processing.

### **Synthesis Results**
Statistics obtained using YOSYS for FP Adder (mkFPadd.v)


   		Number of wires:               4565
   		Number of wire bits:           4754
   		Number of public wires:         645
   		Number of public wire bits:     834
   		Number of memories:               0
   		Number of memory bits:            0
   		Number of processes:              0
   		Number of cells:               4621
     		sky130_fd_sc_hd__a2111oi_2      1
     		sky130_fd_sc_hd__a211o_2       64
     		sky130_fd_sc_hd__a211oi_2       4
     		sky130_fd_sc_hd__a21bo_2       15
     		sky130_fd_sc_hd__a21boi_2      11
     		sky130_fd_sc_hd__a21o_2       155
     		sky130_fd_sc_hd__a21oi_2       74
     		sky130_fd_sc_hd__a221o_2       12
     		sky130_fd_sc_hd__a221oi_2       1
     		sky130_fd_sc_hd__a22o_2        53
     		sky130_fd_sc_hd__a22oi_2       24
     		sky130_fd_sc_hd__a2bb2o_2       2
     		sky130_fd_sc_hd__a31o_2        32
     		sky130_fd_sc_hd__a31oi_2        2
     		sky130_fd_sc_hd__a32o_2        10
     		sky130_fd_sc_hd__a32oi_2        1
     		sky130_fd_sc_hd__and2_2       254
     		sky130_fd_sc_hd__and2_4         2
     		sky130_fd_sc_hd__and2b_2        5
     		sky130_fd_sc_hd__and3_2        56
     		sky130_fd_sc_hd__and3b_2        5
     		sky130_fd_sc_hd__and4_2         7
     		sky130_fd_sc_hd__and4b_2        1
     		sky130_fd_sc_hd__and4bb_2       1
     		sky130_fd_sc_hd__buf_1        519
     		sky130_fd_sc_hd__buf_2          2
     		sky130_fd_sc_hd__conb_1         3
     		sky130_fd_sc_hd__dfxtp_2      698
     		sky130_fd_sc_hd__inv_2         32
     		sky130_fd_sc_hd__mux2_1        69
     		sky130_fd_sc_hd__mux2_2       294
     		sky130_fd_sc_hd__mux4_2        45
     		sky130_fd_sc_hd__nand2_2      195
     		sky130_fd_sc_hd__nand2b_2      10
     		sky130_fd_sc_hd__nand3_2        6
     		sky130_fd_sc_hd__nand3b_2       2
     		sky130_fd_sc_hd__nand4_2        3
     		sky130_fd_sc_hd__nand4b_2       1
     		sky130_fd_sc_hd__nor2_2       182
     		sky130_fd_sc_hd__nor2b_2        4
     		sky130_fd_sc_hd__nor3_2         8
     		sky130_fd_sc_hd__nor3b_2        1
     		sky130_fd_sc_hd__nor4_2         1
     		sky130_fd_sc_hd__o2111a_2       3
     		sky130_fd_sc_hd__o2111ai_2      1
     		sky130_fd_sc_hd__o211a_2      499
     		sky130_fd_sc_hd__o211ai_2       2
     		sky130_fd_sc_hd__o21a_2       112
     		sky130_fd_sc_hd__o21ai_2       63
     		sky130_fd_sc_hd__o21ba_2       38
     		sky130_fd_sc_hd__o21bai_2       3
     		sky130_fd_sc_hd__o221a_2      128
     		sky130_fd_sc_hd__o221a_4        1
     		sky130_fd_sc_hd__o221ai_2       4
     		sky130_fd_sc_hd__o22a_2         7
     		sky130_fd_sc_hd__o22ai_2        1
     		sky130_fd_sc_hd__o2bb2a_2       3
     		sky130_fd_sc_hd__o311a_2       11
     		sky130_fd_sc_hd__o31a_2        33
     		sky130_fd_sc_hd__o31ai_2        9
     		sky130_fd_sc_hd__o32a_2        19
     		sky130_fd_sc_hd__o41a_2         3
     		sky130_fd_sc_hd__or2_2        502
     		sky130_fd_sc_hd__or2_4         11
     		sky130_fd_sc_hd__or2b_2         8
     		sky130_fd_sc_hd__or3_2         50
     		sky130_fd_sc_hd__or3_4         11
       		sky130_fd_sc_hd__or3b_2        10
     		sky130_fd_sc_hd__or4_2         49
    		sky130_fd_sc_hd__or4_4         12
     		sky130_fd_sc_hd__or4b_2        33
     		sky130_fd_sc_hd__or4b_4         3
     		sky130_fd_sc_hd__or4bb_2        1
     		sky130_fd_sc_hd__xnor2_2       81
     		sky130_fd_sc_hd__xor2_2        43

   	Chip area for module '\mkFPadd': 48048.582400
