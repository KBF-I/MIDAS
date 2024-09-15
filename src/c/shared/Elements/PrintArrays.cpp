#include "./elements.h"
#include "../io/Print/Print.h"
#include <iomanip>
using namespace std;

void printarray(IssmPDouble* array,int lines,int cols){
	_printf_("\n");
	for(int i=0;i<lines;i++){  
		_printf_("   [ ");
		for(int j=0;j<cols;j++) _printf_( " " << setw(11) << setprecision (5) << array[i*cols+j]);
		_printf_(" ]\n");
	}  
	_printf_("\n");
}
#ifdef _HAVE_AD_
void printarray(IssmDouble* array,int lines,int cols){
	_printf_("\n");
	for(int i=0;i<lines;i++){  
		_printf_("   [ ");
		for(int j=0;j<cols;j++) _printf_( " " << setw(11) << setprecision (5) << array[i*cols+j]);
		_printf_(" ]\n");
	}  
	_printf_("\n");
}
#endif
void printsparsity(IssmPDouble* array,int lines,int cols){
	int count;
	_printf_("\n");
	for(int i=0;i<lines;i++){  
		_printf_("   [ ");
		count = 0;
		for(int j=0;j<cols;j++){
			if(array[i*cols+j]!=0.0){
				_printf_( " X"); count++;
			}
			else
			 _printf_( " .");
		}
		_printf_(" ] "<<i<<" => "<<count << "\n");
	}  
	_printf_("\n");
}
void printarray(int* array,int lines,int cols){
	_printf_("\n");
	for(int i=0;i<lines;i++){  
		_printf_("   [ ");
		for(int j=0;j<cols;j++) _printf_( " " << setw(11) << setprecision (5) << array[i*cols+j]);
		_printf_(" ]\n");
	}  
	_printf_("\n");
}
void printarray_matlab(const char* filename,int* array,int lines,int cols){
	FILE *f = fopen(filename,"w");
	fprintf(f,"%% Matrix of size %ix%i\n",lines,cols);
	fprintf(f,"\n");
	fprintf(f,"A=[...\n");
	for(int i=0;i<lines;i++){  
		for(int j=0;j<cols;j++) fprintf(f," %i",array[i*cols+j]);
		fprintf(f,"\n");
	}  
	fprintf(f,"];\n");
	fclose(f);
}
void printarray(bool* array,int lines,int cols){
	_printf_("\n");
	for(int i=0;i<lines;i++){  
		_printf_("   [ ");
		for(int j=0;j<cols;j++){
			if(array[i*cols+j]) _printf_( " 1");
			else _printf_( " 0");
		}
		_printf_(" ]\n");
	}  
	_printf_("\n");
}
void printbinary(int n){
	unsigned int i=1L<<(sizeof(n)*8-1);
	while (i>0) {
		if (n&i)
		 _printf_("1");
		else
		 _printf_("0");
		i>>=1;
	}
}
