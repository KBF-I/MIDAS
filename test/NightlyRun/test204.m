%Test Name: SquareShelfStressFS
md=triangle(model(),'../Exp/Square.exp',180000.);
md=setmask(md,'all','');
md=parameterize(md,'../Par/SquareShelf.par');
md=extrude(md,3,2.);
md=setflowequation(md,'FS','all');
md.cluster=generic('name',oshostname(),'np',1);
md.stressbalance.shelf_dampening=1;
md.timestepping.time_step=0;
md1=solve(md,'Stressbalance');
md.stressbalance.shelf_dampening=0;
md=solve(md,'Stressbalance');

%Fields and tolerances to track changes
field_names     ={'Vx','Vy','Vz','Vel','Pressure','Vx_damp','Vy_damp','Vz_damp','Vel_damp','Pressure_damp'};
field_tolerances={1e-08,1e-08,4e-06,1e-08,1e-08,1e-08,1e-08,2e-07,1e-08,1e-08};
field_values={...
	(md.results.StressbalanceSolution.Vx),...
	(md.results.StressbalanceSolution.Vy),...
	(md.results.StressbalanceSolution.Vz),...
	(md.results.StressbalanceSolution.Vel),...
	(md.results.StressbalanceSolution.Pressure),...
	(md1.results.StressbalanceSolution.Vx),...
	(md1.results.StressbalanceSolution.Vy),...
	(md1.results.StressbalanceSolution.Vz),...
	(md1.results.StressbalanceSolution.Vel),...
	(md1.results.StressbalanceSolution.Pressure),...
	};
