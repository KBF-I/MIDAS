%HYDROLOGYGLADS class definition
%
%   Usage:
%      hydrologyglads=hydrologyglads();

classdef hydrologyglads
	properties (SetAccess=public) 
		%Sheet
		pressure_melt_coefficient = 0.;
		sheet_conductivity        = NaN;
		cavity_spacing            = 0.;
		bump_height               = NaN;

		%Channels
		ischannels           = 0;
		channel_conductivity = NaN;
		channel_sheet_width  = 0.;

		%Other
		spcphi               = NaN;
		moulin_input         = NaN;
		neumannflux          = NaN;
		englacial_void_ratio = 0.;
		requested_outputs    = {};
		melt_flag            = 0;
	end
	methods
		function self = hydrologyglads(varargin) % {{{
			switch nargin
				case 0
					self=setdefaultparameters(self);
				case 1
					self=structtoobj(self,varargin{1});
				otherwise
					error('constructor not supported');
			end
		end % }}}
		function list = defaultoutputs(self,md) % {{{
			list = {'EffectivePressure','HydraulicPotential','HydrologySheetThickness','ChannelArea','ChannelDischarge'};
		end % }}}    

		function self = setdefaultparameters(self) % {{{

			%Sheet parameters
			self.pressure_melt_coefficient = 7.5e-8; %K/Pa (See table 1 in Erder et al. 2013)
			self.cavity_spacing = 2.; %m

			%Channel parameters
			self.ischannels=false;
			self.channel_conductivity = 5.e-2; %Dow's default, Table uses 0.1
			self.channel_sheet_width = 2.; %m

			%Other
			self.englacial_void_ratio = 1.e-5;% Dow's default, Table from Werder et al. uses 1e-3;
			self.requested_outputs={'default'};
			self.melt_flag=0;
		end % }}}
		function md = checkconsistency(self,md,solution,analyses) % {{{

			%Early return
			if ~ismember('HydrologyGladsAnalysis',analyses)
				return;
			end

			%Sheet
			md = checkfield(md,'fieldname','hydrology.pressure_melt_coefficient','numel',[1],'>=',0);
			md = checkfield(md,'fieldname','hydrology.sheet_conductivity','size',[md.mesh.numberofvertices 1],'>',0,'NaN',1,'Inf',1);
			md = checkfield(md,'fieldname','hydrology.cavity_spacing','numel',[1],'>',0);
			md = checkfield(md,'fieldname','hydrology.bump_height','size',[md.mesh.numberofvertices 1],'>=',0,'NaN',1,'Inf',1);

			%Channels
			md = checkfield(md,'fieldname','hydrology.ischannels','numel',[1],'values',[0 1]);
			md = checkfield(md,'fieldname','hydrology.channel_conductivity','size',[md.mesh.numberofvertices 1],'>=',0,'NaN',1,'Inf',1);
			md = checkfield(md,'fieldname','hydrology.channel_sheet_width','numel',[1],'>=',0);

			%Other
			md = checkfield(md,'fieldname','hydrology.spcphi','Inf',1,'timeseries',1);
			md = checkfield(md,'fieldname','hydrology.englacial_void_ratio','numel',[1],'>=',0);
			md = checkfield(md,'fieldname','hydrology.moulin_input','>=',0,'timeseries',1,'NaN',1,'Inf',1);
			md = checkfield(md,'fieldname','hydrology.neumannflux','timeseries',1,'NaN',1,'Inf',1);
			md = checkfield(md,'fieldname','hydrology.requested_outputs','stringrow',1);
			md = checkfield(md,'fieldname','hydrology.melt_flag','numel',[1],'values',[0 1 2]);
			if self.melt_flag==1 || self.melt_flag==2
				md = checkfield(md,'fieldname','basalforcings.groundedice_melting_rate','NaN',1,'Inf',1,'timeseries',1);
			end
		end % }}}
		function disp(self) % {{{
			disp(sprintf('   GlaDS (hydrologyglads) solution parameters:'));
			disp(sprintf('      SHEET'));
			fielddisplay(self,'pressure_melt_coefficient','Pressure melt coefficient (c_t) [K Pa^-1]');
			fielddisplay(self,'sheet_conductivity','sheet conductivity (k) [m^(7/4) kg^(-1/2)]');
			fielddisplay(self,'cavity_spacing','cavity spacing (l_r) [m]');
			fielddisplay(self,'bump_height','typical bump height (h_r) [m]');
			disp(sprintf('      CHANNELS'));
			fielddisplay(self,'ischannels','Do we allow for channels? 1: yes, 0: no');
			fielddisplay(self,'channel_conductivity','channel conductivity (k_c) [m^(3/2) kg^(-1/2)]');
			disp(sprintf('      OTHER'));
			fielddisplay(self,'spcphi','Hydraulic potential Dirichlet constraints [Pa]');
			fielddisplay(self,'neumannflux','water flux applied along the model boundary (m^2/s)');
			fielddisplay(self,'moulin_input','moulin input (Q_s) [m^3/s]');
			fielddisplay(self,'englacial_void_ratio','englacial void ratio (e_v)');
			fielddisplay(self,'requested_outputs','additional outputs requested');
			fielddisplay(self,'melt_flag','User specified basal melt? 0: no (default), 1: use md.basalforcings.groundedice_melting_rate');
		end % }}}
		function marshall(self,prefix,md,fid) % {{{

			yts=md.constants.yts;

			%Marshall model code first
			WriteData(fid,prefix,'name','md.hydrology.model','data',5,'format','Integer');

			%Sheet
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','pressure_melt_coefficient','format','Double');
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','sheet_conductivity','format','DoubleMat','mattype',1);
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','cavity_spacing','format','Double');
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','bump_height','format','DoubleMat','mattype',1);

			%Channels
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','ischannels','format','Boolean');
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','channel_conductivity','format','DoubleMat','mattype',1);
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','channel_sheet_width','format','Double');

			%Others
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','spcphi','format','DoubleMat','mattype',1,'timeserieslength',md.mesh.numberofvertices+1,'yts',md.constants.yts);
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','neumannflux','format','DoubleMat','mattype',2,'timeserieslength',md.mesh.numberofelements+1,'yts',md.constants.yts);
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','moulin_input','format','DoubleMat','mattype',1,'timeserieslength',md.mesh.numberofvertices+1,'yts',md.constants.yts);
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','englacial_void_ratio','format','Double');
			WriteData(fid,prefix,'object',self,'class','hydrology','fieldname','melt_flag','format','Integer');
			outputs = self.requested_outputs;
			pos  = find(ismember(outputs,'default'));
			if ~isempty(pos),
				outputs(pos) = [];  %remove 'default' from outputs
				outputs      = [outputs defaultoutputs(self,md)]; %add defaults
			end
			WriteData(fid,prefix,'data',outputs,'name','md.hydrology.requested_outputs','format','StringArray');
		end % }}}
	end
end
