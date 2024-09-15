%KAsra
% #define _IS_MULTI_ICE_
classdef meshmulti_Ice
    
    properties (Access=public)
        currentPeriodThickness = 0; %holds the value that is being added to the thickness in this period.
        numberOfElementsIn2D = 0;
        numberOfVerticesIn2D = 0;
        extrusionlist=[];
        periodSMB=0;      %this is a placeholder to carry the smbs for plotting purposes. if it is not set correctly the MassVolume_Changes_Accumulative will not show the correct SMB value
        domainArea = -1;  %[m^2]

        min_numLayers        = 7; %while numLayers is the total number of layers in a model, this is the esitmated min number of layers.
        
        currentIceUnitsCnt   =  0;  %Shows the current number of physical ice units in the model
        iceUnits             = [];
        
        isModel3D      = false;
        impactedUnit   = -1; %this is the unit that has received deposition or gone through sublimation
        onlyAdjustImpactedUnit      = true; %if set the change in height (after transientRun) will only be implemented on the impacted unit; vs. entire model
    end    
    
    methods
        function self=registerNbrLayers(self, minNumLayers)
            self.min_numLayers = minNumLayers;
        end
        
        function cnt=get.currentIceUnitsCnt(obj)
            cnt=length(obj.iceUnits);
        end
   
        function [UID, iceType]=getElementIceType_UnitID(self,elementID)
            %GETELEMENTICETYPE_UNITID returns the unit id and the ice type of an element using the element id
            %USAGE
            %      [UID, iceType]=md.meshmulti_ice.getElementIceType_UnitID(elementID)
            UID=-1; iceType=-1;
            for idx=1:self.currentIceUnitsCnt
                unit=self.iceUnits(idx);
                if elementID>=unit.startingElementID && elementID<=unit.endingElementID
                    iceType=unit.IceType;
                    UID=unit.ID;
                    return
                end
            end
        end
        
        function [UID, iceType]=getVertexIceType_UnitID(self,vertexID, md)
            %GETVERTEXICETYPE_UNITID returns the unit id and the ice type of a vertex using the vertex id
            %USAGE
            %      [UID, iceType]=md.meshmulti_ice.getVertexIceType_UnitID(vertexID)
            %NOTE: This assumes that lower vertices are in the unit; and upper
            %vertices are part of the upper unit
            UID=-1; iceType=-1;
            
            for i=1:3
                elementID=find(md.mesh.elements(:, i)==vertexID);
                for ii=1:length(elementID)
                    [UID, iceType]=getElementIceType_UnitID(self, elementID(ii));
                    return
                end
            end
        end
        
        function [UID, iceType]=getZIceType_UnitID(self,meshZ, md)
            vertexID= find(abs(md.mesh.z(:)-meshZ)<0.02);
            [UID, iceType]=getVertexIceType_UnitID(self,vertexID);
        end
        
        function v=getUnitBaseElements(~, UID, md)
            %GETUNITBASEELEMENTS returns all the elements in the base of a unit
            %USAGE
            %     md.meshmulti_IceType.getUnitBaseElements(UID, md);
            unit=md.multiIceMesh.iceUnits(UID);
            elements=unit.startingElementID:unit.startingElementID+md.mesh.numberofelements2d-1;
            v=md.mesh.elements(elements',:);
            
        end
        
        function unitElements=getUnitAllElements(~, UID, md)
            try
                unitElements=md.mesh.elements(md.multiIceMesh.iceUnits(UID).startingElementID:md.multiIceMesh.iceUnits(UID).endingElementID, :);
            catch ME
                disp (ME);
                error('error happened');
            end
        end
        
        function v=getUnitSurfaceElements(~, UID, md)
            %GETUNITSURFACEELEMENTS returns all the elements in the base of a unit
            %USAGE
            %     md.meshmulti_IceType.getUnitSurfaceElements(UID, md);
            unit=md.multiIceMesh.iceUnits(UID);
            elements=(unit.endingElementID-md.mesh.numberofelements2d+1):unit.endingElementID;
            v=md.mesh.elements(elements',:);
            
        end

        function unitVertices=getUnitAllVertices(~, UID, md)
            unitElements= md.multiIceMesh.getUnitAllElements(UID, md);
            unitVertices=(sort(unique(unitElements)));
        end        
       
        function v=getUnitBaseVertices(~, UID,md)
            v=md.multiIceMesh.getUnitBaseElements(UID, md);
            v=v(:,1:3);
            v=sort(unique((v(1:end))));
        end
        
        function v=getUnitSurfaceVertices(~, UID,md)
            v=md.multiIceMesh.getUnitSurfaceElements(UID, md);
            v=v(:,4:6);
            v=sort(unique((v(1:end))));
        end
        
        function [first, last]=getUnitVerticesRange(~, UID, md)
            unitVertices=md.multiIceMesh.getUnitAllVertices(UID, md);
            first=min(unitVertices);
            last=max(unitVertices);
        end
          
        function md=addNewUnit(~, md, tempUnit)
            unitPos=md.multiIceMesh.currentIceUnitsCnt;
            threshold=md.settings.thickness_minThreshld;
            %TODO next line should be mean(..currentperiodthickness); but I
            %am assuming it is all the same for performance
            md.multiIceMesh.periodSMB=(md.multiIceMesh.currentPeriodThickness(1))/md.settings.output_frequency;%mean(md.mu  /(timespan/md.settings.output_frequency);  %% KK
            newUnit=false;
            if unitPos<=1
                threshold=md.settings.thickness_firstIceUnit_threshold;
            else
                if md.multiIceMesh.iceUnits(unitPos).IceType~=tempUnit.IceType && any(tempUnit.Thickness<0)
                    if md.multiIceMesh.iceUnits(unitPos-1).IceType~=tempUnit.IceType || unitPos<2
                        error('no appropriate unit to apply sublimation to... Sublimation is to be applied to the unit immediately below the surface unit');
                    end
                    unitPos=unitPos-1;
                end
            end
            if unitPos==0 || (md.multiIceMesh.iceUnits(unitPos).IceType~=tempUnit.IceType && ~any(tempUnit.Thickness<0))
                newUnit=true;
            end

            if ~newUnit %//2
                md.multiIceMesh.iceUnits(unitPos).Thickness=md.multiIceMesh.iceUnits(unitPos).Thickness+tempUnit.Thickness;
                md.multiIceMesh.iceUnits(unitPos).Surface=md.multiIceMesh.iceUnits(unitPos).Thickness+md.multiIceMesh.iceUnits(unitPos).Bed;
                md.multiIceMesh.impactedUnit = unitPos;
            else
                tempUnit.Thickness(tempUnit.Thickness==0)=threshold;
                if tempUnit.Thickness(1)>0
                    md.multiIceMesh.iceUnits = [md.multiIceMesh.iceUnits; tempUnit];
                    md.multiIceMesh.impactedUnit = md.multiIceMesh.currentIceUnitsCnt;
                else
                    md.multiIceMesh.impactedUnit =-1;
                    return
                end
            end

            md=md.collapse();
            %if any thickness is less than threshold, set it to the threshold and reconstruct the unit
            for a=1: md.multiIceMesh.currentIceUnitsCnt
                md.multiIceMesh.iceUnits(a).Thickness(md.multiIceMesh.iceUnits(a).Thickness<threshold)=threshold;
                md.multiIceMesh.iceUnits(a).Surface=md.multiIceMesh.iceUnits(a).Thickness+md.multiIceMesh.iceUnits(a).Bed;
                if a<md.multiIceMesh.currentIceUnitsCnt
                    md.multiIceMesh.iceUnits(a+1).Bed=md.multiIceMesh.iceUnits(a).Surface;
                end
            end

            %MERGE!
            if md.multiIceMesh.currentIceUnitsCnt >=3 %If 3 units or more
                for k=md.multiIceMesh.currentIceUnitsCnt:-1:3
                    if  ((k-2>0) &&  (md.multiIceMesh.iceUnits(k).IceType==md.multiIceMesh.iceUnits(k-2).IceType ))
                        M=find(md.multiIceMesh.iceUnits(k-1).Thickness<=threshold); %   the find all nodes where the unit blow has 0 thickness
                        if ~isempty(M)
                            % For those points, remove the thickness in the
                            % top unit. Add it to the below unit.
                            md.multiIceMesh.iceUnits(k-2).Thickness(M)= md.multiIceMesh.iceUnits(k-2).Thickness(M)+ md.multiIceMesh.iceUnits(k).Thickness(M);
                            % the top unit and the middle unit will now
                            % have the minimum threshold thickness. 
                            md.multiIceMesh.iceUnits(k-1).Thickness(M)=threshold*1.0001;%    
                            md.multiIceMesh.iceUnits(k).Thickness(M)=threshold*1.0001;%         
                        end
                    end
                end
            end

            %TODO check extrusion func for any nodes being zero.

            %if we are using SMBs clean up and leave
            if md.materials.useSMB
                if newUnit, md=md.multiIceMesh.setUnits_Elements(md, true);end
                md=md.extrudeModel(2);
                %we are using smbs, so do not modify the geometry.
                return
            end

            %now setup the geometry: here we are going through the units
            %and their dimentions to double check and fix any issues
            s=md.multiIceMesh.iceUnits(end).Surface;
            b=md.multiIceMesh.iceUnits(1).Bed;

            temp_thickness=s-b;
            temp_thickness(temp_thickness<threshold)=threshold; %%0.5;%%
            md.geometry.surface =b+temp_thickness;
            md.geometry.bed=b;
            md.geometry.base=b;
            md.geometry.thickness = temp_thickness;

            %fix the last units based on the geometry
            md.multiIceMesh.iceUnits(end).Surface=md.geometry.surface(1:length(md.multiIceMesh.iceUnits(end).Surface));
            md.multiIceMesh.iceUnits(end).Thickness=md.multiIceMesh.iceUnits(end).Surface-md.multiIceMesh.iceUnits(end).Bed;

            if newUnit, md=md.multiIceMesh.setUnits_Elements(md, md.multiIceMesh.currentIceUnitsCnt<2); end

            md=md.extrudeModel(2);
            md.initialization.pressure=md.materials.multiUnitPressure_In3D(md);
            md.smb.mass_balance=zeros(md.mesh.numberofvertices, 1);
        end

        function disp(self)
            disp(sprintf('   multiIceMesh:')); %#ok<*DSPS> 
            fielddisplay(self,'numberOfElementsIn2D','Number Of Elements In 2D');
            fielddisplay(self,'numberOfVerticesIn2D','Number Of Vertices In 2D');
            fielddisplay(self,'extrusionlist','Extrusion Factors List');
            fielddisplay(self,'min_numLayers','Minimum alloable Number of Layers in the Model');
            fielddisplay(self,'currentIceUnitsCnt','Number Of Units in the Model');
            fielddisplay(self,'iceUnits','Ice Units structs');
            fielddisplay(self,'isModel3D','Returns True if the Model is Extruded');
            fielddisplay(self,'impactedUnit','ID of the Unit that was Just Updated/Adjusted');
        end %display       

        function md=setUnits_Elements(~, md, force_it)
            if md.multiIceMesh.currentIceUnitsCnt<1, error('add a unit before trying to register elements'); end
            oldMesh=md.multiIceMesh;
            md.multiIceMesh=md.multiIceMesh.setNumberOfLayers();  %new or not, the numlayers will need to be redone
            for idx=1:md.multiIceMesh.currentIceUnitsCnt
                if md.multiIceMesh.iceUnits(idx).NmbLayers~=oldMesh.iceUnits(idx).NmbLayers || force_it%let's rebuild the elements structure
                    if md.multiIceMesh.isModel3D, md=md.collapse(); end
                    E=md.mesh.numberofelements;
                    for UID=1:md.multiIceMesh.currentIceUnitsCnt
                        numblayer=md.multiIceMesh.iceUnits(UID).NmbLayers - 1;
                        md.multiIceMesh.iceUnits(UID).startingElementID=1;
                        if UID~=1, md.multiIceMesh.iceUnits(UID).startingElementID=md.multiIceMesh.iceUnits(UID-1).endingElementID+1;end
                        md.multiIceMesh.iceUnits(UID).endingElementID=md.multiIceMesh.iceUnits(UID).startingElementID+E*numblayer-1;

                        %[unitID, starting ElementID, ending elementID,iceType] ; the starting and ending ids are inclusive.
                        md.multiIceMesh.iceUnits(UID).unitLowerElements=[UID, md.multiIceMesh.iceUnits(UID).startingElementID,   md.multiIceMesh.iceUnits(UID).startingElementID+E-1];
                        md.multiIceMesh.iceUnits(UID).unitUpperElements=[UID, md.multiIceMesh.iceUnits(UID).endingElementID-E+1, md.multiIceMesh.iceUnits(UID).endingElementID];
                    end
                    break; %get out of here! end it!
                end
            end
        end %reconstruct UnitsMesh
    
        function md=reconstruct_IceUnitsMesh(~, md)
            if md.multiIceMesh.currentIceUnitsCnt<1, error('add a unit before trying to register elements'); end
            if ~md.multiIceMesh.isModel3D, error('You will need a 3D mesh to do this. Best to do this right after solver has solved a 3D mesh'); end

            % setup the start and end element IDs
            %[unitID, starting ElementID, ending elementID] ; the starting and ending ids are inclusive.
            E=md.mesh.numberofelements2d;
            for UID=1:md.multiIceMesh.currentIceUnitsCnt
                numblayer=md.multiIceMesh.iceUnits(UID).NmbLayers - 1;
                md.multiIceMesh.iceUnits(UID).startingElementID=1;
                if UID~=1, md.multiIceMesh.iceUnits(UID).startingElementID=md.multiIceMesh.iceUnits(UID-1).endingElementID+1;end
                md.multiIceMesh.iceUnits(UID).endingElementID=md.multiIceMesh.iceUnits(UID).startingElementID+E*numblayer-1;

                md.multiIceMesh.iceUnits(UID).unitLowerElements=[UID, md.multiIceMesh.iceUnits(UID).startingElementID,   md.multiIceMesh.iceUnits(UID).startingElementID+E-1];
                md.multiIceMesh.iceUnits(UID).unitUpperElements=[UID, md.multiIceMesh.iceUnits(UID).endingElementID-E+1, md.multiIceMesh.iceUnits(UID).endingElementID];
            end
        
            for UID=1:md.multiIceMesh.currentIceUnitsCnt
                %thickness
                md.multiIceMesh.iceUnits(UID).Thickness=md.mesh.z(md.multiIceMesh.getUnitSurfaceVertices(UID, md)) -  md.mesh.z(md.multiIceMesh.getUnitBaseVertices(UID, md));
                             
                %Bed
                if UID==1
                    md.multiIceMesh.iceUnits(UID).Bed=md.geometry.bed(md.multiIceMesh.getUnitSurfaceVertices(UID, md));
                else
                    md.multiIceMesh.iceUnits(UID).Bed=md.multiIceMesh.iceUnits(UID-1).Surface;
                end
    
                %Surface
                if UID==md.multiIceMesh.currentIceUnitsCnt
                     md.multiIceMesh.iceUnits(UID).Surface=md.geometry.surface(md.multiIceMesh.getUnitSurfaceVertices(UID, md));
                else
                    md.multiIceMesh.iceUnits(UID).Surface=md.multiIceMesh.iceUnits(UID).Bed + md.multiIceMesh.iceUnits(UID).Thickness;
                end
    
            end

        end %reconstruct_IceUnitsMesh


     end       
     methods(Access=private)
        function self=setNumberOfLayers(self)

            %find the current total average height of the ice cap
            myThickness=zeros(length(self.iceUnits(1).Thickness),1);
            for idx=1:self.currentIceUnitsCnt
                myThickness=myThickness+self.iceUnits(idx).Thickness;
            end

            %the current height percentage of average height of each unit
            for idx=1:self.currentIceUnitsCnt
                self.iceUnits(idx).currentHeightPercentage=self.iceUnits(idx).Thickness./myThickness;
                self.iceUnits(idx).currentHeightPercentage(self.iceUnits(idx).currentHeightPercentage<0)=0;
            end

            try
                myThickness=ones(length(self.iceUnits(1).Thickness),1);
                for idx=1:self.currentIceUnitsCnt
                    myThickness=myThickness-self.iceUnits(idx).currentHeightPercentage;
                end

                M=find(myThickness~=0);
                if ~isempty(M)
                    positive_M=(myThickness(M)>0);
                    negative_M=(myThickness(M)<0);
                    %This is very risky - the assumption is that doing this
                    %as per below will set the percentages to 1; TODO - fix
                    %it
                    if ~isempty(positive_M)
                        self.iceUnits(end).currentHeightPercentage(positive_M)= self.iceUnits(end).currentHeightPercentage(positive_M)+myThickness(positive_M);
                    end
                     if ~isempty(negative_M)
                        self.iceUnits(1).currentHeightPercentage(negative_M)= self.iceUnits(1).currentHeightPercentage(negative_M)+myThickness(negative_M);
                    end                   
                end

            catch ME
                disp(ME);
            end
            %the number of layers...each unit can have layers between 
            % settingsmulti_Ice.minNbrLayersInIceUnit (default is 2) and
            % the min_numlayers
            nmLayers=self.min_numLayers;
            %TODO why is this here: 
            if self.currentIceUnitsCnt==2, nmLayers=nmLayers+1; end
            for idx=1:self.currentIceUnitsCnt
                n=ceil(mean(self.iceUnits(idx).currentHeightPercentage)*nmLayers);
                if n<2 %md.settings.minNbrLayersInIceUnit, 
                     n=2 %md.settings.minNbrLayersInIceUnit;
                end %make sure there is a top for the element
                if n>self.min_numLayers, n=self.min_numLayers; end
                self.iceUnits(idx).NmbLayers=n;
            end
            
            %how many layers do we have?
            totalLayers=0;
            for idx=1:self.currentIceUnitsCnt
                totalLayers=totalLayers+self.iceUnits(idx).NmbLayers;
            end
            %  remaining layers; add to the base unit
            if nmLayers>totalLayers, self.iceUnits(1).NmbLayers=self.iceUnits(1).NmbLayers+(nmLayers-totalLayers);end
 
        end
     end

     methods(Static)
         function temperature=getElementTemperature(md, elementID)
             temperature=(md.initialization.temperature(md.mesh.elements(elementID,1))+...
                 md.initialization.temperature(md.mesh.elements(elementID,2))+...
                 md.initialization.temperature(md.mesh.elements(elementID,3))+...
                 md.initialization.temperature(md.mesh.elements(elementID,4))+...
                 md.initialization.temperature(md.mesh.elements(elementID,5))+...
                 md.initialization.temperature(md.mesh.elements(elementID,6)))/6;
         end

     end
end