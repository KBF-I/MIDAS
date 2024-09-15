% #define _IS_MULTI_ICE_
classdef planetProperties

    properties (Constant)
        %planets
        EARTH    = 1;
        MARS     = 2;
        PLUTO    = 3;
        EUROPA   = 4;  % For future implementation

        PLANETS_Code2Text = [planetProperties.EARTH, "EARTH"; planetProperties.MARS, "Mars";planetProperties.PLUTO, "Pluto"; planetProperties.EUROPA, "Europa"; ];
    end


    methods (Static)

        function [radius_a, radius_b] = planetRadius(planetName)
            switch (planetName)
                case planetProperties.EARTH     
                    radius_a                  = 6378137;        radius_b         = 6356752.314245;
                case planetProperties.MARS   
                    radius_a                  = 3396200;        radius_b         = 3376200;
                case planetProperties.PLUTO  
                    radius_a                  = 1188300;        radius_b          = 1188300;
                case planetProperties.EUROPA   
                    radius_a                  = 1560800;        radius_b           = 1560800;
            end
        end 

        function temperature = minPlanetSurfaceTemperature(planetName)
             switch (planetName)
                case planetProperties.EARTH
                    temperature = 200;

                case planetProperties.MARS
                    temperature = 150;

                case planetProperties.PLUTO
                    temperature = 40;

            end %switch
        end

        function [md, radius_a, radius_b] = setPlanetMoonProperties(md, planetName)
            switch (planetName)
                case planetProperties.EARTH
                    md.materials.earth_density       = 5512;           md.constants.g   = 9.81;
                    md.constants.omega               = 7.292*1e-5;     md.constants.yts = 365.*24.*3600.;
                    md.constants.referencetemperature= 223.15;         
                    radius_a                         = 6378137;        radius_b         = 6356752.314245;

                case planetProperties.MARS
                    md.materials.earth_density       = 3930;           md.constants.g   = 3.72;
                    md.constants.omega               = 1.1324*1e-5;    md.constants.yts = 687.*24.*3600.;
                    md.constants.referencetemperature= 223.15;         
                    radius_a                         = 3396200;        radius_b         = 3376200;

                case planetProperties.PLUTO
                    md.materials.earth_density       = 1854;            md.constants.g   = 0.62;
                    md.constants.omega               = 1.755*1e-6;      md.constants.yts = 90560.*24.*3600.;
                    md.constants.referencetemperature= 223.15;          
                    radius_a                         = 1188300;        radius_b          = 1188300;

            end %switch
        end  %func: planet_moon_selection

    end
end
