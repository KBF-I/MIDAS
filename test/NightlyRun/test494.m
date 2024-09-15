%Test Name: SquareSheetShelfTranMeltFCT
md=triangle(model(),'../Exp/Square.exp',150000.);
md=setmask(md,'../Exp/SquareShelf.exp','');
md=parameterize(md,'../Par/SquareSheetShelf.par');
md.geometry.bed=md.geometry.base;
pos=find(md.mask.ocean_levelset<0);
md.geometry.bed(pos)=md.geometry.base(pos)-10;
md.friction=frictioncoulomb();
md.friction.coefficient=20.*ones(md.mesh.numberofvertices,1);
md.friction.p=ones(md.mesh.numberofelements,1);
md.friction.q=ones(md.mesh.numberofelements,1);
md.friction.coefficientcoulomb=0.02*ones(md.mesh.numberofvertices,1);
md.transient.isthermal=0;
md.transient.isgroundingline=1;
md=setflowequation(md,'SSA','all');
md.cluster=generic('name',oshostname(),'np',3);
md.transient.requested_outputs={'default','GroundedArea','FloatingArea','TotalFloatingBmb','TotalGroundedBmb','TotalSmb'};
md.masstransport.stabilization=4;
md=solve(md,'Transient');

%Fields and tolerances to track changes
field_names={...
	'Vx1','Vy1','Vel1','Pressure1','Bed1','Surface1','Thickness1','GroundedArea1','FloatingArea1','TotalFloatingBmb1','TotalGroundedBmb1','TotalSmb1',...
	'Vx2','Vy2','Vel2','Pressure2','Bed2','Surface2','Thickness2','GroundedArea2','FloatingArea2','TotalFloatingBmb2','TotalGroundedBmb2','TotalSmb2',...
	'Vx3','Vy3','Vel3','Pressure3','Bed3','Surface3','Thickness3','GroundedArea3','FloatingArea3','TotalFloatingBmb3','TotalGroundedBmb3','TotalSmb3'...
};
field_tolerances={...
	2e-13,2e-13,2e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,...
	2e-13,2e-13,2e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,...
	2e-13,2e-13,2e-13,1e-13,2e-13,4e-13,9e-13,1e-13,1e-13,1e-13,1e-13,1e-13...
};
field_values={...
	(md.results.TransientSolution(1).Vx),...
	(md.results.TransientSolution(1).Vy),...
	(md.results.TransientSolution(1).Vel),...
	(md.results.TransientSolution(1).Pressure),...
	(md.results.TransientSolution(1).Base),...
	(md.results.TransientSolution(1).Surface),...
	(md.results.TransientSolution(1).Thickness),...
	(md.results.TransientSolution(1).GroundedArea),...
	(md.results.TransientSolution(1).FloatingArea),...
	(md.results.TransientSolution(1).TotalFloatingBmb),...
	(md.results.TransientSolution(1).TotalGroundedBmb),...
	(md.results.TransientSolution(1).TotalSmb),...
	(md.results.TransientSolution(2).Vx),...
	(md.results.TransientSolution(2).Vy),...
	(md.results.TransientSolution(2).Vel),...
	(md.results.TransientSolution(2).Pressure),...
	(md.results.TransientSolution(2).Base),...
	(md.results.TransientSolution(2).Surface),...
	(md.results.TransientSolution(2).Thickness),...
	(md.results.TransientSolution(2).GroundedArea),...
	(md.results.TransientSolution(2).FloatingArea),...
	(md.results.TransientSolution(2).TotalFloatingBmb),...
	(md.results.TransientSolution(2).TotalGroundedBmb),...
	(md.results.TransientSolution(2).TotalSmb),...
	(md.results.TransientSolution(3).Vx),...
	(md.results.TransientSolution(3).Vy),...
	(md.results.TransientSolution(3).Vel),...
	(md.results.TransientSolution(3).Pressure),...
	(md.results.TransientSolution(3).Base),...
	(md.results.TransientSolution(3).Surface),...
	(md.results.TransientSolution(3).Thickness),...
	(md.results.TransientSolution(3).GroundedArea),...
	(md.results.TransientSolution(3).FloatingArea),...
	(md.results.TransientSolution(3).TotalFloatingBmb),...
	(md.results.TransientSolution(3).TotalGroundedBmb),...
	(md.results.TransientSolution(3).TotalSmb),...
};
