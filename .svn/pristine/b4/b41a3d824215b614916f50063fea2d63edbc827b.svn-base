/*!\file DependentObject.c
 * \brief: implementation of the DependentObject object
 */

#ifdef HAVE_CONFIG_H
	#include <config.h>
#else
#error "Cannot compile with HAVE_CONFIG_H symbol! run configure first!"
#endif

#include "./classes.h"
#include "shared/shared.h"
#include "../modules/modules.h"

/*DependentObject constructors and destructor*/
DependentObject::DependentObject(){/*{{{*/
	this->name=NULL;
	this->index=-1;
	this->response_value=0.;
}
/*}}}*/
DependentObject::DependentObject(char* in_name,int in_index){/*{{{*/

	this->name=xNew<char>(strlen(in_name)+1); xMemCpy<char>(this->name,in_name,strlen(in_name)+1);
	this->index=in_index;
	this->response_value=0.;

}/*}}}*/
DependentObject::DependentObject(char* in_name,int in_index,IssmDouble in_response){/*{{{*/

	this->name=xNew<char>(strlen(in_name)+1); xMemCpy<char>(this->name,in_name,strlen(in_name)+1);
	this->index=in_index;
	this->response_value=in_response;

}/*}}}*/
DependentObject::~DependentObject(){ //destructor/*{{{*/
	xDelete<char>(this->name);
}/*}}}*/

/*Object virtual functions definitions:*/
Object* DependentObject::copy(void) { /*{{{*/
	return new DependentObject(name,index,response_value);
} /*}}}*/
void DependentObject::DeepEcho(void){/*{{{*/
	this->Echo();
}
/*}}}*/
void DependentObject::Echo(void){/*{{{*/

	_printf_("DependentObject:\n");
	_printf_("   name: " << this->name << "\n");
	if(this->index>=0) _printf_("   index: " << this->index << "\n");
	_printf_("   response_value: " << this->response_value<< "\n");
}
/*}}}*/
int  DependentObject::Id(void){ return -1; }/*{{{*/
/*}}}*/
int  DependentObject::ObjectEnum(void){/*{{{*/

	return DependentObjectEnum;

}
/*}}}*/
void DependentObject::Marshall(MarshallHandle* marshallhandle){/*{{{*/

	int object_enum = DependentObjectEnum;
	marshallhandle->call(object_enum);

	/*Marshall name (tricky)*/
	marshallhandle->call(this->name);

	marshallhandle->call(this->index);
	marshallhandle->call(this->response_value);
}/*}}}*/

/*DependentObject methods: */
void  DependentObject::Responsex(IssmDouble* poutput_value,FemModel* femmodel){/*{{{*/

	/*Is this some special type of response for which we need to go in the output definitions? :*/
	if (StringToEnumx(this->name,false)==-1){
		*poutput_value=OutputDefinitionsResponsex(femmodel,this->name);
	}
	else femmodel->Responsex(poutput_value,this->name);
}
/*}}}*/
IssmDouble DependentObject::GetValue(void){/*{{{*/
	return this->response_value;
}
/*}}}*/
void DependentObject::AddValue(IssmDouble in_value){/*{{{*/
	this->response_value+=in_value;
}
/*}}}*/
void DependentObject::ResetResponseValue(){/*{{{*/
	this->response_value=0.;
}
/*}}}*/
