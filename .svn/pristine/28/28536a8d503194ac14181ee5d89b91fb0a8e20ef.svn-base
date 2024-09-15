#!/bin/bash

MATLAB_PATH="/cygdrive/c/Programs/MATLAB/R2015a"
PACKAGE="ISSM" # Name of directory to copy distributable files to
TARBALL_NAME='ISSM-Win10-64'
TARBALL=$TARBALL_NAME.tar.gz

# Source Windows environment
source $ISSM_DIR/externalpackages/windows/windows_environment.sh

# Clean up from previous packaging
echo "Cleaning up existing assets"
cd $ISSM_DIR
rm -rf $PACKAGE
mkdir $PACKAGE

# Add/modify required binaries
cd $ISSM_DIR/bin

echo "Making generic_static.m work like generic.m"
cat generic_static.m | sed -e "s/generic_static/generic/g" > generic.m

echo "Copying scripts from /src to /bin"
rm $ISSM_DIR/bin/*.m
find $ISSM_DIR/src/m -name '*.m' | xargs cp -t $ISSM_DIR/bin

echo "Copying gmsh to bin"
if [ -f ../externalpackages/gmsh/install/gmsh.exe ]; then
	cp ../externalpackages/gmsh/install/gmsh.exe ./gmsh.exe
else
	echo "gmsh not found"
fi

# Copy gmt to package
# NOTE: The following assumes the precompiled version of gmt
echo "Moving gmt to externalpackages"
if [ -f $ISSM_DIR/externalpackages/gmt/install/bin/gmt ]; then
	mkdir $ISSM_DIR/$PACKAGE/externalpackages
	mkdir $ISSM_DIR/$PACKAGE/externalpackages/gmt
	cp -a $ISSM_DIR/externalpackages/gmt/install $ISSM_DIR/$PACKAGE/externalpackages/gmt/install
else
	echo "gmt not found"
fi

# Check that test 101 runs
cd $ISSM_DIR/test/NightlyRun
rm matlab.log
$MATLAB_PATH/bin/matlab -nodisplay -nosplash -r "try, addpath $ISSM_DIR_WIN/bin $ISSM_DIR_WIN/lib; runme('id',101); exit; catch me,fprintf('%s',getReport(me)); exit; end" -logfile matlab.log

# Wait until MATLAB closes
sleep 5
pid=$(ps aux -W | grep MATLAB | awk '{printf("%s\n","MATLAB");}')
while [ -n "$pid" ]
do
	pid=$(ps aux -W | grep MATLAB | awk '{printf("%s\n","MATLAB");}')
	sleep 1
done

if [[ $(cat matlab.log | grep -c SUCCESS) -lt 10 ]]; then
	echo "test101 FAILED"
	exit 1;
else
	echo "test101 passed"
fi

# Create tarball
echo "Creating tarball: ${TARBALL_NAME}"
cd $ISSM_DIR
rm -f $TARBALL
cp -rf bin lib test examples scripts $PACKAGE/

# Create link to gmt from bin
# NOTE: It is important that we are in the destination dir when sym linking so that the path is relative
if [ -f $ISSM_DIR/$PACKAGE/externalpackages/gmt/bin/gmt ]; then
	cd $ISSM_DIR/$PACKAGE/bin
	ln -s ../externalpackages/gmt/bin/gmt.exe ./gmt.exe
fi

cd $ISSM_DIR
tar -czf $TARBALL $PACKAGE
ls -lah $TARBALL

# Ship binaries to website
echo "Shipping binaries to website"

# We're using public key authentication method to upload the tarball The
# following lines check to see if the SSH Agent is running. If not, then it is
# started and relevant information is forwarded to a script.
pgrep "ssh-agent" > /dev/null

if [ $? -ne 0 ]; then
	echo "SSH agent is not running. Starting it..."
	ssh-agent > ~/.ssh/agent.sh
else
	echo "SSH agent is running..."
fi

source ~/.ssh/agent.sh
ssh-add ~/.ssh/win_bins-geidi_prime_to_ross

scp $TARBALL jenkins@ross.ics.uci.edu:/var/www/html/$TARBALL

if [ $? -ne 0 ]; then
	echo "The upload failed."
	echo "Perhaps the SSH agent was started by some other means."
	echo "Try killing the agent and running again."
fi
