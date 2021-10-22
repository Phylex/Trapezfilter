# Trapezfilter
A trapezoidal filter implemented on a Xilinx ZYNQ FPGA with an AXI4 Lite interface to the CPU

## Overview
This repository contains the needed scripts and sources to compile and simulate a trapezoidal filter attached to the CPU of a ZYNQ chip.
The IP-core was designed to work on the Red-Pitaya, utilizing it's ADCs as input to the trapezoidal filter. Together with the trapezoidal filter,
periphery is implemented, that can detect a peak in the filter output, that will then be measured and stored in a FIFO for the CPU to access.

This IP-core is used in the Physics laboratory courses at KIT to measure the Moessbauer-effect. It provides the high speed processing needed to
measure this effect.
It relies on external hardware to control the experimental setup and receives the auxiliary signals 'Speed' and 'Cycle' from this hardware. It also
needs software to run on the Red-Pitayas linux OS to collect the data from the hardware on the FPGA. As this host software sends the data to a client
over it's network interface, a special piece of client software also needs to run on a client that is connected to the Red-Pitaya over the network.

## Experimental Setup
The current experimental Setup is 
