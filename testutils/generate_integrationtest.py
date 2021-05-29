#!/usr/bin/python
import datautils as du
import argparse as ap
import numpy as np

if __name__ == "__main__":
    parser = ap.ArgumentParser(description="Generates a file containing a series of test vectors for the Trapezoidal filter from a picoscope export")
    parser.add_argument("rawdata", help="Path to the file containing the raw picoscope export")
    parser.add_argument("testfile", help="Path to the file that the resulting test vectors are written to (the file is created if does not yet exist)")
    parser.add_argument("paramfile", help="Path to the File that holds the parameters that configure the filter in the simulation")
    parser.add_argument("-b", "--bits",type=int, default=14, help="Define the width of the binary (2's complement) representation of the number")
    parser.add_argument("-r", "--range", type=float, default=20, help="Define the Voltage for which the binary representation reaches the magnitude of 2^(bits-1)-1")
    parser.add_argument("-k", type=int, default=30, help="set the k filter parameter to a custom value (rise time in clk cycles)")
    parser.add_argument("-l", type=int, default=100, help="set the l filter parameter to a custom value (l-k is the hold time in clk cycles)")
    parser.add_argument("-m", type=int, default=500, help="set the m filter parameter to a custom value (m compensates for exponential decay)")
    parser.add_argument("-pt", "--peak_threshhold", type=int, default=100000, help="set the minimum peak value so that the peaks registers")
    parser.add_argument("-th", "--timer_hold", type=int, default=100, help="the time that the event filter accumulates events before outputting the max event")
    parser.add_argument("-sf", "--speed_tick_freq", type=int, default=10, help="set the repeat time for the speed tick")
    parser.add_argument("-cf", "--cycle_tick_freq", type=int, default=133, help="set the repeat time for the cycle tick")
    parser.add_argument("-p", '--plot', help="Gererate a plot showing the original and the converted data side by side")
    args = parser.parse_args()

    result_file = open(args.testfile, 'w+')
    param_file = open(args.paramfile, 'w+')
    # get the data and units from the source file and process
    data, units = du.read_file(args.rawdata)
    if 's' in units:
        t_col = units.index('s')
    else:
        t_col = 0
    fdata = du.remove_time_duplicates(data, t_col)
    bdata = du.convert_to_binary_word(fdata, t_col, args.bits, args.range)
    # create the plot (optional)
    if args.plot is not None:
        figure = du.plot_waveform(bdata, units)
        figure.savefig(args.plot)
    # create the cycle and speed ticks
    cycle_ticks = np.zeros(len(bdata))
    speed_ticks = np.zeros(len(bdata))
    for i, elem in enumerate(cycle_ticks):
        if i % args.speed_tick_freq == 0:
            speed_ticks[i] = 1
        if i % args.cycle_tick_freq == 0:
            cycle_ticks[i] = 1

    # write everything to a file
    param_file.write(str(args.k)+'\n')
    param_file.write(str(args.l)+'\n')
    param_file.write(str(args.m)+'\n')
    param_file.write(str(args.peak_threshhold)+'\n')
    param_file.write(str(args.timer_hold)+'\n')
    for elem, cycle_tick, speed_tick in zip(bdata, cycle_ticks, speed_ticks):
        result_file.write(str(elem[1])+' '+str(int(cycle_tick))+' '+str(int(speed_tick))+'\n')
    result_file.close()
