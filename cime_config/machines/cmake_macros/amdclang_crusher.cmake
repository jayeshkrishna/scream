set(MPICC "cc")
set(MPICXX "CC")
set(MPIFC "ftn")
set(SCC "cc")
set(SCXX "CC")
set(SFC "ftn")

set(NETCDF_PATH "$ENV{NETCDF_DIR}")
set(PNETCDF_PATH "$ENV{PNETCDF_DIR}")
string(APPEND CPPDEFS " -DLINUX")
if (COMP_NAME STREQUAL gptl)
    string(APPEND CPPDEFS " -DHAVE_NANOTIME -DBIT64 -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY")
endif()
string(APPEND SLIBS " -L$ENV{PNETCDF_PATH}/lib -lpnetcdf -L$ENV{CRAY_LIBSCI_PREFIX_DIR}/lib -lsci_amd")
if (NOT MPILIB STREQUAL mpi-serial)
  string(APPEND SLIBS " -L$ENV{ADIOS2_DIR}/lib64 -ladios2_c_mpi -ladios2_c -ladios2_core_mpi -ladios2_core -ladios2_evpath -ladios2_ffs -ladios2_dill -ladios2_atl -ladios2_enet")
endif()
set(PNETCDF_PATH "$ENV{PNETCDF_DIR}")
set(CRAY_LIBSCI_PREFIX_DIR "$ENV{CRAY_LIBSCI_PREFIX_DIR}")
