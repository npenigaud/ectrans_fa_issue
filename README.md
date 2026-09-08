## Description

A refactoring is in progress in ecTrans, aiming to propagate list of pointers down to the internal routines, instead of using the PGP/PSP arrays.

The related Pull Request is here : https://github.com/dhaumont/ectrans/pull/11
The corresponding branch is here: https://github.com/dhaumont/ectrans/tree/propagate_ptr

In this branch, the new way of propagating pointers is activated for the benchmark by adding thea dditional `--field-api` argument.
```
 ectrans-benchmark-gpu-dp -f 10 -l 10 --field-api --uvders --scders --vordiv
```

Unfortunately, there is big performance penalty when running on GPU when using this `--field-api` version.

This reproducer demonstrates the performance problems in the `PRFI1B` and `UPDSP` routines.

Different versions of these routines are implemented, and their performance is evaluated: 

- PRFI1B_REF and UPDSP_REF: reference versions, mimicking PRFI1B and UPDSP from ecTrans 
- PRFIB_V1 and UPDSP_V1: direct adaptation of the reference versions, using YDSP instead of PSPEC
- PRFIB_V2 and UPDSP_V2: version  mimicking EXCHANGE_MS_MOD.F90 from IAL (https://github.com/ACCORD-NWP/IAL/blob/develop/arpifs/module/exchange_ms_mod.F90)
- PRFIB_V3 and UPDSP_V3: version keeping YDSP on CPU

## Compilation and run

Compilation using the script `compile_nvhpc.sh`.
It builds the `main.x` program, which takes as arguments `KFIELD` (number of 2d fields), `KN` (spectral dim), `KMLOC` (spectral dim), and `COUNT` (iteration count)

```
compile_nvhpc.sh
main.x 100 100 100 10
```


## Results

Running on ATOS with the default parameters:

```
$ main.x
 ** Parameters **
  NFIELDS:          100
  NSMAX:          200
  DNUMP:          100
  NITER:         1000
 
 ** PRFI1B **
  PRFI1B_REF:   18.16
  PRFIB_V1:   57.81
  PRFIB_V2:   74.61
  PRFIB_V3:  869.09
 
 ** UPDSP **
  UPDSP_REF:   16.98
  UPDSP_V1:   89.69
  UPDSP_V2:   51.12
  UPDSP_V3:  856.73
```


Different results are obtained for different values for KFIELD, KN and KMLOC:
```
$ main.x 100 10 80 1000
 ** Parameters **
  NFIELDS:          100
  NSMAX:           10
  DNUMP:           80
  NITER:         1000
 
 ** PRFI1B **
  PRFI1B_REF:  202.55
  PRFIB_V1: 1037.89
  PRFIB_V2: 1162.90
  PRFIB_V3:18715.75
 
 ** UPDSP **
  UPDSP_REF:  224.31
  UPDSP_V1: 1161.05
  UPDSP_V2: 1094.77
  UPDSP_V3:18653.67
```

## Discussion

We suspect that the problems lie in the accesses to `YDSP(JFLD)%P`, which are not coalescent anymore.

Furthermore, the initial version is based on `PSPEC` which is dimensioned `(NFIELDS,NSPEC)`, meaning that the leading dimension is the fields. It's not the case anymore when we use`YDSP(JFLD)%P`, where the leading dimension is NSPEC.

It would be interesting to investigate if the implementation of a CACHE, as done in EXCHANGE_MS_MOD.F90, can solve this problem (https://github.com/ACCORD-NWP/IAL/blob/782aa4da884ec3d7c83a8e064955bd75e00660e4/arpifs/module/exchange_ms_mod.F90#L310).
