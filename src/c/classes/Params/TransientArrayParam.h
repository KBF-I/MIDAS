/*! \file TransientArrayParam.h 
 *  \brief: header file for triavertexinput object
 */

#ifndef _TRANSIENTARRAYPARAM_H_
#define _TRANSIENTARRAYPARAM_H_

/*Headers:*/
/*{{{*/
#ifdef HAVE_CONFIG_H
	#include <config.h>
#else
#error "Cannot compile with HAVE_CONFIG_H symbol! run configure first!"
#endif

#include "./Param.h"
#include "../../shared/shared.h"
/*}}}*/

class TransientArrayParam: public Param{

	protected: 
		int         enum_type;
		int         N;
		int         M;
		bool        interpolation;
		bool        cycle;
		IssmDouble *values;
		IssmDouble *timesteps;

	public:
		/*TransientArrayParam constructors, destructors: {{{*/
		TransientArrayParam();
		TransientArrayParam(int in_enum_type,IssmDouble* in_values,IssmDouble* in_time,bool interpolation_on,bool cycle_in,int in_N,int in_M);
		~TransientArrayParam();
		/*}}}*/
		/*Object virtual functions definitions:{{{ */
		Param* copy();
		void  DeepEcho();
		void  Echo();
		int   Id(); 
		void Marshall(MarshallHandle* marshallhandle);
		int   ObjectEnum();
		/*}}}*/
		/*Param vritual function definitions: {{{*/
		void  GetParameterValue(bool* pbool){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a bool");}
		void  GetParameterValue(int* pinteger){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return an integer");}
		void  GetParameterValue(int** pintarray,int* pM){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return an array of integers");}
		void  GetParameterValue(int** pintarray,int* pM,int* pN){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a array of integers");}
		void  GetParameterValue(IssmDouble* pIssmDouble){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a IssmDouble");}
		void  GetParameterValue(IssmDouble* pdouble,int row,IssmDouble time);
		void  GetParameterValue(IssmDouble* pdouble,IssmDouble time){_error_("Parameter " <<EnumToStringx(enum_type) << " needs row to be specified");}
		void  GetParameterValue(char** pstring){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a string");}
		void  GetParameterValue(char*** pstringarray,int* pM){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a string array");}
		void  GetParameterValue(IssmDouble** pIssmDoublearray,int* pM){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a IssmDouble array");}
		void  GetParameterValue(IssmDouble** pIssmDoublearray,int* pM,int* pN){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a IssmDouble array");}
		void  GetParameterValue(IssmDouble*** parray, int* pM,int** pmdims, int** pndims){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a matrix array");}
		void  GetParameterValue(Vector<IssmDouble>** pvec){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a Vec");}
		void  GetParameterValue(Matrix<IssmDouble>** pmat){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a Mat");}
		void  GetParameterValue(FILE** pfid){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot return a FILE");}
		void  GetParameterValue(DataSet** pdataset){_error_("Param "<< EnumToStringx(enum_type) << " cannot return a DataSet");}
		int   InstanceEnum(){return enum_type;}

		void  SetEnum(int enum_in){this->enum_type = enum_in;};
		void  SetValue(bool boolean){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a boolean");}
		void  SetValue(int integer){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold an integer");}
		void  SetValue(IssmDouble scalar){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a scalar");}
		void  SetValue(char* string){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a string");}
		void  SetValue(char** stringarray,int M){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a string array");}
		void  SetValue(IssmDouble* IssmDoublearray,int M){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a IssmDouble vec array");}
		void  SetValue(IssmDouble* IssmDoublearray,int M,int N){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a IssmDouble array");}
		void  SetValue(int* intarray,int M){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a int vec array");}
		void  SetValue(int* intarray,int M,int N){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a int mat array");};
		void  SetValue(Vector<IssmDouble>* vec){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a Vec");}
		void  SetValue(Matrix<IssmDouble>* mat){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a Mat");}
		void  SetValue(FILE* fid){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold a FILE");}
		void  SetValue(IssmDouble** array, int M, int* mdim_array, int* ndim_array){_error_("Parameter " <<EnumToStringx(enum_type) << " cannot hold an array of matrices");}
		/*}}}*/
};
#endif  /* _TRANSIENTARRAYPARAM_H */
