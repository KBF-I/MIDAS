%% MIDAS: Martian South Polar Multi-layered/Stratified Ice Deposition Modelling  
%Kasra Fard, 2023 % #define _IS_MULTI_ICE_

mp=modellingParams();

%the target machine, either a computeCanada cluster, or the local machine
mp.cluster = computecanada('email','kbfard@yorku.ca',       'mailtype', 'NONE',   'login','kbfard',  'name','narval', ...
                           'projectaccount','def-ibsmith',  'cpuspertask',2,      'memory',8,...
                           'codepath',     '/home/kbfard/projects/def-ibsmith/kbfard/v3/trunk-jpl/bin',...
                           'executionpath','/home/kbfard/projects/def-ibsmith/kbfard/v3/trunk-jpl/execution');
mp.cluster=generic('name',oshostname(),'np',45);% local machine

mp.inputsFolderName     = 'MCID-MultiLayeredv5';                         %! where the input files are
mp.outputFolderName     = 'MCID-MultiLayeredv5';                                               %! where the output files will be; leave empty to outputFolderName=inputsFolder name
      
mp.prepareData          = false;                                            %! Execute & Plot both use this: to setup the input mat file; or to create the plotting input files  
mp.convertLatLon2UTM    = false;                                             % if the coordinates are on lat/lon degrees, set this to true to convert to meters.
mp.useMatlabMeshFunc    = true;                                             % if the interop function in ISSM fails, then set this to true to use matlab's function. 
mp.diffCoord4Thicknesses= true;                                             % if true, the coordinate for the surface and the thicknesses will be different, MIDAS will read the thickness coordinates from the first 2 columns in each thickness tab 
mp.inversionAmnt        = 12000;                                                %! [m] inversionAmnt-base to inverse the base. For Mars SP (and the default) is 12000
mp.shiftBaseUp          = 0;                                             %! [m] base(or inversed base)+the amount to lift the base up to move the base higher than the "sea level"

mp.inputFileName        = 'Input_Params.xlsx'; 
mp.coordinateFile       = 'coordinates2.csv';                          %  coordinate file with the extension that is in the inputsfolder
mp.planetName           = planetProperties.MARS;                             % the planet 
mp.numb_MeshVirtualLayers = 5; 
mp.initialMeshRes       = 3000;                                              %! [m] initial triangle base resolution. Maximum 10 times that of the very minimum res used anywhere in the mesh
mp.mainDomainFile       = 'maindomain.exp';                                %! The main domain file name.
mp.mainDomainMinRes     = 4000;                                             %!
mp.mainDomainMaxRes     = 6000;                                             %! the minimum and maximum resolutions in the main domain area
mp.nestedDomainFile     = '2.exp';%nesteddomain.exp';%'smalldomain.exp';                                  %  nested domain area if there is one; leave it "empty" if there is none.
mp.nestedDomainRes      = 3500;                                              %  [m] the resolution of the nested domain area
mp.fullThicknessesListFileName = 'fullThicknessesList.mat'; 

onlyPlot                = false;                                             %  only plot the results, or only run a simulation 
mp.RunSimulation        = ~onlyPlot;                                         %  set it to false, if it is neither only plot nor running the simulation
mp.DrawMesh             = false;
mp.plotView_x           = 0;           mp.plotView_y = 90;                %  used only if onlyPlot=true   -120/60
Boundaries              = [0,600; 0,0.7; 150,190; -1,-1];                % Boundaries define the scale boundaries for plots; use -1 in at least x or y of one, to ignore and use max and min from the available data. The structure is ...
% Boundaries=[minThickness, maxThickness;minVel, maxVel; minTemperature, maxTemperature; minquiver, maxquiver]
xlim=[-2.73e5 -1.1e5] ;    ylim=[-3.5e4 1.9e5];                              % Use these to zoom into an area in the plot; use -1 for any one of the 4 numbers to plot the entire domain
makeMovie               = true;                                              % set to true to make vidoes from the plots that have been created.

mp.resumeAfterFailure   = true;                                              %  restarts from <year> in _<outputFolderName>_start_from_<year>. TransientStartingYr needs to be 0 or this flag will be ingnored and the process will start from  that year
mp.transientStartingYr  = 0;                                                 %! starting year - 0: if it starts from year 0, or to use the folder name. IF there is a number here, it will take precedence over the folder name 
mp.useSMB2EndOfYear     = 57000;                                                 %! up to this year, MIDAS will use SMBs
mp.useSMB_to_CallSolver = false;                                             %  true means after the year in the variable above, only for the top units SMBs will be used. 
mp.SMBYrs2CallSolver    = 5;                                                %  the year time steps if the variable above it true
mp.noSMBYrs2CallSolver  = 10;                                                 %  every this # of year the solver will be called, when SMB is not used
mp.minTimeStep          = 0.1;                                             
mp.maxTimeStep          = 5;                                                %  this and above variable: min and max internal solver timesteps
mp.outputFreq           = 100;                                                %  the solver will produce out put every this number of years 

mp.capThicknessLimitFactor=50000;      mp.capThicknessOnlyOnBoundaries=true; %limit the thickness of any node if it reaches this limit: median(thicknesses)*capsThicknessLimitFactor
mp.geoFlux              = 0.03;       mp.SolverEngine         = 'HO';     
mp.thicknessThreshold   = 1.0;         mp.thickness_minThreshld= 0.001;
mp.normalRsdlThrshld    = 1e-3;        mp.icreasedRsdlThrshld  = 1e-1;     

mp.SavePlots            = false;
mp.debugging            = false;       mp.verboseFlag          = false; 

s=Stratified_iceModel(mp);  
   
%% Run, Run... Never Stop 
try
    startTime=tic;
    if onlyPlot
        if mp.prepareData, s.toolbox.createArray4Plotting_MassVolInfoLst_Solutions(); end   % set up the input data for plotting
        s.toolbox.plotMe  (mp.plotView_x, mp.plotView_y, mp.DrawMesh, Boundaries, xlim, ylim, makeMovie);                      % plot using the viewing angles
    else
        copyfile([mfilename('fullpath') '.m'],[s.toolbox.runsPath s.toolbox.outputRunFolder '/Inputs']); % copy this file into the outputs folder
        s.runMe(mp);  % Run simulation. 


    end
catch me
    % if an error has happened
    endTime=toc(startTime)/60;
    fprintf('\n\nThe code has been terminated abnormally. Duration: %.2f minutemp.\n', endTime );
    disp (me);
    datetime("now")
    rethrow (me);
end
endTime=toc(startTime)/60;
fprintf('\n\nProcess ended normally. Duration: %.2f minutemp.\n', endTime );
datetime("now")

clear s;
