%MATMULTI_ICE class definition
% This class allows for multiple types of ice to be used in a domain. The
% avilalbe types of ice include
% availableIceTypes=["CO2", "H2O", "N2", "CO", "CH4", "H2O_DUST", "ROCK", "MAT1", "MAT2", "MAT3"];
% MAT1 to MAT3 are for future use and have not been implemented yet.
% At the moment only CO2 and H2O are fully implemented and ROCK is
% partially implemented. Also, nye method for rigidity is the only method
% implemented.
%
% The constructor take the planet and the ice type.
%   Usage:
%      MatMulti_Ice=matmulti_ice(planet, IceType);
%
% When the material changes and move from one unit to another, the solver
% will handle the discontinuity in material properties: 
% Discontinuous Galerkin Method: If the finite element solver in ISSM uses a 
% method like Discontinuous Galerkin (DG), it’s specifically designed to handle 
% discontinuities at interfaces between different materials. Check if ISSM or 
% your particular solver settings support this method.
% Element-Based Stress and Strain Calculations: The solver will calculate 
% stresses and strains on an element-by-element basis, ensuring that the 
% properties within each element are correctly used, and discontinuities are 
% respected at the element boundaries.

% #define _IS_MULTI_ICE_

classdef matmulti_Ice < matice

    properties   
        propTable_H2O = [];
        propTable_CO2 = [];
        propTable_N2  = [];
        
        % The following have not been implemented, but they can be added in
        % makePropertyTable function
        propTable_CH4      = [];         propTable_CO       = [];
        propTable_ROCK     = [];         propTable_H2O_DUST = [];
        propTable_MAT1     = [];         propTable_MAT2     = [];
        
        type          = 8;   %material type; 8 means multi_matice in the backend
        Rho_ice_List  = []; %this is placeholder for the list of rho_ice before density goes through the marshalling process.  
        planetRadius; %an unused property for now
        densities     = ["Do not use!"]; %just a placeholder for densities to be sent to the backend
        allMaterialTypes= [];

        %To protected and keep the calculated values during
        %collapse/extrude process
        boundaryConditions_temperature=[];                 boundaryConditions_pressure=[];
        boundaryConditions_vx=[];                          boundaryConditions_vy =[];
        boundaryConditions_vz=[];                          boundaryConditions_vel=[];
    
        alwaysRecalculatePressureDuringExtrusion=true;  %if there is no need to recalculate the pressure during extrusion, set this to false;
        useSMB=false;  %whether or not to use SMB; the defualt is false.
    end

    methods

        function self = matmulti_Ice(varargin)
            
            if nargin == 0
                temp={};
            else
                temp=varargin;
            end
            self = self@matice(temp{:});

            self=self.makePropertyTables();
        end %func: constructor

        function self=makePropertyTables(self)
            %makePropertyTables-Creates a table of material properties to
            %be used during the modelling process
            %To improve the modelling process, instead of calcualting the
            %properties on-demand, this function creates tables containing
            %property values for a range of temperature.
            %
            %Note-Currently only temperature dependent equations for H2O,
            %CO2 and N2 have been included. Extending the equations to
            %cover other materials can be done easily in this function.
            self.propTable_H2O = [];
            self.propTable_CO2 = [];
            self.propTable_N2 = [];

            %FUTURE IMPLEMENTATION: The following have not been implemented.
            self.propTable_CH4      = [];         self.propTable_CO       = [];
            self.propTable_ROCK     = [];         self.propTable_H2O_DUST = [];
            self.propTable_MAT1     = [];         self.propTable_MAT2     = [];

            %from 1 K to 280 K
            %Hack: to improve the modelling process and save on memory, the
            %T1 can be set to a more appropriate temperature range. For
            %exampel for CO2 ice on Mars, T1 can be safely be set to 130 K to
            %190 K
            for T1=1:28000   
                T=T1/100;                                       %1) latent heat                2) Thermal Conductivity                                         3) heat capacity                                                      4) rho                                          5)n (Glen's exp.)              6) A_const                    7)Q
                self.propTable_CO2=[self.propTable_CO2; T1,      189811,                       10^(-5.39941+5.45894*log10(T)-1.41326*log10(T)*log10(T)),       -10^(-6)*T^4  + 0.001*T^3  - 0.2381*T^2  + 28.253*T - 355.66,         1000*(1.72391-(2.53e-4)*T-(2.87e-6)*(T*T)),     8,                             10^(13.0),                  66900];
                self.propTable_H2O=[self.propTable_H2O; T1, -3.76812*T^2-55.81*T+629992,       903.65*(T^(-1.072)),                                            -22.86*10^(-3)*T^2+16.3163*T-720.5987,                                -0.0003*T^2 + 0.0316*T + 933.29,                3,                             9e4,                        60000];
                if T1>3560
                    self.propTable_N2= [self.propTable_N2;  T1,           2.55e4,               213.27*T^(-1.952),                                             0.1957*T^2 + 8.1019*T + 2059.2,                                       -0.0134*T*T - 0.6981 * T + 1039.1 ,            .0155*T+1.4025                  .00501* exp(422/45-422/T),   3500 ];
                else
                    self.propTable_N2= [self.propTable_N2;  T1,           2.55e4,               213.27*T^(-1.952),                                             0.0688*T^3 - 3.9291*T^2 + 173.13*T - 1046.1,                          -0.0334*T^2+0.5547*T+1029.1,                   .0155*T+1.4025                  .00501* exp(422/45-422/T),   3500 ];
                end

            end

            %if a function does not provide the temperature, then the
            %static values per below will be used.
                                    %1)Type,          2)latentheat,    3)thermalconductivity,  4)heatcapacity,    5)rho_ice,  6)rho_water,  7)rho_freshwater,    8)mu_water,      9)temperateiceconductivity ,   10)thermal_exchange_velocity ,  11)meltingpoint,   12) beta,       13)mixed_layer_capacity     ,  14)effectiveconductivity_averaging ,      15)rheology_n,   16)rheology_law         17)A_const                18) Q
            self.allMaterialTypes= [ mat_consts.H2O,   3.34e5,         2.4,                         2093.,          929.2,      1023.,        1000.,                0.0017914,            .24,                        1.00e-4,                       273.15,         9.8e-8,             3974.,                      1,                                         3,               8.,                     9e4,                  60000; ...
                                     mat_consts.CO2,   189662,         0.63,                        700. ,          1562.,      1530.,        1415. ,               2.572e-4,             .24,                        1.00e-4,                       195.00,         9.8e-8,             3974.,                      1,                                         8.0,             7.,                     10^(13.0),            66900; ...
                                     mat_consts.N2,    2.55e4,         0.7,                         1565. ,         1039.,      1070.,        1070. ,               3.118e-4,             .24,                        1.00e-4,                       63.15,          2e-7,               3974.,                      1,                                         2.2,            10.,                     .005,                 3500];

        end

        function self=setIceProperties (self, md)

            %if there is no temperature set, do not assign any properties
            if isnan(md.initialization.temperature), return, end

            self=self.set_ice_properties(md);
        end

        function rho_ice=getSurfaceRhoIce(self, md)
            %getSurfaceRhoIce-Returns the average of temperature dependent
            %density of all the elements in the mesh making up the top most
            %unit of ice in a stratified glacier. It receives the model as
            %an input parameter and returns one value.
            %     Usage:
            %      rho_ice=getSurfaceRhoIce(self, md)

            rho_ice1=self.getRhoIce(md.multiIceMesh.iceUnits(md.multiIceMesh.currentIceUnitsCnt).IceType, ...
                md.initialization.temperature(md.mesh.numberofvertices-md.mesh.numberofvertices2d+1:end));
            rho_ice=mean(rho_ice1);
        end

        function rho_ice=getRhoIce(self, iceType, T)
            %getRhoIce - Finds the density of a point with a certain
            %material type, and, optionally, the temperature (or a list of
            %temperatures).
            %
            %  This can use one value for T, and return one density, or get
            %  an array of temperatures and return the corresponding array
            %  of densities. If a temperature value is not provided, a
            %  constant value will be returned. 
            %      Usage:
            %        rhoIce = getRhoIce(iceType, Temperature);
            %          

            %NOTE This assumes all materials other than water ice will have
            %a temperature dependent Rho. If not, update this. 
            if  ~exist('T','var') || any(isnan(T))
                rho_ice= self.allMaterialTypes(self.allMaterialTypes (:,1)==iceType,mat_consts.Rho_Ice);
            else
                rho_ice=matProperty(self, mat_consts.Rho_Ice, iceType, T);
            end
        end

        function rho_ice=getUnitRhoIce(self, md, UnitID)
            %getUnitRhoIce - Finds the average density of a unit of ice 
            %
            %      Usage:
            %        rhoIce = getUnitRhoIce(Model, ModelUnitID);
            %
            [s, end1]=md.multiIceMesh.getUnitVerticesRange(UnitID, md);
            rho_ice1=self.getRhoIce(md.multiIceMesh.iceUnits(UnitID).IceType, md.initialization.temperature(s:end1));
            rho_ice=mean(rho_ice1);
        end

        function rho_ice=getUnitRhoIceList(self, md, UnitID)
            %getUnitRhoIceList - Returns a list of densities of vertices of a
            %certain unit of ice in a model
            %      Usage:
            %        rhoIce = getUnitRhoIceList(model, model_unit_ID);
            %
            [s, end1]=md.multiIceMesh.getUnitVerticesRange(UnitID, md);
            rho_ice=self.getRhoIce(md.multiIceMesh.iceUnits(UnitID).IceType, md.initialization.temperature(s:end1));
        end

        function rho_ice=getMeanRhoIce(self, iceType, T)
            %getMeanRhoIce - Finds the average densities of a series of points with a certain
            %material types, and optionally the temperature (or a list of temperatures)
            %
            %  This can use one value for T, and return one density, or get
            %  an array of temperatures and return the corresponding array
            %  of densities. If a temperature is not provided, then a
            %  constant density value for the specified iceType will be
            %  returned. 
            %  The output of this function is one number. 
            %      Usage:
            %        rhoIce = getRhoIce(iceType, Temperature);
            %
            rho_ice1=self.getRhoIce(iceType, T); 
            rho_ice=mean(rho_ice1);
        end
        
        function flowLawList=getIceFlowLaws_4Elements_InIceLayer(~, A_List, Q_List, T_List, n_List)

            %FUTURE IMPLEMENTATION:  add the laws for other flows here.

            % Arrhenius Law
            Rg=8.3144598;       % J mol^-1 K^-1
            A=A_List.*exp((-1.*Q_List)./(Rg*T_List));% s^-1 MPa
            flowLawList=(A.^(-1./n_List))*1e6; % s^(1/n) P

        end
        
        function property=matProperty(self, propertyCONST, iceType, T)
            %matProperty - Finds the material property of a point with a certain
            %material type, and optionally the temperature (or a list of
            %temperatures)
            %
            %  This can use one value for T, and return one property, or get
            %  an array of temperatures and return the corresponding array
            %  of properties. If a temperature is not provided, then a
            %  constant value for the specified iceType will be
            %  returned. Best to use this instead of getRho functions
            %  unless needed an appropriate variation
            %      Usage:
            %        property = matProperty(ConstForPropertyName, IceType, Temperature);
            %

            if ~exist('T','var')
                property= self.allMaterialTypes(self.allMaterialTypes (:,1)==iceType,propertyCONST);
                return
            end

            if propertyCONST==mat_consts.LatentHeat   || propertyCONST==mat_consts.ThermalConductivity || ...
               propertyCONST==mat_consts.HeatCapacity || propertyCONST==mat_consts.Rho_Ice || propertyCONST==mat_consts.Q || ...
               propertyCONST==mat_consts.A_const      || propertyCONST==mat_consts.Rheology_n
                   count=length(T);
                   T1=ceil(T*100);
                 
                   if iceType==mat_consts.H2O
                       propTable=self.propTable_H2O;
                   elseif iceType==mat_consts.CO2
                       propTable=self.propTable_CO2;
                   elseif iceType==mat_consts.N2
                       propTable=self.propTable_N2;
                   end

                   %what column in proptable to read?
                   columnNbr=-1;
                   switch propertyCONST
                       case {mat_consts.LatentHeat, mat_consts.ThermalConductivity, mat_consts.HeatCapacity, mat_consts.Rho_Ice}
                           columnNbr=propertyCONST;
                       case mat_consts.Rheology_n
                            columnNbr=6;
                       case mat_consts.A_const
                           columnNbr=7;
                       case mat_consts.Q
                           columnNbr=8;
                   end


                   if count>1 
                      [~,c] = ismember(T1, propTable);
                      property=propTable(c, columnNbr);
                   else
                      property=propTable(propTable(:,1)==T1, columnNbr);
                   end     
            else 
                property=convert1Prop2List(self, iceType, propertyCONST, length(T));
            end 
        end
        
        function property=convert1Prop2List(self, iceType, propertyCONST, L)
            property= self.allMaterialTypes(self.allMaterialTypes (:,1)==iceType,propertyCONST);
            if L>1
                property=property*ones(L,1);
            end
        end

        function propertyList=MatPropLst4Vertices(self, md, propertyCONST)
            %MatPropLst4Vertices - Returns the list of the material property 
            %of all vertices in a model 
            %
            %      Usage:
            %        propertyList = MatPropLst4Vertices(Model, ConstForPropertyName);
            %

            propertyList=[];
            for i=1:md.multiIceMesh.currentIceUnitsCnt
                vertices=md.multiIceMesh.getUnitAllVertices(i,md);
                T=md.initialization.temperature(vertices);
                propertyList=[propertyList; self.matProperty(propertyCONST, md.multiIceMesh.iceUnits(i).IceType, T)];
            end            
        end

        function propertyList=matPropLst4ElmntRange(self, md, propertyCONST,iceType, elementID_s)
            %matPropLst4ElmntRange - Returns one or the list of the material 
            %property for one element or a range of elements in form of 
            %first_element_inrange:last_element_in_range 
            %
            %      Usage:
            %        propertyList = matPropLst4ElmntRange(Model, ConstForPropertyName, iceType, RangeOfElements);
            
            T=meshmulti_Ice.getElementTemperature(md, elementID_s);
            propertyList=matProperty(self, propertyCONST, iceType, T);
        end

		function self = extrude(self,md)  
            if length(self.rheology_B)==1
                self.rheology_B=self.rheology_B*ones(md.mesh.numberofelements2d,1);
            end
            self.rheology_B=project3d(md,'vector',self.rheology_B,'type','element');
           % end
            if length(self.rheology_n)==1
                self.rheology_n=self.rheology_n*ones(md.mesh.numberofelements2d,1);
            end
            self.rheology_n=project3d(md,'vector',self.rheology_n,'type','element');
		end  

        function marshall(self,prefix,md,fid)  
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','earth_density','format','Double');
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','type','format','Integer');
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','allMaterialTypes','format','DoubleMat','mattype',2);
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','densities','format','DoubleMat','mattype',2);
           
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','rho_ice','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','rho_water','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','rho_freshwater','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','mu_water','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','heatcapacity','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','latentheat','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','thermalconductivity','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','temperateiceconductivity','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','effectiveconductivity_averaging','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','meltingpoint','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','beta','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','mixed_layer_capacity','format','DoubleMat','mattype',2);
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','thermal_exchange_velocity','format','DoubleMat','mattype',2);
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','rheology_law','format','DoubleMat','mattype',2);
            WriteData(fid,prefix,'object',self,'class','materials','fieldname','rheology_n','format','DoubleMat','mattype',2);

            if(size(self.rheology_B,1)==md.mesh.numberofvertices || size(self.rheology_B,1)==md.mesh.numberofvertices+1 || (size(self.rheology_B,1)==md.mesh.numberofelements && size(self.rheology_B,2)>1))
                mattype=1; tsl = md.mesh.numberofvertices;
            else
                mattype=2; tsl = md.mesh.numberofelements;
            end
			WriteData(fid,prefix,'object',self,'class','materials','fieldname','rheology_B','format','DoubleMat','mattype',mattype,'timeserieslength',tsl+1,'yts',md.constants.yts);

        end %marshall


        function md = checkconsistency(~,md,solution,~) % {{{

			if strcmpi(solution,'TransientSolution') && md.transient.isslc
				md = checkfield(md,'fieldname','materials.earth_density','>',0,'numel',1);
			else
			% removed rho_water, B, and effectiveconductivity_averaging as
            % these are now vectors and the check consistency expected them
            % to be scalar values
				md = checkfield(md,'fieldname','materials.rho_water','>',0);
				md = checkfield(md,'fieldname','materials.rho_freshwater','>',0);
				md = checkfield(md,'fieldname','materials.mu_water','>',0);
				md = checkfield(md,'fieldname','materials.rheology_B','>',0,'universal',1,'NaN',1,'Inf',1);
				md = checkfield(md,'fieldname','materials.rheology_n','>',0,'universal',1,'NaN',1,'Inf',1);
			end

		end  
    end

    methods(Access=private)
        function self=set_ice_properties(self, md)  
            self.Rho_ice_List                   =[];            self.rho_water                      =[];
            self.rho_freshwater                 =[];            self.mu_water                       =[];
            self.heatcapacity                   =[];            self.latentheat                     =[];
            self.thermalconductivity            =[];            self.temperateiceconductivity       =[];
            self.effectiveconductivity_averaging=[];            self.meltingpoint                   =[];
            self.beta                           =[];            self.mixed_layer_capacity           =[];
            self.thermal_exchange_velocity      =[];            self.rheology_n                     =[];
            self.rheology_law                   =[];            self.rheology_B                     =[];
            temperature=md.initialization.temperature;
 
            for idx=1:md.multiIceMesh.currentIceUnitsCnt
                startE=md.multiIceMesh.iceUnits(idx).startingElementID;
                endE=md.multiIceMesh.iceUnits(idx).endingElementID;
                iceType=md.multiIceMesh.iceUnits(idx).IceType;

                self.Rho_ice_List                   =[self.Rho_ice_List;                self.matPropLst4ElmntRange(md, mat_consts.Rho_Ice, iceType, startE:endE)];
                self.rho_water                      =[self.rho_water;                   self.matPropLst4ElmntRange(md, mat_consts.Rho_OceanWater, iceType, startE:endE)];
                self.rho_freshwater                 =[self.rho_freshwater;              self.matPropLst4ElmntRange(md, mat_consts.Rho_FreshWater, iceType, startE:endE)];
                self.mu_water                       =[self.mu_water;                    self.matPropLst4ElmntRange(md, mat_consts.Mu_IceCompoenent, iceType, startE:endE)];
                self.heatcapacity                   =[self.heatcapacity;                self.matPropLst4ElmntRange(md, mat_consts.HeatCapacity, iceType, startE:endE)];
                self.latentheat                     =[self.latentheat;                  self.matPropLst4ElmntRange(md, mat_consts.LatentHeat, iceType, startE:endE)];
                self.thermalconductivity            =[self.thermalconductivity;         self.matPropLst4ElmntRange(md, mat_consts.ThermalConductivity, iceType, startE:endE)];
                self.temperateiceconductivity       =[self.temperateiceconductivity;    self.matPropLst4ElmntRange(md, mat_consts.TemperateIceConductivity, iceType, startE:endE)];
                self.effectiveconductivity_averaging=[self.effectiveconductivity_averaging;self.matPropLst4ElmntRange(md, mat_consts.EffectiveConductivity_Averaging, iceType, startE:endE)];
                self.meltingpoint                   =[self.meltingpoint;                self.matPropLst4ElmntRange(md, mat_consts.MeltingPoint, iceType, startE:endE)];
                self.beta                           =[self.beta;                        self.matPropLst4ElmntRange(md, mat_consts.Beta, iceType, startE:endE)];
                self.mixed_layer_capacity           =[self.mixed_layer_capacity;        self.matPropLst4ElmntRange(md, mat_consts.Mixed_Layer_Capacity, iceType, startE:endE)];
                self.thermal_exchange_velocity      =[self.thermal_exchange_velocity;   self.matPropLst4ElmntRange(md, mat_consts.Thermal_Exchange_Velocity, iceType, startE:endE)];
                rheology_n                          = matPropLst4ElmntRange(self, md, mat_consts.Rheology_n, iceType, startE:endE);
                rheology_Aconst                     = matPropLst4ElmntRange(self, md, mat_consts.A_const, iceType, startE:endE);
                rheology_Q                          = matPropLst4ElmntRange(self, md, mat_consts.Q, iceType, startE:endE);         
                self.rheology_n                     =[self.rheology_n;                  rheology_n];
                self.rheology_law                   =[self.rheology_law;                self.matPropLst4ElmntRange(md, mat_consts.Rheology_Law, iceType, startE:endE)];

                tempMat=ones(endE-startE+1, 5); %placeholder with 5 cols for rheology_B
                %get all the temperature of all elements 
                counter=1;   
                for jdx=md.multiIceMesh.iceUnits(idx).startingElementID: md.multiIceMesh.iceUnits(idx).endingElementID
                    %use the average temperature of all the nodes making up
                    %the element to find the B for that element.
                    tempMat(counter,1)=mean(temperature(md.mesh.elements(jdx,:)));
                    counter=counter+1;
                end
                %get the n, A and Qs and make them into a list 
                tempMat(:,2)=iceType.*tempMat(:,2);
                tempMat(:,3)=rheology_n;
                tempMat(:,4)=rheology_Aconst; 
                tempMat(:,5)=rheology_Q;
                %use the lists built above to get the Bs per element, per ice Type
                self.rheology_B=[self.rheology_B; getIceFlowLaws_4Elements_InIceLayer(self,  tempMat(:,4), tempMat(:,5), tempMat(:,1), tempMat(:,3))];
            end

            self.densities=self.MatPropLst4Vertices(md, mat_consts.Rho_Ice); % this is only being used by StressbalanceAnalysis::CreateMultiIceConstraints in the solver
            %note that everything is going to the solver as element based,
            %but density is vertices based, as StressbalanceAnalysis needs
            %it vertix based. 

            %doing a control check on the temperatures...

            for idx1=1:size(self.allMaterialTypes,1)
                currentIceType=self.allMaterialTypes(idx1,1);
                temp1=tempMat(tempMat(:,2)==currentIceType,:);
                unitMeltingPoint=self.matProperty(mat_consts.MeltingPoint, currentIceType, 273); %melting point is temperature independent

                if (any(temp1(:,1)>unitMeltingPoint&temp1(:,1)<(unitMeltingPoint*1.1)))
                    fprintf('%s ICE - POSSIBLE MELTING. Some temperature values are between %iK and %iK.\nLook at indexes: %s\n',...
                        currentIceType, unitMeltingPoint, unitMeltingPoint*1.1, mat2str(find(tempMat(:,1)>(unitMeltingPoint) & tempMat(:,1)<(unitMeltingPoint*1.1)))');
                elseif (any(temp1(:,1)>=(unitMeltingPoint*1.1)))
                    fprintf('%s ICE - GUARANTEED MELTING. Some temperature values are beyond %iK.\nLook at indexes: %s\n',...
                        currentIceType, unitMeltingPoint*1.1, mat2str(find(tempMat(:,1)>(unitMeltingPoint) & tempMat(:,1)<(unitMeltingPoint*1.1)))');
                end
            end

            % to maintain compatibility with the old code, we need these,
            % but before going to the backend, the vectors will replace the
            % scalar values
            self.rho_ice=self.Rho_ice_List(1);
        end
        
        function self=setSingularPorperties(self, md, iceType)  %, factor, temperature)

            factor=ones(md.mesh.numberofelements,1);
            temperature=md.initialization.temperature;
            temp=self.allMaterialTypes(self.allMaterialTypes  (:,1)==iceType,:)';
            if isempty(temp), temp =[9999, 2094, 2094,2094,2094,2094,2094,2094,2094,2094,2094,2094,2094,2094,2094]; end

            %setup properties vertex based...but one ;)
            self.rho_ice                   = temp(2);    self.rho_water                = temp(3);
            self.rho_freshwater            = temp(4);    self.mu_water                 = temp(5);
            self.heatcapacity              = temp(6);    self.latentheat               = temp(7);
            self.thermalconductivity       = temp(8);    self.temperateiceconductivity = temp(9);
            self.thermal_exchange_velocity = temp(10);   self.meltingpoint             = temp(11);
            self.beta                      = temp(12);   self.mixed_layer_capacity     = temp(13);
            self.effectiveconductivity_averaging = temp(14);
            self.rheology_n                = temp(15)*factor;
            self.rheology_law              = mat_consts.getRheology_Law(iceType);
            self.densities                 = temp(2);

            % and here is the last one - rheology B that needs to be
            % element based
            tempMat=zeros(md.mesh.numberofelements, 5); %placeholder with 4 cols
            for jdx=1:md.mesh.numberofelements
                tempMat(jdx,1)=mean(temperature(md.mesh.elements(jdx,:)));
                tempMat(jdx,2)=iceType;
                tempMat(jdx,3)=temp(15);
                tempMat(jdx,4)=self.allMaterialTypes(self.allMaterialTypes (:,1)==iceType,17);%placeholders for A_consts
                tempMat(jdx,5)=self.allMaterialTypes(self.allMaterialTypes (:,1)==iceType,18);%placeholders for Qs

            end

            self.rheology_B=getIceFlowLaws_4Elements_InIceLayer(self,  tempMat(:,4), tempMat(:,5), tempMat(:,1), tempMat(:,3));
        end
    end

    methods (Static)
     
        function pressure = multiUnitPressure_In3D(md)
            %totalUnitsPressure - Finds the pressure on every node in the
            %current stratified ice Model
            %
            %  This function reads the available units, and starting from the
            %  top unit calculates the pressure on every node.
            %      Usage:
            %        totalPressure = multiUnitInitializationPressure_In3D(modelName);
            %

            %we are in 3D, therefore, at the very top
            pressure = zeros(md.mesh.numberofvertices,1);
           
            for j=1:md.multiIceMesh.currentIceUnitsCnt 
                Cnst_Rho_G=md.materials.getRhoIce(md.multiIceMesh.iceUnits(j).IceType, 170);
                [s, finalVertex]=md.multiIceMesh.getUnitVerticesRange(j, md);

                 surfaces=repmat(md.multiIceMesh.iceUnits(j).Surface, md.multiIceMesh.iceUnits(j).NmbLayers,1);
                 vertexHeight_G=md.constants.g.*(surfaces - md.mesh.z(s:finalVertex));
                 if any(isnan(md.initialization.temperature))
                        pressure(s:finalVertex)=Cnst_Rho_G.*vertexHeight_G;
                 else
                    try
                        pressure(s:finalVertex)=...
                            (md.materials.getRhoIce(md.multiIceMesh.iceUnits(j).IceType,...
                                    md.initialization.temperature(s:finalVertex))).*vertexHeight_G;
                    catch
                        pressure(s:finalVertex)=Cnst_Rho_G.*vertexHeight_G;
                    end
                 end

            end

            if md.multiIceMesh.currentIceUnitsCnt>1
                for idx=md.multiIceMesh.currentIceUnitsCnt:-1:2
                    %pressure in the base of the top unit
                    v=md.multiIceMesh.getUnitBaseVertices(idx, md);
                    vertices=unique(sort(v(:)));
                    p=pressure(vertices);

                    %augment the pressure in every node in the unit below
                    %with the pressure in the base of the top unit
                    v=md.multiIceMesh.getUnitAllVertices(idx-1, md);
                    vertices=unique(sort(v(:)));
                    p=repmat(p, md.multiIceMesh.iceUnits(idx-1).NmbLayers,1);
                    pressure(vertices)=pressure(vertices)+p;
                end
            end

        end

        function rheology_law=getRheology_Law(iceType)
            switch (iceType)
                case mat_consts.H2O
                    rheology_law      = mat_consts.NyeH2O;
                case mat_consts.CO2
                    rheology_law     = mat_consts.NyeCO2;
                case mat_consts.CO
                    rheology_law     = mat_consts.NyeCO;
                case mat_consts.N2
                    rheology_law      = mat_consts.NyeN2;
                case mat_consts.CH4
                    rheology_law      = mat_consts.NyeCH4;
                case mat_consts.H2O_DUST
                    rheology_law      = mat_consts.NyeH2O_DUST;
                case mat_consts.MAT1
                    rheology_law      = mat_consts.NyeMAT1;
                case mat_consts.MAT2
                    rheology_law      = mat_consts.NyeMAT2;
                case mat_consts.MAT3
                    rheology_law     = mat_consts.NyeMAT3;
                case mat_consts.ROCK
                    rheology_law      = mat_consts.NyeROCK;
                otherwise
                    rheology_law      = mat_consts.NyeH2O;

            end %switch iceCompound
        end

        function rheology_lawCode=getRheology_LawCode(iceType)
            switch (iceType)
                case mat_consts.H2O
                    rheology_lawCode      = 8;
                case mat_consts.CO2
                    rheology_lawCode      = 7;
                case mat_consts.CO
                    rheology_lawCode      = 9;
                case mat_consts.N2
                    rheology_lawCode      = 10;
                case mat_consts.CH4
                    rheology_lawCode      = 11;
                case mat_consts.H2O_DUST
                    rheology_lawCode      = 12;
                case mat_consts.ROCK
                    rheology_lawCode      = 13;
                otherwise
                    rheology_lawCode = 8; % that of H2O
            end  
        end

        function iceUnitName=convertIceCode2Name(iceType)
            switch iceType
                case mat_consts.CO2
                    iceUnitName = 'CO2';
                case mat_consts.H2O
                    iceUnitName = 'H2O';
                case mat_consts.N2
                    iceUnitName = 'N2';
                case mat_consts.CO
                    iceUnitName = 'CO';
                case mat_consts.CH4
                    iceUnitName = 'CH4';
                case mat_consts.H2O_DUST
                    iceUnitName = 'H2O_DUST';
                case mat_consts.ROCK
                    iceUnitName = 'ROCK';
                case mat_consts.MAT1
                    iceUnitName = 'MAT1';
                case mat_consts.MAT2
                    iceUnitName = 'MAT2';
                case mat_consts.MAT3
                    iceUnitName = 'MAT3';
               
            end
        end
  
    end

end

