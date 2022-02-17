clear all

% this fuction needs Antarctic mapping tools installed/downloaded
% Antarctic Mapping Tools: https://www.mathworks.com/matlabcentral/fileexchange/47638
addpath('Z:\docs\ikoch\src\AntarcticMappingTools'); % change this to your path
addpath('Z:\docs\ikoch\src\AMT');
% and Antarctic Bedmachine codes
% https://github.com/chadagreene/BedMachine
addpath('Z:\docs\ikoch\src\AMT\BedMachine'); % change this to your path and also change the path within codes to access the following data file
% and data: https://nsidc.org/data/nsidc-0756 
%add final fuctions
addpath('D:\Publications\Koch_ice_shelf_characteristics\src\process_radar');

%add path to Geoid
Geoidpath = 'D:\Data_general_Antarctica\EIGEN-6C4\geoid_large_domain';
FApath = 'D:\Data_general_Antarctica\Bedmachine_FA_content\firn22.tif';

myDir = cd; %folder with data to be processed, needs to be open as 'Current Folder'
myFiles = dir(fullfile(myDir,'*.mat')); %gets all mat files in struct
nf=length(myFiles);

for k=1:nf
FileName = myFiles(k).name(1:end-4);
FileName_org=myFiles(k).name;
fprintf(1, 'Now reading %s\n', FileName);

my_field = strcat('v',num2str(k));
Data.(my_field) = importdata(FileName_org);
%GeoidFirnFileName = ['D:\Radar\Data\AWI_flights\Data\Picked_data\processed\Firncorrect_Bedmach_surf\GeoidFirn' FileName '.csv'];
end

%%set variables for density correction
MaxDepth=1000; %in metres
dz=0.001; % in meters.
%rho = 910-460*exp(-0.033*z);%for RBIS
z=0:dz:MaxDepth;
rho = 910-460*exp(-0.025*z);%for DIR 

%concacenate layers together
%may want to create loop for more than one layer
Dataall.psX = [Data.v1.psX Data.v2.psX Data.v3.psX Data.v4.psX Data.v5.psX Data.v6.psX Data.v7.psX Data.v8.psX Data.v9.psX];
Dataall.psY = [Data.v1.psY Data.v2.psY Data.v3.psY Data.v4.psY Data.v5.psY Data.v6.psY Data.v7.psY Data.v8.psY Data.v9.psY];
%Dataall.layers_relto_surface(kk,:)
Dataall.twt=Data.v1.twt;

dt=Dataall.twt(3)-Dataall.twt(2);
[nr nc]=size(Data.v1.layers_relto_surface);

%min horizons that overlap - check why only 8
%min_nr=8;%usually would use nr
min_nr=1;%usually would use nr

%%change hardcoding!
for kk=1:min_nr
Dataall.layers_relto_surface(kk,:)=[Data.v1.layers_relto_surface(kk,:) Data.v2.layers_relto_surface(kk,:) Data.v3.layers_relto_surface(kk,:) Data.v4.layers_relto_surface(kk,:) Data.v5.layers_relto_surface(kk,:) Data.v6.layers_relto_surface(kk,:) Data.v7.layers_relto_surface(kk,:) Data.v8.layers_relto_surface(kk,:) Data.v9.layers_relto_surface(kk,:)];
end

%plot layers to check
figure(1)
for kk=1:min_nr
plot3(Dataall.psX,Dataall.psY,Dataall.layers_relto_surface(kk,:))
hold on
set(gca,'Zdir','reverse')
end

nr=1; %only added for test purposes

%Firncorrection (external function)
%It is taking lots of time!!!
Dataall=Firncorrect(Dataall, rho, dt, dz, MaxDepth, nr, nc,z);

%plot firncorr layers to check
figure(2)
for kk=1:min_nr
plot3(Dataall.psX,Dataall.psY,Dataall.layers_firncorr_depth(kk,:))
hold on
set(gca,'Zdir','reverse')
end

Dataall=ExtractElevationFromGeiod(Dataall,Geoidpath); 
Dataall=ExtractFAcontent(Dataall,FApath);
%the following uses the fuction bedmachine_data, which accesses the AMT toolbox and the
%AntarcticaFilename = 'BedMachineAntarctica_2020-07-15_v02.nc'; 
%Bedmachine surface is using the REMA DEM smoothly interpolated
addpath('Z:\docs\ikoch\src\AntarcticMappingTools'); 
Dataall.Surface_Bedmachine_ice = bedmachine_interp('surface',Dataall.psX,Dataall.psY);
Dataall.Surface_Bedmachine_firn = Dataall.Surface_Bedmachine_ice+Dataall.FA;
Dataall.Surface_REMA_fromBedmachine_firn=Dataall.Surface_Bedmachine_ice+Dataall.geoid+Dataall.FA;
Dataall.Surface_geoid_firn=Dataall.Surface_Bedmachine_ice+Dataall.FA;

%add same for bed picks considering average density over profile

%correct for topography
for kk=1:min_nr
Dataall.layers_firncorr_elevation_REMA(kk,:)=Dataall.Surface_REMA_fromBedmachine_firn-Dataall.layers_firncorr_depth(kk,:);
end

figure(3) % check results
plot3(Dataall.psX, Dataall.psY, Dataall.Surface_REMA_fromBedmachine_firn)
hold on
for kk=1:min_nr
plot3(Dataall.psX, Dataall.psY, Dataall.layers_firncorr_elevation_REMA)
end
xlabel('Eastings')
ylabel('Northings')
zlabel('Elevation (m)')

Geoall_FirnFileName = ['D:\Publications\Koch_ice_shelf_characteristics\Data\Picked_Layers\Geoall_' FileName];

% %consider FA content to derive layer depth in tune with ELMER Model
% for nn=1:Drows
%     Layer_firn(nn,:)=Data.layers_firncorr_depth_below_surf(nn,:);
% for kk=1:Dcolumns
%     %depth_l=Layer_firn(1,kk);
%     depth_kk=Layer_firn(nn,kk);
%     depth_ind=depth_kk/dz;
%     depth_ind=round(depth_ind);
%     NaNdepth_ind = isnan(depth_ind);
%     if NaNdepth_ind==1
%         FA_layer2(nn,kk)=NaN;
%         FA_layer(nn,kk)=NaN;
%         mean_rho(nn,kk)=NaN;
%     else
%     rho_kk=rho(1:depth_ind);
%     mean_rho(nn,kk)=mean(rho_kk);
%     FA_layer(nn,kk)=(mean_rho(nn,kk)/910)*depth_kk;
%     FA_layer2(nn,kk)=depth_kk-FA_layer(nn,kk);
%     end
% end
% Data.layers_firncorr_elevation_Bedmachine_ice_FA(nn,:)=Data.layers_firncorr_elevation_Bedmachine_ice(nn,:)-FA_layer2(nn,:); % shouldn't it be plus?
% end

% Data.depth_bed=Data.elevation_surface-Data.elevation_bed(1,1:Dcolumns);
% 
% for kk=1:Dcolumns
%     depth_ii=Data.depth_bed(1,kk);
%     depth_ind=depth_ii/dz;
%     depth_ind=round(depth_ind);
%    % NaNdepth_ind = isnan(depth_ind);
%     %if NaNdepth_ind==1
%     %    Data.elevation_bed_ice(1,kk)=NaN;
%    % else
%     rho_ii=rho(1:depth_ind);
%     mean_rhoi(1,kk)=mean(rho_ii);
%     FA_layer22(1,kk)=(mean_rhoi(1,kk)/910)*depth_ii;
%     FA_layer222(1,kk)=depth_ii-FA_layer22(1,kk);
%     %end
% end
% 
% Data.elevation_bed_Bedmachine_ice=Data.Surface_Bedmachine_ice-(Data.depth_bed-FA_layer222);
% Data.elevation_bed_REMA_fromBedmachine_firn=Data.Surface_REMA_fromBedmachine_firn-Data.depth_bed;
% Data.elevation_bed_geoid_firn=Data.Surface_geoid_firn-Data.depth_bed;

save(Geoall_FirnFileName,'-struct', 'Dataall')

%need to combine for all layers 
% kk1=1;
% XYZ_layers=[Dataall.psX', Dataall.psY', Dataall.twt', Dataall.layers_firncorr_elevation_REMA(kk1,:)'];
% csvwrite(Geoall_FirnFileName, XYZ_layers);