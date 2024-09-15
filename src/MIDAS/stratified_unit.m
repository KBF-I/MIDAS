%KAsra
% #define _IS_MULTI_ICE_
classdef stratified_unit

    properties
        ID        = 0;
        Bed       = [];
        Thickness = [];
        Surface   = [];
        IceType   = 0;

        currentHeightPercentage=0; %the height percentage of this unit
        NmbLayers = 0; % the number of virtual mesh layers in the unit

        startingElementID = 0;
        endingElementID   = 0;       
        unitUpperElements =[];%[unitID, Element startingID, element ending ID]  inclusive IDs
        unitLowerElements =[];

        mergedUnit=false;
    end

    methods (Static)




    end
end