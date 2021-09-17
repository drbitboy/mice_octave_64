#!/bin/bash

########################################################################
########################################################################
### Build MICE for 64-bit Gnu Octave (https://octave.org/)
### This procedure is based on:
### https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/req/mice.html
###
### Brian T. Carcich ca. 2021-09-15
### BrianTCarcich@gmail.com
########################################################################
########################################################################
###
### Quick-start
### ===========
###
###   cd [...]/mice/            ### CHDIR to MICE/Matlab/CSPICE toolkit
###                             ### - Replace [...] with the local
###                             ###   path to the toolkit
###   path/mice_octave_64.bash  ### Execute this script
###
###
### Post-build
### ==========
###
###   Add the following two lines in ~/.octaverc
###
###     addpath('[...]/mice/lib/octave');
###     addpath('[...]/mice/src/');
###
###   %%% N.B. Replace [...] with the local path to the toolkit
###
###
### Prerequisites
### =============
###
### * This script should be executable
###
###     chmod a+x mice_octave_64.bash
###
### * Start with 64-bit MICE (Matlab/SPICE) installation, and
###   CHDIR to top of MICE hierarchy e.g.
###
###     curl https://naif.jpl.nasa.gov/pub/naif/toolkit/MATLAB/PC_Linux_GCC_MATLAB7.x_64bit/packages/mice.tar.Z | tar zxf -
###     cd mice
###
### * A development environment, typically gcc and g++
###
### * Octave and Octave development must be installed, and the mkoctfile
###   executable script is in the PATH.  E.g. in a debian-based
###   distribution such as Ubuntu, this would be satisified via a
###   command such as as
###
###      sudo apt install octave liboctave-dev
###
########################################################################


####################################
### Check prerequisites

### - 64-bit MICE/CSPICE install

[ "$(ar p lib/cspice.a tkvrsn_c.o | head -5c | tail -c -1 | tr @ 0 | tr \\002 @)" == "@" ] \
|| ( echo "64-bit tkvrsn_c.o not found in lib/cspice.a" && false ) || exit -1

### - Octave development script is present and in PATH

which mkoctfile | grep -q /mkoctfile \
|| ( echo "Octave development script [mkoctfile] not found in PATH" && false ) || exit -2


####################################
### Make minor fixes to CSPICE source code to avoid compiler warnings

sed -e '/^[ \t]*fread(.*);/s/fread[(].*[)]/if(&)/'            -i src/cspice/backspace.c
sed -e '/sprintf.*fort.%ld",/s/%ld",/%d",(int)/'              -i src/cspice/endfile.c src/cspice/open.c
sed -e '4s/ftnint/sig_pf/' -e '/return (ftnint)/s/(ftnint)//' -i src/cspice/signal_.c


####################################
### Create and run script to build lib/cspice_mix.a for Octave/Mice

cp -p src/cspice/mkprodct.csh src/cspice/mkprodct_mix.csh
sed \
  -e '/ set TKCOMPILEOPTIONS/aset TKCOMPILEOPTIONS = "${TKCOMPILEOPTIONS} -DMIX_C_AND_FORTRAN"' \
  -e '/set LIBRARY *=.*item:t/aset LIBRARY = "${LIBRARY}_mix"' \
  -i src/cspice/mkprodct_mix.csh

( cd src/cspice ; ./mkprodct_mix.csh 2>&1 | tee mkprodct_mix.log | grep -vE '^[ar] -|^ *Compiling.*\.c$|^ *$' )


####################################
### Edit src/mice/*mice*.c files to fix integer size problems

sed -i -e '/^ *int     *sizearray/s/int    /int64_t/' src/mice/*mice*.c
sed -i -e '/^ *const * int     *[*] *Dims/s/int    /int64_t/' src/mice/zzmice.c

sed -e '/^ *int     *size_limbpts/s/int    /int64_t/'  \
    -e '/^ *int     *size_plateIDs/s/int    /int64_t/' \
    -e '/^ *int     *size_spoints/s/int    /int64_t/'  \
    -e '/^ *int     *size_termpts/s/int    /int64_t/'  \
    -i src/mice/mice.c


########################################################################
########################################################################
### Build lib/octave/mice.mex from those files; adapted from
### https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/req/mice.html
########################################################################

[ -d lib/octave ] || mkdir -pv lib/octave


####################################
### mkoctfile options
###
### -v     Verbose mode, output compile, link command (use if needed)
### -c     Compile to object code
### --mex  Compile code based on the Matlab environment MEX
###


####################################
### Use mkoctfile to compile the Mice source files for Octave use.

mkoctfile --mex -c -Iinclude -DOCTAVE -o src/mice/mice.o -Wno-date-time src/mice/mice.c

mkoctfile --mex -c -Iinclude src/mice/zzmice.c -o src/mice/zzmice.o

mkoctfile --mex -c -Iinclude src/mice/zzmice_CreateIntScalar.c -o src/mice/zzmice_CreateIntScalar.o


####################################
### Link the source files to an extension library. Use the "mixed"
### version of the CSPICE library.

mkoctfile --mex -o src/mice/mice.mex  \
                   src/mice/mice.o    \
                   src/mice/zzmice.o  \
                   src/mice/zzmice_CreateIntScalar.o \
                   lib/cspice_mix.a

####################################
### Clean-up and move the library to the expected directory,
### lib/octave.

find src/mice/ -maxdepth 1 -name '*.o' -not -type d | xargs rm
mv src/mice/mice.mex lib/octave/mice.mex

octave --no-window-system << EoFoctave
addpath('$PWD/lib/octave');
addpath('$PWD/src/mice');
cspice_furnsh('data/cook_01.tls');
utc = '2000-01-01T12:00';
printf("\n===============================\n");
printf("Running Octave/CSPICE/MIXE test\n");
printf("===============================\n");
printf("Cookbook DELTA_ET for\n  UTC = %s\nshould be 57.184:\n  "
      ,utc
      );
cookbook_DELTA_ET = cspice_str2et(utc)
printf("===============================\n\n");
exit
EoFoctave
