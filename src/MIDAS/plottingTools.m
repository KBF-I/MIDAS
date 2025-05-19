%% Multi-layered Ice Deposition Modelling - MARS MCID Modelling
%Kasra  March 2021 - March 2022
% #define _IS_MULTI_ICE_
classdef plottingTools

    properties
        runsPath;
        finalModelFilename;
        numblayers;
        %predefined max and min for plotting 
        adjustColorBar=false;
        maxTemperature;         minTemperature;
        minV;          maxV;
        minVx;         maxVx;
        minVy;         maxVy;
        minVz;         maxVz;
        minVel;        maxVel;
        maxThickness;  minThickness;
        view_x;        view_y;
    end

    methods

        function self=plottingTools(runsPath, outputFolder, numberofLayers, Array4Plotting)
            self.runsPath=runsPath;
            self.finalModelFilename=outputFolder;
            self.numblayers=numberofLayers;       

%             [1: time, 2: periodVolume, 3: AccumativeVolume, 4: currenPeriodMass, 5: AccumulativeMass, 6: periodSMB, 7: AccumulativeSMB, 8: TotalSMB , 9: accumalativeTotalSMB,10: -- , 11 ---
%              12: Max_vx, 13: Max_vy, 14: MAx_vz, 15: Max_vel, 16: Max_Thickness, 17: MAx_Pressure, 18: Max_velocity2d=sqrt(vx^2+vy^2), 19: minvx, 20: minvy, 21: minvz, 22: minvel,23: min_velocity2d,
%              24: minThickness, 25: minPressure, 26: minTemperature, 27: max_Temperature

            if exist('Array4Plotting','var') 
                start1=1;
                end1=size(Array4Plotting,1);
                self.minTemperature=min(Array4Plotting(start1:end1,27));   
                self.maxTemperature=max(Array4Plotting(start1:end1,27));

                self.minV=min(Array4Plotting(start1:end1,23));            %velocity2d=sqrt(vx^2+vy^2)         
                self.maxV=max(Array4Plotting(start1:end1,18)) ;
                
                self.minVx=min(Array4Plotting(start1:end1,19));                    
                self.maxVx=max(Array4Plotting(start1:end1,12));
                
                self.minVy=min(Array4Plotting(start1:end1,20));                    
                self.maxVy=max(Array4Plotting(start1:end1,13));
                
                self.minVz=min(Array4Plotting(start1:end1,21));                    
                self.maxVz=max(Array4Plotting(start1:end1,14));
                
                self.minVel=min(Array4Plotting(start1:end1,22));                                  
                self.maxVel=max(Array4Plotting(start1:end1,15));

                self.minThickness=min(Array4Plotting(start1:end1,16));          
                self.maxThickness=max(Array4Plotting(start1:end1,16));            

                self.adjustColorBar =true;   
            end

             set(gcf,'units','normalized','outerposition',[0 0 1 1]);

        end 
        
        % Boundaries define the scale boundaries for plots. The structure is Boundaries=[minThickness, maxThickness;minVel, maxVel; minTemperature, maxTemperature; minquiver, maxquiver]
        % se -1 in at least x or y of one, to ignore and use max and min from the available data.

        %Use xlim and ylim these to zoom into an area in the plot; use -1 for any one of the 4 numbers to plot the entire domain

        function plots_1(self,md, Array4Plotting, Boundaries, xlim, ylim, quiverScaling, quiverDensity)

            if Boundaries(1,1)~=-1 && Boundaries(1,2)~=-1
                minThicknessBoundary=Boundaries(1,1);   maxThicknessBoundary=Boundaries(1,2);
            else 
                minThicknessBoundary=self.minThickness; maxThicknessBoundary=self.maxThickness;
            end
            if minThicknessBoundary==maxThicknessBoundary, minThicknessBoundary=0; end
            if Boundaries(2,1)~=-1 && Boundaries(2,2)~=-1
                minVelBoundary=Boundaries(2,1);   maxVelBoundary=Boundaries(2,2);
            else 
                minVelBoundary=self.minVel; maxVelBoundary=self.maxVel;
            end
            if minVelBoundary==maxVelBoundary, minVelBoundary=0; end
            if Boundaries(3,1)~=-1 && Boundaries(3,2)~=-1
                minTemperatureBoundary=Boundaries(3,1);   maxTemperatureBoundary=Boundaries(3,2);
            else
                minTemperatureBoundary=self.minTemperature; maxTemperatureBoundary=self.maxTemperature;
            end
            if minTemperatureBoundary==maxTemperatureBoundary, minTemperatureBoundary=0; end
            if Boundaries(4,1)~=-1 && Boundaries(4,2)~=-1
                minQuiverBoundary=Boundaries(4,1);   maxQuiverBoundary=Boundaries(4,2);
            else
                minQuiverBoundary=self.minV; maxQuiverBoundary=self.maxV;
            end
            if minQuiverBoundary==minQuiverBoundary, minQuiverBoundary=0; end




            DrawPlot(self, md, 'Thickness',  false, '[m]'   , [minThicknessBoundary, maxThicknessBoundary], xlim, ylim);
            DrawPlot(self, md, 'Vel',        false, '[m/yr]', [minVelBoundary, maxVelBoundary], xlim, ylim);
            DrawPlot(self, md, 'quiver',     false, '[m/yr]', [minQuiverBoundary, maxQuiverBoundary], xlim, ylim, quiverScaling,quiverDensity);
            DrawPlot(self, md, 'Vel',        false, '[m/yr]', [minQuiverBoundary, maxQuiverBoundary], xlim, ylim);
            DrawPlot(self, md, 'Streamline',        false, ' ', [minVelBoundary, maxVelBoundary], xlim, ylim);
            DrawPlot(self, md, 'Temperature',true,  '[K]'   , [minTemperatureBoundary, maxTemperatureBoundary], xlim, ylim);
            DrawPlot(self, md, 'Surface', false,' ',[3800 5800], xlim, ylim );

            maxplot (self, md, Array4Plotting);
        end

        function DrawPlot(self, md, plotType, isBasal, unit, caxis, xlim, ylim, quiverScaling, quiverDensity)
            if startsWith(plotType, "vel",'IgnoreCase', true)
                plotTitle = sprintf('Velocity (year %0.1d) %s',md.uniqueTransientSolutions(end).time, unit);
            elseif startsWith(plotType, "temp",'IgnoreCase', true)
                plotTitle = sprintf('Basal Temperature (year %0.1d) %s',md.uniqueTransientSolutions(end).time, unit);
            else
                plotTitle = sprintf('%s (year %0.1d) %s',plotType, md.uniqueTransientSolutions(end).time, unit);
            end
            plotFilename = sprintf('%s_3D@%06dyr',plotType, md.uniqueTransientSolutions(end).time);
            plotFilename = [self.finalModelFilename '_' plotFilename];
            
            if startsWith(plotType, "streamline",'IgnoreCase', true)
                md2=collapse(md);  
                plotmodel(md2,'data',md2.uniqueTransientSolutions(end).Vel(1: md2.mesh.numberofvertices),'streamlines',200,'title',plotTitle)%,'caxis',caxis,'xlim', xlim, 'ylim', ylim)
            else
                if ~exist('caxis','var')
                    if startsWith(plotType, "quiver",'IgnoreCase', true)
                        plotTitle = sprintf('Flow (year %0.1d) %s',md.uniqueTransientSolutions(end).time, unit);  
                        plotmodel(md, 'data',sqrt(md.uniqueTransientSolutions(end).Vx^2+ md.uniqueTransientSolutions(end).Vy^2),'title',plotTitle,'scaling', .2,'colorlevels', 700)%, 'density',10,'northarrow','on')
                    else 
                        plotmodel(md, 'data',md.uniqueTransientSolutions(end).(plotType),'title',plotTitle) %,'northarrow','on')
                    end
                else
                    if (xlim(1,1)~=-1 && xlim(1,2)~=-1 && ylim(1,1)~=-1 && ylim(1,2)~=-1)
                        if startsWith(plotType, "quiver",'IgnoreCase', true)
                            %'northarrow',[1*10^4 -3.1*10^5 4500 [.2 100 15]],
                            %TODO Change the density and scaling for quiver here
                            plotTitle = sprintf('Flow (year %0.1d) %s',md.uniqueTransientSolutions(end).time, unit);
                            if (caxis(1,1)~=-1 && caxis(1,2)~=-1)
                                plotmodel(md, 'data',[md.uniqueTransientSolutions(end).Vx md.uniqueTransientSolutions(end).Vy md.uniqueTransientSolutions(end).Vz],'title',plotTitle, 'caxis',caxis,'scaling',quiverScaling, 'density',quiverDensity,'xlim', xlim, 'ylim', ylim,'colorlevels',200);%,'northarrow',[2.2*10^4 -2.88*10^5 4500 [.2 100 15]], 'scaleruler',[2.95*10^4 -2.94*10^5 1000 20 3])
                            else
                                plotmodel(md, 'data',[md.uniqueTransientSolutions(end).Vx md.uniqueTransientSolutions(end).Vy md.uniqueTransientSolutions(end).Vz],'title',plotTitle, 'scaling',quiverScaling, 'density',quiverDensity,'xlim', xlim, 'ylim', ylim)%,'colorlevels',1000);%,'northarrow',[2.2*10^4 -2.88*10^5 4500 [.2 100 15]], 'scaleruler',[2.95*10^4 -2.94*10^5 1000 20 3])
                            end
                        else
                            if (caxis(1,1)~=-1 && caxis(1,2)~=-1)
                                plotmodel(md, 'data',md.uniqueTransientSolutions(end).(plotType),'title',plotTitle,'caxis',caxis,'xlim', xlim, 'ylim', ylim)%, 'colormap', 'jet');%,'northarrow',[2.2*10^4 -2.88*10^5 4500 [.2 100 15]], 'scaleruler',[2.95*10^4 -2.94*10^5 1000 20 3] )
                            else
                                plotmodel(md, 'data',md.uniqueTransientSolutions(end).(plotType),'title',plotTitle,'xlim', xlim, 'ylim', ylim)%, 'colormap', 'jet');%,'northarrow',[2.2*10^4 -2.88*10^5 4500 [.2 100 15]], 'scaleruler',[2.95*10^4 -2.94*10^5 1000 20 3] )
                            end
                        end
                    else
                        if startsWith(plotType, "quiver",'IgnoreCase', true)
                            plotTitle = sprintf('Flow (year %0.1d) %s',md.uniqueTransientSolutions(end).time, unit);
                            if (caxis(1,1)~=-1 && caxis(1,2)~=-1)
                                plotmodel(md, 'data',[md.uniqueTransientSolutions(end).Vx md.uniqueTransientSolutions(end).Vy md.uniqueTransientSolutions(end).Vz],'title',plotTitle, 'caxis',caxis,'scaling',quiverScaling, 'density',quiverDensity,'colorlevels',200 ,'xlim', xlim, 'ylim', ylim)
                            else
                                plotmodel(md, 'data',[md.uniqueTransientSolutions(end).Vx md.uniqueTransientSolutions(end).Vy md.uniqueTransientSolutions(end).Vz],'title',plotTitle, 'scaling',quiverScaling, 'density',quiverDensity ,'xlim', xlim, 'ylim', ylim)
                            end
    
                        else
                            if (caxis(1,1)~=-1 && caxis(1,2)~=-1)
                                plotmodel(md, 'data',md.uniqueTransientSolutions(end).(plotType),'title',plotTitle,'caxis',caxis)
                            else
                                plotmodel(md, 'data',md.uniqueTransientSolutions(end).(plotType),'title',plotTitle)
                            end
                        end
                    end
                end

            end
            factor=1; bottom='';
            if isBasal
                factor=-1;
                bottom='bottom';
            end
      
            view(self.view_x,self.view_y*factor); 
            try
                saveas(gcf,[self.runsPath self.finalModelFilename '/Figs/' plotType '/' plotFilename '.fig']);
            catch
                saveas(gcf,[self.runsPath self.finalModelFilename '/Figs/'  plotFilename '.fig']);
            end
            pause(5)
            plotFilename = sprintf('%s%s2D@%06dyr',bottom,plotType,md.uniqueTransientSolutions(end).time);
            plotFilename = [self.finalModelFilename '_' plotFilename];
            view(self.view_x,self.view_y*factor)
            try
                saveas(gcf,[self.runsPath self.finalModelFilename '/Plots/' plotType '/' plotFilename '.jpg']);
            catch
                saveas(gcf,[self.runsPath self.finalModelFilename '/Plots/' plotFilename '.jpg']);
            end
            pause(5)

      
        end

        function plots_2(self, timeVector,iceVolumeVector, deltaVolumeLogTextFile,minThickVector,massVector, ...
                volumeLogTextFile, thickThresholdLogTextFile, Array4Plotting, md)

            if length(timeVector)~=length(iceVolumeVector), timeVector=timeVector(2:end); end

            plot(timeVector,iceVolumeVector,'linewidth',2);
            title('Absolute Ice Volume vs Time');           xlabel('Time [yr]');       ylabel('Absolute Ice Volume [m^3]');
            grid on
            plotFilename = sprintf('absoluteIceVolumePlot');            
            saveas(gcf,[self.runsPath self.finalModelFilename '/IceLog/' self.finalModelFilename '_' plotFilename '.jpg']);
            pause(5)

            plot(timeVector,iceVolumeVector-iceVolumeVector(1),'linewidth',2);
            title('Delta Ice Volume wrt Initial Volume vs Time');          xlabel('Time [yr]');            ylabel('Delta Ice Volume [m^3]');
            grid on
            plotFilename = sprintf('deltaIceVolumePlot');               
            saveas(gcf,[self.runsPath self.finalModelFilename '/IceLog/' self.finalModelFilename '_' plotFilename '.jpg']);
            pause(5)

            plot(timeVector,minThickVector,'linewidth',2);
            title('Minimum Thickness vs Time');                            xlabel('Time [yr]');           ylabel('Min Thickness [m]');
            grid on
            plotFilename = sprintf('minThicknessVolumePlot');
            saveas(gcf,[self.runsPath self.finalModelFilename '/IceLog/' self.finalModelFilename '_' plotFilename '.jpg']);
            pause(5)

            plot(timeVector,massVector,'linewidth',2);
            title('Ice Mass vs Time');                                     xlabel('Time [yr]');           ylabel('Ice Mass [kg]');
            grid on
            plotFilename = sprintf('iceMassPlot');
            saveas(gcf,[self.runsPath self.finalModelFilename '/IceLog/' self.finalModelFilename '_' plotFilename '.jpg']);
            pause(5)

            fprintf(volumeLogTextFile,'> Ice Volume [m^3] and Ice Mass [kg] (absolute values): \n\n');
            fprintf(deltaVolumeLogTextFile,'> Delta Ice Volume [m^3] and Delta Ice Mass [kg] (delta with respect to initial volume): \n\n');
            fprintf(thickThresholdLogTextFile,'> Periods with minimum thickness results equal or greater than 40.0 m: \n\n');
            for i = 1:length(iceVolumeVector)
                fprintf(volumeLogTextFile,'@ %06d yr: %.4e m^3 | %.4e kg\n',timeVector(i),iceVolumeVector(i),massVector(i));
                fprintf(deltaVolumeLogTextFile,'@ %06d yr: %.4e m^3 | %.4e kg\n',timeVector(i), iceVolumeVector(i)-iceVolumeVector(1), massVector(i)-massVector(1));
                if(minThickVector(i) >= 40)
                    fprintf(thickThresholdLogTextFile,'@ %06d yr: %.1f m\n',timeVector(i),minThickVector(i));
                end
            end
            fclose(volumeLogTextFile);
            fclose(deltaVolumeLogTextFile);
            fclose(thickThresholdLogTextFile);
            pause(5)

  %          maxplot(self, md, Array4Plotting);
        end

        function saveMeshPlot(self,md,title1, plotFilename)
            plottingTools.plotmultiUnit_mesh(md, 'title', title1, 'data', 'mesh');
            saveas(gcf,[self.runsPath self.finalModelFilename '/Figs/Mesh'  plotFilename '.fig']);
            saveas(gcf,[self.runsPath self.finalModelFilename '/Plots/Mesh'  plotFilename '.jpg']);
            pause(5);
        end
  
        function maxplot(self, md, Array4Plotting)
            maxplotFig = figure('units','normalized','outerposition',[0 0 1 1]);
            EndTime=md.uniqueTransientSolutions(end).time;      whereAmI=find(Array4Plotting (:,1)==EndTime);
%             time=[0; Array4Plotting(1:whereAmI, 1)];            PlotThis=[zeros(1,27) ;Array4Plotting(1:whereAmI, :)];
            time=[Array4Plotting(1:whereAmI, 1)];            PlotThis=[Array4Plotting(1:whereAmI, :)];


            subplot(7,1,1),             plot(time,PlotThis(:,18),'linewidth',2);
            grid on,                    title("Max \surd(Vx^2 + Vy^2) Velocity [m/yr] vs Time [yr]")

            subplot(7,1,2),             plot(time,PlotThis(:,15),'linewidth',2);
            grid on,                    title("Max Velocity [m/yr] vs Time [yr]")

            subplot(7,1,3),             plot(time,PlotThis(:,27),'linewidth',2);
            grid on,                    title("Max Temperature [K] vs Time [yr]")

            subplot(7,1,4),             plot(time,PlotThis(:,16),'linewidth',2);
            grid on,                    title("Max Thickness [m] vs Time [yr]")

            subplot(7,1,5),             plot(time,PlotThis(:, 5),'linewidth',2);
            grid on,                    title("Ice Mass [kg] vs Time [yr]")

            subplot(7,1,6),             plot(time,PlotThis(:, 7),'linewidth',2);
            grid on,                    title("SMB Distribution [m/yr] vs Time [yr]")

            subplot(7,1,7),             plot(time,PlotThis(:, 9),'linewidth',2);
            grid on,                    title("Total Mass Balance [kg/yr] vs Time [yr]")

           % ax = gca, ax.XYAxis.Exponent = 0;

            plotFilename = sprintf('maxplots1@%06dyr',md.uniqueTransientSolutions(end).time);
            plotFilename = [self.finalModelFilename '_' plotFilename];
            saveas(gcf,[self.runsPath self.finalModelFilename '/Plots/'  '/' plotFilename '.jpg']);
            pause(5)
            close(maxplotFig);

            clear vel temp time thick smbLimits smbRest mass i
        end
    end
    methods(Static)
        function faceColour=iceColour(matType)
            switch matType
                case mat_consts.CO2,     faceColour=[89/255 115/255 169/255];   %[0.4940 0.1840 0.5560]      %CO2
                case mat_consts.H2O,     faceColour=[0   152/255  234/255];             %H20
                case mat_consts.N2,      faceColour=[0.3010 0.7450 0.9330];             %N2
                case mat_consts.CO,      faceColour=[0.4660 0.6740 0.1880];             %CO
                case mat_consts.CH4,     faceColour=[0.9290 0.6940 0.1250];            %CH4
                case mat_consts.ROCK,    faceColour=[0.6350 0.0780 0.1840];            %ROCK
                case mat_consts.H2O_DUST,faceColour=[0   159/255  242/255];
                case mat_consts.MAT1,    faceColour=[0.9290 0.6940 0.1250];
                case mat_consts.MAT2,    faceColour=[0.9290 0.6940 0.1250];
                case mat_consts.MAT3,    faceColour=[0.9290 0.6940 0.1250];
                otherwise
                    faceColour=[0 0.4470 0.7410];
            end
        end

        function plotmultiUnit_FullElements_Mesh(md,quickDraw, varargin)

            options=plotoptions(varargin{:});
            options=addfielddefault(options.list{1},'colorbar',0);

            numberofplots=1;
            subplotwidth=ceil(sqrt(numberofplots));
            %              nlines=ceil(numberofplots/subplotwidth);
            %              ncols=subplotwidth;
            f=figure(1);
            clf;
            subplot(1,1,1);
            linewidth=1;
            edgecolor='black';

            data=zeros(md.multiIceMesh.currentIceUnitsCnt, 3);
            for idx=1:md.multiIceMesh.currentIceUnitsCnt
                data(idx,:)=plottingTools.iceColour(md.multiIceMesh.iceUnits(idx).IceType);
            end

            set(f,'Renderer','zbuffer','color',getfieldvalue(options,'figurebackgroundcolor','w'));

            try
                %                elements=md.mesh.elements;

                [x, y, z, elements, ~, ~]=processmesh(md,[],options);

                for idx=1:md.multiIceMesh.currentIceUnitsCnt

                    %                    v=md.multiIceMesh.getUnitVerticesRange(idx, md);
                    %                    v=min(v):max(v)+md.mesh.numberofvertices2d;
                    %                    x=md.mesh.x(v);
                    %                    y=md.mesh.y(v);
                    %                    z=md.mesh.z(v);

                    start=md.multiIceMesh.iceUnits(idx).startingElementID;
                    end1=md.multiIceMesh.iceUnits(idx).endingElementID;%'FaceVertexCData', CDATA,
                    %CDATA=length(md.multiIceMesh.getUnitVerticesRange(idx,md));
                    A=elements(start:end1,1); B=elements(start:end1,2); C=elements(start:end1,3); D=elements(start:end1,4); E=elements(start:end1,5); F=elements(start:end1,6);
                    patch( 'Faces', [A B C],  'Vertices', [x y z],'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                    patch( 'Faces', [D E F],  'Vertices', [x y z],'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                    if ~quickDraw %these are the walls outside; many many walls will be drawn that will be facing inwards and will not be seen; so this is mostly a waste of processing power - these are 10's of millions...
                        patch( 'Faces', [A B E D],'Vertices', [x y z],'FaceVertexCData',zeros(size(x)),'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                        patch( 'Faces', [B E F C],'Vertices', [x y z],'FaceVertexCData',zeros(size(x)),'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                        patch( 'Faces', [C A D F],'Vertices', [x y z],'FaceVertexCData',zeros(size(x)),'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                    end
                    applyoptions(md,[],options);
                end
            catch me
                rethrow(me);
            end

            view (16, 6);  hold on;   m=[];     p=[];
            for i=1:md.multiIceMesh.currentIceUnitsCnt
                m=[m convertCharsToStrings(strcat(md.materials.convertIceCode2Name(md.multiIceMesh.iceUnits(i).IceType), " Thickness: ",num2str( mean(md.multiIceMesh.iceUnits(i).Thickness))))];
                p(i)=plot(NaN, NaN,  'Color',  plottingTools.iceColour(md.multiIceMesh.iceUnits(i).IceType));
            end
            [~,hObj]= legend(p,m);
            hL=findobj(hObj,'type','line');
            set(hL,'linewidth',5)
            hold off;
        end

        function plotSaveMeshPlot(runsPath, finalModelFilename,md,title1, plotFilename)
            plottingTools.plotmultiUnit_mesh(md, 'title', title1, 'data', 'mesh');
            saveas(gcf,[runsPath finalModelFilename '/Figs/Mesh'  plotFilename '.fig']);
            saveas(gcf,[runsPath finalModelFilename '/Plots/Mesh'  plotFilename '.jpg']);
            pause(5);
        end
        
        function plotmultiUnit_mesh(md, varargin)

            options=plotoptions(varargin{:});
            options=addfielddefault(options.list{1},'colorbar',0);

            f=figure(1);               clf;
            subplot(1,1,1);            linewidth=1;
            edgecolor='black';
            data=zeros(md.multiIceMesh.currentIceUnitsCnt, 3);
            for idx=1:md.multiIceMesh.currentIceUnitsCnt
                data(idx,:)=plottingTools.iceColour(md.multiIceMesh.iceUnits(idx).IceType);
            end
            set(f,'Renderer','zbuffer','color',getfieldvalue(options,'figurebackgroundcolor','w'));


            [x, y, z, allElements, ~, ~]=processmesh(md,[],options);
            try
                for idx=1:md.multiIceMesh.currentIceUnitsCnt

                    start=md.multiIceMesh.iceUnits(idx).startingElementID;
                    end1=md.multiIceMesh.iceUnits(idx).endingElementID;
                    unitAllElements=allElements(start:end1,:);
                    %surface and base elements

                    SurfaceElements=[unitAllElements(1:md.mesh.numberofelements2d,:);unitAllElements(end-md.mesh.numberofelements2d+1:end,:)];
                    %side elements
                    [A,~]=ismember(unitAllElements, find(md.mesh.vertexonboundary==1));C=[find(A(:,1)==1);find(A(:,2)==1);find(A(:,3)==1);find(A(:,4)==1)];C=sort(unique(C));
                    sideElements=unitAllElements(C,:);
                    %elements to be drawn
                    elements=[sideElements; SurfaceElements];
                    elements=unique(elements,'rows');
                    end1=length(elements);start=1;

                    A=elements(start:end1,1); B=elements(start:end1,2); C=elements(start:end1,3); D=elements(start:end1,4); E=elements(start:end1,5); F=elements(start:end1,6);
                    %surface of elements
                    patch( 'Faces', [A B C],  'Vertices', [x y z], 'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                    %base of elements
                    patch( 'Faces', [D E F],  'Vertices', [x y z], 'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                    % three sides of elements
                   % if length(allElements)<100000 && idx<5
                        patch( 'Faces', [A B E D],'Vertices', [x y z], 'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                        patch( 'Faces', [B E F C],'Vertices', [x y z], 'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                        patch( 'Faces', [C A D F],'Vertices', [x y z], 'FaceColor',data(idx,:),'EdgeColor',edgecolor,'linewidth',linewidth);
                   % end
                    applyoptions(md,[],options);
                end
            catch me
                rethrow(me);
            end

            view (16, 6);  hold on;   m=[];     p=[];
            for i=1:md.multiIceMesh.currentIceUnitsCnt
                t="         ";
                if md.multiIceMesh.iceUnits(i).mergedUnit, t=" (merged)";end
                str1 = sprintf("%8.2f",round(abs(mean(md.multiIceMesh.iceUnits(i).Thickness))*100)/100);
                m=[m convertCharsToStrings(strcat(md.materials.convertIceCode2Name(md.multiIceMesh.iceUnits(i).IceType), " Mean Thickness: ", str1," m",t)) ];
                p(i)=plot(NaN, NaN,  'Color',  plottingTools.iceColour(md.multiIceMesh.iceUnits(i).IceType));
            end
            [~,hObj]= legend(p,m);
            hL=findobj(hObj,'type','line');
            set(hL,'linewidth',5)
            hold off;
        end
    
       
    
    end

end