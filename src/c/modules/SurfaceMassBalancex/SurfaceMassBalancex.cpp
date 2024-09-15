/*!\file SurfaceMassBalancex
 * \brief: calculates SMB
 */

#include <config.h>
#include "./SurfaceMassBalancex.h"
#include "../../shared/shared.h"
#include "../../toolkits/toolkits.h"
#include "../modules.h"
#include "../../classes/Inputs/TransientInput.h"
#include "../../shared/Random/random.h"

void SmbForcingx(FemModel* femmodel){/*{{{*/

	// void SmbForcingx(smb,ni){
	//    INPUT parameters: ni: working size of arrays
	//    OUTPUT: mass-balance (m/yr ice): agd(NA)

}/*}}}*/
void SmbGradientsx(FemModel* femmodel){/*{{{*/

	// void SurfaceMassBalancex(hd,agd,ni){
	//    INPUT parameters: ni: working size of arrays
	//    INPUT: surface elevation (m): hd(NA)
	//    OUTPUT: mass-balance (m/yr ice): agd(NA)
	int v;
	IssmDouble rho_water;                   // density of fresh water
	IssmDouble rho_ice;                     // density of ice
	IssmDouble yts;								// conversion factor year to second

	/*Loop over all the elements of this partition*/
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/*Allocate all arrays*/
		int         numvertices = element->GetNumberOfVertices();
		IssmDouble* Href        = xNew<IssmDouble>(numvertices); // reference elevation from which deviations are used to calculate the SMB adjustment
		IssmDouble* Smbref      = xNew<IssmDouble>(numvertices); // reference SMB to which deviations are added
		IssmDouble* b_pos       = xNew<IssmDouble>(numvertices); // Hs-SMB relation parameter
		IssmDouble* b_neg       = xNew<IssmDouble>(numvertices); // Hs-SMB relation paremeter
		IssmDouble* s           = xNew<IssmDouble>(numvertices); // surface elevation (m)
		IssmDouble* smb         = xNew<IssmDouble>(numvertices);

		/*Recover SmbGradients*/
		element->GetInputListOnVertices(Href,SmbHrefEnum);
		element->GetInputListOnVertices(Smbref,SmbSmbrefEnum);
		element->GetInputListOnVertices(b_pos,SmbBPosEnum);
		element->GetInputListOnVertices(b_neg,SmbBNegEnum);

		/*Recover surface elevation at vertices: */
		element->GetInputListOnVertices(s,SurfaceEnum);

		/*Get material parameters :*/
		rho_ice=element->FindParam(MaterialsRhoIceEnum);
		rho_water=element->FindParam(MaterialsRhoFreshwaterEnum);

		/* Get constants */
		femmodel->parameters->FindParam(&yts,ConstantsYtsEnum);

		// loop over all vertices
		for(v=0;v<numvertices;v++){
			if(Smbref[v]>0){
				smb[v]=Smbref[v]+b_pos[v]*(s[v]-Href[v]);
			}
			else{
				smb[v]=Smbref[v]+b_neg[v]*(s[v]-Href[v]);
			}

			smb[v]=smb[v]/1000*rho_water/rho_ice;      // SMB in m/y ice
		}  //end of the loop over the vertices

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smb,P1Enum);
		xDelete<IssmDouble>(Href);
		xDelete<IssmDouble>(Smbref);
		xDelete<IssmDouble>(b_pos);
		xDelete<IssmDouble>(b_neg);
		xDelete<IssmDouble>(s);
		xDelete<IssmDouble>(smb);
	}

}/*}}}*/
void SmbGradientsElax(FemModel* femmodel){/*{{{*/

	// void SurfaceMassBalancex(hd,agd,ni){
	//    INPUT parameters: ni: working size of arrays
	//    INPUT: surface elevation (m): hd(NA)
	//    OUTPUT: surface mass-balance (m/yr ice): agd(NA)
	int v;

	/*Loop over all the elements of this partition*/
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/*Allocate all arrays*/
		int         numvertices = element->GetNumberOfVertices();
		IssmDouble* ela       = xNew<IssmDouble>(numvertices); // Equilibrium Line Altitude (m a.s.l) to which deviations are used to calculate the SMB
		IssmDouble* b_pos       = xNew<IssmDouble>(numvertices); // SMB gradient above ELA (m ice eq. per m elevation change)
		IssmDouble* b_neg       = xNew<IssmDouble>(numvertices); // SMB gradient below ELA (m ice eq. per m elevation change)
		IssmDouble* b_max       = xNew<IssmDouble>(numvertices); // Upper cap on SMB rate (m/y ice eq.)
		IssmDouble* b_min       = xNew<IssmDouble>(numvertices); // Lower cap on SMB rate (m/y ice eq.)
		IssmDouble* s           = xNew<IssmDouble>(numvertices); // Surface elevation (m a.s.l.)
		IssmDouble* smb         = xNew<IssmDouble>(numvertices); // SMB (m/y ice eq.)

		/*Recover ELA, SMB gradients, and caps*/
		element->GetInputListOnVertices(ela,SmbElaEnum);
		element->GetInputListOnVertices(b_pos,SmbBPosEnum);
		element->GetInputListOnVertices(b_neg,SmbBNegEnum);
		element->GetInputListOnVertices(b_max,SmbBMaxEnum);
		element->GetInputListOnVertices(b_min,SmbBMinEnum);

		/*Recover surface elevation at vertices: */
		element->GetInputListOnVertices(s,SurfaceEnum);

		/*Loop over all vertices, calculate SMB*/
		for(v=0;v<numvertices;v++){
			// if surface is above the ELA
			if(s[v]>ela[v]){
				smb[v]=b_pos[v]*(s[v]-ela[v]);
			}
			// if surface is below or equal to the ELA
			else{
				smb[v]=b_neg[v]*(s[v]-ela[v]);
			}

			// if SMB is larger than upper cap, set SMB to upper cap
			if(smb[v]>b_max[v]){
				smb[v]=b_max[v];
			}
			// if SMB is smaller than lower cap, set SMB to lower cap
			if(smb[v]<b_min[v]){
				smb[v]=b_min[v];
			}
		}  //end of the loop over the vertices

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smb,P1Enum);
		xDelete<IssmDouble>(ela);
		xDelete<IssmDouble>(b_pos);
		xDelete<IssmDouble>(b_neg);
		xDelete<IssmDouble>(b_max);
		xDelete<IssmDouble>(b_min);
		xDelete<IssmDouble>(s);
		xDelete<IssmDouble>(smb);

	}

}/*}}}*/
void Smbarmax(FemModel* femmodel){/*{{{*/

   /*Get time parameters*/
   IssmDouble time,dt,starttime,tstep_arma;
   femmodel->parameters->FindParam(&time,TimeEnum);
   femmodel->parameters->FindParam(&dt,TimesteppingTimeStepEnum);
   femmodel->parameters->FindParam(&starttime,TimesteppingStartTimeEnum);
   femmodel->parameters->FindParam(&tstep_arma,SmbARMATimestepEnum);

   /*Determine if this is a time step for the ARMA model*/
   bool isstepforarma = false;

   #ifndef _HAVE_AD_
   if((fmod(time,tstep_arma)<fmod((time-dt),tstep_arma)) || (time<=starttime+dt) || tstep_arma==dt) isstepforarma = true;
   #else
   _error_("not implemented yet");
   #endif

   /*Load parameters*/
   bool isstochastic;
   bool issmbstochastic = false;
   int M,N,arorder,maorder,numbasins,numparams,numbreaks,numelevbins,my_rank;
   femmodel->parameters->FindParam(&numbasins,SmbNumBasinsEnum);
   femmodel->parameters->FindParam(&numparams,SmbNumParamsEnum);
   femmodel->parameters->FindParam(&numbreaks,SmbNumBreaksEnum);
	femmodel->parameters->FindParam(&arorder,SmbARMAarOrderEnum);
   femmodel->parameters->FindParam(&maorder,SmbARMAmaOrderEnum);
   femmodel->parameters->FindParam(&numelevbins,SmbNumElevationBinsEnum);
   IssmDouble* datebreaks    = NULL;
	IssmDouble* arlagcoefs    = NULL;
   IssmDouble* malagcoefs    = NULL;
	IssmDouble* polyparams    = NULL;
   IssmDouble* lapserates    = NULL;
   IssmDouble* elevbins      = NULL;
   IssmDouble* refelevation  = NULL;

   femmodel->parameters->FindParam(&datebreaks,&M,&N,SmbARMAdatebreaksEnum);             _assert_(M==numbasins); _assert_(N==max(numbreaks,1));
   femmodel->parameters->FindParam(&polyparams,&M,&N,SmbARMApolyparamsEnum);             _assert_(M==numbasins); _assert_(N==(numbreaks+1)*numparams);
	femmodel->parameters->FindParam(&arlagcoefs,&M,&N,SmbARMAarlagcoefsEnum);             _assert_(M==numbasins); _assert_(N==arorder);
   femmodel->parameters->FindParam(&malagcoefs,&M,&N,SmbARMAmalagcoefsEnum);             _assert_(M==numbasins); _assert_(N==maorder);
   femmodel->parameters->FindParam(&lapserates,&M,&N,SmbLapseRatesEnum);                 _assert_(M==numbasins); _assert_(N==numelevbins*12);
   femmodel->parameters->FindParam(&elevbins,&M,&N,SmbElevationBinsEnum);                _assert_(M==numbasins); _assert_(N==(numelevbins-1)*12);
   femmodel->parameters->FindParam(&refelevation,&M,SmbRefElevationEnum);                _assert_(M==numbasins);

   femmodel->parameters->FindParam(&isstochastic,StochasticForcingIsStochasticForcingEnum);
   if(isstochastic){
      int  numstochasticfields;
      int* stochasticfields;
      femmodel->parameters->FindParam(&numstochasticfields,StochasticForcingNumFieldsEnum);
      femmodel->parameters->FindParam(&stochasticfields,&N,StochasticForcingFieldsEnum); _assert_(N==numstochasticfields);
      for(int i=0;i<numstochasticfields;i++){
         if(stochasticfields[i]==SMBarmaEnum) issmbstochastic = true;
      }
      xDelete<int>(stochasticfields);
   }

   /*Loop over each element to compute SMB at vertices*/
   for(Object* &object:femmodel->elements->objects){
      Element* element = xDynamicCast<Element*>(object);
      /*Compute ARMA*/
		element->ArmaProcess(isstepforarma,arorder,maorder,numparams,numbreaks,tstep_arma,polyparams,arlagcoefs,malagcoefs,datebreaks,issmbstochastic,SMBarmaEnum);
		/*Compute lapse rate adjustment*/
		element->LapseRateBasinSMB(numelevbins,lapserates,elevbins,refelevation);
	}

   /*Cleanup*/
   xDelete<IssmDouble>(arlagcoefs);
   xDelete<IssmDouble>(malagcoefs);
	xDelete<IssmDouble>(polyparams);
   xDelete<IssmDouble>(datebreaks);
   xDelete<IssmDouble>(lapserates);
   xDelete<IssmDouble>(elevbins);
   xDelete<IssmDouble>(refelevation);
}/*}}}*/
void Delta18oParameterizationx(FemModel* femmodel){/*{{{*/

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		element->Delta18oParameterization();
	}

}/*}}}*/
void MungsmtpParameterizationx(FemModel* femmodel){/*{{{*/

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		element->MungsmtpParameterization();
	}

}/*}}}*/
void Delta18opdParameterizationx(FemModel* femmodel){/*{{{*/

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		element->Delta18opdParameterization();
	}

}/*}}}*/
void PositiveDegreeDayx(FemModel* femmodel){/*{{{*/

	// void PositiveDegreeDayx(hd,vTempsea,vPrec,agd,Tsurf,ni){
	//    note "v" prefix means 12 monthly means, ie time dimension
	//    INPUT parameters: ni: working size of arrays
	//    INPUT: surface elevation (m): hd(NA)
	//    monthly mean surface sealevel temperature (degrees C): vTempsea(NA
	//    ,NTIME)
	//    monthly mean precip rate (m/yr water equivalent): vPrec(NA,NTIME)
	//    OUTPUT: mass-balance (m/yr ice): agd(NA)
	//    mean annual surface temperature (degrees C): Tsurf(NA)

	int    it, jj, itm;
	IssmDouble DT = 0.02, sigfac, snormfac;
	IssmDouble signorm = 5.5;      // signorm : sigma of the temperature distribution for a normal day
	IssmDouble siglim;       // sigma limit for the integration which is equal to 2.5 sigmanorm
	IssmDouble signormc = signorm - 0.5;     // sigma of the temperature distribution for cloudy day
	IssmDouble siglimc, siglim0, siglim0c;
	IssmDouble tstep, tsint, tint, tstepc;
	int    NPDMAX = 1504, NPDCMAX = 1454;
	//IssmDouble pdds[NPDMAX]={0};
	//IssmDouble pds[NPDCMAX]={0};
	IssmDouble pddt, pd ; // pd : snow/precip fraction, precipitation falling as snow
	IssmDouble PDup, PDCUT = 2.0;    // PDcut: rain/snow cutoff temperature (C)
	IssmDouble tstar; // monthly mean surface temp

	bool ismungsm;
	bool issetpddfac;

	IssmDouble *pdds    = NULL;
	IssmDouble *pds     = NULL;
	Element    *element = NULL;

	pdds=xNew<IssmDouble>(NPDMAX+1);
	pds=xNew<IssmDouble>(NPDCMAX+1);

	// Get ismungsm parameter
	femmodel->parameters->FindParam(&ismungsm,SmbIsmungsmEnum);

	// Get issetpddfac parameter
	femmodel->parameters->FindParam(&issetpddfac,SmbIssetpddfacEnum);

	/* initialize PDD (creation of a lookup table)*/
	tstep    = 0.1;
	tsint    = tstep*0.5;
	sigfac   = -1.0/(2.0*pow(signorm,2));
	snormfac = 1.0/(signorm*sqrt(2.0*acos(-1.0)));
	siglim   = 2.5*signorm;
	siglimc  = 2.5*signormc;
	siglim0  = siglim/DT + 0.5;
	siglim0c = siglimc/DT + 0.5;
	PDup     = siglimc+PDCUT;

	itm = reCast<int,IssmDouble>((2*siglim/DT + 1.5));

	if(itm >= NPDMAX) _error_("increase NPDMAX in massBalance.cpp");
	for(it = 0; it < itm; it++){
		//    tstar = REAL(it)*DT-siglim;
		tstar = it*DT-siglim;
		tint = tsint;
		pddt = 0.;
		for ( jj = 0; jj < 600; jj++){
			if (tint > (tstar+siglim)){break;}
			pddt = pddt + tint*exp(sigfac*(pow((tint-tstar),2)))*tstep;
			tint = tint+tstep;
		}
		pdds[it] = pddt*snormfac;
	}
	pdds[itm+1] = siglim + DT;

	//*********compute PD(T) : snow/precip fraction. precipitation falling as snow
	tstepc   = 0.1;
	tsint    = PDCUT-tstepc*0.5;
	signormc = signorm - 0.5;
	sigfac   = -1.0/(2.0*pow(signormc,2));
	snormfac = 1.0/(signormc*sqrt(2.0*acos(-1.0)));
	siglimc  = 2.5*signormc ;
	itm = reCast<int,IssmDouble>((PDCUT+2.*siglimc)/DT + 1.5);
	if(itm >= NPDCMAX) _error_("increase NPDCMAX in p35com");
	for(it = 0; it < itm; it++ ){
		tstar = it*DT-siglimc;
		//    tstar = REAL(it)*DT-siglimc;
		tint = tsint;          // start against upper bound
		pd = 0.;
		for (jj = 0; jj < 600; jj++){
			if (tint<(tstar-siglimc)) {break;}
			pd = pd + exp(sigfac*(pow((tint-tstar),2)))*tstepc;
			tint = tint-tstepc;
		}
		pds[it] = pd*snormfac;  // gaussian integral lookup table for snow fraction
	}
	pds[itm+1] = 0.;
	//     *******END initialize PDD

	for(Object* & object : femmodel->elements->objects){
		element=xDynamicCast<Element*>(object);
		element->PositiveDegreeDay(pdds,pds,signorm,ismungsm,issetpddfac);
	}
	/*free ressouces: */
	xDelete<IssmDouble>(pdds);
	xDelete<IssmDouble>(pds);
}/*}}}*/
void PositiveDegreeDaySicopolisx(FemModel* femmodel){/*{{{*/

	bool isfirnwarming;
	femmodel->parameters->FindParam(&isfirnwarming,SmbIsfirnwarmingEnum);

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		element->PositiveDegreeDaySicopolis(isfirnwarming);
	}

}/*}}}*/
void SmbHenningx(FemModel* femmodel){/*{{{*/

	/*Intermediaries*/
	IssmDouble  z_critical = 1675.;
	IssmDouble  dz = 0;
	IssmDouble  a = -15.86;
	IssmDouble  b = 0.00969;
	IssmDouble  c = -0.235;
	IssmDouble  f = 1.;
	IssmDouble  g = -0.0011;
	IssmDouble  h = -1.54e-5;
	IssmDouble  smb,smbref,anomaly,yts,z;

	/* Get constants */
	femmodel->parameters->FindParam(&yts,ConstantsYtsEnum);
	/*iomodel->FindConstant(&yts,"md.constants.yts");*/
	/*this->parameters->FindParam(&yts,ConstantsYtsEnum);*/
	/*Mathieu original*/
	/*IssmDouble  smb,smbref,z;*/

	/*Loop over all the elements of this partition*/
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/*Get reference SMB (uncorrected) and allocate all arrays*/
		int         numvertices = element->GetNumberOfVertices();
		IssmDouble* surfacelist = xNew<IssmDouble>(numvertices);
		IssmDouble* smblistref  = xNew<IssmDouble>(numvertices);
		IssmDouble* smblist     = xNew<IssmDouble>(numvertices);
		element->GetInputListOnVertices(surfacelist,SurfaceEnum);
		element->GetInputListOnVertices(smblistref,SmbSmbrefEnum);

		/*Loop over all vertices of element and correct SMB as a function of altitude z*/
		for(int v=0;v<numvertices;v++){

			/*Get vertex elevation, anoma smb*/
			z      = surfacelist[v];
			anomaly = smblistref[v];

			/* Henning edited acc. to Riannes equations*/
			/* Set SMB maximum elevation, if dz = 0 -> z_critical = 1675 */
			z_critical = z_critical + dz;

			/* Calculate smb acc. to the surface elevation z */
			if(z<z_critical){
				smb = a + b*z + c;
			}
			else{
				smb = (a + b*z)*(f + g*(z-z_critical) + h*(z-z_critical)*(z-z_critical)) + c;
			}

			/* Compute smb including anomaly,
				correct for number of seconds in a year [s/yr]*/
			smb = smb/yts + anomaly;

			/*Update array accordingly*/
			smblist[v] = smb;

		}

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smblist,P1Enum);
		xDelete<IssmDouble>(surfacelist);
		xDelete<IssmDouble>(smblistref);
		xDelete<IssmDouble>(smblist);
	}

}/*}}}*/
void SmbComponentsx(FemModel* femmodel){/*{{{*/

	// void SmbComponentsx(acc,evap,runoff,ni){
	//    INPUT parameters: ni: working size of arrays
	//    INPUT: surface accumulation (m/yr water equivalent): acc
	//    surface evaporation (m/yr water equivalent): evap
	//    surface runoff (m/yr water equivalent): runoff
	//    OUTPUT: mass-balance (m/yr ice): agd(NA)

	/*Loop over all the elements of this partition*/
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/*Allocate all arrays*/
		int         numvertices = element->GetNumberOfVertices();
		IssmDouble* acc         = xNew<IssmDouble>(numvertices);
		IssmDouble* evap        = xNew<IssmDouble>(numvertices);
		IssmDouble* runoff      = xNew<IssmDouble>(numvertices);
		IssmDouble* smb         = xNew<IssmDouble>(numvertices);

		/*Recover Smb Components*/
		element->GetInputListOnVertices(acc,SmbAccumulationEnum);
		element->GetInputListOnVertices(evap,SmbEvaporationEnum);
		element->GetInputListOnVertices(runoff,SmbRunoffEnum);

		// loop over all vertices
		for(int v=0;v<numvertices;v++) smb[v]=acc[v]-evap[v]-runoff[v];

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smb,P1Enum);
		xDelete<IssmDouble>(acc);
		xDelete<IssmDouble>(evap);
		xDelete<IssmDouble>(runoff);
		xDelete<IssmDouble>(smb);
	}

}/*}}}*/
void SmbMeltComponentsx(FemModel* femmodel){/*{{{*/

	// void SmbMeltComponentsx(acc,evap,melt,refreeze,ni){
	//    INPUT parameters: ni: working size of arrays
	//    INPUT: surface accumulation (m/yr water equivalent): acc
	//    surface evaporation (m/yr water equivalent): evap
	//    surface melt (m/yr water equivalent): melt
	//    refreeze of surface melt (m/yr water equivalent): refreeze
	//    OUTPUT: mass-balance (m/yr ice): agd(NA)

	/*Loop over all the elements of this partition*/
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/*Allocate all arrays*/
		int         numvertices = element->GetNumberOfVertices();
		IssmDouble* acc         = xNew<IssmDouble>(numvertices);
		IssmDouble* evap        = xNew<IssmDouble>(numvertices);
		IssmDouble* melt        = xNew<IssmDouble>(numvertices);
		IssmDouble* refreeze    = xNew<IssmDouble>(numvertices);
		IssmDouble* smb         = xNew<IssmDouble>(numvertices);

		/*Recover Smb Components*/
		element->GetInputListOnVertices(acc,SmbAccumulationEnum);
		element->GetInputListOnVertices(evap,SmbEvaporationEnum);
		element->GetInputListOnVertices(melt,SmbMeltEnum);
		element->GetInputListOnVertices(refreeze,SmbRefreezeEnum);

		// loop over all vertices
		for(int v=0;v<numvertices;v++) smb[v]=acc[v]-evap[v]-melt[v]+refreeze[v];

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smb,P1Enum);
		xDelete<IssmDouble>(acc);
		xDelete<IssmDouble>(evap);
		xDelete<IssmDouble>(melt);
		xDelete<IssmDouble>(refreeze);
		xDelete<IssmDouble>(smb);
	}

}/*}}}*/
void SmbDebrisMLx(FemModel* femmodel){/*{{{*/

	//      The function is based on:
	//      Evatt GW, Abrahams ID, Heil M, Mayer C, Kingslake J, Mitchell SL, et al. Glacial melt under a porous debris layer. Journal of Glaciology 61 (2015) 825–836, doi:10.3189/2
	//      Constants/Values are taken from Mayer, Licciulli (2021): https://www.frontiersin.org/articles/10.3389/feart.2021.710276/full#B7
	//      function taken from https://github.com/carlolic/DebrisExp/blob/main/USFs/USF_DebrisCoverage.f90

	/*Intermediaries*/
	// altitude gradients of the crucial parameters (radiation from Marty et al., TaAClimat; 2002)
	IssmDouble LW=2.9;          // W/m^2 /100m                       2.9
	IssmDouble SW=1.3;          // W/m^2 /100m                       1.3
	IssmDouble HumidityG=0;     // % /100m         rough estimate
	IssmDouble AirTemp=0.7;     // C /100m
	IssmDouble WindSpeed=0.02;  // m/s /100m       rough estimate    0.2

	// accumulation follows a linear increase above the ELA up to a plateau
	IssmDouble AccG=0.1;                    // m w.e. /100m
	IssmDouble AccMax=1.;                    // m w.e.
	IssmDouble ReferenceElevation; 
	IssmDouble AblationDays=120.;            //

	IssmDouble In=100.;                 // Wm^-2        incoming long wave
	IssmDouble Q=500.;                  // Wm^-2        incoming short wave
	IssmDouble K=0.585;                // Wm^-1K^-1    thermal conductivity          0.585
	IssmDouble Qm=0.0012;              // kg m^-3      measured humiditiy level
	IssmDouble Qh=0.006 ;              // kg m^-3      saturated humidity level
	IssmDouble Tm=2.;                   // C            air temperature
	IssmDouble Rhoaa=1.22;             // kgm^-3       air densitiy
	IssmDouble Um=1.5;                 // ms^-1        measured wind speed
	IssmDouble Xm=1.5;                 // ms^-1        measurement height
        IssmDouble Xr=0.01;                // ms^-1        surface roughness             0.01
        IssmDouble Alphad=0.07;            //              debris albedo                 0.07
        IssmDouble Alphai=0.4;             //              ice ablbedo
        IssmDouble Alphaeff;
        IssmDouble Ustar=0.16;             // ms^-1        friction velocity             0.16
        IssmDouble Ca=1000.;                // jkg^-1K^-1   specific heat capacity of air
        IssmDouble Lm;//=3.34E+05;            // jkg^-1K^-1   latent heat of ice melt
        IssmDouble Lv=2.50E+06;            // jkg^-1K^-1   latent heat of evaporation
        IssmDouble Tf=273.;                 // K            water freeezing temperature
        IssmDouble Eps=0.95;               //              thermal emissivity
        IssmDouble Rhoi=900.;               // kgm^-3       ice density
        IssmDouble Sigma=5.67E-08;         // Wm^-2K^-4    Stefan Boltzmann constant
        IssmDouble Kstar=0.4;              //              von kármán constant
        IssmDouble Gamma=180.;              // m^-1         wind speed attenuation        234
	IssmDouble PhiD;//=0.005;              //              debris packing fraction       0.01
	IssmDouble Humidity=0.2;           //              relative humidity

	IssmDouble smb,yts,z,debris;
	IssmDouble MassBalanceCmDayDebris,MassBalanceMYearDebris;
	bool isdebris;
	int domaintype;
	femmodel->parameters->FindParam(&isdebris,TransientIsdebrisEnum);

	/*Get material parameters and constants */
	//femmodel->parameters->FindParam(&Rhoi,MaterialsRhoIceEnum); // Note Carlo's model used as  benchmark was run with different densities for debris and FS
	femmodel->parameters->FindParam(&Lm,MaterialsLatentheatEnum);
	femmodel->parameters->FindParam(&yts,ConstantsYtsEnum); 
	PhiD=0.;
	if(isdebris) femmodel->parameters->FindParam(&PhiD,DebrisPackingFractionEnum);

	/* Loop over all the elements of this partition */
	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);

		/* Allocate all arrays */
		int         numvertices=element->GetNumberOfVertices();
		IssmDouble* surfacelist=xNew<IssmDouble>(numvertices);
		IssmDouble* smb=xNew<IssmDouble>(numvertices);
		IssmDouble* debriscover=xNew<IssmDouble>(numvertices);
		element->GetInputListOnVertices(surfacelist,SurfaceEnum);

		/* Get inputs */
		element->GetInputListOnVertices(debriscover,DebrisThicknessEnum);
		element->FindParam(&domaintype,DomainTypeEnum);		

		/*Loop over all vertices of element and calculate SMB as function of Debris Cover and z */
		for(int v=0;v<numvertices;v++){

			/*Get vertex elevation */
			z=surfacelist[v];

			/*Get top element*/
			//if(domaintype==Domain3DEnum){

			//}else{
			//	Alphaeff=Alphad;
			//	ReferenceElevation=2200.;     // m M&L                        	
			//}

			/* compute smb */
			for (int ismb=0;ismb<2;ismb++){
				if(ismb==0){
					// calc a reference smb to identify accum and melt region; debris only develops in ablation area
					debris=0.;
					PhiD=0.;
				}else{
					// only in the meltregime debris develops
					if(-MassBalanceCmDayDebris<1e-14) debris=debriscover[v]; 
				}
				if(debris<=0.) debris=0.;
				IssmDouble dk=1e-5; // TODO make Alphad and Alphai a user input
				IssmDouble n=debris/dk;
				IssmDouble nmax=1000;
				IssmDouble Alphaeff;
				if(n>nmax){
					Alphaeff=Alphad;
				} else {
					Alphaeff=Alphai+n*(Alphad-Alphai)/nmax;
				}
				ReferenceElevation=3200.;     // m HEF


				Alphaeff=Alphad;
				ReferenceElevation=2200.;     // m M&L  

				MassBalanceCmDayDebris=(((In-(z-ReferenceElevation)*LW/100.)-(Eps*Sigma*(Tf*Tf*Tf*Tf))+ 
							(Q+(z-ReferenceElevation)*SW/100.)*(1.-Alphaeff)+ 
							(Rhoaa*Ca*Ustar*Ustar)/((Um-(z-ReferenceElevation)* 
									WindSpeed/100.)-Ustar*(2.-(exp(Gamma*Xr))))*(Tm-(z- 
										ReferenceElevation)*AirTemp/100.))/((1-PhiD)*Rhoi*Lm)/(1.+ 
									((Rhoaa*Ca*Ustar*Ustar)/((Um-(z-ReferenceElevation)* 
											WindSpeed/100.)-Ustar*(2.-(exp(Gamma*Xr))))+4.*Eps*Sigma*(Tf*Tf*Tf))/ 
									K*debris)-(Lv*Ustar*Ustar*(Qh-(Qh*(Humidity-(z- 
														ReferenceElevation)*HumidityG/100.)))*(exp(-Gamma*Xr)))/((1.-PhiD)* 
											Rhoi*Lm*Ustar)/((((Um-(z-ReferenceElevation)*WindSpeed/100.) 
                                    -2.*Ustar)*exp(-Gamma*Xr))/Ustar+exp(Gamma*debris)))*100.*24.*60.*60.;
                        }

                        /* account form ablation days, and convert to m/s */
			MassBalanceMYearDebris=-MassBalanceCmDayDebris/100.*AblationDays/yts;

			/*Update array accordingly*/
			smb[v]=MassBalanceMYearDebris;
		}

		/*Add input to element and Free memory*/
		element->AddInput(SmbMassBalanceEnum,smb,P1Enum);
		xDelete<IssmDouble>(surfacelist);
		xDelete<IssmDouble>(smb);
		xDelete<IssmDouble>(debriscover);
	}
}/*}}}*/
void SmbGradientsComponentsx(FemModel* femmodel){/*{{{*/

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		element->SmbGradCompParameterization();
	}

}/*}}}*/
#ifdef _HAVE_SEMIC_
void SmbSemicx(FemModel* femmodel,int ismethod){/*{{{*/

	for(Object* & object : femmodel->elements->objects){
		Element* element=xDynamicCast<Element*>(object);
		if (ismethod == 1) element->SmbSemicTransient(); // Inwoo's version.
		else element->SmbSemic(); // original SmbSEMIC
	}

}/*}}}*/
#else
void SmbSemicx(FemModel* femmodel){_error_("SEMIC not installed");}
#endif //_HAVE_SEMIC_
