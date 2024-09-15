#ifndef _CHACO_DEFS_H_
#define _CHACO_DEFS_H_

#define TRUE		1
#define FALSE		0

#ifndef _HAVE_CHACO_ //protect ISSM compilation. This symbol is defined when we compile ISSM

	#define	max(A, B)	((A) > (B) ? (A) : (B))
	#define	min(A, B)	((A) < (B) ? (A) : (B))
	#define sign(A)		((A) <  0  ? -1  :  1)
	#define absval(A)	((A) <  0  ? -(A): (A))

	/* Define constants that are needed in various places */
	#define	PI	3.141592653589793
	#define	TWOPI	6.283185307179586
	#define HALFPI  1.570796326794896

    #define check_graph chaco_check_graph


	#ifdef MATLAB
		#include "mat.h"
		#include "mex.h"
		#include "matrix.h"
	   
		#define printf mexPrintf
		#define fprintf(file,...) (file == stdout || file == stderr ? mexPrintf(__VA_ARGS__) : fprintf(file,__VA_ARGS__))
		#define malloc mxMalloc
		#define calloc mxCalloc
		#define realloc mxRealloc
		#define free mxFree
		#define exit(status) mexErrMsgTxt("exit=" #status)

	#endif

#endif  //#ifndef _HAVE_CHACO_ 

#endif //ifndef _CHACO_DEFS_H_
