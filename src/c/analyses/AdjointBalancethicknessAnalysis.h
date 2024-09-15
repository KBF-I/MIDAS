/*! \file AdjointBalancethicknessAnalysis.h 
 *  \brief: header file for generic external result object
 */

#ifndef _AdjointBalancethicknessAnalysis_
#define _AdjointBalancethicknessAnalysis_

/*Headers*/
#include "./Analysis.h"

class AdjointBalancethicknessAnalysis: public Analysis{

	public:
		/*Model processing*/
		void CreateConstraints(Constraints* constraints,IoModel* iomodel);
		void CreateLoads(Loads* loads, IoModel* iomodel);
		void CreateNodes(Nodes* nodes,IoModel* iomodel,bool isamr=false);
		int  DofsPerNode(int** doflist,int domaintype,int approximation);
		void UpdateElements(Elements* elements,Inputs* inputs,IoModel* iomodel,int analysis_counter,int analysis_type);
		void UpdateParameters(Parameters* parameters,IoModel* iomodel,int solution_enum,int analysis_enum);

		/*Finite element Analysis*/
		void           Core(FemModel* femmodel);
		void           PreCore(FemModel* femmodel);
		ElementVector* CreateDVector(Element* element);
		ElementMatrix* CreateJacobianMatrix(Element* element);
		ElementMatrix* CreateKMatrix(Element* element);
		ElementVector* CreatePVector(Element* element);
		void           GetSolutionFromInputs(Vector<IssmDouble>* solution,Element* element);
		void           GradientJ(Vector<IssmDouble>* gradient,Element*  element,int control_type,int control_interp,int control_index);
		void           GradientJDirichlet(Element* element,Vector<IssmDouble>* gradient,int control_interp,int control_index);
		void           GradientJDhDt(Element* element,Vector<IssmDouble>* gradient,int control_interp,int control_index);
		void           GradientJVx(Element* element,Vector<IssmDouble>* gradient,int control_interp,int control_index);
		void           GradientJVy(Element* element,Vector<IssmDouble>* gradient,int control_interp,int control_index);
		void           InputUpdateFromSolution(IssmDouble* solution,Element* element);
		void           UpdateConstraints(FemModel* femmodel);
};
#endif
