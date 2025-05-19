%KAsra
% #define _IS_MULTI_ICE_
classdef modellingParams

    properties
        %NOTE: to add anew property add it here, and in the properties of
        %Stratified_iceModel.m or tools.m depending who is using it.

        %input/output files and locations
        cluster;
        inputFileName       = 'Input_Params.xlsx';      %the input parameters
        inputsFolderName    = '';                                %the subfolder in the inputs folder where the input files are located.
        outputFolderName    = '';                                %the subfolder in the outputs folder where the model is being created
        fullThicknessesListFileName = 'fullThicknessesList.mat'; %fullThicknessesList.mat filename
        coordinateFile      = 'coordinates.xlsx' ;    % coordinate file with the extension that is in the inputsfolder

        %data prep flags
        prepareData         = false;   %200times; start at 16000
        convertLatLon2UTM   = false;   % if the coordinates are on lat/lon degrees, set this to true to convert to meters. 
        diffCoord4Thicknesses= true;                                             % if true, the coordinate for the surface and the thicknesses will be different, MIDAS will read the thickness coordinates from the first 2 columns in each thickness tab 
        initialMeshRes      = 10000;  %initial resolution for a triangular form raw mesh within the specified domain       
        mainDomainFile      = '';
        mainDomainMinRes    = 1000;
        mainDomainMaxRes    = 2000;
        nestedDomainFile    = '';
        planetName          = planetProperties.MARS;
        numb_MeshVirtualLayers = 5;
        nestedDomainRes     = 100;      
        inversionAmnt       = 12000;   % if Amount is given then the base will be inversionAmnt-Base. Otherwise Base will be used as is. Default for MCID is 12000 m. 
        shiftBaseUp         = 0;       % if an amount is given then the base will be base+shiftBaseUp. This is useful to push the base uniformly above the sea level. 
        useMatlabMeshFunc   = false;   %sets tools to use griddata instead of issm interop function

        %executation configuration
        RunSimulation       = true;    %set it to false if no simulation is to be run. this is good to draw mesh without the flow or run the code without any simulations
        DrawMesh            = true;    %true to draw the mesh after each time period
   
        SavePlots           = false;   %this actually enables pause function between drawing each plot. whether or not it is "true" the plots are still saving on more powerful machineself. in slower machines this will have to be "true" to give the machine enough time to save a plot before moving on to the next plot
         resumeAfterFailure=true; %if this is true, as soon as the script starts, it look for a 
        % _<outputFolderName>_start_from_<year>, and if one exists, it will
        % continue from <year>. TransientStartingYr needs to be 0
        % or this flag will be ingnored and the process will start from
        % that year

        plotView_x          = 23;
        plotView_y          = 61;

        %what time period to start? how to run the solver
        minTimeStep         = 0.1;     %[yr]; the input value will be overwritten by =0.1 of years, if the solver fails with a high level of residual threshold.
        maxTimeStep         = 1;
        outputFreq          = 1;	   %[time steps]
        transientStartingYr = 0;       %starting time in the excel file (i.e. time period) to load; use 0 for the very first period; if there is a model existing and we want to continue from there, enter the time period here.
        % if you want to start from year 0, make sure there is no folder
        % with ./<outputfoldername><_TransientStartingYr>  naming structure
        useSMB2EndOfYear    = 0;      %if there is number greater than 0, SMB and the original extrude/collapse functions will be used to end end of this year before switching to the multi_unit logic
        normalRsdlThrshld   = 1e-6;   %normal residual_threshold for the solve
        icreasedRsdlThrshld = 1e-3;   %if the normal residual_threshold is too low and the solver can't handle it, then the solver can use this value. If this fails too, then for the third and last time the solver will run with the residual thresholde of 0.01

        %debugging flags 
        debugging           = false;   %if true everytime that the solver is called, a copy of the model will be saved. turn this off for actual model run or this will create a major overhead
        verboseFlag         = false;   %set it to true to see the full output from the solver. setting it to true will increase the runtime of the solver


        %solver configuration flags
        SolverEngine        = 'HO';    %the solver engine: HO, SSA
        nestedSolverEngine  = false;
        
        geoFlux             = 0.025;   %[W/m^2]
        thicknessThreshold  = 1.0;     %[m]
        thickness_minThreshld=0;

        EveryNmbYrCallSolver = 50;   %use this if useSMB_to_CallSolver=true
        %how many times the solver should be called in a time period. e.g. a 
        % time period is 1000 years; if this is 1000, then the solver will  
        % be called 1000 times in 1 year periodself. (different from when 
        % the solver calculates in 1 year time intervals)
        % This will be calculated using everyNbrYrCallSolver and will be
        % used in the code
        callSolverPerPeriod = -1;  
        
        %limit the thickness of any node if it reaches this limit:
        %median(thicknesses)*capsThicknessLimitFactor
        capThicknessLimitFactor=10000;
        capThicknessOnlyOnBoundaries=true;

        useSMB_to_CallSolver=false; % turn this on to use SMB between year 1 and everyNbrYrCallSolver

    end

    methods (Static)




    end
end