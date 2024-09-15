%Test Name: SquareShelfSMBGembClimConstrainT
md=triangle(model(),'../Exp/Square.exp',350000.);
md=setmask(md,'all','');
md=parameterize(md,'../Par/SquareShelf.par');
md=setflowequation(md,'SSA','all');
md.materials.rho_ice=910;
md.cluster=generic('name',oshostname(),'np',3);

% Use of Gemb method for SMB computation
md.smb = SMBgemb(md.mesh,md.geometry);
md.smb.dsnowIdx = 3;
md.smb.aIdx = 2;
md.smb.denIdx = 1;

%load hourly surface forcing date from 1979 to 2009:
inputs=load('../Data/gemb_input.mat');

%setup the inputs:
md.smb.Ta=[repmat(inputs.Ta0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.V=[repmat(inputs.V0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.dswrf=[repmat(inputs.dsw0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.dlwrf=[repmat(inputs.dlw0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.P=[repmat(inputs.P0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.eAir=[repmat(inputs.eAir0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.pAir=[repmat(inputs.pAir0',md.mesh.numberofelements,1);inputs.dateN'];
md.smb.Vz=repmat(inputs.LP.Vz,md.mesh.numberofelements,1);
md.smb.Tz=repmat(inputs.LP.Tz,md.mesh.numberofelements,1);
md.smb.Tmean=repmat(inputs.LP.Tmean,md.mesh.numberofelements,1);
md.smb.C=repmat(inputs.LP.C,md.mesh.numberofelements,1);

md.smb.Ta=md.smb.Ta(:,1:365*8);
md.smb.V=md.smb.V(:,1:365*8);
md.smb.dswrf=md.smb.dswrf(:,1:365*8);
md.smb.dlwrf=md.smb.dlwrf(:,1:365*8);
md.smb.P=md.smb.P(:,1:365*8);
md.smb.eAir=md.smb.eAir(:,1:365*8);
md.smb.pAir=md.smb.pAir(:,1:365*8);

md.timestepping.cycle_forcing=1;
md.smb.isconstrainsurfaceT=1;

%smb settings
md.smb.requested_outputs={'SmbDz','SmbT','SmbD','SmbRe','SmbGdn','SmbGsp','SmbEC','SmbA','SmbMassBalance','SmbMAdd','SmbDzAdd','SmbFAC'};

%only run smb core:
md.transient.isstressbalance=0;
md.transient.ismasstransport=0;
md.transient.isthermal=0;

%time stepping:
md.timestepping.start_time=1965.6;
md.timestepping.final_time=1966.6;
md.timestepping.time_step=1/365.0;
md.timestepping.interp_forcing=0;

%Run transient
md=solve(md,'Transient');

nlayers=size(md.results.TransientSolution(1).SmbT,2);
for i=2:length(md.results.TransientSolution)
	nlayers=min(size(md.results.TransientSolution(i).SmbT,2), nlayers);
end

%Fields and tolerances to track changes
field_names      ={'Layers','SmbDz1','SmbT1' ,'SmbD1' ,'SmbRe1','SmbGdn1','SmbGsp1','SmbA1' ,'SmbEC1','SmbMassBalance1','SmbMAdd1','SmbDzAdd1','SmbFAC1',...
	'SmbDz2','SmbT2' ,'SmbD2' ,'SmbRe2','SmbGdn2','SmbGsp2','SmbA2' ,'SmbEC2','SmbMassBalance2','SmbMAdd2','SmbDzAdd2','SmbFAC2',...
	'SmbDz3','SmbT3' ,'SmbD3' ,'SmbRe3','SmbGdn3','SmbGsp3','SmbA3' ,'SmbEC3','SmbMassBalance3','SmbMAdd3','SmbDzAdd3','SmbFAC3',...
	'SmbDz4','SmbT4' ,'SmbD4' ,'SmbRe4','SmbGdn4','SmbGsp4','SmbA4' ,'SmbEC4','SmbMassBalance4','SmbMAdd4','SmbDzAdd4','SmbFAC4'};
field_tolerances ={1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12,...
                   1e-12,1e-12,1e-11,1e-10,4e-11,1e-11,1e-12,1e-11,1e-12,1e-12,1e-12,1e-11,...
                   1e-12,1e-12,2e-12,2e-11,1e-10,1e-11,1e-12,1e-11,1e-11,1e-12,1e-12,1e-11,...
                   1e-11,1e-11,1e-10,1e-11,1e-12,3e-11,1e-12,4e-12,1e-10,1e-12,1e-12,2e-11};

field_values={...
	(nlayers)...
	(md.results.TransientSolution(1).SmbDz(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbT(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbD(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbRe(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbGdn(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbGsp(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbA(1,1:nlayers)),...
	(md.results.TransientSolution(1).SmbEC(1)),...
	(md.results.TransientSolution(1).SmbMassBalance(1)),...
	(md.results.TransientSolution(1).SmbMAdd(1)),...
	(md.results.TransientSolution(1).SmbDzAdd(1)),...
	(md.results.TransientSolution(1).SmbFAC(1)),...
   (md.results.TransientSolution(146).SmbDz(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbT(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbD(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbRe(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbGdn(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbGsp(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbA(1,1:nlayers)),...
	(md.results.TransientSolution(146).SmbEC(1)),...
	(md.results.TransientSolution(146).SmbMassBalance(1)),...
	(md.results.TransientSolution(146).SmbMAdd(1)),...
	(md.results.TransientSolution(146).SmbDzAdd(1)),...
	(md.results.TransientSolution(146).SmbFAC(1)),...
	(md.results.TransientSolution(147).SmbDz(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbT(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbD(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbRe(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbGdn(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbGsp(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbA(1,1:nlayers)),...
	(md.results.TransientSolution(147).SmbEC(1)),...
	(md.results.TransientSolution(147).SmbMassBalance(1)),...
	(md.results.TransientSolution(147).SmbMAdd(1)),...
	(md.results.TransientSolution(147).SmbDzAdd(1)),...
	(md.results.TransientSolution(147).SmbFAC(1)),...
	(md.results.TransientSolution(end).SmbDz(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbT(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbD(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbRe(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbGdn(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbGsp(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbA(1,1:nlayers)),...
	(md.results.TransientSolution(end).SmbEC(1)),...
	(md.results.TransientSolution(end).SmbMassBalance(1)),...
	(md.results.TransientSolution(end).SmbMAdd(1)),...
	(md.results.TransientSolution(end).SmbDzAdd(1)),...
	(md.results.TransientSolution(end).SmbFAC(1)),...
	};
