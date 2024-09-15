/*\file Print.h
 *\brief: print I/O for ISSM
 */
//M4.2 _IS_MULTI_ICE_

#ifndef _ISSM_PRINT_H_
#define _ISSM_PRINT_H_

#ifdef HAVE_CONFIG_H
#include <config.h>
#else
#error "Cannot compile with HAVE_CONFIG_H symbol! run configure first!"
#endif 

/*Only include forward declaration to save compile time*/
#include <iosfwd>
#include <sstream>

using namespace std;
/*macros:*/
/* _printf_{{{*/
/* macro to print some string on all cpus */
#define _printf_(StreamArgs)\
  do{std::ostringstream aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy; \
	  aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy << StreamArgs; \
	  PrintfFunctionOnAllCpus(aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy.str());}while(0)
/*}}}*/
/* _printf0_ {{{*/
/* macro to print some string only on cpu 0 */
#define _printf0_(StreamArgs)\
  do{std::ostringstream aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy; \
	  aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy << StreamArgs; \
	  PrintfFunctionOnCpu0(aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy.str());}while(0)
/*}}}*/

//** M4.2a+: This is a message writing macro to help with the debugging... 
/* macro to print some string on all cpus with an indicator*/
#define _debug_(StreamArgs_file, StreamArgs_line, StreamArgs_func, StreamArgs_msg  )\
  do{std::ostringstream aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy; \
	 std::ostringstream l098; std::stringstream f098; std::ostringstream m098; \
	  l098 << StreamArgs_line; f098 <<   StreamArgs_func; m098 << StreamArgs_msg; \
	  aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy << StreamArgs_file; \
	  PrintfFunctionOnAllCpus("\nDEBUG says: file:line_nbr= " + aLoNgAnDwEiRdLoCaLnAmeFoRtHiSmAcRoOnLy.str()+":"+l098.str() + ", func="+f098.str()+", msg="+m098.str() + "\n \n")   ;}while(0)
/*}}}*/
void WhoCalled();
void WhoCalled2File(std::string param);
void WhoCalled(bool q_run_now,  int  param_enum);
void WhoCalled(bool q_run_now,  const char*  param_enum);
//M4.2a-/

/*functions: */
int PrintfFunctionOnCpu0(const string & message);
int PrintfFunctionOnAllCpus(const string & message);

#endif	
