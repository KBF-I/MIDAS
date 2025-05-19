%Kasra
% #define _IS_MULTI_ICE_

%{
IMPORTANT NOTES
Nested Domains. If there are two domains, go to the section 
multiple domain below. there 2 steps: the name of the second
(nested domain) need to be hardcoded in the ContourToNodes function as
identified in this code. Also use the appropriate initialresolution value
or if the initialresolution is way larger than one of the domains, the mesh
might get capped (for instance if the initial resolution is 10000, the mesh
resolution won't go below 1000 m, even it if it is specified as 100 m or 10
me, etc.



%}


classdef tools

    properties (SetAccess=private, GetAccess=private)
        thicknessesList;
    end
    properties (SetAccess=private)
       %setup_env
        parametersFile;
        coordinatesFile; %the file with the coordinates, base and thickness values...
        thicknessFiles;
        unitStructureFromInputFile=[]; %just by scanning the input file, what is estimated number of physical layers in the cap
        iceUnitsStructure=[];

    end
    properties (Access=public)
        mainDomainMinResolution;  mainDomainMaxResolution;
        useMatlabMeshFunc=false;
        convertLatLon2UTM=false;  diffCoord4Thicknesses;
        saveDebugsFolder;         timeStep;   maindomainFile;  nested_domainfile; nestedDomainRes;
        finalTimeVector;          saveModelsFolder;  
        outputsPath;inputsPath;   xlsxInput;
        volumeLogPath;deltaVolumeLogPath;thickThresholdLogPath;
        modelFilename;modelInput; name; rightX; leftX; upY; downY; startTimeVector;
        planetCode; runsPath;simulationsPath;elapsedTimePath;debugging;simulationID;

        Array4Plotting=[];
        solutions=[]; %this holds the entire set of transient solutions created by the last function.
        MassVolInfoLst = [];

        %threshold=1;                                
        geoFlux=0;
        smbIceTypeVector=0;                           surfaceTempVector=0;
        previousModelFilename;                        org;                                      
        IceUnitsCntinBase=1;                          err = 0.01;
        gradation = 1;                                tStart=uint64(0.0);
        numbLayers=0;                                 outputRunFolder;
        cluster;                                      filename;
      
        iceAccumulationStartingRow;
    end
   
    methods

        function self=setInitialParams(self, stratifiedModel, cluster)
            inputFileName               = stratifiedModel.inputFileName;
            self.outputRunFolder        = stratifiedModel.outputFolderName ;
            inputFolderName             = stratifiedModel.inputsFolderName ;
                        
            self.parametersFile         = inputFileName;
            %parameters
            self.inputsPath             = ['./Inputs/' inputFolderName '/'];
            self.outputsPath            = './Outputs/';
            self.runsPath               = [self.outputsPath  ''];  %T from 'Run/' to ''
            self.simulationsPath        = [self.outputsPath self.outputRunFolder '/Simulations.txt'];
            self.simulationID           = [self.outputsPath self.outputRunFolder '/ActiveID.txt'];
            self.saveDebugsFolder       = [self.runsPath    self.outputRunFolder '/Debugs/'];
            self.saveModelsFolder       = [self.runsPath    self.outputRunFolder '/Models/'];
            
            self.cluster                = cluster; 
            self.coordinatesFile        = stratifiedModel.coordinateFile;
            self.maindomainFile         = stratifiedModel.mainDomainFile;
            self.nested_domainfile      = stratifiedModel.nestedDomainFile;
            self.mainDomainMinResolution= stratifiedModel.mainDomainMinRes;
            self.mainDomainMaxResolution= stratifiedModel.mainDomainMaxRes;
            self.nestedDomainRes        = stratifiedModel.nestedDomainRes;
            self.convertLatLon2UTM      = stratifiedModel.convertLatLon2UTM;
            self.useMatlabMeshFunc      = stratifiedModel.useMatlabMeshFunc;
            self.diffCoord4Thicknesses  = stratifiedModel.diffCoord4Thicknesses;

            self.planetCode             = stratifiedModel.planetName;
            self.numbLayers             = stratifiedModel.numb_MeshVirtualLayers;
            self.name                   = char(upper(planetProperties.PLANETS_Code2Text(self.planetCode,2))+ '.');

        end

        function self=tools(stratifiedModel, cluster)           
            if isempty(stratifiedModel.inputFileName) && isempty(stratifiedModel.outputFolderName) && isempty(stratifiedModel.inputsFolderName)
                return;
            end
            warning('off','all');

            self=setInitialParams(self, stratifiedModel, cluster);

            %folders management
            mkdir([self.runsPath self.outputRunFolder]);
            try mkdir([self.runsPath self.outputRunFolder '/Figs/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/Vel/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/Thickness/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/Temperature/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/Surface/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/quiver/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Figs/streamline/'  ]);catch, end

            try mkdir([self.runsPath self.outputRunFolder '/Models/']);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/' ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/Vel/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/Thickness/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/Temperature/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/Surface/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/quiver/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Plots/streamline/'  ]);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Inputs/']);catch, end
            try mkdir([self.runsPath self.outputRunFolder '/Debugs/']);catch, end

            %files management
            self.xlsxInput=[self.inputsPath self.parametersFile ];
            if ~exist(self.xlsxInput,'file')
                fprintf('\nThese are all the .xlsx spreadsheet input files found in ./Inputs folder:\n');
                dir([self.inputsPath '/*.xlsx']);
                error ('The input file does not exist - select a file from the list above!!');
            end

            self=readParamsFromExcel(self);

        end

        function readCoordinatesFromExcel(self,md, inversionAmnt, initialResolution, fullThicknessesListFileName, shiftBaseUp)

            fprintf('\n++Retrieving information from input file...** %s ** \n\n', [self.inputsPath self.parametersFile]);
            fullCoordinates=readmatrix([self.inputsPath self.coordinatesFile]);
            mythickness=[];

            xb = fullCoordinates(:,1); 
            yb = fullCoordinates(:,2);  

            if self.convertLatLon2UTM
                if self.planetCode==planetProperties.MARS
                    xb=59274.69752.*xb;
                    yb=59274.69752.*yb;
                elseif self.planetCode==planetProperties.PLUTO
                    xb=20088.739690454734 .*xb;  
                    yb=20088.739690454734 .*yb; 
                end
            end

            format longG;  Dataset_Full_Domain_Boundaries=[max(xb),max(yb);max(xb),min(yb);min(xb),min(yb);min(xb),max(yb);max(xb),max(yb)]
       %     md= triangle(md, [self.inputsPath self.maindomainFile],initialResolution); %use this if you don't need adaptive mesh
             md=bamg(md,'domain',[self.inputsPath self.maindomainFile],'hmax',initialResolution);  

            coordCount=length(xb);
            if ~self.useMatlabMeshFunc
                indexb=delaunay(xb,yb);
            end
            %this shows the area of all triangles in a mesh, and then removes those with certain areas            
            %M=[];for i=1:size(indexb,1), M=[M;(xb(indexb(i,1))*(yb(indexb(i,2))-yb(indexb(i,3)))+xb(indexb(i,2))*(yb(indexb(i,3))-yb(indexb(i,1)))+xb(indexb(i,3))*(yb(indexb(i,1))-yb(indexb(i,2))))/2];  end
            %indexb(M<1e7,:)=[];
            if inversionAmnt>0, base = inversionAmnt - fullCoordinates(:,3); else, base = fullCoordinates(:,3); end
            if shiftBaseUp~=0,  base = shiftBaseUp + base; end   

            for iidx=1:length(self.thicknessesList)  
                fprintf('Getting files: %s ; file# %i from a list of %i files\n', self.thicknessesList(iidx),iidx, length(self.thicknessesList));
                thicknesses=readmatrix(self.xlsxInput, 'Sheet',  self.thicknessesList(iidx));
                iceTypestr=split(self.thicknessesList(iidx),"_");
                first=1;
                for idx=1:length(self.finalTimeVector)   
                    fprintf('Getting thicknesses:# %i out of %i\n ', idx, length(self.finalTimeVector));
                    i=thicknesses(1,:)==self.finalTimeVector(idx);
                    thickness=rmmissing(thicknesses(2:end, i));

                    if self.diffCoord4Thicknesses
                        xt=thicknesses(2:end,1);
                        yt=thicknesses(2:end,2);
                        coordCount=length(xt);
                    end

                    %IMPORTANT: we can have values + NaN but we cannot
                    %have values + NaN + Values...NaN must be the last
                    %in the list
                    if isempty(thickness)
                        first=first+1;
                        continue
                    elseif length(thickness)<coordCount
                        thickness=[thickness; ones(coordCount-length(thickness),1)*thickness(end)]; %#ok<*AGROW>
                    end

                    if idx==first && iidx==1
                        if ~self.diffCoord4Thicknesses
                            surface = thickness + base;
                            %ISSM mesh
                            if ~self.useMatlabMeshFunc
                                surfaceObs = InterpFromMeshToMesh2d(indexb,xb,yb,surface,md.mesh.x,md.mesh.y); %*Mesh*
                            else
                                %%*Mesh*if the ISSM mesh function above does not work, we can use this. and then check and remove anything that is NaN. If using this line, delauney above is not required
                                surfaceObs=griddata(xb,yb,surface,md.mesh.x,md.mesh.y, "nearest"); 
                                surfaceObs(isnan(surfaceObs))=0;                                
                                                               
                            end                   
                        else
                            if ~self.useMatlabMeshFunc
                                indext=delaunay(xt,yt); 
                                thicknessobs= InterpFromMeshToMesh2d(indext,xt,yt,thickness,md.mesh.x,md.mesh.y);
                                baseObs = InterpFromMeshToMesh2d(indexb,xb,yb,base,md.mesh.x,md.mesh.y);
                                surfaceObs=baseObs+thicknessobs;
                            else

                             %   xmin = min(xt);
                              %  xmax = max(xt);
                               % ymin = min(yt);
                                %ymax = max(yt);
                              %  outOfBoundIdx = (xb < xmin | xb > xmax | yb < ymin | yb > ymax);
                               %  
                                %xb_out = xb(outOfBoundIdx);
                                %yb_out = yb(outOfBoundIdx);
                                 
                            %    newPoints = [xb_out, yb_out, zeros(length(xb_out), 1)];  % New coordinates with thickness = 0
                         %       thickness = [thickness; newPoints(:,3)];  % Append new points to original array
                          %      xt=[xt ;xb_out];
                           %     yt=[yt ;yb_out];


                                thicknessobs=griddata(xt,yt,thickness,md.mesh.x,md.mesh.y, "nearest");
                                thicknessobs(isnan(thicknessobs))=0;
                        

                               % currentDayThickness=readmatrix('/home/developer/Documents/ISSM/MATLABCodes/MIDAS/Inputs/MCID-MultiLayeredv5/base_v5_fixed_bis.csv');
                           
                               baseObs = griddata(xb,yb,base,md.mesh.x,md.mesh.y, 'nearest');
                               
                                
                               
                            surfaceObs=baseObs+thicknessobs;
                            end
                        end

                        %nested domain  
                        if isempty(self.nested_domainfile)
                            md= bamg(md,'field',surfaceObs,'err',self.err,'gradation',self.gradation,'hmin',self.mainDomainMinResolution,'hmax',self.mainDomainMaxResolution);
                        else
                           h=NaN*ones(md.mesh.numberofvertices,1);
                            

                          domainFile2=self.nested_domainfile;

                             in1=ContourToNodes(md.mesh.x,md.mesh.y,[self.inputsPath domainFile2],1);
                             h(find(in1))=self.nestedDomainRes;    %the required resolution for the second domain
 
                             %$$  Middle Domains+
                          % in1=ContourToNodes(md.mesh.x,md.mesh.y,[self.inputsPath 'Lobate.exp'],2);   
                          % h(find(in1))=500;    %500
                          % in1=ContourToNodes(md.mesh.x,md.mesh.y,[self.inputsPath 'Sakarya.exp'],2);  
                          % h(find(in1))=500;    %500
                          % in1=ContourToNodes(md.mesh.x,md.mesh.y,[self.inputsPath 'GedizVallis.exp'],2);  
                          % h(find(in1))=200;    %200
                          % in1=ContourToNodes(md.mesh.x,md.mesh.y,[self.inputsPath 'Curiosity.exp'],2);  
                          % h(find(in1))=35;    %35
                             
                             %$$  Middle Domains- 
 
   

                            md=bamg(md,'field',surfaceObs,'err',0.02,'hmin',self.mainDomainMinResolution,'hmax',self.mainDomainMaxResolution, 'hVertices',h);
                        end

                        %final cleaning the mesh coordinates
                        if ~self.diffCoord4Thicknesses
                            if ~self.useMatlabMeshFunc
                                surfaceObs = InterpFromMeshToMesh2d(indexb,xb,yb,surface,md.mesh.x,md.mesh.y);%*Mesh*
                            else
                                %%*Mesh*if above was decided not to use the ISSM meshing function, then we should use matlab functions everywhere:
                                surfaceObs=griddata(xb,yb,surface,md.mesh.x,md.mesh.y, "nearest");

                            end
                        else
                            if ~self.useMatlabMeshFunc
                                thicknessobs= InterpFromMeshToMesh2d(indext,xt,yt,thickness,md.mesh.x,md.mesh.y);
                                baseObs = InterpFromMeshToMesh2d(indexb,xb,yb,base,md.mesh.x,md.mesh.y);
                            else
                                thicknessobs=griddata(xt,yt,thickness,md.mesh.x,md.mesh.y, "nearest");
                                thicknessobs(isnan(thicknessobs))=0;
                                baseObs =    griddata(xb,yb,base,md.mesh.x,md.mesh.y , "nearest");                                
                            end
                            surfaceObs=baseObs+thicknessobs;
                        end
                        surfaceObs(isnan(surfaceObs))=0;                      
                    end  %idx==first

                    uThickness=unique(thickness);
                    if length(uThickness)>2
                        if ~self.diffCoord4Thicknesses
                            if ~self.useMatlabMeshFunc
                                thicknessObs = InterpFromMeshToMesh2d(indexb,xb,yb,thickness,md.mesh.x,md.mesh.y);%*Mesh*
                            else
                                thicknessObs=griddata(xb,yb,thickness,md.mesh.x,md.mesh.y, "nearest"); 
                            end
                        else
                            if ~self.useMatlabMeshFunc
                                thicknessObs = InterpFromMeshToMesh2d(indext,xt,yt,thickness,md.mesh.x,md.mesh.y);%*Mesh*
                            else
                                thicknessObs=griddata(xt,yt,thickness,md.mesh.x,md.mesh.y, "nearest");%*Mesh*
                            end
                        end
                    else
                        thicknessObs=uThickness(1)*ones(length(surfaceObs),1);
                    end

                    if idx==first && iidx==1
                        thicknessObs(thicknessObs<md.settings.thickness_firstIceUnit_threshold)=md.settings.thickness_firstIceUnit_threshold;
                        modelBed=surfaceObs-thicknessObs;  
                        md.geometry.thickness=thicknessObs;
                        md.geometry.surface=surfaceObs;
                        md.geometry.bed=modelBed;
                        md.geometry.base=modelBed;
                        first=-1;
                    end
                    tempThickness=[self.finalTimeVector(idx); self.str2iceTypeCode(iceTypestr(1)); thicknessObs];
                    mythickness=[mythickness, tempThickness];
                end
            end
            inputsPath1 =self.inputsPath ;
            Resolution=self.mainDomainMinResolution;

            [totalModelHeightFromInputFile, iceUnitsFromInputFile]= self.analyzeUnitsB4Deposition(mythickness);

            clear self thicknesses thickness thicknessObs fullCoordinates base coordCount i iceTypestr  idx iidx indexb ...
                initialResolution inversed m surface sb yb xb  surfaceObs tempThickness first
            save ([inputsPath1 fullThicknessesListFileName]);
        end

        function self=readParamsFromExcel(self)
            VariableCol = 3;
            %Variables
%             planetRow      = 7;        numbLayersRow     = 9;
            leftXRow       = 3;        rightXRow         = 4;
            downYRow       = 5;        upYRow            = 6;   
            unitsStructureRow=8;      

            self.iceAccumulationStartingRow=19;    %the line in the excel file (parameters) where the years start

            %SMB Stuff
            finalTimeVectorCo   = 1;
            surfaceTempVectorCo = 2;
            smbIceTypeVectorCo  = 3; 
            xlsxFile=readtable(self.xlsxInput, 'Sheet', 'MainParams');

            % Get the planet
%            planetTextName = cell2mat(xlsxFile{planetRow,VariableCol});
%            self.name = [ upper(planetTextName) '.'];
%             self.planetCode =...
%                  str2int(planetProperties.PLANETS_Code2Text( find (strcmpi(planetProperties.PLANETS_Code2Text(1:size(planetProperties.PLANETS_Code2Text,1),2), planetTextName))));

            %Get the units structure
            self.iceUnitsStructure=strip(split(cell2mat(xlsxFile{unitsStructureRow,VariableCol}), ','));

            % Get 'Left X limit'
            self.leftX = str2double(cell2mat(xlsxFile{leftXRow,VariableCol}));
            % Get 'Right X limit'
            self.rightX = str2double(cell2mat(xlsxFile{rightXRow,VariableCol}));
            % Get 'Down Y limit'
            self.downY = str2double(cell2mat(xlsxFile{downYRow,VariableCol}));
            % Get 'Up Y limit'
            self.upY = str2double(cell2mat(xlsxFile{upYRow,VariableCol}));
            % Check & correct limits
            if (self.leftX>self.rightX)
                fprintf('\n');
                warning('Limits were inputted incorrectly. They are inverted.');
                fprintf(['\nSetting limits correctly: left limit %d inputted will be right, and right limit %d '....
                    'will be left.'],self.leftX,self.rightX);
                tmp = self.rightX;
                self.rightX = self.leftX;
                self.leftX = tmp;
                fprintf('\nLimits are now:\nLeft X limit: %d\nRight X limit: %d\n',self.leftX,self.rightX);
            end
            if (self.downY>self.upY)
                fprintf('\n');
                warning('Limits were inputted incorrectly. They are inverted.');
                fprintf(['\nSetting limits correctly: down limit %d inputted will be up, and up limit %d '....
                    'will be down.'],self.downY,self.upY);
                tmp = self.upY;
                self.upY = self.downY;
                self.downY = tmp;
                fprintf('\nLimits are now:\nDown Y limit: %d\nUp Y limit: %d\n',self.downY,self.upY);
            end

%             self.numbLayers = str2int(cell2mat(xlsxFile{numbLayersRow,VariableCol}));

            % Get the vectors
            self.finalTimeVector   = zeros(height(xlsxFile)-self.iceAccumulationStartingRow+1, 1);
            self.surfaceTempVector = zeros(height(xlsxFile)-self.iceAccumulationStartingRow+1, 1);
            smbIceTypeVector1      = string.empty(height(xlsxFile)-self.iceAccumulationStartingRow+1,0);
            for ii1=self.iceAccumulationStartingRow:height(xlsxFile)
                ii2=ii1-self.iceAccumulationStartingRow+1; %write into this row
                try
                    self.finalTimeVector  (ii2) = (xlsxFile{ii1, finalTimeVectorCo  });
                catch
                    self.finalTimeVector  (ii2) = str2double(xlsxFile{ii1, finalTimeVectorCo  });
                end
                self.surfaceTempVector(ii2) = (xlsxFile{ii1, surfaceTempVectorCo});
                smbIceTypeVector1     (ii2) = (xlsxFile{ii1, smbIceTypeVectorCo });
            end
            smbIceTypeVector1 = smbIceTypeVector1' ;
            self = self.ConvertsmbIceTypeVector (smbIceTypeVector1);
            self.modelFilename = self.outputRunFolder;

            % Create simulation's directories
            copyfile( [self.inputsPath '/*.*'],[self.runsPath self.outputRunFolder '/Inputs']);

            mkdir([self.runsPath self.outputRunFolder '/TimeLog/']);
            self.elapsedTimePath = [self.runsPath self.outputRunFolder '/TimeLog/' './' self.modelFilename '_timeLog.txt'];
            timelogTextFile = fopen(self.elapsedTimePath,'w+');
            fclose(timelogTextFile);
            mkdir([self.runsPath self.outputRunFolder '/IceLog/']);
            self.volumeLogPath = [self.runsPath self.outputRunFolder '/IceLog/' './' self.modelFilename '_volumeAndMassLog.txt'];
            self.deltaVolumeLogPath = [self.runsPath self.outputRunFolder '/IceLog/' './' self.modelFilename '_deltaVolumeAndMassLog.txt'];
            self.thickThresholdLogPath = [self.runsPath self.outputRunFolder '/IceLog/' './' self.modelFilename '_thicknessThresholdLog.txt'];

            self.thicknessesList = unique(self.iceUnitsStructure)+"_thicknesses";

            self.org = organizer('repository',['./Outputs/' self.outputRunFolder '/Models/'],'prefix',self.name,'steps',1:6);   

            fprintf('The environment was successfully setup.\n')

            self.logTime('> Variables were read: %s\n\n', -1);
        end

        function code=str2iceTypeCode(~, iceType)
            code=[];
            for i=1:length(iceType)
                if strcmp(iceType(i),"H2O"),           code=[code, mat_consts.H2O];
                elseif (strcmp(iceType(i),"CO2")),     code=[code, mat_consts.CO2];
                elseif (strcmp(iceType(i),"CO")),      code=[code, mat_consts.CO];
                elseif (strcmp(iceType(i),"N2")),      code=[code, mat_consts.N2];
                elseif (strcmp(iceType(i),"CH4")),     code=[code, mat_consts.CH4];
                elseif (strcmp(iceType(i),"H2O_DUST")),code=[code, mat_consts.H2O_DUST];
                elseif (strcmp(iceType(i),"ROCK")),    code=[code, mat_consts.ROCK];
                elseif (strcmp(iceType(i),"MAT1")),    code=[code, mat_consts.MAT1];
                elseif (strcmp(iceType(i),"MAT2")),    code=[code, mat_consts.MAT2];
                elseif (strcmp(iceType(i),"MAT3")),    code=[code, mat_consts.MAT3];
                else, error('iceType not supported')
                end
            end
        end

        function self=ConvertsmbIceTypeVector(self, smbIceTypeVector1)
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"H2O"))=mat_consts.H2O;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"CO2"))=mat_consts.CO2;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"CO"))=mat_consts.CO;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"N2"))=mat_consts.N2;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"CH4"))=mat_consts.CH4;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"H2O_DUST"))=mat_consts.H2O_DUST;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"ROCK"))=mat_consts.ROCK;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"MAT1"))=mat_consts.MAT1;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"MAT2"))=mat_consts.MAT2;
            self.smbIceTypeVector(strcmp(smbIceTypeVector1,"MAT3"))=mat_consts.MAT3;
        end

        function [md, toolbox]=solveModel(toolbox,md, iceType, saveModelTitle, verboseFlag, debugMode, modelType,...
                normalRsdlThrshld, icreasedRsdlThrshld, capsLimitFactor, capsOnlyBoundaries, solverEngine, nestedSolverEngine)      
            if debugMode, toolbox.debug([saveModelTitle 'b4' ], md); end


            md.verbose = verbose('solver', verboseFlag,'qmu',verboseFlag,'solution',verboseFlag, 'control', verboseFlag);
           
            try  %try1: first attempt, threshold 10e-5; entered timestep
                md.settings.solver_residue_threshold=normalRsdlThrshld;
                if strcmpi(modelType, 'Transient')
                    fprintf("   - * FIRST ATTEMPT: Setting the min time step to %i and the residue threshold to %i Period Ending in %i\n\n",  md.timestepping.time_step_min, normalRsdlThrshld, md.timestepping.final_time);
                end
                if nestedSolverEngine
                    md=setflowequation(md, solverEngine, [toolbox.inputsPath toolbox.nested_domainfile],'fill','SSA');  
                else
                    md = setflowequation(md,solverEngine,'all');
                end
                md= solve(md,modelType);
  %md=loadresultsfromcluster(md,'runtimename','PLUTO.-11-04-2023-23-29-35-34029');
                %to check that the solve was successful
                if strcmpi(modelType, 'Transient')
                    if md.results.TransientSolution(end).time~=md.timestepping.final_time
                        throw("output from the backend seems to have missing components.")
                    end
                end
            catch Me %catch1
                disp(Me);
                try %try2: second attempt, threshold icreasedRsdlThrshld; entered timestep
                    md.settings.solver_residue_threshold=icreasedRsdlThrshld;  %increase to be prepared if this going to fail
                    fprintf("   - ** SECOND ATTEMPT: Setting the min time step to %i and the residue threshold to %i. Period ending in %i.\n",  md.timestepping.time_step_min,icreasedRsdlThrshld, md.timestepping.final_time);
                    md= solve(md,modelType);
                    %to check that the solve was successful
                    if strcmpi(modelType, 'Transient')
                        if md.results.TransientSolution(end).time~=md.timestepping.final_time
                            throw("output from the backend seems to have missing components.")
                        end
                    end
                catch %catch2: third attempt, threshold: icreasedRsdlThrshld; min timestep: 0.00001
                    %try to recover by using the auxiliary extrude function
                    try %try 3
                        md.settings.solver_residue_threshold=icreasedRsdlThrshld;  %increase to be prepared if this going to fail
                        minTime=md.timestepping.time_step_min;
                        md.timestepping.time_step_min=0.00001;     %reduce the timestep
               
                        toolbox.debug(['capture_ResultsError_3_' int2str(md.timestepping.start_time)], md);   %just capture what this is; if this fails again, we can see what it was.
                        fprintf("   - *** THIRD ATTEMPT: Setting the min time step to %i and the residue threshold to %i. Period ending in %i. \n",  md.timestepping.time_step_min, icreasedRsdlThrshld, md.timestepping.final_time);
                        md=solve(md,modelType);
                        %to check that the solve was successful
                        if strcmpi(modelType, 'Transient')
                            if md.results.TransientSolution(end).time~=md.timestepping.final_time
                                throw("output from the backend seems to have missing components.")
                            end
                        end
                        md.timestepping.time_step_min=minTime;
                    catch %catch 3: Fourth attemtp, the same as above with threshold of 0.001
                        md.settings.solver_residue_threshold=0.9;  %increase to be prepared if this going to fail
                        minTime=md.timestepping.time_step_min;
                        md.timestepping.time_step_min=0.000001;     %reduce the timestep
                        toolbox.debug(['capture_ResultsError_4_' int2str(md.timestepping.start_time)], md);   %just capture what this is; if this fails again, we can see what it was.
                        fprintf("   - **** Fourth ATTEMPT: Setting the min time step to %i and the residue threshold to %i. Period ending in %i. \n",  md.timestepping.time_step_min, 0.9, md.timestepping.final_time);
                                md=md.collapse();                          %use the auxiliary extrude
                        md=md.extrudeModel(1);
                        md=solve(md,modelType);
                        %to check that the solve was successful
                        if strcmpi(modelType, 'Transient')
                            if md.results.TransientSolution(end).time~=md.timestepping.final_time
                                throw("output from the backend seems to have missing components.")
                            end
                        end
                        md.timestepping.time_step_min=minTime;
                    end %try 3
                end %try2
            end %try1


            if strcmpi(modelType, 'Transient')
                if md.results.TransientSolution(end).time~=md.timestepping.final_time
                    throw("output from the backend seems to have missing components.")
                end
            end
            if debugMode , toolbox.debug([saveModelTitle '_After' modelType 'Run' ], md); end
            
            md=md.captureResults(md, iceType, modelType,toolbox.saveDebugsFolder, capsLimitFactor, capsOnlyBoundaries);
            if debugMode , toolbox.debug(['After' modelType 'Capture_Results-Run' saveModelTitle], md); end
        end

        function logStartSimulation(self, StratifiedIceModel, SimID)
            %log what happened...

            simsTextFile = fopen(self.simulationsPath,'a+');
            fprintf(simsTextFile,'============================================================== \n');
            fprintf(simsTextFile,'----------------------S T A R T I N G-------------------------- \n');
            if exist('SimID', 'var')
                Description = input('\nProvide the simulation description. This will be saved in the Simulations.txt file in the output folder:\n ','s');
                fprintf(simsTextFile,'> Simulation Description: %s \n',Description);
                simsIDFile = fopen(self.simulationID,'w');
                fprintf(simsIDFile,'%s',SimID);
                fclose(simsIDFile);
            else
                fprintf(simsTextFile,'> Continuing from the last modelling process: %s \n','none');
                SimID=readlines(self.simulationID);
            end
            fprintf(simsTextFile,' Simulation Unique ID   : %s \n',SimID);

            fprintf(simsTextFile,'> Simulation model: %s -> .xlsx file used: %s\n',self.modelFilename,self.xlsxInput);
            time1 = datetime("now", "Format","default");
            fprintf(simsTextFile,'> Started on date/time: %23s \n',time1);

            fprintf(simsTextFile,' inputFileName   : %s \n',           StratifiedIceModel.inputFileName);
            fprintf(simsTextFile,' outputFolderName: %s \n',           StratifiedIceModel.outputFolderName);
            fprintf(simsTextFile,' inputsFolderName: %s \n',           StratifiedIceModel.inputsFolderName);
            fprintf(simsTextFile,' debugging       : %i \n',           StratifiedIceModel.debugging);
            fprintf(simsTextFile,' verboseFlag     : %i \n',           StratifiedIceModel.verboseFlag);
            fprintf(simsTextFile,' RunSimulation   : %i \n',           StratifiedIceModel.RunSimulation);
            fprintf(simsTextFile,' prepareData     : %i \n',           StratifiedIceModel.prepareData);
            fprintf(simsTextFile,' DrawMesh        : %i \n',           StratifiedIceModel.DrawMesh);
            fprintf(simsTextFile,' useMatlabMeshFunc: %i \n',          StratifiedIceModel.useMatlabMeshFunc);
            fprintf(simsTextFile,' diffCoord4Thicknesses: %i \n',      StratifiedIceModel.diffCoord4Thicknesses);

            fprintf(simsTextFile,' inversionAmnt: %i \n',              StratifiedIceModel.inversionAmnt);
            fprintf(simsTextFile,' shiftBaseUp: %i \n',                StratifiedIceModel.shiftBaseUp);
            fprintf(simsTextFile,' useSMB2EndOfYear: %i \n',           StratifiedIceModel.useSMB2EndOfYear);
            fprintf(simsTextFile,' useSMB_to_CallSolver: %i \n',       StratifiedIceModel.useSMB_to_CallSolver);
            fprintf(simsTextFile,' SMBYrs2CallSolver: %i \n',          StratifiedIceModel.SMBYrs2CallSolver);

            fprintf(simsTextFile,' noSMBYrs2CallSolver: %i \n',        StratifiedIceModel.noSMBYrs2CallSolver);
            fprintf(simsTextFile,' capThicknessLimitFactor: %i \n',    StratifiedIceModel.capThicknessLimitFactor);
            fprintf(simsTextFile,' capThicknessOnlyOnBoundaries: %i\n',StratifiedIceModel.capThicknessOnlyOnBoundaries);

            fprintf(simsTextFile,' callSolverPerPeriod: %i \n',        StratifiedIceModel.callSolverPerPeriod);
            fprintf(simsTextFile,' timeStep         : %i \n',          StratifiedIceModel.minTimeStep);
            fprintf(simsTextFile,' Max timeStep         : %i \n',      StratifiedIceModel.maxTimeStep);
            fprintf(simsTextFile,' outputFreq       : %i \n',          StratifiedIceModel.outputFreq);
            fprintf(simsTextFile,' transientStartingYear: %i \n',      StratifiedIceModel.transientStartingYr);
            fprintf(simsTextFile,' SolverEngine       : %s \n',        StratifiedIceModel.SolverEngine);
            fprintf(simsTextFile,' geoFlux            : %i \n',        StratifiedIceModel.geoFlux);

            fclose(simsTextFile);
        end

        function logEndSimulation(self, error, time)
            %log what happened...

            simsTextFile = fopen(self.simulationsPath,'a+');
            fprintf(simsTextFile,'----------------------E N D I N G-------------------------- \n');
            fprintf(simsTextFile,'> Ended in: %i \n',time);
            time1 = datetime("now", "Format","default");
            fprintf(simsTextFile,'> Ended on date/time: %23s \n',time1);
            if ~strcmpi(error, ' ')
                fprintf(simsTextFile,'> An error happened: %s -> \n',error);
            end
            fprintf(simsTextFile,'============================================================== \n');

            fclose(simsTextFile);
        end

        function logTime(self,text, loggingType    )
            if nargin == 2, loggingType=0;end
            timelogTextFile = fopen(self.elapsedTimePath,'a+');
            if loggingType==-1
                elapsedTime = toc(self.tStart);
                finalElapsedTimeMins = elapsedTime/60;
                finalElapsedTimeHours = elapsedTime/3600;
                finalElapsedTimeDays = elapsedTime/86400;
                fprintf(timelogTextFile,'> Total elapsed time of the simulation: \n\n%.2f seconds\n%.2f minutes\n%.2f hours\n%.2f days\n\n',elapsedTime,finalElapsedTimeMins,finalElapsedTimeHours,finalElapsedTimeDays);
            elseif loggingType>0
                elapsedStepTime = toc;
                finalStepTimeMins = elapsedStepTime/60;
                finalStepTimeHours = elapsedStepTime/3600;
                finalStepTimeDays = elapsedStepTime/86400;
                fprintf(timelogTextFile,'> Elapsed time of step #%d: \n\n%.2f seconds\n%.2f minutes\n%.2f hours\n%.2f days\n\n',loggingType,elapsedStepTime,finalStepTimeMins,finalStepTimeHours,finalStepTimeDays);
            end

            fprintf(timelogTextFile,text,datetime);
            fclose(timelogTextFile);
        end

        function title=saveMe (self,  objToSave)

         try
                 ids = [objToSave.uniqueTransientSolutions.time];
               divisible_by_100_idx = mod(ids, objToSave.settings.output_frequency) == 0;
          rows_to_keep = find(divisible_by_100_idx);
             rows_to_keep_full=[rows_to_keep numel(objToSave.uniqueTransientSolutions)];  rows_to_keep_full=sort(unique(rows_to_keep_full));
              objToSave.uniqueTransientSolutions = objToSave.uniqueTransientSolutions(rows_to_keep_full);
          catch
           end

            savemodel(self.org,objToSave);
            title = [self.saveModelsFolder 'self_'  self.org.prefix self.org.steps(self.org.currentstep).string '.mat'];
            save (title, 'self');
        end

        function [self, md]=loadMe(self,title      )
            md=loadmodel(self.org, title);
            currentOutputModel=self.saveModelsFolder;
            currentCluster=self.cluster;
            self=load([self.saveModelsFolder 'self_' self.org.prefix title '.mat']);

            if ~strcmp(self.self.org.repository, currentOutputModel)
                self.self.org.repository=currentOutputModel;
            end
            md.cluster=currentCluster;
            self.self.cluster=currentCluster;
        end

        function md=debug(self,title, obj          )
%              if ~self.debugging, return; end
            md=obj;
            save ([self.saveDebugsFolder title '_new.mat'],'md');
        end

        %unitHeights: Row1: starting period; Row2: end period; Row3:
        %iceType; Row4: percentage; Row5: mean height
        function [totalHeight,unitHeights]=analyzeUnitsB4Deposition(self,  mythickness)
            timePeriod_iceType=[];  %starting time, end time, iceType
            currentIceType=self.smbIceTypeVector(1);
            startingPoint=self.finalTimeVector(1);
            for idx=2:length(self.smbIceTypeVector)
                if self.smbIceTypeVector(idx)==currentIceType
                    continue
                else
                    timePeriod_iceType=[timePeriod_iceType;startingPoint, self.finalTimeVector(idx-1), currentIceType];
                    currentIceType=self.smbIceTypeVector(idx);
                    startingPoint=self.finalTimeVector(idx);
                end
            end
            if self.smbIceTypeVector(idx)==currentIceType
                timePeriod_iceType=[timePeriod_iceType;startingPoint, self.finalTimeVector(idx), currentIceType];
            end

            unitHeights=[];
            for idx=1:size(timePeriod_iceType, 1)
                temp=mythickness(3:end,mythickness(2,:)==timePeriod_iceType(idx, 3) & mythickness(1,:)>timePeriod_iceType(idx,1) &  mythickness(1,:)<timePeriod_iceType(idx,2));
                unitHeights=[unitHeights, sum(temp,2)];
            end

            unitHeights=[mean(unitHeights(:,:)); unitHeights];
            totalHeight=sum(unitHeights(1,:));
            unitHeights=[timePeriod_iceType';mean(unitHeights(:,:))/totalHeight; unitHeights];

        end

        function self=saveValues4Plotting(self,md, startingpoint, endingpointID)
            %1=time, 2=periodVolume, 3=, 4=currentPeriodMass, 5=AccumulativeMass, 6=periodSMB,
            % 7=accumulativeSMB, 8=periodTotalSMB, 9=accumalativeTotalSMB,10=iceType, 11=unitID
            %  12:vx,13:vy,14vz,15:vel,16Thickness,17Pressure,18velocity2d,19minvx,20minvy,21minvz,22minvel,23minvelocity2d,24minThickness,25minPressure,
            %  26minTemperature, 27maxTemperature

            vx=0;vy=0;vz=0;vel=0;Thickness=0;Pressure=0;velocity2d=0;
            minvx=0;minvy=0;minvz=0;minvel=0;minvelocity2d=0;minThickness=0;minPressure=0;
            minTemperature=planetProperties.minPlanetSurfaceTemperature(self.planetCode);
            Temperature=0;

            for idx=1:length(md.uniqueTransientSolutions)
                vx=max(max(md.uniqueTransientSolutions(idx).Vx),vx);
                vy=max(max(md.uniqueTransientSolutions(idx).Vy),vy);
                vz=max(max(md.uniqueTransientSolutions(idx).Vz),vz);
                velocity2d=max(sqrt(vx^2+vy^2),velocity2d);
                vel=max(max(md.uniqueTransientSolutions(idx).Vel), vel);
                Thickness=max(max(md.uniqueTransientSolutions(idx).Thickness),Thickness);
                Pressure=max(max(md.uniqueTransientSolutions(idx).Pressure), Pressure);
                Temperature=max(max(md.uniqueTransientSolutions(idx).Temperature), Temperature);
                
                minvx=min(min(md.uniqueTransientSolutions(idx).Vx),minvx);
                minvy=min(min(md.uniqueTransientSolutions(idx).Vy),minvy);
                minvz=min(min(md.uniqueTransientSolutions(idx).Vz),minvz);
                minvelocity2d=min(sqrt(vx^2+vy^2), minvelocity2d);
                minvel=min(min(md.uniqueTransientSolutions(idx).Vel), minvel);
                minThickness=min(min(md.uniqueTransientSolutions(idx).Thickness),minThickness);
                minPressure=min(min(md.uniqueTransientSolutions(idx).Pressure), minPressure);
                minTemperature=min(min(md.uniqueTransientSolutions(idx).Temperature), minTemperature);
                
            end

            if startingpoint==0, startingpoint=1;end
            try
                endingpoint=self.finalTimeVector(endingpointID);
            catch
                endingpoint=endingpointID;
            end         
            a=find(self.MassVolInfoLst(:,1)==startingpoint);
            if isempty(a), a=1; end    
            b=find(self.MassVolInfoLst(:,1)==endingpoint);
            myArray=self.MassVolInfoLst(a:b,:);
            time=myArray(end, 1);
            periodVolume=sum(myArray(:,2));
            AccumativeVolume=myArray(end, 3);
            currenPeriodMass=sum(myArray(:,4));
            AccumulativeMass=myArray(end, 5);
            periodSMB=sum(myArray(:,6));
            AccumulativeSMB=myArray(end, 7);
            TotalSMB=sum(myArray(:,8));
            accumalativeTotalSMB=myArray(end, 9);

%             [1: time, 2: periodVolume, 3: AccumativeVolume, 4: currenPeriodMass, 5: AccumulativeMass, 6: periodSMB, 7: AccumulativeSMB, 8: TotalSMB , 9: accumalativeTotalSMB,10: -- , 11 ---
%              12: Max_vx, 13: Max_vy, 14: MAx_vz, 15: Max_vel, 16: Max_Thickness, 17: MAx_Pressure, 18: Max_velocity2d=sqrt(vx^2+vy^2), 19: minvx, 20: minvy, 21: minvz, 22: minvel,23: min_velocity2d,
%              24: minThickness, 25: minPressure, 26: minTemperature, 27: max_Temperature

            self.Array4Plotting=[self.Array4Plotting;time, ...
                periodVolume, AccumativeVolume, currenPeriodMass, AccumulativeMass, ...
                periodSMB, AccumulativeSMB,TotalSMB ,...
                accumalativeTotalSMB,myArray(end, 10),myArray(end, 11),...
                 vx,vy,vz,vel,Thickness,Pressure,velocity2d,minvx,minvy,minvz,minvel,minvelocity2d,minThickness,minPressure, minTemperature, Temperature];
        end

        function self=massVolume_sets(self, md)
            %if md.multiIceMesh.domainArea<0, error('Domain Area has not been set. It is a variable in MultiIceMesh object of the model, and need to be set before massVolume_sets can be created'); end
            tranSolutions=md.uniqueTransientSolutions;
            Period_MassVol_Total=self.MassVolInfoLst;
            previousAccuVol=0;                      previousAccuMass=0;
            previousAccuSMB=0;                      previousAccuTotalSMB=0;

            for idx=1: length(tranSolutions)
                if size(Period_MassVol_Total,1)>1  %accumulative values up to now
                    previousAccuVol=Period_MassVol_Total(end,3);           previousAccuMass=Period_MassVol_Total(end,5);
                    previousAccuSMB=Period_MassVol_Total(end,7);           previousAccuTotalSMB=Period_MassVol_Total(end,9);
                end
                CurrentAccuIceVolume=tranSolutions(idx).IceVolume;         periodVol=CurrentAccuIceVolume-previousAccuVol;
                periodMass=periodVol*md.materials.getSurfaceRhoIce(md);currentAccuMass=periodMass+previousAccuMass;
                periodSMB=md.multiIceMesh.periodSMB;                       currentAccuSMB=periodSMB+previousAccuSMB;
                periodTotalSMB=tranSolutions(idx).TotalSmb;                currentAccuTotalSMB=periodTotalSMB+previousAccuTotalSMB;
                if periodSMB==0 && length(tranSolutions(idx).SmbMassBalance)>1
                    periodSMB=tranSolutions(idx).SmbMassBalance(end);
                end
                if size(Period_MassVol_Total,1)==0
                    Period_MassVol_Total =[Period_MassVol_Total;...
                        tranSolutions(idx).time, periodVol, CurrentAccuIceVolume, periodMass, currentAccuMass, periodSMB, ...
                        currentAccuSMB, periodTotalSMB, currentAccuTotalSMB, tranSolutions(idx).iceType, tranSolutions(idx).unitID];
                elseif Period_MassVol_Total(end,1)~=tranSolutions(idx).time
                    %1=time, 2=periodVolume, 3=AccumativeVolume, 4=currentPeriodMass, 5=AccumulativeMass, 6=periodSMB,
                    % 7=accumulativeSMB, 8=periodTotalSMB, 9=accumalativeTotalSMB,10=iceType, 11=unitID
                    Period_MassVol_Total =[Period_MassVol_Total;...
                        tranSolutions(idx).time, periodVol, CurrentAccuIceVolume, periodMass, currentAccuMass, periodSMB, ...
                        currentAccuSMB, periodTotalSMB, currentAccuTotalSMB, tranSolutions(idx).iceType, tranSolutions(idx).unitID];
                else
                    Period_MassVol_Total(end,6)=periodSMB+Period_MassVol_Total(end,6);
                    Period_MassVol_Total(end,7)=currentAccuSMB;
                    Period_MassVol_Total(end,8)=periodTotalSMB;
                    Period_MassVol_Total(end,9)=currentAccuTotalSMB;
                end
            end
            Period_MassVol_Total=unique(Period_MassVol_Total, "rows");

            self.MassVolInfoLst = Period_MassVol_Total;    %[period,iceVolme change, ice mass change, smb change, accumulative iceVolume, accumulative ice mass , accumulative smb]
        end
     
        %These two functions (createArray4Plotting_MassVolInfoLst_Solutions
        % and plotMe) are to create auxillary tables and plot outside of
        %a model run. To use these first create an instance of tools, %and then call these two
        %functions. PlotMe needs the first one to have been called. 
        function self=createArray4Plotting_MassVolInfoLst_Solutions(self)

            d = dir([['./Outputs/' self.outputRunFolder '/Models/'], '*.mat']);MaxNumber=length(d)-1; %these are the number of mat files, becuase we have files from 0.mat to ... and 0.mat is a thermal file, and we need to ignore, then the count will be minus 1
            %IMPORTANT: NOTE that there should not be any other mat files
            %in the folder or they will be read.
        
            list_Period_MassVol_Total=[];
            Array4Plotting1=[];
            self.solutions=[];
            startPeriod = 0;
            for i=1:MaxNumber
                try
                    fprintf('Reading:  %i from %i files.\n',  i, MaxNumber);
                    perform (self.org, ['TransientRuns' int2str(i)]);
                    [~, md] = self.loadMe(['TransientRuns' int2str(i)]);

                    %md.multiIceMesh.domainArea = domainArea;
                    try
                        solution=md.uniqueTransientSolutions(end);
                    catch
                        md.uniqueTransientSolutions=md.results.TransientSolution; 
                        solution=md.results.TransientSolution(end);
                    end
                    solution.Mesh=md.mesh;
                    solution.MultiIceMesh=md.multiIceMesh;
                    self.solutions=[self.solutions; solution ];
                    if i==1
                        self.MassVolInfoLst=list_Period_MassVol_Total;
                    end
                    self=massVolume_sets (self, md);
                    list_Period_MassVol_Total=self.MassVolInfoLst;
                    self=saveValues4Plotting(self,md, startPeriod, md.timestepping.start_time);
                    startPeriod=md.timestepping.start_time;
                    Array4Plotting1= self.Array4Plotting;
                catch ME
                    disp(ME);
                    fprintf('An Error in the FOR LOOP happened...\n');
                end
            end

            fprintf('saving....\n');
            title = [self.saveModelsFolder 'Array4Plotting.mat'];
            save (title, 'Array4Plotting1');
            title = [self.saveModelsFolder 'Solutions.mat'];
            solutionList=self.solutions;
            save (title, 'solutionList');
             title = [self.saveModelsFolder 'MassVolInfoLst.mat'];
            save (title, 'list_Period_MassVol_Total');
            fprintf('Completed....\n');
        end

        function self=plotMe(self, view_x, view_y, plotMesh, Boundaries, xlim, ylim, makeMovie,quiverScaling, quiverDensity)
   
            [self,plotting]=loadVaraible_createPlotting(self, view_x, view_y);

            fprintf('Plotting starting ...\n\n');
            md=modelmulti_Ice();
            for idx=1: size(self.solutions,1)    
                md=loadmd4Plotting(self, md, idx);            

                plots_1(plotting, md, self.Array4Plotting, Boundaries, xlim, ylim,quiverScaling, quiverDensity);   

                if plotMesh
                    plotting.saveMeshPlot(md, ['Year: ' int2str(self.solutions(idx).time )],  int2str(self.solutions(idx).time ) );
                end
            end

            timeVector=self.MassVolInfoLst (:,1);
            if timeVector(1)~=0, timeVector=[0; timeVector];end

%             iceTypes_source=self.smbIceTypeVector';
%             iceTypesList=zeros(length(timeVector),2);
%             i=1;
% 
%             for iii=1:length(iceTypes_source)-1  %time_step
%                 loop=timeVector(find(timeVector(:)==self.finalTimeVector(iii)):find(timeVector(:)==self.finalTimeVector(iii+1))-1);
%                 for ii=1:length(loop)
%                     iceTypesList(i,1)=loop(ii);
%                     iceTypesList(i,2)=iceTypes_source(iii);
%                     i=i+1;
%                 end
%             end
%             iceTypesList(i,1)=self.finalTimeVector(end);
%             iceTypesList(i,2)=iceTypes_source(iceTypes_source(end));

            plots_2(plotting, timeVector,self.MassVolInfoLst(:,3),fopen(self.deltaVolumeLogPath,'w+'), self.MassVolInfoLst(:,7), ...
                self.MassVolInfoLst(:,5), fopen(self.volumeLogPath,'w+'), fopen(self.thickThresholdLogPath,'w+'), self.Array4Plotting, md);

            if makeMovie
                make_movie(self, 'Thickness');
                make_movie(self, 'Surface');
                make_movie(self, 'quiver');
                make_movie(self, 'Vel');
                make_movie(self, 'Temperature');
                make_movie(self, 'streamline');
            end

           self.logTime('> End of the simulation: %s\n');
           fprintf('\nPlots have been completed...\n\n\n');               
        end
  
        function make_movie(self, plotType)
            currentFolder=pwd;
            cd ([self.runsPath self.outputRunFolder '/Plots/' plotType]);
            system('ffmpeg -framerate 4/3 -pattern_type glob -i "*.jpg"  -c:v libx264 -profile:v high -crf 20 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"  "${PWD##*/}".mp4')
            cd (currentFolder);
        end

        function [self,plotting]=loadVaraible_createPlotting(self, view_x, view_y)
            M=load ([self.saveModelsFolder 'Array4Plotting.mat']);
            self.Array4Plotting=M.Array4Plotting1;
            M=load([self.saveModelsFolder 'Solutions.mat']);
            self.solutions=M.solutionList;
            M=load([self.saveModelsFolder 'MassVolInfoLst.mat']);
            self.MassVolInfoLst=M.list_Period_MassVol_Total;
            pause('off');
 
            plotting=plottingTools(self.runsPath, self.outputRunFolder, self.numbLayers, self.Array4Plotting);
 
            plotting.view_x=view_x; plotting.view_y=view_y;
        end

        function md=loadmd4Plotting(self, md, Year)
            md.uniqueTransientSolutions=  self.solutions(Year);
            md.geometry.surface        =  self.solutions(Year).Surface;
            md.geometry.thickness      =  self.solutions(Year).Thickness;
            md.geometry.base           =  self.solutions(Year).Base;
            md.geometry.bed            =  self.solutions(Year).Base;         
            md.mesh                    =  self.solutions(Year).Mesh;
            md.multiIceMesh            =  self.solutions(Year).MultiIceMesh;
            md.materials.rheology_B    =  md.materials.rheology_B.*ones(md.mesh.numberofelements,1);
            md.initialization.vx       = self.solutions(Year).Vx;
            md.initialization.vy       = self.solutions(Year).Vy;
            md.initialization.vz       = self.solutions(Year).Vz;
            md.initialization.vel      = self.solutions(Year).Vel;       
            
        end

    end

end