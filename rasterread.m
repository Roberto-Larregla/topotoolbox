function [dem,X,Y,header] = rasterread(file)

% read/import ESRI ascii grid
%
% Syntax
%
%     [dem,X,Y] = rasterread
%     [dem,X,Y] = rasterread('file')
%     [dem,X,Y,info] = rasterread('file')
%
% Description
%
%     read ASCII raster exported from ESRI ArcGIS. 'file' is a string 
%     indicating location and name of the file, e.g. 'srtm.txt'. If no
%     input arguments are supplied, rasterread opens a dialog box for
%     retrieving the file.
% 
%     the header must contain following rows (in arbitrary order)
%     _________________________
%     ncols         201
%     nrows         451
%     xllcorner     329995.5
%     yllcorner     5297997.5
%     cellsize      5
%     NODATA_value  -9999
%     _________________________
% 
%     dem is a matrix with ncols columns and nrows rows. X and Y are 
%     coordinate matrices and provide the spatial reference for the dem.
%     header is a 6-x-1 structur array that contains the information
%     of the header of the file.
%
%
% See also: RASTERWRITE, DLMREAD, DLMWRITE
% 
% Author: Wolfgang Schwanghart (w.schwanghart[at]unibas.ch)
% Date: 15. March, 2009



% read header data

if nargin == 0;
    FilterSpec  = {'*.txt';'*.asc'};
    DialogTitle = 'Select ESRI ASCII grid';
    [FileName,PathName] = uigetfile(FilterSpec,DialogTitle);
    if FileName == 0;
        X = []; Y = []; dem = []; header = [];
        return;
    end
    file = [PathName FileName];
end

if ischar(file);
else
    error('file is a string indicating the ASCII file name and position')
end



fid=fopen(file,'r');
% loop through header

header = struct('ncols',[],...
                'nrows',[],...
				'xllcorner',[],...
				'yllcorner',[],...
				'cellsize',[],...
				'nodata',[]);
				
names   = fieldnames(header);
nrnames = numel(names);

try
fseek(fid,0,'bof');
for r = 1:nrnames ;
    headertext = fgetl(fid);
    [headertext, headernum] = strtok(headertext,' ');
    I = cellfun(@(x,y) strcmpi(x(1:4),y(1:4)),names,repmat({headertext},nrnames,1));
	header.(names{I}) = str2double(headernum);
end
catch ME1
    error('header can not be read')
end


% read raster data
dem = fscanf(fid,'%lg',[header.ncols header.nrows]);
fclose(fid);
dem(dem==header.nodata) = NaN;

dem = dem';


% create X and Y using meshgrid

if nargout>1
y = (header.yllcorner+(0.5*header.cellsize))+((header.nrows-1)*header.cellsize):...
     -header.cellsize:...
     header.yllcorner+(0.5*header.cellsize);
x = header.xllcorner+(0.5*header.cellsize):...
    header.cellsize:...
    (header.xllcorner+(0.5*header.cellsize))+((header.ncols-1)*header.cellsize);

[X,Y] = meshgrid(x,y);
end


