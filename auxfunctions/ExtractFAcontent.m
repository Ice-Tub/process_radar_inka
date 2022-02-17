function [Data] = ExtractFAcontent (Data, FApath)
%Extract surface elevation of radar data from a DEM (e.g. REMA-DEM)
%DEMpath should be the path where the wished DEM is located

%% if such a path is not given, the REMA DEM with 200m resolution is used
if nargin < 2
    FApath = 'D:\Data_general_Antarctica\Bedmachine_FA_content\firn22.tif';
end

%% The info-file and the DEM itselve are needed
info.FA = geotiffinfo(FApath);
FA = geotiffread(FApath);

%% Transforming Lat/Lon values of data into polar stereographic projection
%[DataX,DataY] = ll2ps(Data.latitude,Data.longitude);
DataX=Data.psX;
DataY=Data.psY;

%% Extract the elevation along the flightline
%k is a vector as long as the Latitude vector having values 1,2,3,...
%Datarow,Datacol include each value of the pixels of the DEM that is
    %the nearest to the each data point of the radar flight using polar 
    %stereographic projection 
%Data.DemElevation creats a new vector including the DEM elevation data
    %of the DEM. int16 must be used because Datarow and Datacol are not
    %exactly even numbers.
    
for k = 1:length(DataX)
    [Datarow,Datacol] = map2pix(info.FA.RefMatrix,DataX(k),DataY(k));
    Data.FA(k) = FA(int16(Datarow),int16(Datacol));
end


indkill=find((isnan(Data.FA))==1);
if (length(indkill)>0)
    Data.FA(indkill)=0;
    display('Warning: The Geoid has some NANs. Replaced them with zeros.')
end
end
