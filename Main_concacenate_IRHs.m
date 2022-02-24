clear all

%% load IRH data in open folder

% load from Z:\data\ikoch\data_large\Radar\Data\AWI_flights\Picked_final\07_01_Heiko
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

%% concacenate layers together

%FIX: create loop to concacenate and also adjust for variable number of data files
Dataall.psX = [Data.v1.psX Data.v2.psX Data.v3.psX];
Dataall.psY = [Data.v1.psY Data.v2.psY Data.v3.psY];
Dataall.twt=Data.v1.twt; % all twt of batch are assumed to be the same

dt=Dataall.twt(3)-Dataall.twt(2);
[nr nc]=size(Dataall.psY); %number of rows and colums

% may need to add here a loop to create layers relative to surface (in twt)
% - change wording to IRH
% that would be just be IRH

%%change hardcoding!
for kk=1:min_nr
Dataall.layers_relto_surface(kk,:)=[Data.v1.layers_relto_surface(kk,:) Data.v2.layers_relto_surface(kk,:) Data.v3.layers_relto_surface(kk,:)];
end

%plot layers to check
figure(1)
for kk=1:min_nr
plot3(Dataall.psX,Dataall.psY,Dataall.layers_relto_surface(kk,:))
hold on
set(gca,'Zdir','reverse')
end

%% save data
Geoall_FirnFileName = ['D:\Publications\Koch_ice_shelf_characteristics\Data\Picked_Layers\Geoall_' FileName]; %change path to something that makes sense
save('Geoall_DIR_all_layers_h','-struct', 'Dataall')
