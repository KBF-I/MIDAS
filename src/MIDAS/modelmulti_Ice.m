% #define _IS_MULTI_ICE_
classdef modelmulti_Ice < model
    properties
        multiIceMesh;     

        uniqueTransientSolutions    = []; %this one captures only the second occurance of a time period if there are multipe occurances (ie. when they have multiple smb vaiues being applied
    end

    methods (Static)
        function md = loadobj(md)
        end
    end

    methods 
        function md = modelmulti_Ice(varargin)
            if nargin == 0
                temp={};
            else
                temp=varargin;
            end
            md = md@model(temp{:});
        end %func: constructor

        function md = setdefaultparameters(md,planet)
            md = setdefaultparameters@model(md, planet);
            md.multiIceMesh = meshmulti_Ice();
            md.materials = matmulti_Ice();
            md.settings=settingsmulti_Ice();
            [md, md.materials.planetRadius] = planetProperties.setPlanetMoonProperties(md, planetProperties.MARS);
        end %func: setdefaultparameters

        function md = collapse(md)

            if ~md.multiIceMesh.isModel3D, return, end
            md.multiIceMesh.isModel3D = false;

            if length(md.geometry.bed)<length(md.geometry.thickness)
                b=md.geometry.bed;
                beds=[];
                for index=1:md.mesh.numberoflayers
                    beds=[beds; b];
                end
                md.geometry.bed=beds;
                md.geometry.base=beds;
            end

            md.materials.boundaryConditions_temperature  = md.initialization.temperature;
            md.materials.boundaryConditions_vx           = md.initialization.vx      ;
            md.materials.boundaryConditions_vy           = md.initialization.vy      ;
            md.materials.boundaryConditions_vz           = md.initialization.vz      ;
            md.materials.boundaryConditions_vel          = md.initialization.vel     ;
            md.materials.boundaryConditions_pressure     = md.initialization.pressure     ;
            
            md = collapse@model(md);
        end

        function md=captureResults(~, md, iceType, modelType, logFileLocation, varargin)
            if strcmpi(modelType, "StressBalance")
                results = md.results.StressbalanceSolution;
                md.initialization.vx = results.Vx;
                md.initialization.vy = results.Vy;
                md.initialization.vz = results.Vz;
                md.initialization.vel= results.Vel;
                md.initialization.pressure = results.Pressure;
                return
            elseif strcmpi(modelType, "Thermal")
                md.initialization.temperature=md.results.ThermalSolution.Temperature;
                md.thermal.spctemperature(md.mesh.vertexonsurface==1) = md.results.ThermalSolution.Temperature(md.mesh.vertexonsurface==1);
                md.basalforcings.groundedice_melting_rate=md.results.ThermalSolution.BasalforcingsGroundediceMeltingRate;
                md.timestepping.start_time = 0;
                return
            end

            %it is transient; let's continue
                results = md.results.TransientSolution(end);
                md.initialization.vx = results.Vx;
                md.initialization.vy = results.Vy;
                md.initialization.vz = results.Vz;
                md.initialization.vel= results.Vel;
                md.initialization.pressure = results.Pressure;
                md.initialization.temperature=results.Temperature;

            for ii=1:length(md.results.TransientSolution)
                md.results.TransientSolution(ii).iceType=iceType;
                md.results.TransientSolution(ii).unitID=md.multiIceMesh.currentIceUnitsCnt;%the uppermost unit is the one we are working on...
            end
            try
                fields={'StressbalanceConvergenceNumSteps','SolutionType','errlog', 'outlog'};
                md.results.TransientSolution = rmfield(md.results.TransientSolution,fields);
            catch
                return
            end
            tempSolutions=md.results.TransientSolution;
            timeSet=[];
            if ~md.materials.useSMB
                if md.multiIceMesh.domainArea==-1, error('Domain Area is not set. Set it in md.multiIceMesh before you continue'); end
                totalSMB=md.multiIceMesh.periodSMB*md.multiIceMesh.domainArea*md.materials.getSurfaceRhoIce(md)/1e12;  %1e12 is to convert kg to gigaton
                SMBs=md.multiIceMesh.periodSMB*ones(md.mesh.numberofvertices, 1);
            end
            for idx=length(tempSolutions):-1:1   
                tempTime=tempSolutions(idx).time;
                if sum(ismember(timeSet, tempTime))>=1
                    tempSolutions(idx)=[];
                else
                    timeSet=[timeSet, tempTime];
                end
                %if we are not using SMBs then the backend will return 0
                %for SMB values, so here we need to set them up manually
                if ~md.materials.useSMB
                    if md.multiIceMesh.currentPeriodIceType==1
                        tempSolutions(idx).TotalSmb=totalSMB;
                        tempSolutions(idx).SmbMassBalance=SMBs;
                                                tempSolutions(idx).H2OTotalSmb=0;
                        tempSolutions(idx).H2OSmbMassBalance=zeros(md.mesh.numberofvertices, 1);
                    else
                        tempSolutions(idx).H2OTotalSmb=totalSMB;
                        tempSolutions(idx).H2OSmbMassBalance=SMBs;
                                                tempSolutions(idx).TotalSmb=0;
                        tempSolutions(idx).SmbMassBalance=zeros(md.mesh.numberofvertices, 1);;
                    end
                end
            end
            iii=1;
            try
                startStep=md.uniqueTransientSolutions(end).step;
            catch
                startStep=0;
            end
            for ii=startStep+1:startStep+length(tempSolutions)
                tempSolutions(iii).step=ii;
                iii=iii+1;
            end
            try
                md.uniqueTransientSolutions=[md.uniqueTransientSolutions, tempSolutions];
            catch
                % Assuming md.uniqueTransientSolutions is an array of structures

                % Define the values you want to assign to the new fields
                % Replace the "zeros(1, length(md.uniqueTransientSolutions))" with actual values or calculated data
                H2OTotalSmbValues = zeros(1, length(md.uniqueTransientSolutions)); % Example: Initialize with zeros
                H2OSmbMassBalanceValues = zeros(1, length(md.uniqueTransientSolutions)); % Example: Initialize with zeros

                % Add the new fields to each structure in the array
                for i = 1:length(md.uniqueTransientSolutions)
                    md.uniqueTransientSolutions(i).H2OTotalSmb = H2OTotalSmbValues(i);
                    md.uniqueTransientSolutions(i).H2OSmbMassBalance = H2OSmbMassBalanceValues(i);
                end
                md.uniqueTransientSolutions=[md.uniqueTransientSolutions, tempSolutions];
            end

            s=md.timestepping.start_time;
            md = transientrestart(md);
            md.results=[]; % we no longer need the results
            md.timestepping.start_time=s;

            md=md.multiIceMesh.reconstruct_IceUnitsMesh(md);

        end

        function md=extrudeModel(md, type1)
            
            if md.multiIceMesh.isModel3D, return, end
            
            %extrude 
            % type1=1: auxilary extrude function 
            % type1=2: multi_unit extrude
            % type1=3: original extrude from the parent class
            if type1==1 || md.materials.useSMB
                md=md.extrude(md.multiIceMesh.min_numLayers,1);
            elseif type1==2 
                md=md.newExtrude();
            end

            %always after extrude reset the materials, as the materials
            %are assigned to each element, and we need to reset them based
            %on the new element structure
                        md.multiIceMesh.isModel3D = true;
            md=md.multiIceMesh.reconstruct_IceUnitsMesh(md);
            md.materials = md.materials.setIceProperties (md);

            if ~isempty (md.materials.boundaryConditions_temperature)
                if size(md.materials.boundaryConditions_temperature,1)<=size(md.initialization.temperature,1)
                    md.initialization.temperature (1:size(md.materials.boundaryConditions_temperature,1)) = md.materials.boundaryConditions_temperature(:);
                end
                md.materials.boundaryConditions_temperature="";
            end
            if ~isempty (md.materials.boundaryConditions_vx)
                if size(md.materials.boundaryConditions_vx,1)<=size(md.initialization.vx,1)
                    md.initialization.vx     (1:size(md.materials.boundaryConditions_vx,1))      = md.materials.boundaryConditions_vx      (:)        ;
                end
                md.materials.boundaryConditions_vx="";
            end
            if ~isempty (md.materials.boundaryConditions_vy)
                if size(md.materials.boundaryConditions_vy,1)<=size(md.initialization.vy,1)
                    md.initialization.vy     (1:size(md.materials.boundaryConditions_vy,1))      = md.materials.boundaryConditions_vy      (:)        ;
                end
                md.materials.boundaryConditions_vy="";
            end
            if ~isempty (md.materials.boundaryConditions_vz)
                if size(md.materials.boundaryConditions_vz,1)<=size(md.initialization.vz,1)
                    md.initialization.vz     (1:size(md.materials.boundaryConditions_vz,1))      = md.materials.boundaryConditions_vz      (:)        ;
                end
                md.materials.boundaryConditions_vz="";
            end
            if ~isempty (md.materials.boundaryConditions_vel)
                if size(md.materials.boundaryConditions_vel,1)<=size(md.initialization.vel,1)
                    md.initialization.vel    (1:size(md.materials.boundaryConditions_vel,1))     = md.materials.boundaryConditions_vel     (:)       ;
                end
                md.materials.boundaryConditions_vel="";
            end
            if ~isempty (md.materials.boundaryConditions_pressure)
                if size(md.materials.boundaryConditions_pressure,1)<=size(md.initialization.pressure,1)
                    md.initialization.pressure    (1:size(md.materials.boundaryConditions_pressure,1))     = md.materials.boundaryConditions_pressure     (:)       ;
                end
                md.materials.boundaryConditions_vel="";
            end

        end      
        
        function md=extrude(md, varargin)
            %extrude-This is a work in progress function. User newExtrude
            %or extrudeModel instead.

            if md.multiIceMesh.numberOfElementsIn2D == 0
                md.multiIceMesh.numberOfElementsIn2D = md.mesh.numberofelements;
                md.multiIceMesh.numberOfVerticesIn2D = md.mesh.numberofvertices;
            end
            if nargin==1 % we need to determine the extrusion list based on the units
                md.multiIceMesh.extrusionlist=[]; 
                startingPoint=0;
                for idx=1: md.multiIceMesh.currentIceUnitsCnt
                    numlayers1=(md.multiIceMesh.iceUnits(idx).NmbLayers);
                    extrusionlist1=abs(mean(md.multiIceMesh.iceUnits(idx).currentHeightPercentage) * ((0:1:numlayers1-1)/(numlayers1-1)))+startingPoint;

                    extrusionlist1(extrusionlist1>=0.999999999999999)=[];
                    if idx==md.multiIceMesh.currentIceUnitsCnt
                        extrusionlist1=[extrusionlist1, 1];
                    end
                    n=0; if idx~=1; n=1; end
                    for i=1+n:length(extrusionlist1)
                        md.multiIceMesh.extrusionlist=[md.multiIceMesh.extrusionlist, extrusionlist1(i)]; 
                    end
                    if isempty(i), i=1; end
                    startingPoint=extrusionlist1(i);
                end
                M=unique(md.multiIceMesh.extrusionlist, 'sorted');
                M(M<0)=[];
                M(M>=0.999999999999999)=[];
                md.multiIceMesh.extrusionlist=M;
                md=extrude@model(md, md.multiIceMesh.extrusionlist);
               
            else
                temp=varargin;
                md=extrude@model(md, temp{:});

            end
        end
        
        function disp(self)
            disp('Multi Ice Model:');
            disp@model(self);
        end
    end

    methods (Access=private) 

        function md=newExtrude(md,varargin)

            if 1==1
                if md.multiIceMesh.numberOfElementsIn2D == 0
                    md.multiIceMesh.numberOfElementsIn2D = md.mesh.numberofelements;
                    md.multiIceMesh.numberOfVerticesIn2D = md.mesh.numberofvertices;
                end

                if numel(md.geometry.base)~=md.mesh.numberofvertices || numel(md.geometry.surface)~=md.mesh.numberofvertices
                    error('model has not been parameterized yet: base and/or surface not set');
                end

                numlayers=0;
                for idx=1:md.multiIceMesh.currentIceUnitsCnt
                    numlayers=numlayers+md.multiIceMesh.iceUnits(idx).NmbLayers;
                end
                numlayers=numlayers-md.multiIceMesh.currentIceUnitsCnt+1;

                if numlayers<=md.settings.minNbrLayersInIceUnit
                    error('number of layers should be at least %i', md.settings.minNbrLayersInIceUnit);
                end
                if strcmp(md.mesh.domaintype(),'3D')
                    error('Cannot extrude a 3d mesh (extrude cannot be called more than once)');
                end

                %Initialize with the 2d mesh
                mesh2d = md.mesh;
                md.mesh=mesh3dprisms();
                md.mesh.x                           = mesh2d.x;
                md.mesh.y                           = mesh2d.y;
                md.mesh.elements                    = mesh2d.elements;
                md.mesh.numberofelements            = mesh2d.numberofelements;
                md.mesh.numberofvertices            = mesh2d.numberofvertices;

                md.mesh.lat                         = mesh2d.lat;
                md.mesh.long                        = mesh2d.long;
                md.mesh.epsg                        = mesh2d.epsg;
                md.mesh.scale_factor                = mesh2d.scale_factor;

                md.mesh.vertexonboundary            = mesh2d.vertexonboundary;
                md.mesh.vertexconnectivity          = mesh2d.vertexconnectivity;
                md.mesh.elementconnectivity         = mesh2d.elementconnectivity;
                md.mesh.average_vertex_connectivity = mesh2d.average_vertex_connectivity;

                md.mesh.extractedvertices           = mesh2d.extractedvertices;
                md.mesh.extractedelements           = mesh2d.extractedelements;
            end

  		  x3d=[];  y3d=[];   z3d=[];  %the lower node is on the bed
          md.multiIceMesh.extrusionlist=[];
          for idx=1:md.multiIceMesh.currentIceUnitsCnt
  		    thickness3d=md.multiIceMesh.iceUnits(idx).Thickness; %thickness and bed for these nodes
            bed3d=md.multiIceMesh.iceUnits(idx).Bed;
            surface=md.multiIceMesh.iceUnits(idx).Surface;

            numlayers1=(md.multiIceMesh.iceUnits(idx).NmbLayers);
            extrusionlist=((0:1:numlayers1-1)/(numlayers1-1));
            md.multiIceMesh.extrusionlist=[md.multiIceMesh.extrusionlist, extrusionlist];

            n=0; if idx~=1; n=1; end
            %Create the new layers
            for i=1+n:numlayers1
                x3d=[x3d; md.mesh.x]; %#ok<*AGROW>
                y3d=[y3d; md.mesh.y];

                temp=bed3d+thickness3d*extrusionlist(i);
                pos=temp>surface;
                temp(pos)=surface(pos);
                pos=temp<bed3d;
                temp(pos)=bed3d(pos);
                z3d=[z3d; temp];
            end

          end

          number_nodes3d=size(x3d,1); %number of 3d nodes for the non extruded part of the mesh

          %Extrude elements
          elements3d=[];
          for i=1:numlayers-1
              elements3d=[elements3d;[md.mesh.elements+(i-1)*md.mesh.numberofvertices md.mesh.elements+i*md.mesh.numberofvertices]]; %Create the elements of the 3d mesh for the non extruded part
          end
          number_el3d=size(elements3d,1); %number of 3d nodes for the non extruded part of the mesh

          if 2==2
  			%Keep a trace of lower and upper nodes
            lowervertex=NaN*ones(number_nodes3d,1);
            uppervertex=NaN*ones(number_nodes3d,1);
            lowervertex(md.mesh.numberofvertices+1:end)=1:(numlayers-1)*md.mesh.numberofvertices;
            uppervertex(1:(numlayers-1)*md.mesh.numberofvertices)=md.mesh.numberofvertices+1:number_nodes3d;
            md.mesh.lowervertex=lowervertex;
            md.mesh.uppervertex=uppervertex;

            %same for lower and upper elements
            lowerelements=NaN*ones(number_el3d,1);
            upperelements=NaN*ones(number_el3d,1);
            lowerelements(md.mesh.numberofelements+1:end)=1:(numlayers-2)*md.mesh.numberofelements;
            upperelements(1:(numlayers-2)*md.mesh.numberofelements)=md.mesh.numberofelements+1:(numlayers-1)*md.mesh.numberofelements;
            md.mesh.lowerelements=lowerelements;
            md.mesh.upperelements=upperelements;

            %Save old mesh
            md.mesh.x2d=md.mesh.x;
            md.mesh.y2d=md.mesh.y;
            md.mesh.elements2d=md.mesh.elements;
            md.mesh.numberofelements2d=md.mesh.numberofelements;
            md.mesh.numberofvertices2d=md.mesh.numberofvertices;

            %Build global 3d mesh
            md.mesh.elements=elements3d;
            md.mesh.x=x3d;
            md.mesh.y=y3d;
            md.mesh.z=z3d;
            md.mesh.numberofelements=number_el3d;
            md.mesh.numberofvertices=number_nodes3d;
            md.mesh.numberoflayers=numlayers;

            %Ok, now deal with the other fields from the 2d mesh:

            %bedinfo and surface info
            md.mesh.vertexonbase=project3d(md,'vector',ones(md.mesh.numberofvertices2d,1),'type','node','layer',1);
            md.mesh.vertexonsurface=project3d(md,'vector',ones(md.mesh.numberofvertices2d,1),'type','node','layer',md.mesh.numberoflayers);
            md.mesh.vertexonboundary=project3d(md,'vector',md.mesh.vertexonboundary,'type','node');

            %lat long
            md.mesh.lat=project3d(md,'vector',md.mesh.lat,'type','node');
            md.mesh.long=project3d(md,'vector',md.mesh.long,'type','node');
            md.mesh.scale_factor=project3d(md,'vector',md.mesh.scale_factor,'type','node');

            md.geometry=extrude(md.geometry,md);
            pos=(md.geometry.surface<md.mesh.z);
            md.mesh.z(pos)=md.geometry.surface(pos);

            md.friction  = extrude(md.friction,md);
            md.inversion = extrude(md.inversion,md);
            md.smb = extrude(md.smb,md);
            md.initialization = extrude(md.initialization,md);

            md.flowequation=md.flowequation.extrude(md);
            md.stressbalance=extrude(md.stressbalance,md);
            md.thermal=md.thermal.extrude(md);
            md.masstransport=md.masstransport.extrude(md);
            md.levelset=extrude(md.levelset,md);
            md.calving=extrude(md.calving,md);
            md.frontalforcings=extrude(md.frontalforcings,md);
            md.hydrology = extrude(md.hydrology,md);
            md.debris = extrude(md.debris,md);
            md.solidearth = extrude(md.solidearth,md);
            md.dsl = extrude(md.dsl,md);
			md.stochasticforcing = extrude(md.stochasticforcing,md);

            %connectivity
            if ~isnan(md.mesh.elementconnectivity)
                md.mesh.elementconnectivity=repmat(md.mesh.elementconnectivity,numlayers-1,1);
                md.mesh.elementconnectivity(find(md.mesh.elementconnectivity==0))=NaN;
                for i=2:numlayers-1
                    md.mesh.elementconnectivity((i-1)*md.mesh.numberofelements2d+1:(i)*md.mesh.numberofelements2d,:)...
                        =md.mesh.elementconnectivity((i-1)*md.mesh.numberofelements2d+1:(i)*md.mesh.numberofelements2d,:)+md.mesh.numberofelements2d;
                end
                md.mesh.elementconnectivity(find(isnan(md.mesh.elementconnectivity)))=0;
            end

            md.materials=extrude(md.materials,md);
            md.damage=extrude(md.damage,md);
            md.mask=extrude(md.mask,md);
            md.qmu=extrude(md.qmu,md);
            md.basalforcings=extrude(md.basalforcings,md);
            md.outputdefinition=extrude(md.outputdefinition,md);
          end

            %increase connectivity if less than 25:
            if md.mesh.average_vertex_connectivity<=25
 			   md.mesh.average_vertex_connectivity=100;
            end
       

        end % func: newExtrude

        function md=modelRestart(md,logFileLocation, varargin)
            if ~md.multiIceMesh.isModel3D, error('Model needs to be in 3D'), end
            count=md.mesh.numberofvertices2d;  
            s=md.timestepping.start_time;
            md = transientrestart(md);
            md.results=[]; % we no longer need the results
            md.timestepping.start_time=s;
            thicknessAfterTransient=md.geometry.thickness(1:count);
            bed= md.geometry.bed(1:count); %first unit is the lowest unit

            if ~md.multiIceMesh.onlyAdjustImpactedUnit
                %let's adjust all the units first
                for idx=1:md.multiIceMesh.currentIceUnitsCnt       %1 to unitsCnt: from lowest to the upper levels
                    md.multiIceMesh.iceUnits(idx).Bed       = bed;
                    md.multiIceMesh.iceUnits(idx).Thickness = thicknessAfterTransient * md.multiIceMesh.iceUnits(idx).currentHeightPercentage;
                    md.multiIceMesh.iceUnits(idx).Surface   = md.multiIceMesh.iceUnits(idx).Thickness + md.multiIceMesh.iceUnits(idx).Bed;

                    bed = md.multiIceMesh.iceUnits(idx).Surface;
                end
            elseif md.multiIceMesh.currentIceUnitsCnt>1
                % what is the change between and after the transient run?
                %Delta= new - old
                deltaThickness=md.geometry.surface(1:count)-md.multiIceMesh.iceUnits(end).Surface;
                positive_delta=deltaThickness;
                positive_delta(positive_delta<0)=0;
                negative_delta=deltaThickness;
                negative_delta(negative_delta>0)=0;
                
                %if the top unit is CO2 it gets the changes. If the top
                %unit is H2O, it'll get the positive chagnes and the
                %negative chagnes will go to the unit underneath it. 

                %CO2_H2O_Specific: The assumption is that H2O is much
                %stronger than CO2, therefore if the impacted layer is of type
                %of H2O, after the model is run, the impact on the thickness
                %will be applied to the CO2 unit below the H2O unit. However,
                %if the impacted unit is of type of CO2, then the change to the
                %overal thickness of the model will be applied to the same
                %unit.
                %If this is a unit that is just forming now, and it is of
                %type of CO2, then the changes in the thickness will be
                %applied to the previous CO2 unit (two units below) if
                %such exists

                %what is the type of the impacted unit?
                ice_Type=md.multiIceMesh.iceUnits(md.multiIceMesh.impactedUnit).IceType;
                activeUnit=md.multiIceMesh.impactedUnit;
                if activeUnit<md.multiIceMesh.currentIceUnitsCnt && ice_Type==mat_consts.CO2
                    %sublimation 
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+deltaThickness;
                else
                    %deposition
                    if ice_Type==mat_consts.H2O
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+positive_delta;
                        %per note above
                        if activeUnit>1
                            md.multiIceMesh.iceUnits(activeUnit-1).Thickness= ...
                                md.multiIceMesh.iceUnits(activeUnit-1).Thickness+negative_delta;
                        else
                            md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                                md.multiIceMesh.iceUnits(activeUnit).Thickness+negative_delta;
                        end
                    else
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+deltaThickness;
                    end
                end
               
                %let's makes sure no node gets a negative thickness
                M=find(md.multiIceMesh.iceUnits(activeUnit).Thickness<0);
                N=[];
                if activeUnit>1,  N=find(md.multiIceMesh.iceUnits(activeUnit-1).Thickness<0); end
                %Note: we are fixing the minimum thickness of a unit to a certain
                %threshold here. for eample. If the timestep is less than 200
                %years, for the first ~200 years the thickness will be
                %fixed at this threshold (because most probably the accumulation is
                % about 3-5 mm and when the time step is about 100-200 years,
                % the accumulation will be less than 50 cm, so this part of the
                % code will continuously set the thickness to 50 cm),
                % until it starts to grow and go
                %beyond the threshold. This is necessary to do or the
                %backend will result in negative jackobian. This should be
                %fine for simulations that will run for hundreds of
                %thousands of years
                threshold=md.settings.thickness_minThreshld; %minium thickness is 
                if activeUnit==1
                    threshold=md.settings.thickness_firstIceUnit_threshold;
                end

                if ~isempty(M)
                    if activeUnit==md.multiIceMesh.currentIceUnitsCnt
                        md.multiIceMesh.iceUnits(activeUnit).Thickness(M)=0;  %only negative thickness...
                    else
                        md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(M)= md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(M)+ md.multiIceMesh.iceUnits(activeUnit).Thickness(M);
                        md.multiIceMesh.iceUnits(activeUnit).Thickness(M)=threshold;
                    end
                end
                if ~isempty(N)
                    md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(N)= md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(N)+ md.multiIceMesh.iceUnits(activeUnit-1).Thickness(N);
                    md.multiIceMesh.iceUnits(activeUnit-1).Thickness(N)=threshold;
                end
         

                %if the thickness of a node on the boundary of a none_H2O unit becomes too
                %high, cap the thickness, and let the ice flow out of the model
                %maximum acceptable thickness is x times that of the median
                %of the thickess of the nodes on the boundary
                %if you want to activate this logic chagne x to a
                %reasonable amount. at currently 100 km it will never run. 

                x=100000;                       %times that of the median of thickness; for Pluto use 10, for MCID use 4
                onlyOnBoundary=true;        %do the cap only on the boundary vertices

                switch nargin
                    case 3
                        x=varargin{1};
                    case 4
                        x=varargin{1};
                        onlyOnBoundary=varargin{2};
                end

                if onlyOnBoundary
                    b=round(median(md.geometry.thickness(md.mesh.vertexonboundary==1)),2)*x;  %max allowable thickness
                else 
                    b=round(median(md.geometry.thickness),2)*x; %#ok<UNRCH> 
                end

                if max(md.geometry.thickness)>b 

                    %boudary nodes with higher thickness
                    if onlyOnBoundary
                        M=(md.geometry.thickness>b)+md.mesh.vertexonboundary;
                        M=find(M==2);
                    else
                        % vs. all nodes with higher thickness
                        M=(md.geometry.thickness>b); %#ok<UNRCH> 
                        M=find(M==1);
                    end

                    %move M to 2D
                    M=M(M<=md.multiIceMesh.numberOfVerticesIn2D);
                    if ~isempty(M)
                        simsTextFile = fopen([logFileLocation '/ThicknessCapLog.txt'],'a+');
                        %how many None_H2O units?
                        none_h2o_count=0;
                        for id=1:md.multiIceMesh.currentIceUnitsCnt
                            if md.multiIceMesh.iceUnits(id).IceType~=mat_consts.H2O, none_h2o_count=none_h2o_count+1;end
                        end
                        %adjust their thickness
                        t=0;
                        adjustedThickness=b/none_h2o_count;
                        for id=1:md.multiIceMesh.currentIceUnitsCnt
                            if md.multiIceMesh.iceUnits(id).IceType~=mat_consts.H2O
                                A=M(md.multiIceMesh.iceUnits(id).Thickness(M)>adjustedThickness);

                                %Log the changes...
                                fprintf(simsTextFile,'=================Time Period Ending in  : %i============================= \n', md.timestepping.final_time);
                                fprintf(simsTextFile,' Unit ID: %i \n', id);
                                fprintf(simsTextFile,' Unit IceType: %i \n', md.multiIceMesh.iceUnits(id).IceType);
                                fprintf(simsTextFile,' Node        Thickness                    To \n');
                                fprintf(simsTextFile,'  %i,       %i,              %i  \n', ...
                                    [A, md.multiIceMesh.iceUnits(id).Thickness(A), (adjustedThickness)*ones(size(A,1),1)].');

                                md.multiIceMesh.iceUnits(id).Thickness(A)=adjustedThickness;
                            end

                            t=t+md.multiIceMesh.iceUnits(id).Thickness;
                        end
                        %now adjust the geometry
                        if md.multiIceMesh.isModel3D, md=md.collapse(); end
                        md.geometry.thickness=t;
                        md.geometry.surface=md.geometry.bed+md.geometry.thickness;

                        fclose(simsTextFile);
                    end
                end  %capping the thickness- done.

                for a=1: md.multiIceMesh.currentIceUnitsCnt
                    md.multiIceMesh.iceUnits(a).Thickness(md.multiIceMesh.iceUnits(a).Thickness<0)=threshold;
                    md.multiIceMesh.iceUnits(a).Surface=md.multiIceMesh.iceUnits(a).Thickness+md.multiIceMesh.iceUnits(a).Bed;
                    if a<md.multiIceMesh.currentIceUnitsCnt
                        md.multiIceMesh.iceUnits(a+1).Bed=md.multiIceMesh.iceUnits(a).Surface;
                    end
                end

                md.multiIceMesh.iceUnits(1).Bed=bed;
                md.multiIceMesh.iceUnits(end).Surface=md.geometry.surface(1:count);
                md.multiIceMesh.iceUnits(end).Thickness=md.multiIceMesh.iceUnits(end).Surface-md.multiIceMesh.iceUnits(end).Bed;

            end

         %   md=md.multiIceMesh.setUnits_Elements(md, false);

        end
    

%{
        function md=modelRestart(md,logFileLocation, varargin)
            if ~md.multiIceMesh.isModel3D, error('Model needs to be in 3D'), end
            count=md.mesh.numberofvertices2d;  
            s=md.timestepping.start_time;
            md = transientrestart(md);
            md.results=[]; % we no longer need the results
            md.timestepping.start_time=s;
            thicknessAfterTransient=md.geometry.thickness(1:count);
            bed= md.geometry.bed(1:count); %first unit is the lowest unit

            if ~md.multiIceMesh.onlyAdjustImpactedUnit
                %let's adjust all the units first
                for idx=1:md.multiIceMesh.currentIceUnitsCnt       %1 to unitsCnt: from lowest to the upper levels
                    md.multiIceMesh.iceUnits(idx).Bed       = bed;
                    md.multiIceMesh.iceUnits(idx).Thickness = thicknessAfterTransient * md.multiIceMesh.iceUnits(idx).currentHeightPercentage;
                    md.multiIceMesh.iceUnits(idx).Surface   = md.multiIceMesh.iceUnits(idx).Thickness + md.multiIceMesh.iceUnits(idx).Bed;

                    bed = md.multiIceMesh.iceUnits(idx).Surface;
                end
            elseif md.multiIceMesh.currentIceUnitsCnt>1
                % what is the change between and after the transient run?
                %Delta= new - old
                deltaThickness=md.geometry.surface(1:count)-md.multiIceMesh.iceUnits(end).Surface;
                positive_delta=deltaThickness;
                positive_delta(positive_delta<0)=0;
                negative_delta=deltaThickness;
                negative_delta(negative_delta>0)=0;
                
                %if the top unit is CO2 it gets the changes. If the top
                %unit is H2O, it'll get the positive chagnes and the
                %negative chagnes will go to the unit underneath it. 

                %CO2_H2O_Specific: The assumption is that H2O is much
                %stronger than CO2, therefore if the impacted layer is of type
                %of H2O, after the model is run, the impact on the thickness
                %will be applied to the CO2 unit below the H2O unit. However,
                %if the impacted unit is of type of CO2, then the change to the
                %overal thickness of the model will be applied to the same
                %unit.
                %If this is a unit that is just forming now, and it is of
                %type of CO2, then the changes in the thickness will be
                %applied to the previous CO2 unit (two units below) if
                %such exists

                %what is the type of the impacted unit?
                ice_Type=md.multiIceMesh.iceUnits(md.multiIceMesh.impactedUnit).IceType;
                activeUnit=md.multiIceMesh.impactedUnit;
                if activeUnit<md.multiIceMesh.currentIceUnitsCnt && ice_Type==mat_consts.CO2
                    %sublimation 
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+deltaThickness;
                else
                    %deposition
                    if ice_Type==mat_consts.H2O
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+positive_delta;
                        %per note above
                        if activeUnit>1
                            md.multiIceMesh.iceUnits(activeUnit-1).Thickness= ...
                                md.multiIceMesh.iceUnits(activeUnit-1).Thickness+negative_delta;
                        else
                            md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                                md.multiIceMesh.iceUnits(activeUnit).Thickness+negative_delta;
                        end
                    else
                        md.multiIceMesh.iceUnits(activeUnit).Thickness= ...
                            md.multiIceMesh.iceUnits(activeUnit).Thickness+deltaThickness;
                    end
                end
               
                %let's makes sure no node gets a negative thickness
                M=find(md.multiIceMesh.iceUnits(activeUnit).Thickness<0);
                N=[];
                if activeUnit>1,  N=find(md.multiIceMesh.iceUnits(activeUnit-1).Thickness<0); end
                %Note: we are fixing the minimum thickness of a unit to a certain
                %threshold here. for eample. If the timestep is less than 200
                %years, for the first ~200 years the thickness will be
                %fixed at this threshold (because most probably the accumulation is
                % about 3-5 mm and when the time step is about 100-200 years,
                % the accumulation will be less than 50 cm, so this part of the
                % code will continuously set the thickness to 50 cm),
                % until it starts to grow and go
                %beyond the threshold. This is necessary to do or the
                %backend will result in negative jackobian. This should be
                %fine for simulations that will run for hundreds of
                %thousands of years
                threshold=md.settings.thickness_minThreshld; %minium thickness is 
                if activeUnit==1
                    threshold=md.settings.thickness_firstIceUnit_threshold;
                end

                if ~isempty(M)
                    if activeUnit==md.multiIceMesh.currentIceUnitsCnt
                        md.multiIceMesh.iceUnits(activeUnit).Thickness(M)=0;  %only negative thickness...
                    else
                        md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(M)= md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(M)+ md.multiIceMesh.iceUnits(activeUnit).Thickness(M);
                        md.multiIceMesh.iceUnits(activeUnit).Thickness(M)=threshold;
                    end
                end
                if ~isempty(N)
                    md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(N)= md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).Thickness(N)+ md.multiIceMesh.iceUnits(activeUnit-1).Thickness(N);
                    md.multiIceMesh.iceUnits(activeUnit-1).Thickness(N)=threshold;
                end
         

                %if the thickness of a node on the boundary of a none_H2O unit becomes too
                %high, cap the thickness, and let the ice flow out of the model
                %maximum acceptable thickness is x times that of the median
                %of the thickess of the nodes on the boundary
                %if you want to activate this logic chagne x to a
                %reasonable amount. at currently 100 km it will never run. 

                x=100000;                       %times that of the median of thickness; for Pluto use 10, for MCID use 4
                onlyOnBoundary=true;        %do the cap only on the boundary vertices

                switch nargin
                    case 3
                        x=varargin{1};
                    case 4
                        x=varargin{1};
                        onlyOnBoundary=varargin{2};
                end

                if onlyOnBoundary
                    b=round(median(md.geometry.thickness(md.mesh.vertexonboundary==1)),2)*x;  %max allowable thickness
                else 
                    b=round(median(md.geometry.thickness),2)*x; %#ok<UNRCH> 
                end

                if max(md.geometry.thickness)>b 

                    %boudary nodes with higher thickness
                    if onlyOnBoundary
                        M=(md.geometry.thickness>b)+md.mesh.vertexonboundary;
                        M=find(M==2);
                    else
                        % vs. all nodes with higher thickness
                        M=(md.geometry.thickness>b); %#ok<UNRCH> 
                        M=find(M==1);
                    end

                    %move M to 2D
                    M=M(M<=md.multiIceMesh.numberOfVerticesIn2D);
                    if ~isempty(M)
                        simsTextFile = fopen([logFileLocation '/ThicknessCapLog.txt'],'a+');
                        %how many None_H2O units?
                        none_h2o_count=0;
                        for id=1:md.multiIceMesh.currentIceUnitsCnt
                            if md.multiIceMesh.iceUnits(id).IceType~=mat_consts.H2O, none_h2o_count=none_h2o_count+1;end
                        end
                        %adjust their thickness
                        t=0;
                        adjustedThickness=b/none_h2o_count;
                        for id=1:md.multiIceMesh.currentIceUnitsCnt
                            if md.multiIceMesh.iceUnits(id).IceType~=mat_consts.H2O
                                A=M(md.multiIceMesh.iceUnits(id).Thickness(M)>adjustedThickness);

                                %Log the changes...
                                fprintf(simsTextFile,'=================Time Period Ending in  : %i============================= \n', md.timestepping.final_time);
                                fprintf(simsTextFile,' Unit ID: %i \n', id);
                                fprintf(simsTextFile,' Unit IceType: %i \n', md.multiIceMesh.iceUnits(id).IceType);
                                fprintf(simsTextFile,' Node        Thickness                    To \n');
                                fprintf(simsTextFile,'  %i,       %i,              %i  \n', ...
                                    [A, md.multiIceMesh.iceUnits(id).Thickness(A), (adjustedThickness)*ones(size(A,1),1)].');

                                md.multiIceMesh.iceUnits(id).Thickness(A)=adjustedThickness;
                            end

                            t=t+md.multiIceMesh.iceUnits(id).Thickness;
                        end
                        %now adjust the geometry
                        if md.multiIceMesh.isModel3D, md=md.collapse(); end
                        md.geometry.thickness=t;
                        md.geometry.surface=md.geometry.bed+md.geometry.thickness;

                        fclose(simsTextFile);
                    end
                end  %capping the thickness- done.

                for a=1: md.multiIceMesh.currentIceUnitsCnt
                    md.multiIceMesh.iceUnits(a).Thickness(md.multiIceMesh.iceUnits(a).Thickness<0)=threshold;
                    md.multiIceMesh.iceUnits(a).Surface=md.multiIceMesh.iceUnits(a).Thickness+md.multiIceMesh.iceUnits(a).Bed;
                    if a<md.multiIceMesh.currentIceUnitsCnt
                        md.multiIceMesh.iceUnits(a+1).Bed=md.multiIceMesh.iceUnits(a).Surface;
                    end
                end

                md.multiIceMesh.iceUnits(1).Bed=bed;
                md.multiIceMesh.iceUnits(end).Surface=md.geometry.surface(1:count);
                md.multiIceMesh.iceUnits(end).Thickness=md.multiIceMesh.iceUnits(end).Surface-md.multiIceMesh.iceUnits(end).Bed;

            end

         %   md=md.multiIceMesh.setUnits_Elements(md, false);

        end
    

%}

    end

end

