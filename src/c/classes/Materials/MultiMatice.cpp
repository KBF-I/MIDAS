#define _IS_MULTI_ICE_

#include <config.h>

#ifdef _IS_MULTI_ICE_
#include "../classes.h"
#include "../../shared/shared.h"

MultiMatice::MultiMatice(){
	this->helement=NULL;
	this->element=NULL;
	this->isdamaged=false;
	this->isenhanced=false;

	return;
}

MultiMatice::MultiMatice(int MultiMatice_mid,int index, IoModel* iomodel){/*{{{*/
	 /*Get material type and initialize object*/
   int materialtype;
   iomodel->FindConstant(&materialtype,"md.materials.type");
 
	this->Init(MultiMatice_mid,index,materialtype);
}

MultiMatice::MultiMatice(int MultiMatice_mid,int index,int materialtype){/*{{{*/
	this->Init(MultiMatice_mid,index,materialtype);
	return;
} 

MultiMatice::~MultiMatice(){/*{{{*/
	return;
}

void MultiMatice::Init(int MultiMatice_mid,int index,int materialtype){/*{{{*/
	this->mid=MultiMatice_mid;
	int MultiMatice_eid=index+1;
	this->helement=new Hook(&MultiMatice_eid,1);
	this->element=NULL;

	switch(materialtype){
		case MatdamageiceEnum:
			this->isdamaged = true;
			this->isenhanced = false;
			break;
		case MatMultiIceEnum: 
		case MaticeEnum:
			this->isdamaged = false;
			this->isenhanced = false;
			break;
		case MatenhancediceEnum:
			this->isdamaged = false;
			this->isenhanced = true;
			break;
		default:
			_error_("Material type not recognized");
	}
	return;
} /*}}}*/

/*Object virtual functions definitions:*/
Object*   MultiMatice::copy() {/*{{{*/

	/*Output*/
	MultiMatice* multiMatice=NULL;

	/*Initialize output*/
	multiMatice=new MultiMatice();

	/*copy fields: */
	multiMatice->mid=this->mid;
	multiMatice->helement=(Hook*)this->helement->copy();
	multiMatice->element =(Element*)this->helement->delivers();
	multiMatice->isdamaged = this->isdamaged;
	multiMatice->isenhanced = this->isenhanced;

	return multiMatice;
}
/*}}}*/
Material* MultiMatice::copy2(Element* element_in) {/*{{{*/

	/*Output*/
	MultiMatice* multiMatice=NULL;

	/*Initialize output*/
	multiMatice=new MultiMatice();

	/*copy fields: */
	multiMatice->mid=this->mid;
	multiMatice->helement=(Hook*)this->helement->copy();
	multiMatice->element =element_in;
	multiMatice->isdamaged = this->isdamaged;
	multiMatice->isenhanced = this->isenhanced;

	return multiMatice;
}
/*}}}*/
void      MultiMatice::DeepEcho(void){/*{{{*/

	_printf_("MultiMatice:\n");
	_printf_("   mid: " << mid << "\n");
	_printf_("   isdamaged: " << isdamaged << "\n");
	_printf_("   isenhanced: " << isenhanced << "\n");

	/*helement and element DeepEcho were commented to avoid recursion.*/
	/*Example: element->DeepEcho calls MultiMatice->DeepEcho which calls element->DeepEcho etc*/
	_printf_("   helement:\n");
	_printf_("		note: helement not printed to avoid recursion.\n");
	//if(helement) helement->DeepEcho();
	//else _printf_("   helement = NULL\n");

	_printf_("   element:\n");
	_printf_("     note: element not printed to avoid recursion.\n");
	//if(element) element->DeepEcho();
	//else _printf_("   element = NULL\n");
}		
/*}}}*/
void      MultiMatice::Echo(void){/*{{{*/

	_printf_("MultiMatice:\n");
	_printf_("   mid: " << mid << "\n");
	_printf_("   isdamaged: " << isdamaged << "\n");
	_printf_("   isenhanced: " << isenhanced << "\n");

	/*helement and element Echo were commented to avoid recursion.*/
	/*Example: element->Echo calls MultiMatice->Echo which calls element->Echo etc*/
	_printf_("   helement:\n");
	_printf_("     note: helement not printed to avoid recursion.\n");
	//if(helement) helement->Echo();
	//else _printf_("   helement = NULL\n");

	_printf_("   element:\n");
	_printf_("     note: element not printed to avoid recursion.\n");
	//if(element) element->Echo();
	//else _printf_("   element = NULL\n");
}
/*}}}*/
int       MultiMatice::Id(void){ return mid; }/*{{{*/
/*}}}*/
void      MultiMatice::Marshall(MarshallHandle* marshallhandle){ /*{{{*/

	if(marshallhandle->OperationNumber()==MARSHALLING_LOAD)helement=new Hook(); 

	int object_enum = MatMultiIceEnum;
	marshallhandle->call(object_enum);

	marshallhandle->call(this->mid);
	marshallhandle->call(this->isdamaged);
	marshallhandle->call(this->isenhanced);
	this->helement->Marshall(marshallhandle);
	this->element=(Element*)this->helement->delivers();
}/*}}}*/
int       MultiMatice::ObjectEnum(void){/*{{{*/

	return MatMultiIceEnum;

}
/*}}}*/

/*All properties that are coming as matrix to the backend*/
// IssmDouble MultiMatice::GetThermalExchangeVelocity(int inputEnum, Gauss* gauss){/*{{{*/

// 	_assert_(gauss); 

// 	/*Output*/
// 	IssmDouble B;
// 	Input* B_input = element->GetInput(inputEnum); _assert_(B_input);
// 	B_input->GetInputValue(&B,gauss);
// 	return B;
// }


/*Matice management*/
void  MultiMatice::Configure(Elements* elementsin){/*{{{*/

	/*Take care of hooking up all objects for this element, ie links the objects in the hooks to their respective 
	 * datasets, using internal ids and offsets hidden in hooks: */
	 
	helement->configure((DataSet*)elementsin);
	this->element  = (Element*)helement->delivers();
}
/*}}}*/



 IssmDouble MultiMatice::GetMaterialValue(int materialPropEnum)
 {  
	/*The value of nan is very important to this function. if nan is returned, it could mean one of these three things: this is not
	a multiple material type- OR, if it is a multi-material, but the passed enum is not a matrial related enum, or it is a mulit-matrial 
	but an error happened while trying to retrieve the information. in any of these cases, we go back and try to use use the normal, 
	none multi-mat route. 
	RISK: if it is multi-mat, but an error happens while trying to retrieve, then the code will try to use the normal route, which will 
	result in another failure! So, probably, if an error happens here, we should do somthing different than just returning nan  */
	try{ 	
		int materialstype=element->material->ObjectEnum();	 
		if (materialstype!=MatMultiIceEnum) return NAN;

		int newEnum;
		switch(materialPropEnum)
		{
			case MaterialsBetaEnum: 							newEnum= MultiMaterialsBetaEnum ; 							break; 
			case MaterialsEarthDensityEnum: 					newEnum= MultiMaterialsEarthDensityEnum ; 					break; 
			case MaterialsEffectiveconductivityAveragingEnum: 	newEnum= MultiMaterialsEffectiveconductivityAveragingEnum;  break; 
			case MaterialsHeatcapacityEnum: 					newEnum= MultiMaterialsHeatcapacityEnum; 					break; 
			case MaterialsLatentheatEnum: 						newEnum= MultiMaterialsLatentheatEnum ; 					break; 
			case MaterialsMeltingpointEnum: 					newEnum= MultiMaterialsMeltingpointEnum ; 					break; 
			case MaterialsMixedLayerCapacityEnum: 				newEnum= MultiMaterialsMixedLayerCapacityEnum ; 			break; 
			case MaterialsMuWaterEnum: 							newEnum= MultiMaterialsMuWaterEnum ; 						break; 
			case MaterialsRheologyLawEnum: 						newEnum= MultiMaterialsRheologyLawEnum ; 					break; 
			case MaterialsRhoFreshwaterEnum: 					newEnum= MultiMaterialsRhoFreshwaterEnum ; 					break; 
			case MaterialsRhoIceEnum: 							newEnum= MultiMaterialsRhoIceEnum  ; 						break; 
			case MaterialsRhoSeawaterEnum: 						newEnum= MultiMaterialsRhoWaterEnum ; 						break; 
			case MaterialsTemperateiceconductivityEnum: 		newEnum= MultiMaterialsTemperateiceconductivityEnum ; 		break; 
			case MaterialsThermalExchangeVelocityEnum: 			newEnum= MultiMaterialsThermalExchangeVelocityEnum  ; 		break; 
			case MaterialsThermalconductivityEnum: 				newEnum= MultiMaterialsThermalconductivityEnum ; 			break; 
			default: return NAN;
		}
					
		Gauss* gauss=((Penta*)element)->NewGauss();
		IssmDouble pv;
		Input* B_input = element->GetInput(newEnum); 
		B_input->GetInputValue(&pv,gauss);
		delete(gauss);
		/*
		//enhancemnt to replace the block above; but currently returns:
		//libc++abi: terminating with uncaught exception of type ErrorException: PentaInput cannot return a double!
		IssmDouble pv;
		element->GetInputValue(&pv,newEnum);
		*/
		if (newEnum==MultiMaterialsRheologyLawEnum){
			int i=(int)pv;
			switch(i){
				case 0 :pv=(IssmDouble)NoneEnum; 			break;
				case 1 :pv=(IssmDouble)BuddJackaEnum;		break;
				case 2 :pv=(IssmDouble)CuffeyEnum;			break;
				case 3 :pv=(IssmDouble)CuffeyTemperateEnum;	break;
				case 4 :pv=(IssmDouble)PatersonEnum;		break;
				case 5 :pv=(IssmDouble)ArrheniusEnum;		break;
				case 6 :pv=(IssmDouble)LliboutryDuvalEnum;	break;
				case 7 :pv=(IssmDouble)NyeCO2Enum;			break; 
				case 8 :pv=(IssmDouble)NyeH2OEnum;			break;
				case 10:pv=(IssmDouble)NyeN2Enum;			break;
			    default: 									break;
			}
		}

		return pv;
	}
	catch (exception e)
	{
		return NAN;
	}
 }  
#endif
