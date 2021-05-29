'''
    
'''
import numpy as np

def add_exponential(data, start, length, height):
    '''
        adds an exponential decay signal to a given signal (superimposes lineare additive ueberlagerung beider signale)

        Args:
            * data: a list of numerical values that represent discrete measurements of a signal. This is the signal that the exponential decay function is added to
            * start: a positive integer that is the index in data where the exponential decay signal begins
            * length: a positive integer that is the length of the exponential decay signal added to data. The decay signal is terminated at the end of data.
            * height: The height of the first value of the exponential decay signal added to data

        Returns:
            * edata: a copy of data that contains the added exponential signal
    '''
    if start > len(data):
        return data
    if len(data) > start+length:
        end = start+length
    else:
        end = len(data)
    for i, elem in enumerate(data[start:end]):
        data[start+i] = elem + height*np.exp(-i/(length/5))
    return data
