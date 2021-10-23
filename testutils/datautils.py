#! /usr/bin/python
import os
import sys
import math
import matplotlib.pyplot as plt
import numpy as np
import bisect

SI_units = ('V', 'A', 'N', 'kg', 'm', 's', 'cd')
prefixes = {'m': 10**-3, 'd': 10**2, 'u':10**-6, 'n':10**-9, 'p':10**-12, 'k':10**3, 'G': 10**9}

def read_file(filepath):
    '''
        read in data from the txt files exported by Picoscope. This function also converts all inputs
        to SI base units (so from ms -> s, for example)

        Args:
          * filepath: string, path to the file containing the data (relative or absolut)

        Returns:
          * data: normalized data from the inputs
          * units: metric units (and derivatives) in columns all normalized to not include prefixes
    '''
    f = open(filepath, 'r')
    if filepath.split('.')[-1]=="csv":
        delim=','
    else:
        delim='\t'
    _ = f.readline().strip()
    # the second line contains the units so it needs to be treated seperately
    line2 = f.readline().strip()
    # discard empty line
    f.readline()
    units = []
    data = []
    # extract the units from the second line
    for word in line2.split(delim):
        units.append(word.strip('()'))
    # all other lines are assumed to contain data so read them into a list per row (of floats)
    for line in f.readlines():
        data.append(list(float(i) for i in line.split(delim)))
    if len(data[1]) != len(units):
        raise IndexError('number of units inconsistent with number of data columns')
    # convert the data to si units using the units provided by the csv file
    for i, unit in enumerate(units):
        if len(unit) > 1:
            if unit[1:] in SI_units:
                if unit[0] in prefixes:
                    for j, elem in enumerate(data):
                        data[j][i] = elem[i] * prefixes[unit[0]]
                    units[i] = unit[1:]
                else:
                    raise ValueError('The Unit prefix is not contained in the table of prefixes.')
            else:
                raise ValueError('The Unit in column %d cannot be found in the unit table' % i)
    f.close()
    return data, units

def remove_time_duplicates(data, t_col):
    '''
        removes all data rows that have the same timestamp as the previous one

        Args:
            * data: a list of lists that contain numerical data of any kind
            * t_col: column number that contains the timestamp

        Returns:
            * fdata: data with all successive duplicate timestamp-rows removed
    '''
    fdata = [data[0]]
    prev_val = data[0]
    for elem in data[1:]:
        if elem[t_col] != prev_val[t_col]:
            fdata.append(elem)
            prev_val = elem
    return fdata

def average_measurements(data):
    '''
        averages all set of measurements of multiple variables into one value per variable

        Args:
            * data: a list of lists. The inner list represents all variables of a measurement that where captured simultaneously

        Returns:
            * adata: a list of the same dimension of the inner list of data. Every entry is the average of the column
    '''
    if len(data) == 1:
        return data
    adata = data[0]
    for measurement in data[1:]:
        for i,value in enumerate(measurement):
            adata[i] += value
    for i, value in enumerate(adata):
        adata[i] = value/len(data)
    return adata

def resample_data(data, t_col, dt):
    '''
        resamples the signal to a different time step. This function does not do any interpolation.

        Args:
            * data: a list of lists that contains the numerical values of a measurement per list element
            * t_col: the column that contains the timestamp of the measurement
            * dt: the interval (in seconds) that is to contains one measurement (measurement rate = 1/dt)

        Returns:
            * ddata: data that is altered to contain one measurement per dt period.
    '''
    original_time = np.array([d[t_col] for d in data])
    t0 = original_time[0]
    tmax = original_time[-1]
    delta = tmax-t0
    num_samples = int(delta/dt)
    linspace_tmax = t0 + (num_samples * dt)
    resample_times = np.linspace(t0, linspace_tmax, num_samples)
    lo_index = 0
    resampled_data =[]
    for t in resample_times:
        index = bisect.bisect_left(original_time, t, lo=lo_index)
        lo_index = index
        resampled_entry = []
        for i, elem in enumerate(data[index]):
            if i != t_col:
                resampled_entry.append(elem)
            else:
                resampled_entry.append(t)
        resampled_data.append(resampled_entry)
    return resampled_data


def downsample_data(data, units, t_col, dt):
    '''
        reduces the amount of measurements in the file to one measurement per dt.
        one row of the data (element in the list) represents one measurement.
        It is assumed that data contains more measurements per dt.

        Args:
            * data: a list of lists that contains the numerical values of a measurement per list element
            * t_col: the column that contains the timestamp of the measurement
            * dt: the interval (in seconds) that is to contains one measurement (measurement rate = 1/dt)

        Returns:
            * ddata: data that is altered to contain one measurement per dt period.
    '''
    prev_val = data[0]
    samples = []
    ddata = [data[0]]
    for elem in data[1:]:
        if abs(prev_val[t_col] - elem[t_col]) < dt:
            samples.append(elem)
        else:
            if len(samples) <= 1:
                ddata.append(elem)
            else:
                averaged_data = average_measurements(samples)
                averaged_data[t_col] = elem[t_col]
                ddata.append(averaged_data)
            prev_val = elem
            samples = []
    return ddata

def plot_waveform(data, units, save=False, savePath=''):
    '''
        plots a graph of the data in data. The data can only contain 2 columns.
        used so that the data can be quickly looked at

        Args:
            * data: a list of lists/tuples of len 2. contains the x and y data for the plot.
                the x-axis is asumed to be the time axis
            * units: a list of strings [x, y] that are to be used as units on the axis

        Returns:
            * figure: a matplotlib figure that contains the plot of the data
    '''
    figure = plt.figure()
    axis = figure.add_subplot(1,1,1)
    xdat = []
    ydat = []
    for elem in data:
        xdat.append(elem[0])
        ydat.append(elem[1])
    axis.plot(xdat, ydat, linestyle='-')
    axis.set_xlabel(units[0])
    axis.set_ylabel(units[1])
    if save:
        if savePath == '':
            raise ValueError('The save path is empty')
        figure.savefig(savePath)
    return figure

def convert_to_binary_word(data, t_col, bits, voltage_range):
    '''
        takes the data and converts all values to the integer equivalent of an unsigned binary number with width 'bits'
        The maxixum value of the binary-number representation is reached, when the value in the file matches/exceeds the
        voltage_range parameter.

        Args:
            * data: a list of lists where the inner list represents one measurement with a timestamp at position t_col
            * t_col: the column in the data (position in inner list) that stores the timestamp
            * bits: width of the word the data should be converted to
            * voltage_range: the voltage (positive and negative) where the numerical representation of the input reaches (bits**(n-1)-1)

        Returns:
            bdata: a list of lists of the same dimension as data but where all values are now positive integers in the range 0 - (2**bits - 1)
                exept for the timestamp which is preserved
    '''
    columns_wo_t = []
    dv = []

    # create a list of columns so that we can work on them individually
    for i in range(len(data[0])):
        if i != t_col:
            col = []
            for measurement in data:
                col.append(measurement[i])
            columns_wo_t.append(col)
    #extract the time data
    timestamps = []
    for measurement in data:
        timestamps.append(measurement[t_col])
    # start working on the other columns
    for col in columns_wo_t:
        scaling_factor = (2**(bits-1)-1) / voltage_range
        for i, val in enumerate(col):
            tmp_val = val * scaling_factor
            col[i] = int(round(tmp_val, 0))
    # add in the timestamp column and convert back to a list of measurements
    columns_wo_t.insert(t_col, timestamps)
    bdata = list(zip(*columns_wo_t))
    return bdata
