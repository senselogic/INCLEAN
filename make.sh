#!/bin/sh
set -x
dmd -m64 inclean.d
rm *.o
