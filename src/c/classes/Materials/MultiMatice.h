#define _IS_MULTI_ICE_

#ifndef MULTIMATICE_H_
#define MULTIMATICE_H_

#include "./Material.h"
class Element;
class Gauss;
class Input;
#ifdef _IS_MULTI_ICE_
class MultiMatice: public Matice{
	public: 
		/*MultiMatice constructors, destructors: {{{*/
		MultiMatice();
		MultiMatice(int mid,int i, IoModel* iomodel);
		MultiMatice(int mid,int i, int materialtype);
		~MultiMatice();
		void Init(int mid,int i, int materialtype);
		Object* copy();
		void  DeepEcho();
		void  Echo();
		int   Id(); 
		void  Marshall(MarshallHandle* marshallhandle);
		int   ObjectEnum();
		void   Configure(Elements* elements);
		Material*  copy2(Element* element);
		IssmDouble GetMaterialValue(int materialPropEnum);
};
#endif
#endif  /* MULTIMATICE_H_ */

