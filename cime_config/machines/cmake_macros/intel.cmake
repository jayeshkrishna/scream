string(APPEND CFLAGS " -fp-model precise -std=gnu99")
if (compile_threaded)
  string(APPEND CFLAGS " -qopenmp")
endif()
if (NOT DEBUG)
  string(APPEND CFLAGS " -O2 -debug minimal")
endif()
if (DEBUG)
  string(APPEND CFLAGS " -O0 -g")
endif()
string(APPEND CXXFLAGS " -std=c++14 -fp-model source")
if (compile_threaded)
  string(APPEND CXXFLAGS " -qopenmp")
endif()
if (DEBUG)
  string(APPEND CXXFLAGS " -O0 -g")
endif()
if (NOT DEBUG)
  string(APPEND CXXFLAGS " -O2")
endif()
string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_R16 -DCPRINTEL")
string(APPEND CXX_LDFLAGS " -cxxlib")
set(CXX_LINKER "FORTRAN")
string(APPEND FC_AUTO_R8 " -r8")
string(APPEND FFLAGS " -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source")
if (compile_threaded)
  string(APPEND FFLAGS " -qopenmp")
endif()
if (DEBUG)
  string(APPEND FFLAGS " -O0 -g -check uninit -check bounds -check pointers -check noarg_temp_created")
endif()
if (NOT DEBUG)
  string(APPEND FFLAGS " -O2 -debug minimal")
endif()
string(APPEND FFLAGS_NOOPT " -O0")
string(APPEND FIXEDFLAGS " -fixed -132")
string(APPEND FREEFLAGS " -free")
set(HAS_F2008_CONTIGUOUS "TRUE")
if (compile_threaded)
  string(APPEND LDFLAGS " -qopenmp")
endif()
set(MPICC "mpicc")
set(MPICXX "mpicxx")
set(MPIFC "mpif90")
set(SCC "icc")
set(SCXX "icpc")
set(SFC "ifort")
set(SUPPORTS_CXX "TRUE")
