if (NOT DEBUG)
  string(APPEND CFLAGS " -O2")
  string(APPEND CXXFLAGS " -O2")
  if (COMP_NAME STREQUAL eam)
    string(APPEND FFLAGS " -O1 -Mnovect -DSUMMITDEV_PGI")
  else()
    string(APPEND FFLAGS " -O2 -DSUMMITDEV_PGI")
  endif()
endif()
if (COMP_NAME STREQUAL cice)
  string(APPEND FFLAGS " -Mnovect")
endif()
string(APPEND SLIBS " -L$ENV{ESSL_PATH}/lib64 -lessl")
set(MPICXX "mpiCC")
set(PIO_FILESYSTEM_HINTS "gpfs")
set(SFC "pgfortran")
set(CMAKE_NO_SYSTEM_FROM_IMPORTED ON)
string(APPEND KOKKOS_OPTIONS " -DKokkos_ARCH_POWER9=On")
