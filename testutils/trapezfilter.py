import sys
import os

class accumulator(object):
    def __init__(self):
        self.prev_acc = 0

    def shift_in(self, in_val):
        result = self.prev_acc + in_val
        self.prev_acc = result
        return result

class delayed_subtractor(object):
    def __init__(self, delay):
        self.delay = delay
        self.i = 0
        self.delayarr = []

    def shift_in(self, in_val):
        if self.i < self.delay:
            self.i += 1
            self.delayarr.append(in_val)
            return in_val
        else:
            delayed_val = self.delayarr[0]
            self.delayarr = [self.delayarr[i] for i in range(1,self.delay)]
            self.delayarr.append(in_val)
            return in_val-delayed_val

class trapezoidalFilter(object):
    def __init__(self, k, l, m):
        self.acc_1 = accumulator()
        self.acc_2 = accumulator()
        self.sub_1 = delayed_subtractor(k)
        self.sub_2 = delayed_subtractor(l)
        self.m = m

    def shift_in(self, in_val):
        dkl = self.sub_2.shift_in(self.sub_1.shift_in(in_val))
        return self.acc_2.shift_in((dkl*self.m)+self.acc_1.shift_in(dkl))
