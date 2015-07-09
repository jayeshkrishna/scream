#!/usr/bin/env perl 
package test_ModuleLoader;

use Data::Dumper;
use Test::More;
use Test::Exception;
use Module::ModuleLoader;

use parent qw(Test::Class);

# Override the constructor so we can pass in arguments
#sub new
#{
#	my ($class, %params) = @_;
#	my $self = {
#        machine => $params{machine} || undef,
#	};
#
#	bless $self, $class;
#	return $self;
#}
sub set_machine
{
	my $self = shift;
	my $machine = shift;
	
	$self->{machine} = $machine;
}
#==============================================================================
# Common test fixtures for all tests. these get reused across all test instances, 
# They MUST be read-only  
#==============================================================================
sub startup: Test(startup => 0) {
	my $self = shift;
	# set up non-machine-specific stuff here. 
	#$self->{scriptsroot} = Cwd::abs_path("../../../scripts/");
	$self->{cimeroot} = Cwd::abs_path("../../../");
	#TODO defined the caseroot?
	
	#if($self->{machine} eq 'goldbach')
	#{
	#	$self->{init_path} = "/usr/share/Modules/init/";
	#	$self->{cmd_path} = "/usr/bin/modulecmd";
	#}
}

#==============================================================================
# 
#==============================================================================
sub shutdown: Test(shutdown) {
	my $self = shift;
}

#==============================================================================
# These get created for each test..
#==============================================================================
sub setup : Test(setup => 0) {
	my $self = shift;
}

#==============================================================================
#
#==============================================================================
sub teardown : Test(setup => 0) {
	my $self = shift;
}


#==============================================================================
# Tests  
#==============================================================================
sub test_new() : Test(1)
{
	my $self = shift;
	#my $machine = $self->{machine};
	my $machine = "goldbach";
	my $compiler = "intel";
	my $mpilib = "openmpi";
	#my $scriptsroot = "../../../scripts";
	#my $cimeroot = "../../../";
	my $cimeroot = "../../";
	
	my $moduleloader = Module::ModuleLoader->new(machine => $machine, compiler => $compiler, mpilib => $mpilib, 
	                                     debug => "FALSE", cimeroot => $cimeroot, caseroot => "$cimeroot/Tools");
	
	isa_ok($moduleloader, "Module::ModuleLoader");
                                         
}

sub test_moduleInit_brutus() : Test(2)
{
	my $self = shift;
	my $moduleloaderbrutus  = Module::ModuleLoader->new(machine => 'brutus', compiler => 'pgi', mpilib => 'openmpi', 
                                                       debug => "FALSE", cimeroot => "../../", caseroot => '.');
	
	$moduleloaderbrutus->moduleInit();
	
	ok($moduleloaderbrutus->{initpath} eq '/etc/profile.d/modules.perl') || diag($moduleloaderbrutus->{initpath});
	ok($moduleloaderbrutus->{cmdpath} eq '/usr/bin/modulecmd perl') || diag($moduleloaderbrutus->{cmdpath});
}

sub test_moduleInit_babbage() : Test(2)
{
	my $self = shift;
	my $moduleloader = Module::ModuleLoader->new(machine => 'babbage', compiler => 'intel', mpilib => 'impi', 
                                                       debug => "FALSE", cimeroot => "../../", caseroot => '.');
	
	$moduleloader->moduleInit();
	
	ok($moduleloader->{initpath} eq '/usr/share/Modules/init/perl.pm') || diag($moduleloader->{initpath});
	ok($moduleloader->{cmdpath} eq '/usr/bin/modulecmd perl') || diag($moduleloader->{cmdpath});
}

sub test_moduleInit_babbageKnc() : Test(2)
{
	my $self = shift;
	my $moduleloader = Module::ModuleLoader->new(machine => 'babbageKnc', compiler => 'intel', mpilib => 'impi', 
                                                       debug => "FALSE", cimeroot => "../../", caseroot => '.');
	
	$moduleloader->moduleInit();
	
	ok($moduleloader->{initpath} eq '/usr/share/Modules/init/perl.pm') || diag($moduleloader->{initpath});
	ok($moduleloader->{cmdpath} eq '/usr/bin/modulecmd perl') || diag($moduleloader->{cmdpath});
}

sub test_moduleInit_bluewaters() : Test(2)
{
	my $self = shift;
	my $moduleloader = Module::ModuleLoader->new(machine => 'bluewaters', compiler => 'pgi', mpilib => 'mpich', 
                                                       debug => "FALSE", cimeroot => "../../", caseroot => '.');
	
	$moduleloader->moduleInit();
	
	ok($moduleloader->{initpath} eq '/opt/modules/default/init/perl.pm') || diag($moduleloader->{initpath});
	ok($moduleloader->{cmdpath} eq '/opt/modules/3.2.10.3/bin/modulecmd perl') || diag($moduleloader->{cmdpath});
}

sub test_moduleInit_goldbach() : Test(2)
{
	my $self = shift;
	my $moduleloaderintel  = Module::ModuleLoader->new(machine => 'goldbach', compiler => 'intel', mpilib => 'openmpi', 
                                                       debug => "FALSE", cimeroot => "../../", caseroot => '.');
	
	$moduleloaderintel->moduleInit();
	
	ok($moduleloaderintel->{initpath} eq '/usr/share/Modules/init/perl.pm') || diag($moduleloaderintel->{initpath});
	ok($moduleloaderintel->{cmdpath} eq '/usr/bin/modulecmd perl') || diag($moduleloaderintel->{cmdpath});
}

sub test_findModulesFromMachinesDir_goldbach() : Test(3):
{
	my $self = shift;
	my @expectedintelmodules = ( { action => 'load', actupon => 'compiler/intel/14.0.2', seqnum => 1} );
	my $moduleloader = Module::ModuleLoader->new(machine => 'goldbach', compiler => 'intel', mpilib => 'openmpi', 
                                                 debug => 'FALSE', cimeroot => "../../", caseroot => '.');
	$moduleloader->moduleInit();
	my @actualintelmodules = $moduleloader->findModulesFromMachinesDir();
	is_deeply(\@expectedintelmodules, \@actualintelmodules);

	my @expectedpgimodules = ( { action => 'load', actupon => 'compiler/pgi/14.10', seqnum => 1} );
	my $pgimoduleloader = Module::ModuleLoader->new(machine => 'goldbach', compiler => 'pgi', mpilib => 'openmpi', 
                                                 debug => 'FALSE', cimeroot => "../../", caseroot => '.');
	$pgimoduleloader->moduleInit();
	my @actualpgimodules = $pgimoduleloader->findModulesFromMachinesDir();
	is_deeply(\@expectedpgimodules, \@actualpgimodules);
}

sub test_moduleInit_yellowstone() : Test(2)
{
	my $self = shift;
	my $moduleloaderys = Module::ModuleLoader->new(machine => 'yellowstone', compiler => 'intel', mpilib => 'mpich2',
                                                   debug => "FALSE", cimeroot => "../../", caseroot => ".");

	$moduleloaderys->moduleInit();
	
	ok($moduleloaderys->{initpath} eq '/glade/apps/opt/lmod/lmod/init/perl') || diag($moduleloaderys->{initpath});
	ok($moduleloaderys->{cmdpath} eq '/glade/apps/opt/lmod/lmod/libexec/lmod perl') || diag($moduleloaderys->{cmdpath});
}
sub test_findModulesFromMachinesDir_yellowstone() : Test(3):
{
	my $self = shift;
	my @expectedintelmpichmodules = ( 
                            { action => 'purge', actupon => '', seqnum => 1},
                            { action => 'load', actupon => 'ncarenv/1.0', seqnum => 2},
                            { action => 'load', actupon => 'ncarbinlibs/1.1', seqnum => 3},
                            { action => 'load', actupon => 'perlmods', seqnum => 4},
                            { action => 'load', actupon => 'gmake/4.1', seqnum => 5},
                            { action => 'load', actupon => 'python', seqnum => 6},
                            { action => 'load', actupon => 'all-python-libs', seqnum => 7},
                            { action => 'load', actupon => 'intel/15.0.1', seqnum => 8},
                            { action => 'load', actupon => 'mkl/11.1.2', seqnum => 9},
                            { action => 'load', actupon => 'netcdf-mpi/4.3.3-rc3', seqnum => 10},
                            { action => 'load', actupon => 'pnetcdf/1.6.0', seqnum => 11},
                            { action => 'load', actupon => 'esmf', seqnum => 12},
                            { action => 'load', actupon => 'esmf-6.3.0rp1-defio-mpi-O', seqnum => 13},
                            { action => 'load', actupon => 'ncarcompilers/1.0', seqnum => 14},
                            { action => 'load', actupon => 'cmake/2.8.10.2', seqnum => 15},
						  );
	#print Dumper \@expectedintelmpichmodules;
	my $moduleloader = Module::ModuleLoader->new(machine => 'yellowstone', compiler => 'intel', mpilib => 'mpich2', 
                                                 debug => 'false', cimeroot => "../../", caseroot => '.');
	$moduleloader->moduleInit();
	my @actualintelmpichmodules = $moduleloader->findModulesFromMachinesDir();
	#print Dumper \@actualintelmpichmodules;
	#print "expected: ", ref $expectedintelmpichmodules[0], "\n";
	#print "actual: ", ref $actualintelmpichmodules[0], "\n";
	is_deeply(\@actualintelmpichmodules, \@expectedintelmpichmodules, "do modules match");

    my @expectedpgimpichmodules = (
                            { action => 'purge', actupon => '', seqnum => 1},
                            { action => 'load', actupon => 'ncarenv/1.0', seqnum => 2},
                            { action => 'load', actupon => 'ncarbinlibs/1.1', seqnum => 3},
                            { action => 'load', actupon => 'perlmods', seqnum => 4},
                            { action => 'load', actupon => 'gmake/4.1', seqnum => 5},
                            { action => 'load', actupon => 'python', seqnum => 6},
                            { action => 'load', actupon => 'all-python-libs', seqnum => 7},
                            { action => 'load', actupon => 'pgi/14.7', seqnum => 8},
                            { action => 'load', actupon => 'netcdf/4.3.0', seqnum => 9},
                            { action => 'load', actupon => 'pnetcdf/1.4.1', seqnum => 10},
                            { action => 'load', actupon => 'ncarcompilers/1.0', seqnum => 11},
                            { action => 'load', actupon => 'cmake/2.8.10.2', seqnum => 12},
							);
	my $moduleloaderpgi = Module::ModuleLoader->new(machine => 'yellowstone', compiler => 'pgi', mpilib => 'mpich2', 
                                                 debug => 'false', cimeroot => "../../", caseroot => '.');
	$moduleloaderpgi->moduleInit();
	my @actualpgimpichmodules = $moduleloaderpgi->findModulesFromMachinesDir();
	is_deeply(\@actualpgimpichmodules, \@expectedpgimpichmodules);
	
	my @expectedintelmpiserialdebugmodules = (
                            { action => 'purge', actupon => '', seqnum => 1},
                            { action => 'load', actupon => 'ncarenv/1.0', seqnum => 2},
                            { action => 'load', actupon => 'ncarbinlibs/1.1', seqnum => 3},
                            { action => 'load', actupon => 'perlmods', seqnum => 4},
                            { action => 'load', actupon => 'gmake/4.1', seqnum => 5},
                            { action => 'load', actupon => 'python', seqnum => 6},
                            { action => 'load', actupon => 'all-python-libs', seqnum => 7},
                            { action => 'load', actupon => 'intel/15.0.1', seqnum => 8},
                            { action => 'load', actupon => 'mkl/11.1.2', seqnum => 9},
                            { action => 'load', actupon => 'netcdf-mpi/4.3.3-rc3', seqnum => 10},
                            { action => 'load', actupon => 'pnetcdf/1.6.0', seqnum => 11},
                            { action => 'load', actupon => 'esmf', seqnum => 12},
                            { action => 'unload', actupon => 'netcdf-mpi/4.3.3-rc3', seqnum => 13},
                            { action => 'unload', actupon => 'pnetcdf/1.6.0', seqnum => 14},
                            { action => 'load', actupon => 'netcdf/4.3.2', seqnum => 15},
                            { action => 'load', actupon => 'esmf-6.3.0rp1-defio-mpi-g', seqnum => 16},
                            { action => 'unload', actupon => 'esmf-6.3.0rp1-defio-mpi-g', seqnum => 17},
                            { action => 'load', actupon => 'esmf-6.3.0rp1-defio-uni-g', seqnum => 18},
                            { action => 'load', actupon => 'ncarcompilers/1.0', seqnum => 19},
                            { action => 'load', actupon => 'cmake/2.8.10.2', seqnum => 20},
	);
	my $moduleloadermpiserialdebug = Module::ModuleLoader->new(machine => 'yellowstone', compiler => 'intel', mpilib => 'mpi-serial', 
                                                 debug => 'true', cimeroot => "../../", caseroot => '.');
	$moduleloadermpiserialdebug->moduleInit();
	my @actualintelmpiserialdebugmodules = $moduleloadermpiserialdebug->findModulesFromMachinesDir();
	is_deeply(\@actualintelmpiserialdebugmodules, \@expectedintelmpiserialdebugmodules);
}

sub test_writeXMLFileForCase_yellowstone() : Test(3):
{
	my $self = shift;
    my $moduleloader = Module::ModuleLoader->new(machine => 'yellowstone', compiler => 'intel', mpilib => 'mpich2',
                                                 debug => 'false', cimeroot => "../../", caseroot => '.');
    $moduleloader->moduleInit();
	$moduleloader->writeXMLFileForCase();
	
	my $expectedfile = "./t/mocks_ModuleLoader/mach_specific.yellowstone.xml";
	open(my $EXPECTED, "<", $expectedfile) or die "could not open $expectedfile";
	my $expected = <$EXPECTED>;
	close $EXPECTED;

	my $actualfile = "./mach_specific.xml";
	open(my $ACTUAL, "<", $actualfile) or die "could not open $actualfile";
	my $actual = <$ACTUAL>;
	close $actual;
	ok($actual eq $expected);
}
1;
	
