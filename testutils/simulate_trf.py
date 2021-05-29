#! /usr/bin/python
import sys
import os
import numpy as np
import matplotlib.pyplot as plt
import trapezfilter as trf

if __name__ == "__main__":
    k = int(sys.argv[1])
    l = int(sys.argv[2])
    m = int(sys.argv[3])
    TRF = trf.trapezoidalFilter(k,l,m)

    tau = int(sys.argv[4])
    if len(sys.argv) > 5:
        with open(sys.argv[5], 'r') as f:
           testdata =  [int(line)for line in f.readlines()]
    else:
        exponential = [np.exp(-i/tau) for i in range(6*tau)]
        testdata = np.zeros(10*tau)
        testdata[2*tau:8*tau] += exponential

    output = [TRF.shift_in(elem) for elem in testdata]
    x = np.linspace(0, len(testdata)*8e-9, len(testdata))
    plt.plot(x, testdata, label="Filter Input")
    plt.plot(x, output, label="Filter Output")
    plt.grid()
    plt.legend()
    plt.xlabel("Time [s]")
    plt.ylabel("(ADC/Filter)-Value")
    plt.show()
