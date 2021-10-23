#! /usr/bin/python
import sys
import os
import numpy as np
import matplotlib.pyplot as plt
import trapezfilter as trf
import argparse as ap

if __name__ == "__main__":
    parser = ap.ArgumentParser(description="Simulates the Trapezoidal filter implemented in the Trapezfilter IP Core")
    parser.add_argument("paramfile", help="Path to the file that contains the filter parameters")
    parser.add_argument("datafile", help="Path to the file that contains the input waveform")
    parser.add_argument("-dt", "--timestep",
                        help="Timestep to use for the simulation." +
                        "the Timestep is the duration between measurements",
                        type=float, default=256e-9)
    args = parser.parse_args()

    pfile = open(args.paramfile, 'r')
    k = int(pfile.readline().strip())
    l = int(pfile.readline().strip())
    m = int(pfile.readline().strip())
    TRF = trf.trapezoidalFilter(k,l,m)
    pfile.close()

    data = np.loadtxt(args.datafile, delimiter=' ')
    signal = np.array([d[0] for d in data])

    output = [TRF.shift_in(val) for val in signal]
    x = np.linspace(0, len(signal)*args.timestep, len(signal))

    color = 'tab:red'
    fig, ax = plt.subplots()
    ax.set_xlabel('Time [s]')
    ax.set_ylabel('Digitized Voltage')
    ax.plot(x, signal, label="Filter Input", color='darkred')
    ax.tick_params(axis='y', labelcolor=color)

    color = 'tab:blue'
    ax2 = ax.twinx()
    plt.plot(x, output, label="Filter Output", color='blue')
    ax2.set_ylabel("Filter-Value")
    ax2.tick_params(axis='y', labelcolor=color)
    plt.show()
