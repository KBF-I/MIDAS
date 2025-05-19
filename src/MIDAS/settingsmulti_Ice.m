%Kasra
% #define _IS_MULTI_ICE_
classdef settingsmulti_Ice < issmsettings
    properties      
        stressbalance_restol                = 2e-4;  % ISSM default is 1e-4; error mgmt  ** okay to increase
        matlab_comparison_threshold         = 1e-8;  % Sometimes there are rounding errors; so we can't just use == to compare two numbers, instead we do abs(A-B)<matlab_comparison_threshold
        thickness_firstIceUnit_threshold    = 1;     % The minimum thickness of the first ice unit;
        thickness_minThreshld               = 0;     % The minimum thickness of an ice unit; below which the model will diverge.        
        InitialResolution                   = 100;
        frictionCoeff                       = 500;
        minNbrLayersInIceUnit               = 2;
    end

    methods
        function settings=settingsmulti_Ice (varargin)
            if nargin == 0
                temp={};
            else
                temp=varargin;
            end
            settings = settings@issmsettings(temp{:});
        end

        function settings = setdefaultparameters(settings)
            settings = setdefaultparameters@issmsettings(settings);
        end

        function disp(self)
            disp@issmsettings(self);
           fielddisplay(self,'stressbalance_restol','default is 2e-4; used for error mgmt');
            fielddisplay(self,'matlab_comparison_threshold','if the difference of two number is less than this number, the two numbers are considered to be equal');
            fielddisplay(self,'InitialResolution','Initial Resolution');
            fielddisplay(self,'thickness_firstIceUnit_threshold','In meters, when starting a model, MIDAS will enforce a minimum thickness equal to this amount, to the first ice unit. (i.e., the first ice unit will start with minimum of this thickness on every node, and will not be reduced to less than this amount during transient runs.) ');
            fielddisplay(self,'frictionCoeff','Friction Coefficient');
        end
    end
end
