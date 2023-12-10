# Pipelined-Double-Precision-Floating-Point-Adder

This repository contains the bluespec code for the pipelined double precision floating point adder, done as a part of the course CS6230 CAD For VLSI, IIT Madras.
* Authors : HARIHARAN P (EE20B042)  AND  JAWHAR S (EE20B049)
* Date: 10 Dec 2023
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


** Design Decisions :**
