/*!\file Cfsurfacesquare.cpp
 * \brief: Cfsurfacesquare Object
 */

/*Headers:*/
/*{{{*/
#ifdef HAVE_CONFIG_H
#include <config.h>
#else
#error "Cannot compile with HAVE_CONFIG_H symbol! run configure first!"
#endif

#include "./classes.h"
#include "./ExternalResults/ExternalResult.h"
#include "./ExternalResults/Results.h"
#include "../datastructures/datastructures.h"
#include "./Elements/Element.h"
#include "./Elements/Elements.h"
#include "./FemModel.h"
#include "../modules/SurfaceAreax/SurfaceAreax.h"
#include "../classes/Params/Parameters.h"
#include "../classes/gauss/Gauss.h"
#include "./Inputs/DatasetInput.h"
/*}}}*/

/*Cfsurfacesquare constructors, destructors :*/
Cfsurfacesquare::Cfsurfacesquare(){/*{{{*/

	this->definitionenum   = -1;
	this->name             = NULL;
	this->model_enum       = UNDEF;
	this->datatime         = 0.;
	this->timepassedflag   = false;
}
/*}}}*/
Cfsurfacesquare::Cfsurfacesquare(char* in_name, int in_definitionenum, int in_model_enum, IssmDouble in_datatime, bool in_timepassedflag){/*{{{*/

	this->definitionenum=in_definitionenum;

	this->name		= xNew<char>(strlen(in_name)+1);
	xMemCpy<char>(this->name,in_name,strlen(in_name)+1);

	this->model_enum=in_model_enum;
	this->datatime=in_datatime;
	this->timepassedflag=in_timepassedflag;
}
/*}}}*/
Cfsurfacesquare::~Cfsurfacesquare(){/*{{{*/
	if(this->name)xDelete(this->name);
}
/*}}}*/

/*Object virtual function resolutoin: */
Object* Cfsurfacesquare::copy() {/*{{{*/
	Cfsurfacesquare* mf = new Cfsurfacesquare(this->name,this->definitionenum, this->model_enum,this->datatime,this->timepassedflag);
	return (Object*) mf;
}
/*}}}*/
void Cfsurfacesquare::DeepEcho(void){/*{{{*/
	this->Echo();
}
/*}}}*/
void Cfsurfacesquare::Echo(void){/*{{{*/
	_printf_(" Cfsurfacesquare: " << name << " " << this->definitionenum << "\n");
	_printf_("    model_enum: " << model_enum << " " << EnumToStringx(model_enum) << "\n");
	_printf_("    datatime: " << datatime << "\n");
	_printf_("	  timepassedflag: "<<timepassedflag<<"\n");
}
/*}}}*/
int Cfsurfacesquare::Id(void){/*{{{*/
	return -1;
}
/*}}}*/
void Cfsurfacesquare::Marshall(MarshallHandle* marshallhandle){/*{{{*/

	int object_enum=CfsurfacesquareEnum;
	marshallhandle->call(object_enum);

	marshallhandle->call(this->definitionenum);
	marshallhandle->call(this->model_enum);
	marshallhandle->call(this->name);
	marshallhandle->call(this->datatime);
	marshallhandle->call(this->timepassedflag);
} 
/*}}}*/
int Cfsurfacesquare::ObjectEnum(void){/*{{{*/
	return CfsurfacesquareEnum;
}
/*}}}*/

/*Definition virtual function resolutoin: */
int Cfsurfacesquare::DefinitionEnum(){/*{{{*/
	return this->definitionenum;
}
/*}}}*/
char* Cfsurfacesquare::Name(){/*{{{*/
	char* name2=xNew<char>(strlen(this->name)+1);
	xMemCpy(name2,this->name,strlen(this->name)+1);

	return name2;
}
/*}}}*/
IssmDouble Cfsurfacesquare::Response(FemModel* femmodel){/*{{{*/

	/*recover time parameters: */
	IssmDouble time;
	femmodel->parameters->FindParam(&time,TimeEnum);

	/*Do the calculation only if this is the first time we are passed datatime*/
	if(this->datatime<=time && !this->timepassedflag){

		IssmDouble J=0.;
		IssmDouble J_sum=0.;

		for(Object* & object : femmodel->elements->objects){
			Element* element=xDynamicCast<Element*>(object);
			J+=this->Cfsurfacesquare_Calculation(element,model_enum);
		}

		ISSM_MPI_Allreduce ( (void*)&J,(void*)&J_sum,1,ISSM_MPI_DOUBLE,ISSM_MPI_SUM,IssmComm::GetComm());
		ISSM_MPI_Bcast(&J_sum,1,ISSM_MPI_DOUBLE,0,IssmComm::GetComm());

		this->timepassedflag = true;
		return J_sum;
	}
	else{
		return 0.;
	}
}
/*}}}*/
IssmDouble Cfsurfacesquare::Cfsurfacesquare_Calculation(Element* element, int model_enum){/*{{{*/

	int        domaintype,numcomponents;
	IssmDouble Jelem=0.;
	IssmDouble misfit,Jdet;
	IssmDouble model,obs,weight;
	IssmDouble* xyz_list = NULL;

	/*Get basal element*/
	if(!element->IsOnSurface()) return 0.;

	/*If on water, return 0: */
	if(!element->IsIceInElement()) return 0.;

	/*Get problem dimension*/
	element->FindParam(&domaintype,DomainTypeEnum);
	switch(domaintype){
		case Domain2DverticalEnum:   numcomponents   = 1; break;
		case Domain3DEnum:           numcomponents   = 2; break;
		case Domain2DhorizontalEnum: numcomponents   = 2; break;
		default: _error_("not supported yet");
	}

	/*Spawn surface element*/
	Element* topelement = element->SpawnTopElement();

	/* Get node coordinates*/
	topelement->GetVerticesCoordinates(&xyz_list);

	/*Retrieve all inputs we will be needing: */
	DatasetInput *datasetinput = topelement->GetDatasetInput(definitionenum); _assert_(datasetinput);
	Input        *model_input  = topelement->GetInput(model_enum);            _assert_(model_input);

	/* Start  looping on the number of gaussian points: */
	Gauss* gauss=topelement->NewGauss(2);
	while(gauss->next()){

		/* Get Jacobian determinant: */
		topelement->JacobianDeterminant(&Jdet,xyz_list,gauss);

		/*Get all parameters at gaussian point*/
		datasetinput->GetInputValue(&weight,gauss,WeightsSurfaceObservationEnum);
		model_input->GetInputValue(&model,gauss);
		datasetinput->GetInputValue(&obs,gauss,SurfaceObservationEnum);

		/*Compute SurfaceAbsVelMisfitEnum:
		 *        *
		 *               *      1  [           2              2 ]
		 *                      * J = --- | (u - u   )  +  (v - v   )  |
		 *                             *      2  [       obs            obs   ]
		 *                                    *
		 *                                           */
		misfit=0.5*(model-obs)*(model-obs);

		/*Add to cost function*/
		Jelem+=misfit*weight*Jdet*gauss->weight;
	}

	/*clean up and Return: */
	if(topelement->IsSpawnedElement()){topelement->DeleteMaterials(); delete topelement;};
	xDelete<IssmDouble>(xyz_list);
	delete gauss;
	return Jelem;
}/*}}}*/
