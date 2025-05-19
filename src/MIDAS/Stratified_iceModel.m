%% Multi-layered Ice Deposition Modelling - MARS MCID Modelling
% Martian Ice Deposits Analysis and Simulation (MIDAS)
% Kasra March 2021 - Feb 2023 - version 0.98
% March 2023 - removed the plotting from this code. See backups before
% March 6 to recover those if needed. For Plotting, use the runme script
% #define _IS_MULTI_ICE_ 


%SEARCH KEY WORDS:
    %FUTURE
    %TODO
    %QUESTION
    %NOTE
    %IMPORTANT
    %CO2_H2O_Specific

classdef Stratified_iceModel

    properties (SetAccess=public)
        %variables
        md;                 toolbox;                  plotting;
        initInnerLimits;    fullThicknessesList;      modelBed;
        initializeModel;    iceUnitsFromInputFile;    totalModelHeightFromInputFile; 
        useMatlabMeshFunc;  diffCoord4Thicknesses;    planetName;
        numb_MeshVirtualLayers = 5;

        %NOTE: to add anew property add it here, and in the properties of
        %modellingParams.m

        resumeAfterFailure=true; %if this is true, as soon as the script starts, it look for a 
        % _<outputFolderName>_start_from_<year>, and if one exists, it will
        % continue from <year>. TransientStartingYr needs to be 0
        % or this flag will be ingnored and the process will start from
        % that year

        coordinateFile       = 'coordinates.xlsx' ;    % coordinate file with the extension that is in the inputsfolder

        %domainArea = 0.  %[m^2]
        %UseMultiMaterialBackEnd = true; % activates the multi-ice analysis functionality in the backend by setting up the material type as 8. 

        %input/output files and locations
        inputFileName       = 'Input_Params.xlsx';      %the input parameters
        inputsFolderName    = '';                                %the subfolder in the inputs folder where the input files are located.
        outputFolderName    = '';                                %the subfolder in the outputs folder where the model is being created
        fullThicknessesListFileName = 'fullThicknessesList.mat'; %fullThicknessesList.mat filename

        %debugging flags 
        debugging           = false;   %if true everytime that the solver is called, a copy of the model will be saved. turn this off for actual model run or this will create a major overhead
        verboseFlag         = false;   %set it to true to see the full output from the solver. setting it to true will increase the runtime of the solver
        
        initialMeshRes      = 10000;  %initial resolution for a triangular form raw mesh within the specified domain       
        mainDomainFile     = '';
        mainDomainMinRes   = 1000;
        mainDomainMaxRes   = 2000;
        nestedDomainFile   = '';
        convertLatLon2UTM  = false;
        nestedDomainRes = 100;      

        %executation configuration
        inversionAmnt       = 12000;   % if Amount is given then the base will be inversionAmnt-Base. Otherwise Base will be used as is. Default for MCID is 12000 m. 
        shiftBaseUp         = 0;       % if an amount is given then the base will be base+shiftBaseUp. This is useful to push the base uniformly above the sea level. 
        RunSimulation       = true;    %set it to false if no simulation is to be run. this is good to draw mesh without the flow or run the code without any simulations
        prepareData         = false;   %200times; start at 16000
        DrawMesh            = true;    %true to draw the mesh after each time period
   
        SavePlots           = false;   %this actually enables pause function between drawing each plot. whether or not it is "true" the plots are still saving on more powerful machineself. in slower machines this will have to be "true" to give the machine enough time to save a plot before moving on to the next plot
 
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

        %solver configuration flags
        SolverEngine        = 'HO';    %the solver engine: HO, SSA
        nestedSolverEngine  = false;
        geoFlux             = 0.025;   %[W/m^2]
        thicknessThreshold  = 1.0;     %[m]
        thickness_minThreshld=0;
        thickness_firstIceUnit_threshold=1.0;

        EveryNmbYrCallSolver = 2;    %use this if we are not using SMBs at all

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

    methods
        function self=Stratified_iceModel(mp)
            clc;
            warning OFF BACKTRACE
            if ~mp.SavePlots, pause('off'); end
            fprintf('Modelling Ice Deposition Across the Solar System (MIDAS) 2019-2025\nBased on ISSM - NASA - JPL\n\n ');
            self=self.convertMP2Self(mp);

            self.toolbox=tools(self, mp.cluster);
            self.toolbox=self.toolbox.setInitialParams(self, mp.cluster);
        end

        function self=runMe(self, mp)
            % RUNME main function for the model
            %   inputFileName = the name of the input file that exists in the
            %   Inputs folder. Do not enter the extension, or folder location
            %
            %   outputFolderName = the location of output runs, if left empty
            %   the folder location will be the same as the inputFileName. Do
            %   not use location for outputFolderName; it will be created
            %   inside the Runs folder. Existing folders will be overwritten
            %   without error or warning.
            simulationStartTime=tic;

            if self.prepareData  
                self.md = modelmulti_Ice();
                self.toolbox.readCoordinatesFromExcel(self.md,self.inversionAmnt, self.initialMeshRes, self.fullThicknessesListFileName, self.shiftBaseUp); %10000: initial resolution
            end  
            self.toolbox.debugging = self.debugging;
            %self.plotting = plottingTools(self.toolbox.runsPath, self.toolbox.outputRunFolder, self.toolbox.numbLayers);

            %initiate the model; this file has all the input data. It
            %could be slow to build it so it is based to build it once and
            %reuse it. and it could get really large
            temp=load ([self.toolbox.inputsPath self.fullThicknessesListFileName]);   %'fullThicknessesList.mat'
            temp.md.settings=settingsmulti_Ice();
            self.md=temp.md; 
            self.md.materials=matmulti_Ice();
            
            self.md.settings.thickness_firstIceUnit_threshold=self.thickness_firstIceUnit_threshold;
            self.md.settings.thickness_minThreshld=self.thickness_minThreshld;
            self.md.settings.output_frequency=self.outputFreq;

            self.fullThicknessesList=temp.mythickness;
            self.modelBed=temp.modelBed;
            self.totalModelHeightFromInputFile=temp.totalModelHeightFromInputFile;
            self.iceUnitsFromInputFile=temp.iceUnitsFromInputFile;
            clear temp

            %there is the risk that some of the values are old in the
            %fullthicknesslist, so we need to recreate some of the objects
            %to get their fresh values
            self.md.multiIceMesh=self.md.multiIceMesh.registerNbrLayers(self.toolbox.numbLayers);
           % self.md.materials=matmulti_Ice();
            %self.md.multiIceMesh.domainArea=self.domainArea;
            [self.md, ~] = planetProperties.setPlanetMoonProperties(self.md, self.toolbox.planetCode);
            self.md.miscellaneous.name = self.toolbox.name;

            if ~self.SavePlots, pause('off'); end
            %fprintf(['\nThe Solver Engine is: ' self.SolverEngine '\n']);
            fprintf('Simulation starting ...\n\n');
            [self, self.md]=self.Parameterization(self.md);
            try
                if ~self.SavePlots, pause('off'); end
                self.initializeModel  = true;
                
                [self,loadStep]=loadPrevModel(self,mp);

                if loadStep==1
                   [~,guid] = fileparts(tempname);
                   self.toolbox.logStartSimulation(self, guid);
                else

                end

                %run the model
                self= self.runModel (loadStep);
            catch e
                self.toolbox.logEndSimulation(e.message,toc(simulationStartTime)/60);
                
                rethrow (e)
            end

            simulationEndTime=toc(simulationStartTime)/60;
            fprintf('Simulation Total time elapsed: %.2f minuteself.\n\n', simulationEndTime);
            self.toolbox.logEndSimulation(' ',toc(simulationStartTime)/60);  
        end
        
        function self=runModel(self, loadStep)
            tic;
            self.toolbox.logTime('> Start of the simulation: %s\n\n', -1);

            self.md.multiIceMesh.domainArea=getDomainArea(self);
            
            if self.initializeModel
                currentBed            = self.modelBed;
                self.md.geometry.base = currentBed;
                self.md.geometry.bed  = currentBed;
            elseif loadStep>1    %loading an old model
                currentBed=self.md.multiIceMesh.iceUnits(end).Surface;
            end
            
            %list of all thinkesses -   the rest are thicknesses starting from the lowest layer
            %loop#1: time period loop
            for idx =loadStep:length(self.toolbox.finalTimeVector)
                modelType='';
                try
                    perform (self.toolbox.org, ['TransientRuns' int2str(idx-1)]);
                catch        
                    %if the file already exists, just use it. 
                end

                fprintf ('\n Run for time period ending at: %i \n', self.toolbox.finalTimeVector(idx)); 
                
                %the first row is the timeperiod; the second row is the iceType;
                %find all the thickness columns for this timeperiod
                tempThicknesses=self.fullThicknessesList(:,(self.fullThicknessesList(1,:)==self.toolbox.finalTimeVector(idx)));
                try
                    if isempty(tempThicknesses), tempThicknesses=[0;self.fullThicknessesList(2,2);ones(size(tempThicknesses,1)-2,1)]; end
                catch
                    if isempty(tempThicknesses), tempThicknesses=[0;self.toolbox.finalTimeVector(idx);ones(size(tempThicknesses,1)-2,1)]; end
                end
                self.md.timestepping.final_time=self.md.timestepping.start_time;
                
                %set the time marker: create a folder that says what period is being
                %run; if the run fails use this as the start of the
                %year
                try
                    mkdir(['./_' self.outputFolderName '_'  int2str(self.toolbox.finalTimeVector(idx-1))]);
                catch
                end
                %remove the privious folder
                try
                    rmdir(['./_' self.outputFolderName '_'  int2str(self.toolbox.finalTimeVector(idx-2))]);
                catch
                end

                numberofvertices=self.md.mesh.numberofvertices;
                if self.md.multiIceMesh.isModel3D
                    numberofvertices=self.md.mesh.numberofvertices2d;
                end
                tic;  
                startingPoint=0;if idx>1, startingPoint=self.toolbox.finalTimeVector(idx-1); end
               
                self.callSolverPerPeriod=(self.toolbox.finalTimeVector(idx)-startingPoint)/self.EveryNmbYrCallSolver;
                hhh=self.callSolverPerPeriod; %we can safely use either one of these two going forward
              
                if hhh==0 || (self.useSMB2EndOfYear > 0 && self.useSMB2EndOfYear >= self.toolbox.finalTimeVector(idx)), hhh=1; end
                m=rem((self.toolbox.finalTimeVector(idx)-startingPoint),hhh);
                timeSpan=(self.toolbox.finalTimeVector(idx)-startingPoint)/hhh;
                if m~=0 && (m~=(self.toolbox.finalTimeVector(idx)-startingPoint))
                    error('the callSolverPerPeriod: %i results in non-zero reminder for these periods:%i to %i',...
                        hhh,self.toolbox.finalTimeVector(idx-1),self.toolbox.finalTimeVector(idx)); 
                end
                
                %loop #3: sub-time
                for k=1:hhh %call the solver as many times as self.callSolverPerPeriod sayself...                 

                    %loop #2: material loop
                    for j=1:size(tempThicknesses,2)

                        %set tup the tempUnit:
                        currentIceType=tempThicknesses(2,j);
                        tempUnit=stratified_unit();
                        currentThicknesses=tempThicknesses(3:end, j);        
                        tempUnit.Bed=currentBed(1:numberofvertices);
                        tempUnit.IceType=currentIceType;
                        if currentIceType==2, tempUnit.NmbLayers=2;
                        else, tempUnit.NmbLayers=5;
                        end
                        tempUnit.ID=self.md.multiIceMesh.currentIceUnitsCnt+1;
                        self.md.multiIceMesh.currentPeriodThickness=currentThicknesses/hhh;

                        % Need the current total number of layers
                        TotalLayers=0;
                        for cc=1:self.md.multiIceMesh.currentIceUnitsCnt
                            TotalLayers=TotalLayers+self.md.multiIceMesh.iceUnits(cc).NmbLayers;
                        end
                        TotalLayers=TotalLayers-self.md.multiIceMesh.currentIceUnitsCnt+1;
                        if currentIceType~=self.md.multiIceMesh.iceUnits(end).IceType && self.md.multiIceMesh.currentPeriodThickness(1)>0        
                            TotalLayers=TotalLayers+tempUnit.NmbLayers-1;
                        end 

                        tempPeriodSMBs=repmat(self.md.multiIceMesh.currentPeriodThickness./((self.toolbox.finalTimeVector(idx)-startingPoint)),TotalLayers,1);
            
                        topUnit= (self.md.multiIceMesh.currentIceUnitsCnt==0) || (self.md.multiIceMesh.currentIceUnitsCnt>0 && currentIceType==self.md.multiIceMesh.iceUnits(end).IceType);
                                                
                        %SMB using logic
                        if (self.useSMB2EndOfYear > 0 && self.useSMB2EndOfYear >= self.toolbox.finalTimeVector(idx)) || ...
                           (topUnit && self.useSMB_to_CallSolver)
                            self.md.materials.useSMB=true;
                            self.md.smb.mass_balance=tempPeriodSMBs;
                            tempUnit.Thickness=0.*self.md.multiIceMesh.currentPeriodThickness;
                            fprintf ('   - Using SMBs; SMB=%i\n', tempPeriodSMBs(1));

                        else
                            self.md.materials.useSMB=false;
                            self.md.smb.mass_balance=0.*tempPeriodSMBs;
                            tempUnit.Thickness=self.md.multiIceMesh.currentPeriodThickness;
                            fprintf ('   - Without using SMBs; Thickness Change=%i\n',tempUnit.Thickness(1));
                            self.md.smb.mass_balance=zeros(self.md.mesh.numberofvertices,1);
                        end
                      
                        % CO2_H2O_Specific: CONTROL_ACCUMULATTION  is water on top, but if there is no CO2 beneath
                        %it, do not let it accumulate
                        if currentIceType==mat_consts.H2O && self.md.multiIceMesh.currentIceUnitsCnt>=2
                           threshold1=0;
                           if  self.md.multiIceMesh.currentIceUnitsCnt==2, threshold1=self.thicknessThreshold; end
                           %what is going on underneath?
                           M=find(self.md.multiIceMesh.iceUnits(end-1).Thickness<=threshold1);
                           %for areas we don't have CO2 underneath do
                           %not accumulate water ice
                           tempUnit.Thickness(M)=threshold1;
                        end

                        tempUnit.Surface=currentBed+tempUnit.Thickness;
                        fprintf ('\n   - Run sub year: %i-%i out of %ix%i runs, for period ending at %i \n', ...
                            k, j,hhh,size(tempThicknesses,2),self.toolbox.finalTimeVector(idx));   %print2
                        %tempUnit is ready now...

                        self.md =self.md.multiIceMesh.addNewUnit(self.md, tempUnit, tempPeriodSMBs);

                        self.md.materials = self.md.materials.setIceProperties(self.md); 

                        if self.md.multiIceMesh.impactedUnit ==-1, continue, end
                        if self.initializeModel
                            self.md.initialization.temperature = self.toolbox.surfaceTempVector(1)*ones(self.md.mesh.numberofvertices,1);
                            self.md.initialization.pressure=matmulti_Ice.multiUnitPressure_In3D(self.md);
                            self.md.timestepping.start_time=0;
                            self.md.timestepping.final_time=1;
                            self.md.timestepping.time_step=0;

                            if self.RunSimulation
                                modelType='Thermal';
                                [self.md, self.toolbox]=self.toolbox.solveModel(self.md, currentIceType ,'0', ...
                                    self.verboseFlag, self.debugging, modelType, self.normalRsdlThrshld, self.icreasedRsdlThrshld,...
                                    self.capThicknessLimitFactor, self.capThicknessOnlyOnBoundaries, self.SolverEngine, self.nestedSolverEngine);
                            end
                            self.initializeModel=false;
                            self.md.timestepping=timesteppingadaptive();
                            self.md.timestepping.start_time=0;
                            self.md.timestepping.final_time=timeSpan;
                            self.md.timestepping.time_step_min=self.minTimeStep;
                            self.md.timestepping.time_step_max=self.maxTimeStep;
                        end
 
                        if isempty(modelType), modelType='Transient'; end
                        if  self.md.timestepping.start_time==self.md.timestepping.final_time
                            self.md.timestepping.final_time=self.md.timestepping.final_time+timeSpan;
                        end
                        if self.RunSimulation && idx>1
                            self.md.thermal.spctemperature(self.md.mesh.vertexonsurface==1) = self.toolbox.surfaceTempVector(idx);
                            fprintf ('   - Timestepping, starttime: %i, finalTime: %i, timestep between %i to %i; iceType: %s \n', self.md.timestepping.start_time, ...
                                self.md.timestepping.final_time, self.md.timestepping.time_step_min, self.md.timestepping.time_step_max, ...
                                matmulti_Ice.convertIceCode2Name(currentIceType));
                            [self.md, self.toolbox]=self.toolbox.solveModel(self.md, currentIceType ,[int2str(self.md.timestepping.final_time) '_' ], ...
                                self.verboseFlag, self.debugging, 'Transient', self.normalRsdlThrshld, ...
                                self.icreasedRsdlThrshld,self.capThicknessLimitFactor, self.capThicknessOnlyOnBoundaries, self.SolverEngine, self.nestedSolverEngine);
                            currentBed=self.md.geometry.surface(1:numberofvertices);
                        end
                    end  %material loop

                    self.md.timestepping.start_time=self.md.timestepping.final_time;
                    self.md.timestepping.final_time=self.md.timestepping.start_time+timeSpan;
                end  %sub_time loop
                
                %we finished one time period; it is time to rebuild the
                %mesh, becuase the accumulation rate is now changing:
                % self.md=self.md.collapse();
                % self.md=self.md.extrudeModel(2);
                
                %here all the execution files are being removed.
                location=self.md.cluster.executionpath;
                listing = dir(location);
                for idx11=1: length(listing)
                    if contains(listing(idx11).name, self.toolbox.name)%'MARS'
                         rmdir([self.md.cluster.executionpath '/' listing(idx11).name],'s');
                    end
                end
                %when we are saving, final_time, the title, filename and finalTimevector are the
                %same;idx is one step higher
                if self.useSMB_to_CallSolver
                    self.md.timestepping.final_time=self.md.timestepping.start_time+(self.toolbox.finalTimeVector(idx)-startingPoint);
                end
                self.toolbox.logTime('', idx);

                try
                    % we are only needing and keeping the last output
                    M=unique(vertcat(self.md.uniqueTransientSolutions.unitID));
                    uniqueList2=[];    uniqueList1=[];      uniqueList=[];
                    for ii=1:length(M)
                        uniqueList1=self.md.uniqueTransientSolutions([self.md.uniqueTransientSolutions.unitID]==M(ii));
                        s=uniqueList1.SmbMassBalance;
                        s1=uniqueList1.H2OSmbMassBalance;
                        for i=2:length(uniqueList1)
                            s=s+(uniqueList1(i).SmbMassBalance);
                            s1=s1+(uniqueList1(i).H2OSmbMassBalance);
                        end
                        totalSMB=0;
                        H2OtotalSMB=0;
                        for i=1:length(uniqueList1) 
                            totalSMB=totalSMB+sum(uniqueList1(i).TotalSmb);
                            H2OtotalSMB=H2OtotalSMB+sum(uniqueList1(i).H2OTotalSmb);
                        end
                        step=idx-1;
                        uniqueList2=uniqueList1(end);
                        uniqueList2.step=step;
                        uniqueList2.TotalSmb=totalSMB;
                        uniqueList2.SmbMassBalance=s;
                        uniqueList2.H2OTotalSmb=H2OtotalSMB;
                        uniqueList2.H2OSmbMassBalance=s1;
                    
                        uniqueList=[uniqueList; uniqueList1];
                    end                  
                    self.md.uniqueTransientSolutions=uniqueList;
                    clear T sortedT sortedS uniqueList uniqueList1 uniqueList2;
                catch
                    %if an error happens just continue with what we have
                end

                self.toolbox.saveMe(self.md);%See NOTE1 above.
                self.md.uniqueTransientSolutions=[];         
                self.initInnerLimits = self.md.geometry.thickness>self.thicknessThreshold;

                toc;
            end  %loop1: time loop
        end


%{
function self=runModel(self, loadStep)
            tic;
            self.toolbox.logTime('> Start of the simulation: %s\n\n', -1);

            self.md.multiIceMesh.domainArea=getDomainArea(self);
            
            if self.initializeModel
                currentBed            = self.modelBed;
                self.md.geometry.base = self.modelBed;
                self.md.geometry.bed  = self.md.geometry.base;
            elseif loadStep>1
                currentBed=self.md.multiIceMesh.iceUnits(end).Surface;
            end
            
            %list of all thinkesses -   the rest are thicknesses starting from the lowest layer
            %loop#1: time period loop
            for idx =loadStep:length(self.toolbox.finalTimeVector)
                modelType='';
                try
                    perform (self.toolbox.org, ['TransientRuns' int2str(idx-1)]);
                catch        
                    %if the file already exists, just use it. 
                end

                fprintf ('\n Run for time period ending at: %i \n', self.toolbox.finalTimeVector(idx)); 
                
                %the first row is the timeperiod; the second row is the iceType;
                %find all the thickness columns for this timeperiod
                tempThicknesses=self.fullThicknessesList(:,(self.fullThicknessesList(1,:)==self.toolbox.finalTimeVector(idx)));
                try
                    if isempty(tempThicknesses), tempThicknesses=[0;self.fullThicknessesList(2,2);ones(size(tempThicknesses,1)-2,1)]; end
                catch
                    if isempty(tempThicknesses), tempThicknesses=[0;self.toolbox.finalTimeVector(idx);ones(size(tempThicknesses,1)-2,1)]; end
                end
                %SMB using logic
                if self.useSMB2EndOfYear > 0 && self.useSMB2EndOfYear >= self.toolbox.finalTimeVector(idx)
                    self.md.materials.useSMB=true;
                    fprintf ('   - Using SMBs; \n');   
                    self.md.materials.alwaysRecalculatePressureDuringExtrusion = true;   
                else
                    if self.md.materials.useSMB
                        self.md.materials.useSMB=false; %this needs to be here
                        self.md.materials = self.md.materials.setIceProperties (self.md);
                        self.md.timestepping.final_time=self.md.timestepping.start_time;
                    else
                        self.md.materials.useSMB=false; %this too needs to be here, don't take this out of the if statement
                    end
                   fprintf ('   - Without using SMBs; \n'); 
                   %making sure we don't have any SMBs
                    self.md.smb.mass_balance=zeros(self.md.mesh.numberofvertices,1);
                end

                %set the time marker: create a folder that says what period is being
                %run; if the run fails use this as the start of the
                %year
                try
                    mkdir(['./_' self.outputFolderName '_'  int2str(self.toolbox.finalTimeVector(idx-1))]);
                catch
                end
                %remove the privious folder
                try
                    rmdir(['./_' self.outputFolderName '_'  int2str(self.toolbox.finalTimeVector(idx-2))]);
                catch
                end

                numberofvertices=self.md.mesh.numberofvertices;
                if self.md.multiIceMesh.isModel3D
                    numberofvertices=self.md.mesh.numberofvertices2d;
                end
                tic;  
                startingPoint=0;if idx>1, startingPoint=self.toolbox.finalTimeVector(idx-1); end
               
                highestCntofSolverCall=(self.toolbox.finalTimeVector(idx)-startingPoint)/self.EveryNmbYrCallSolver;
                if self.useSMB_to_CallSolver
                    self.callSolverPerPeriod= (self.toolbox.finalTimeVector(idx)-startingPoint)/self.EveryNmbYrCallSolver;%use maximum
                else
                    self.callSolverPerPeriod= highestCntofSolverCall;
                end
              
                if (self.toolbox.finalTimeVector(idx)-startingPoint)>=self.callSolverPerPeriod
                    hhh=self.callSolverPerPeriod;
                else
                    hhh=self.toolbox.finalTimeVector(idx)-startingPoint;
                end
                
                if hhh==0 || self.md.materials.useSMB, hhh=1; end
                m=rem((self.toolbox.finalTimeVector(idx)-startingPoint),hhh);
                timeSpan=(self.toolbox.finalTimeVector(idx)-startingPoint)/hhh;
                if m~=0 
                    error('the callSolverPerPeriod: %i results in non-zero reminder for these periods:%i to %i',...
                        hhh,self.toolbox.finalTimeVector(idx-1),self.toolbox.finalTimeVector(idx)); 
                end
                loopTransient=false;
                
                %loop #3: sub-time
                for k=1:hhh %call the solver as many times as self.callSolverPerPeriod sayself...                 
                    %loop #2: material loop
                    for j=1:size(tempThicknesses,2)

                        %set tup the tempUnit:
                        currentIceType=tempThicknesses(2,j);
                        tempUnit=stratified_unit();
                        currentThicknesses=tempThicknesses(3:end, j);
                   %Kasra     if sum(currentThicknesses)==0, continue, end
         
                        tempUnit.Bed=currentBed(1:numberofvertices);
                        tempUnit.IceType=currentIceType;
                          tempUnit.NmbLayers=self.toolbox.numbLayers;
                        tempUnit.ID=self.md.multiIceMesh.currentIceUnitsCnt+1;
                        fprintf ('\n   - Run sub year: %i-%i out of %ix%i runs, for period ending at %i \n', ...
                            k, j,hhh,size(tempThicknesses,2),self.toolbox.finalTimeVector(idx));   %print2
                        self.md.multiIceMesh.currentPeriodThickness=currentThicknesses/hhh;
                        tempUnit.Thickness=self.md.multiIceMesh.currentPeriodThickness;
                        tempUnit.Surface=currentBed+tempUnit.Thickness;
                        %tempUnit is ready now...
                      
                        if self.md.materials.useSMB && self.useSMB2EndOfYear>= self.toolbox.finalTimeVector(idx) 
                            timespan2=timeSpan;
                            if timespan2==0, timespan2=1; end
                            t=currentThicknesses./timespan2;
                            if length(t)<length(self.md.geometry.surface)
                                t=repmat(t,self.toolbox.numbLayers,1);
                            end
                            self.md.smb.mass_balance=t; 
                        %end

                        % between 1 year and the number of years that needs
                        % to be covered in a call to the solver we use
                        % SMBs. 
                        elseif self.useSMB_to_CallSolver  
                            self.md.materials.useSMB=true;
                            loopTransient=false; 
                             % loopTransient=true;
                                self.md.multiIceMesh.currentPeriodThickness=self.EveryNmbYrCallSolver*currentThicknesses/(self.toolbox.finalTimeVector(idx)-startingPoint);  %% KK
                              
                            if self.md.multiIceMesh.currentIceUnitsCnt==0   % we are just starting it out
                                tempUnit.Thickness=ones(length(tempUnit.Thickness),1);  %^^^
                            elseif  self.md.multiIceMesh.currentIceUnitsCnt>1 && ...
                                    tempUnit.Thickness(1)<0 && ...
                                    tempUnit.IceType~=self.md.multiIceMesh.iceUnits(self.md.multiIceMesh.currentIceUnitsCnt).IceType   % we have sublimation...we can't use smbs
                                self.md.materials.useSMB=false;
                                 tempUnit.Thickness=self.md.multiIceMesh.currentPeriodThickness;
                                tempUnit.Surface=currentBed+tempUnit.Thickness;
                            else  %any other case
                                tempUnit.Thickness=zeros(length(tempUnit.Thickness),1);
                            end
                            if self.md.materials.useSMB
                                % timespan2=(self.toolbox.finalTimeVector(idx)-startingPoint);
                                % if timespan2==0, timespan2=1; end
                                % t=currentThicknesses./timespan2;
                                % if length(t)<length(self.md.geometry.surface)
                                %     t=repmat(t,self.toolbox.numbLayers,1);
                                % end
                                % 
                                % self.md.multiIceMesh.currentPeriodThickness=self.EveryNmbYrCallSolver*currentThicknesses/timespan2;
                                t=self.md.multiIceMesh.currentPeriodThickness;
                                t=repmat(t,self.toolbox.numbLayers,1);
                                self.md.smb.mass_balance=t;
                                fprintf('   - Switching to SMBs for %i years, and smb is %f; ice Type:%s...\n',self.EveryNmbYrCallSolver, t(1), matmulti_Ice.convertIceCode2Name(tempUnit.IceType));
                            else
                                self.md.smb.mass_balance=zeros(length(self.md.geometry.surface),1);
                                fprintf('   - NOT-USING SMBs - There is sublimation - For %i years; applied thickness is %f for each %i years; ice Type:%s...\n',...
                                    self.EveryNmbYrCallSolver, self.md.multiIceMesh.currentPeriodThickness(1),self.EveryNmbYrCallSolver, matmulti_Ice.convertIceCode2Name(tempUnit.IceType));
                            end
                        end    
   

                        % CO2_H2O_Specific: CONTROL_ACCUMULATTION  is water on top, but if there is no CO2 beneath
                        %it, do not let it accumulate
                        if tempUnit.IceType==mat_consts.H2O && self.md.multiIceMesh.currentIceUnitsCnt>=2
                            threshold1=0;
                            if  self.md.multiIceMesh.currentIceUnitsCnt==2, threshold1=self.thicknessThreshold; end

                            if  self.md.multiIceMesh.iceUnits(end-1).IceType==mat_consts.CO2 %self.md.multiIceMesh.currentIceUnitsCnt>=2
                                %what is going on underneath?
                                M=find(self.md.multiIceMesh.iceUnits(end-1).Thickness<=threshold1);
                                if ~isempty(M)
                                    %for areas we don't have CO2 underneath do
                                    %not accumulate water ice
                                    tempUnit.Thickness(M)=threshold1;
                                    tempUnit.Surface=tempUnit.Bed+tempUnit.Thickness;
                                end
                            end
                        end

                        self.md =self.md.multiIceMesh.addNewUnit(self.md, tempUnit);
                        if self.md.multiIceMesh.impactedUnit ==-1, continue, end
                        if self.initializeModel
                            self.md.initialization.temperature = self.toolbox.surfaceTempVector(1)*ones(self.md.mesh.numberofvertices,1);
                            self.md.initialization.pressure=matmulti_Ice.multiUnitPressure_In3D(self.md);
                            if self.md.multiIceMesh.impactedUnit ==-1, continue, end

                            %Temp everwhere is NaN except for the surface
                            %which is fixed as per the value provided and
                            %is treated as a boundary condition
                            self.md.thermal.spctemperature = NaN*ones(self.md.mesh.numberofvertices,1);
                            self.md.thermal.spctemperature(self.md.mesh.vertexonsurface==1) = self.toolbox.surfaceTempVector(1);

                            self.md.basalforcings.geothermalflux = self.geoFlux*ones(self.md.mesh.numberofvertices,1);
                            self.md.materials = self.md.materials.setIceProperties(self.md); 

                       %     self.md = setflowequation(self.md,self.SolverEngine,'all');

                            self.md.timestepping.final_time=1;
                            self.md.timestepping.time_step=0;
                            if self.md.timestepping.start_time>= self.md.timestepping.final_time
                                 self.md.timestepping.start_time=0;
                            end

                            if self.RunSimulation
                                modelType='Thermal';
                                [self.md, self.toolbox]=self.toolbox.solveModel(self.md, currentIceType ,'0', ...
                                    self.verboseFlag, self.debugging, modelType, self.normalRsdlThrshld, self.icreasedRsdlThrshld,...
                                    self.capThicknessLimitFactor, self.capThicknessOnlyOnBoundaries, self.SolverEngine, self.nestedSolverEngine);
                            end
                            self.initializeModel=false;

                            self.md.timestepping=timesteppingadaptive();
                            self.md.timestepping.start_time=0;
                            self.md.timestepping.final_time=timeSpan;
                        end
                        if ~self.initializeModel  %we cannot use an "else" statement because initializeModel flag could have been just set in line 278 above
                            self.md.timestepping.time_step_min=self.minTimeStep;
                            self.md.timestepping.time_step_max=self.maxTimeStep;
                        end
                        if isempty(modelType), modelType='Transient'; end
                        if   ~loopTransient && self.md.timestepping.start_time==self.md.timestepping.final_time
                            self.md.timestepping.final_time=self.md.timestepping.final_time+timeSpan;
                        end
                        if self.RunSimulation && idx>1
                            %if all the thicknessess have reached the
                            %threshold, then do not run the transient. just
                            %move on to the next time period
                            if ~all(self.md.geometry.thickness<=self.thicknessThreshold) || self.md.materials.useSMB
                                if loopTransient 
                                    count=floor((self.toolbox.finalTimeVector(idx)-startingPoint)/self.EveryNmbYrCallSolver);
                                    timeKeeper=self.md.timestepping.start_time;
                                    for runTrans=1:count
                                        self.md.timestepping.final_time=self.md.timestepping.start_time+self.EveryNmbYrCallSolver;
                                        self=self.executeTransient(idx, currentIceType);
                                        self.md=self.md.multiIceMesh.addNewUnit(self.md, tempUnit);
                                        self.md.timestepping.start_time=self.md.timestepping.final_time;
                                    end
                                    self.md.timestepping.start_time=timeKeeper;
                                    self.md.timestepping.final_time=timeKeeper;
                                else
                                    self=self.executeTransient(idx, currentIceType);
                                end
                            end
                        else
                            self.md.initialization.vx=zeros(size(self.md.initialization.vx,1),1);
                            self.md.initialization.vy=zeros(size(self.md.initialization.vy,1),1);
                            self.md.initialization.vz=zeros(size(self.md.initialization.vz,1),1);
                            self.md.initialization.vel=zeros(size(self.md.initialization.vel,1),1);
                            self.md.initialization.temperature(isnan(self.md.initialization.temperature))=0;
                        end
                        currentBed=self.md.geometry.surface(1:numberofvertices);
                    end  %material loop

                    %NOTE 1: when the mesh shows a year, e.g. Year: 10000, it
                    %means that we have completed a simulation ending in
                    %year 10000 (e.g., simulation from year 9000 to 10000,
                    %if the timestep is 1000 years), and the current year
                    %is the year=10000. We can re-start the process and
                    %continue the simulation runs by using
                    %transientStartingYr=10000. HOWEVER, AFTER saving the 
                    %model the md.timestepping.start_time=10000. It is
                    %because of the two lines below that do the assignment.
                    %The file containing the model will TransientRun11 (one
                    %number above)
                    %NOTE 2: file named as Transient3 shows start time 3000 and
                    %final time of 4000; however it has not run for 3000 to
                    %4000. instead it has run for 2000 to 3000; and it is
                    %ready to run from 3000 to 4000. 
                    self.md.timestepping.start_time=self.md.timestepping.final_time;
                    self.md.timestepping.final_time=self.md.timestepping.start_time+timeSpan;
                end  %sub_time loop
                
                %we finished one time period; it is time to rebuild the
                %mesh, becuase the accumulation rate is now changing:
                self.md=self.md.collapse();
                self.md=self.md.extrudeModel(2);

                if self.DrawMesh
                    figName=[int2str(idx) '-' int2str(idx) '-'  matmulti_Ice.convertIceCode2Name(self.toolbox.smbIceTypeVector(idx))];
                    title1 = ['Year: ' int2str(self.toolbox.finalTimeVector(idx))  ' - ' matmulti_Ice.convertIceCode2Name(self.toolbox.smbIceTypeVector(idx))];
                    plottingTools.plotSaveMeshPlot(self.md,self.toolbox.runsPath,'Mesh ' , title1, figName );
                end
                
                %here all the execution files are being removed.
                location=self.md.cluster.executionpath;
                listing = dir(location);
                for idx11=1: length(listing)
                    if contains(listing(idx11).name, self.toolbox.name)%'MARS'
                         rmdir([self.md.cluster.executionpath '/' listing(idx11).name],'s');
                    end
                end
                %when we are saving, final_time, the title, filename and finalTimevector are the
                %same;idx is one step higher
                if self.useSMB_to_CallSolver
                    self.md.timestepping.final_time=self.md.timestepping.start_time+(self.toolbox.finalTimeVector(idx)-startingPoint);
                end
                self.toolbox.logTime('', idx);

                try
                    % we are only needing and keeping the last output
                    M=unique(vertcat(self.md.uniqueTransientSolutions.unitID));
                    uniqueList2=[];    uniqueList1=[];      uniqueList=[];
                    for ii=1:length(M)
                        uniqueList1=self.md.uniqueTransientSolutions([self.md.uniqueTransientSolutions.unitID]==M(ii));
                        s=uniqueList1.SmbMassBalance;
                        for i=2:length(uniqueList1)
                            s=s+(uniqueList1(i).SmbMassBalance);
                        end
                        totalSMB=0;
                        for i=1:length(uniqueList1) 
                            totalSMB=totalSMB+sum(uniqueList1(i).TotalSmb);
                        end
                    
                        step=idx-1;
                        uniqueList2=uniqueList1(end);
                        uniqueList2.step=step;
                        uniqueList2.TotalSmb=totalSMB;
                        uniqueList2.SmbMassBalance=s;
                    
                        uniqueList=[uniqueList; uniqueList2];
                    end
                    T = struct2table(uniqueList);
                    sortedT = sortrows(T, 'time');
                    sortedS = table2struct(sortedT) ;
                    
                    self.md.uniqueTransientSolutions=uniqueList;
                    T=[]; sortedT=[]; sortedS=[]; uniqueList=[];uniqueList1=[];uniqueList2=[];
                    self.md.uniqueTransientSolutions=uniqueList;
                catch
                    %if an error happens just continue with what we have
                end

                self.toolbox.saveMe(self.md);%See NOTE1 above.
                self.md.uniqueTransientSolutions=[];         
                self.initInnerLimits = self.md.geometry.thickness>self.thicknessThreshold;

                toc;
            end  %loop1: time loop
        end


%}

    end

    methods (Access=private)
        function [self, loadStep]=loadPrevModel(self, mp)

            % resumeAfterFailure does not work if it is
            % onlyPlotSavedModels. for conitnuing to plot from a specific
            % year use the transientstartingyr parameter
            if self.resumeAfterFailure && self.transientStartingYr==0  
                for iidx=1:length(self.toolbox.finalTimeVector)
                    if exist(['./_' self.outputFolderName '_' int2str(self.toolbox.finalTimeVector(iidx))], 'dir')
                        self.transientStartingYr=self.toolbox.finalTimeVector(iidx);
                        break;
                    end
                end
            end

            %this is to continue a previous run; and a start year has
            %been given, here we try to find the input file and load its
            %model:
            loadStep=find(self.toolbox.finalTimeVector==self.transientStartingYr);
            if (self.transientStartingYr==0 || isempty(loadStep) || loadStep<1), loadStep=1; end
            if loadStep>1 && self.transientStartingYr>0
                [tbox, self.md] = self.toolbox.loadMe(['TransientRuns' int2str(loadStep-1)]);
                fprintf("+ An older model is being loaded: TransientRuns%i with starttime of %i\n\n", loadStep-1, self.md.timestepping.start_time);


                self.md.settings=settingsmulti_Ice();
                self=self.convertMP2Self(mp);

                self.md.timestepping.final_time=self.md.timestepping.start_time;
                f=self.toolbox.finalTimeVector;
                f2=self.toolbox.surfaceTempVector;
                self.toolbox=tbox.self;
                self.toolbox.finalTimeVector=f;
                self.toolbox.surfaceTempVector=f2;
                self.md.materials.useSMB=self.useSMB2EndOfYear>0 && self.useSMB2EndOfYear>=self.toolbox.finalTimeVector(loadStep);
                loadStep=loadStep+1;
                self.md.materials=self.md.materials.makePropertyTables();
                self.md.materials=self.md.materials.setIceProperties(self.md);
                if loadStep>length(self.toolbox.finalTimeVector), loadStep=length(self.toolbox.finalTimeVector); end
                self.initializeModel=false;
            end
            %in some cases, when we load, we can an empty object for this; here if there is an empty object, I am setting it to the clasself.
            try self.md.stochasticforcing=stochasticforcing(); catch, end
            try self.md.debris=debris(); catch, end
                % for  backward compatibility
            if isempty(self.md.materials.propTable_H2O), self.md.materials=self.md.materials.makePropertyTables(); end
            self=convertMP2Self(self, mp);

%            self.md = setflowequation(self.md,self.SolverEngine,'all');
        end

        function [self, model]=Parameterization (self,model)
            % Parameters
            %config settings that have to be set before running thev transient
            model.stressbalance.restol =self.md.settings.stressbalance_restol;% 2e-4; %default is 1e-4; error mgmt
            model= setmask(model,'',''); % all ice is grounded
            % Defining friction parameters
            c=self.md.settings.frictionCoeff;
            model.friction.coefficient = c*ones(model.mesh.numberofvertices,1);   

            pos = model.mask.ocean_levelset<0; % all logical 0s, ice is all grounded
             
            model.friction.coefficient(pos) = 0; % no changes, in theory...
            model.friction.p = ones(model.mesh.numberofelements,1);
            model.friction.q = ones(model.mesh.numberofelements,1);
            % Init
            model.initialization.vx  = zeros(model.mesh.numberofvertices,1);
            model.initialization.vy  = zeros(model.mesh.numberofvertices,1);
            model.initialization.vz  = zeros(model.mesh.numberofvertices,1);
            model.initialization.vel = zeros(model.mesh.numberofvertices,1);
            % Basal forcings
            model.basalforcings.groundedice_melting_rate = zeros(model.mesh.numberofvertices,1);
            model.basalforcings.floatingice_melting_rate = zeros(model.mesh.numberofvertices,1);
            % Moving front
            model.levelset.spclevelset = NaN*ones(model.mesh.numberofvertices,1);
            % Inversion
            model.inversion.iscontrol = 0;
            % Some extra initial conditions
            
            model.stressbalance.referential = NaN*ones(model.mesh.numberofvertices,6);
            model.stressbalance.loadingforce = zeros(model.mesh.numberofvertices, 3);
            model.stressbalance.abstol = NaN;

            model.toolkits.DefaultAnalysis = bcgslbjacobioptions();

%Debug            model.transient.issmb = 0;
            model.transient.ismasstransport = 1;
            model.transient.isstressbalance = 1;
            model.transient.isthermal = 1;
            model.transient.isgroundingline = 0;
            model.transient.isesa = 0;
            model.transient.isdamageevolution = 0;
            model.transient.ismovingfront = 0;
            model.transient.ishydrology = 0;
            model.transient.isoceancoupling = 0;
            model.transient.amr_frequency = 0;
            model.transient.requested_outputs = {'default','IceVolume','TotalSmb','SmbMassBalance', 'BasalStress'};
            model.stressbalance.maxiter = 100;

            model.settings.output_frequency =  self.outputFreq;
            model.stressbalance.maxiter = 100;

            %Boundary conditions: temperature is fixed at the surface
            self.md.thermal.spctemperature = NaN*ones(self.md.mesh.numberofvertices,1);

            self.md.materials.alwaysRecalculatePressureDuringExtrusion = true;
            self.md.basalforcings.geothermalflux = self.geoFlux*ones(self.md.mesh.numberofvertices,1);
            pos=find(self.md.mesh.vertexonboundary);
            nanValues=NaN*ones(self.md.mesh.numberofvertices,1);
            % self.md.thermal.spctemperature = nanValues;
            % self.md.thermal.spctemperature(pos) = self.toolbox.surfaceTempVector(idx);
            self.md.masstransport.spcthickness=nanValues;
            %         self.md.masstransport.spcthickness(pos)=1;
            self.md.stressbalance.spcvx=nanValues;
            self.md.stressbalance.spcvy=nanValues;
            self.md.stressbalance.spcvz=nanValues;
            self.md.stressbalance.spcvx(pos)=0;
            self.md.stressbalance.spcvy(pos)=0;
            self.md.stressbalance.spcvz(pos)=0;

            self.md.friction.coefficient = 500*ones(self.md.mesh.numberofvertices,1);

            self.toolbox.logTime('> Setting up the model: %s\n\n', -1);
           
        end
    
        function domainArea=getDomainArea(self)

            text=readlines([ self.toolbox.inputsPath '/' self.toolbox.maindomainFile]);
            boundaries=text(6:end);
            ii=0;
            for i=1:length(boundaries)
                ii=ii+1;
                if boundaries(ii)==""
                     boundaries(ii)=[];
                     ii=ii-1;
                end
            end
            boundaries_xy=split(boundaries," ");
            x=str2double(boundaries_xy(:,1));
            y=str2double(boundaries_xy(:,2));
            domainArea=polyarea(x,y);
        end

        function self=convertMP2Self(self, mp)

            props=properties(mp);
            for i=1: length(props)
                try 
                    self.(string(props(i)))=mp.(string(props(i))); 
                catch  
                    if ~strcmp('cluster', string(props(i)))
                        fprintf('Property %s was not set \n', string(props(i)));
                    end
                end
            end

            if isempty(mp.outputFolderName)
                self.outputFolderName=mp.inputsFolderName;
            else
                self.outputFolderName=mp.outputFolderName;
            end

            self.md.cluster=mp.cluster;

            try
                self.md.settings.thickness_firstIceUnit_threshold=self.thickness_firstIceUnit_threshold;
                self.md.settings.thickness_minThreshld=self.thickness_minThreshld;
                self.md.settings.output_frequency   =self.outputFreq;
            catch 
            end

            try
                self.toolbox=self.toolbox.setInitialParams(self, mp.cluster);
            catch ME
             %  disp(ME)
            end

        end
    
    end

end
