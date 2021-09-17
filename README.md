# Build MICE for 64-bit Gnu Octave (https://octave.org/)

This procedure is based on https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/req/mice.html

Brian T. Carcich ca. 2021-09-15

BrianTCarcich@gmail.com

## Quick-start

    cd [...]/mice/            ### CHDIR to MICE/Matlab/CSPICE toolkit
                              ### - Replace [...] with the local
                              ###   path to the toolkit
    path/mice_octave_64.bash  ### Execute this script


## Post-build

Add the following two lines in ~/.octaverc

    addpath('[...]/mice/lib/octave');
    addpath('[...]/mice/src/');

N.B. Replace [...] with the local path to the toolkit

## Prerequisites

* The script should be executable

    chmod a+x mice_octave_64.bash

* Start with 64-bit MICE (Matlab/SPICE) installation, and CHDIR to top of MICE hierarchy e.g.

      curl https://naif.jpl.nasa.gov/pub/naif/toolkit/MATLAB/PC_Linux_GCC_MATLAB7.x_64bit/packages/mice.tar.Z | tar zxf -
      cd mice

* A development environment, typically gcc and g++

* Octave and Octave development must be installed, and the mkoctfile executable script is in the PATH.  E.g. in a debian-based distribution such as Ubuntu, this would be satisified via a command such as as

    sudo apt install octave liboctave-dev
