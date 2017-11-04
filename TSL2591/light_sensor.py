#!/usr/bin/python -p

# Simple script to read Lux value from TSL2591 Light Sensor using library
# from maxlklaxl - https://github.com/maxlklaxl/python-tsl2591
# It expects to have read_tsl.py in same folder. That's because target
# system doesn't have pip nor setuptools to install whole package

from read_tsl import Tsl2591

tsl = Tsl2591()  # initialize
full, ir = tsl.get_full_luminosity()  # read raw values (full spectrum and ir spectrum)
lux = tsl.calculate_lux(full, ir)  # convert raw values to lux

print lux
