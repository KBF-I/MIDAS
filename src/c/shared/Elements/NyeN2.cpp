/* \file NyeN2.cpp
 * \brief figure out B of N2 ice for a certain temperature
 *		INPUT function B=NyeN2(temperature)
 *    	where rigidigty (in s^(1/n)Pa) is the flow law paramter in the flow law sigma=B*e(1/n) (Nye, p2000). 
 * 	Added by Kasra - March 2023. To support Nitrogen. 
 *#define _IS_MULTI_ICE_
 */

#include "../io/io.h" 
#include <math.h> 
#include "../Numerics/types.h"

IssmDouble NyeN2(IssmDouble temperature){

	/*Coefficients*/
	const IssmPDouble Rg      = 8.3144598;     /* J mol^-1 K^-1   */ 
	const IssmPDouble A_const = 3.5*pow(10.,-12.0); /* s^-1 MPa        */ 
	const IssmPDouble Q       = 3500.;        /* J mol^-1        */ 
	const IssmPDouble n       = 2.2;            /* Glen's exponent 8.*/    

	/*Arrhenius Law*/
	IssmDouble A = A_const *exp(-Q/(temperature*Rg));  /* s^-1 MPa   */
	IssmDouble B = 1e6*pow(A,-1/n);                    /* s^(1/n) Pa */



	/*Beyond-melting-point cases*/
	if((temperature>75.)&&(temperature<80.)) _printf0_("N2 ICE - POSSIBLE MELTING. Some temperature values are between 750K and 80K.\n");
	else if(temperature>=80.){ _printf0_("N2 ICE - GUARANTEED MELTING. Some temperature values are beyond 80K.\n");}

	/*Return output*/
	return B; 
}
