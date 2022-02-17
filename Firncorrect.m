function [Data] = Firncorrect(Data,rho,dt,dz,MaxDepth,nr,nc,z)

%% Get velocity-depth profile considering density
% Kovacs et al.; Cold Regions Science and Technology 23 (1995) 245-256 
%(Kovacs this makes v_ice approx 1.685e8, check specific gravity again)
er = (1 + 0.845*rho/985).^2; % 985 empiric to derive specific density (unitless)
v = 3e8./sqrt(er);

%% link between velocity and traveltime
% consider for small delta t that the density/velocity is constant
IntervalDeltaT = [0 diff(z)]./v;            %Delta t needed to travel through dz at depth z
TravelTimeDepth = cumsum(IntervalDeltaT);   %Time at depth z

%% Now find the closest TravelTime to the IRH TravelTime
for kk=1:nr
%make empty variable
Data.layers_time(kk,:)=Data.layers_relto_surface(kk,:)*dt;  
for nn=1:nc; 
   [MinVal, IndMinVal] = min(abs(TravelTimeDepth-Data.layers_time(kk,nn)));
   Data.layers_firncorr_depth(kk,nn) = z(IndMinVal)/2;
end
Data.layers_firncorr_depth(isnan(Data.layers_time))=NaN;   
end
end