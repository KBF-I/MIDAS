/*\file PrintfFunction.c
 *\brief: this function is used by the _printf_ macro, to take into account the 
 *fact we may be running on a cluster. 
 */
//M4.2 _IS_MULTI_ICE_

#ifdef HAVE_CONFIG_H
	#include <config.h>
#else
#error "Cannot compile with HAVE_CONFIG_H symbol! run configure first!"
#endif

#include <stdarg.h>
#include <cstdio>
#include <string>
#include <iostream>
#include <iomanip>

//M4.2+
#include <execinfo.h>  
#include <iostream>
#include <fstream>
#include <string.h>
//M4.2-

#ifdef _HAVE_ANDROID_NDK_
#include <android/log.h>
#endif
#include "./Print.h"
#include "../Comm/IssmComm.h"
#include "../../String/sharedstring.h"
#include "../../MemOps/MemOps.h"

int PrintfFunctionOnCpu0(const string & message){

	/*recover my_rank:*/
	int my_rank=IssmComm::GetRank();

	if(my_rank==0){
		#ifdef _HAVE_ANDROID_JNI_
		__android_log_print(ANDROID_LOG_INFO, "Native",message.c_str());
		#elif _IS_MSYS2_
		printf("%s",message.c_str());
		#else
		ApiPrintf(message.c_str());
		#endif
	}
	return 1;
}
int PrintfFunctionOnAllCpus(const string & message){

	#ifdef _HAVE_ANDROID_JNI_
	__android_log_print(ANDROID_LOG_INFO, "Native",message.c_str());
	#elif _IS_MSYS2_
	printf("%s",message.c_str());
	#else
	ApiPrintf(message.c_str());
	#endif

	return 1;
}


//M4.2a+
void WhoCalled (){
	void *buffer[100]; char **strings;
		
	int nptrs = backtrace(buffer, 100);
	printf("backtrace() returned %d addresses\n", nptrs);
	strings = backtrace_symbols(buffer, nptrs);
	for (int j = 0; j < nptrs; j++)
		printf("%s\n", strings[j]);
	free(strings);
}

void WhoCalled2File(std::string   msgStream){
	void *buffer[100]; char **strings;
	std::ofstream file; 
	file.open("myfile.txt", std::ios_base::app);
		
	int nptrs = backtrace(buffer, 100);
	strings = backtrace_symbols(buffer, nptrs);
	file << "----------------"<<endl;
	file << msgStream<< endl; 
	file << "backtrace() returned addresses: " << nptrs << endl;
	for (int j = 0; j < nptrs; j++)
		file << strings[j] << endl;file.close();  

	free(strings);
	file.close(); 
}

void WhoCalled(bool q_run_now,  int  param_enum){
	if(q_run_now){
		_debug_(__FILE__, __LINE__, __func__, param_enum);
		WhoCalled();
	}
}

void WhoCalled(bool q_run_now,  const char*  param_enum){
	if(q_run_now){
		_debug_(__FILE__, __LINE__, __func__, param_enum);
		WhoCalled();
    }
}
//M4.2a-