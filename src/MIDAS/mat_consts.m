%Kasra: All material constants are in this class
% #define _IS_MULTI_ICE_
classdef mat_consts

    %introduce new materials here:
    properties (Constant)
        %constants representing ice compounds (molecular compound type)
        CO2      = 1;
        H2O      = 2;
        N2       = 3;
        CO       = 4;
        CH4      = 5;
        H2O_DUST = 6;
        ROCK     = 7;
        MAT1     = 8;
        MAT2     = 9;
        MAT3     =10;

        %rheologyLaws
        None            = 'None';            %  0;
        BuddJacka       = 'BuddJacka';       %  1;
        Cuffey          = 'Cuffey';          %  2;
        CuffeyTemperate = 'CuffeyTemperate'; %  3;
        Paterson        = 'Paterson';        %  4;
        Arrhenius       = 'Arrhenius';       %  5;
        LliboutryDuval  = 'LliboutryDuval';  %  6;
        NyeCO2          = 'NyeCO2';          %  7;
        NyeH2O          = 'NyeH2O';          %  8;
        NyeCO           = 'NyeCO';           %  9;
        NyeN2           = 'NyeN2';           %  10;
        NyeCH4          = 'NyeCH4';          %  11;
        NyeH2O_DUST     = 'NyeH2O_DUST';     %  12;
        NyeROCK         = 'NyeROCK';         %  13; 


        %material properties name; these numbers must match the position in
        %the allmaterial array  

        LatentHeat                     = 2;
        ThermalConductivity            = 3;
        HeatCapacity                   = 4;
        Rho_Ice                        = 5;
        Rho_OceanWater                 = 6;
        Rho_FreshWater                 = 7;
        Mu_IceCompoenent               = 8;
        TemperateIceConductivity       = 9;
        Thermal_Exchange_Velocity      = 10;
        MeltingPoint                   = 11;
        Beta                           = 12;
        Mixed_Layer_Capacity           = 13;
        EffectiveConductivity_Averaging= 14;
        Rheology_n                     = 15;
        Rheology_Law                   = 16;
        A_const                        = 17;
        Q                              = 18;

        %1) latent heat, 2) Thermal Conductivity, 3) heat capacity ,     4) rho
    end

end