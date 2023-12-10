# Pipelined-Double-Precision-Floating-Point-Adder

This repository contains the bluespec code for the pipelined double precision floating point adder, done as a part of the course CS6230 CAD For VLSI, IIT Madras.
* Authors : HARIHARAN P (EE20B042)  AND  JAWHAR S (EE20B049)
* Date: 10 Dec 2023

**How to run the code :**
* Download the FPAdd_Pipelined.bsv file in the repository you wish and open the repository in the terminal.
* Type the following commands:
    * bsc -verilog FPAdd_Pipelined.bsv
    * bsc -o sim -e mkTest mkTest.v
    * ./sim
    * ./sim +bscvcd
* The first command creates two verilog files : mkFPadd.v and mkTest.v
* The second command creates the simulation file : sim
* The third command prints the outputs vs clock time. Each 10 clock time corrosponds to 1 clock cycle as per the bluespec compier.
* The fourth command prints the waveform in GTKWaves.


**Introduction :** 

There are multiple methods available for expressing numerical systems. Integer numbers are employed in certain applications, while others utilize non-integer numbers. Among the various approaches to represent non-integer numbers, the floating-point format is commonly adopted. This project concentrates on the IEEE 754 floating-point standard due to its rapidly growing acceptance.
	
**Floating-Point representation:** 

The floating-point representation allows the depiction of extremely large or small fractions, with the flexibility of placing the decimal point anywhere in relation to a number's significant digits. This positioning is determined by the exponent component. 

Floating-point numbers can be expressed in the following manner: X = (-1)^S * (1 + Fraction) * 2^(E - B). In this expression, S denotes the sign bit (indicating positivity or negativity), E represents the exponent bits, and B denotes the bias value. For single precision floating-point numbers, the bias value is 127, while for double precision floating-point numbers, the bias value is 1023.
	
**Special Numbers :** 

In floating-point number, if the value of the exponent field is all 0s and all 1s,then these fields are reserved to denote the special values in the floating-point scheme according to the IEEE format.
* Zero: In a floating-point number, if the value of the exponent is all 0s and the value of a mantissa is all 0s, then the resultant value will be 0.5
* De-normalized: In a floating-point number, if the value of the exponent is all 0s and the value of a mantissa is non-zero, then the resultant value will be a de-normalized number
* Infinity: In a floating-point number if the value of the exponent is all 1s and the value of a mantissa is all 0s, then the resultant value will be an infinite number and it will be represented by a special value called Infinity. Depending on the value of the sign bit (1-bit) we can specify if the value obtained is positive infinity or negative infinity.
* Not a Number: In a floating-point number if the value of the exponent is all 1’s and the value of a mantissa is non-zero, then the resultant value will not be a number and it will be represented by a special value called Not a Number (NaN).


**Design Decisions :**

* The pipelined hardware architecture for a double precision floating point adder consists of six functional stages. We made sure that the hardware complexity is equal for each stage.
* Giving equal hardware complexity in each stage helps in improving throughput of the adder.
* We made sure that each stage as 1 calculation part and a buffer(shifting values through registers.)

**Project Structure :**
* This project contains one bsv file which contains both testbench and the FP adder.
* Each of them are designed as different module, inwhich the top module is the test bench which gives the inputs to the interface of the FP Adder module for each clock cycles.
* The test bench then collects the output from the interface and prints them.
* The test bench runs for 31 clock cycles. You can change that by changing the condition to activate $finish ().
* The test cases used in the test bench are included in the FPAdd_Test_Cases.pdf for the readers convenience. 


**Verification methodalogy :**

* The test bench has 9 sets of inputs comprising all types of possibilities and the output is printed for each clock cycle.
* Since the first clock cycle is taken to give the inputs from testbench to the FP Adder, the final output of the 1st set of inputs is printed at 7th Clock cycle. 
* While printing the simulation using ./sim , clock cycles are mentioned as 5, 15, 25, 35 in bluespec compiler (Each 10 corrosponds to a clock cycle).
* The first output comes at 75, and the second output comes at 85, and so on. The outputs arrive at each subsquent clock cycles.
* The simulation completes at 31st clock cycle because we have set $finish () if the clock counter hits 31. You can run any number times by increasing the clock counter represented as " rg_y " register in the testbench. ()Test bench is the top module in the bsv script.
* Since we have given 9 set of inputs, the final output for the 9th set of inputs arrive at 15th clock cycle represented by 155 while printing the simulation results. The same result is printed for the clock cycles following this, because the FP adder runs till 31st clock cycle. You can stop at 15th clock cycle by setting the $ finish () condition to activate at 15th clock cycle.
* Check out the FPAdd_Test_Cases.pdf to verify the results.
* Note: The results are printed in the IEE754 format inwhich the exponents are subtrated from its base value 1023. Usual online calculators don't Subtract this base value.
