%Test Name: TransientFrictionTsai
md=triangle(model(),'../Exp/Square.exp',150000.);
md=setmask(md,'../Exp/SquareShelf.exp','');
md=parameterize(md,'../Par/SquareSheetShelf.par');
md=extrude(md,4,1);
md=setflowequation(md,'HO','all');
md.transient.isthermal = 0;
md.friction=frictiontsai(md.friction);
md.friction.C = 20.e4*ones(md.mesh.numberofvertices,1);
md.friction.f = 0.5*ones(md.mesh.numberofvertices,1);
md.friction.m = 1./3.*ones(md.mesh.numberofelements,1);
md.cluster=generic('name',oshostname(),'np',3);
md=solve(md,'Transient');

%Fields and tolerances to track changes
field_names     ={'Vx1','Vy1','Vel1','Pressure1','Bed1','Surface1','Thickness1','Vx2','Vy2','Vel2','Pressure2','Bed2','Surface2','Thickness2','Vx3','Vy3','Vel3','Pressure3','Bed3','Surface3','Thickness3'};
field_tolerances={2e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09,2e-09,1e-09,1e-09,1e-09,1e-09,1e-09,1e-09};
field_values={...
	(md.results.TransientSolution(1).Vx),...
	(md.results.TransientSolution(1).Vy),...
	(md.results.TransientSolution(1).Vel),...
	(md.results.TransientSolution(1).Pressure),...
	(md.results.TransientSolution(1).Base),...
	(md.results.TransientSolution(1).Surface),...
	(md.results.TransientSolution(1).Thickness),...
	(md.results.TransientSolution(2).Vx),...
	(md.results.TransientSolution(2).Vy),...
	(md.results.TransientSolution(2).Vel),...
	(md.results.TransientSolution(2).Pressure),...
	(md.results.TransientSolution(2).Base),...
	(md.results.TransientSolution(2).Surface),...
	(md.results.TransientSolution(2).Thickness),...
	(md.results.TransientSolution(3).Vx),...
	(md.results.TransientSolution(3).Vy),...
	(md.results.TransientSolution(3).Vel),...
	(md.results.TransientSolution(3).Pressure),...
	(md.results.TransientSolution(3).Base),...
	(md.results.TransientSolution(3).Surface),...
	(md.results.TransientSolution(3).Thickness),...
	};
