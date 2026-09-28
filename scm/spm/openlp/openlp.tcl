load $env(G2_ROOT)/bin/libtbcload.so
source $env(G2_ROOT)/tcllib/openlp/openlp.tbc

set task [gvar . task]

set edactrl(procname_disp) 1

source upf_$task/spm.upf

exit

