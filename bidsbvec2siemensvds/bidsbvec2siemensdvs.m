function bidsbvec2siemensdvs(inputFile)
%bidsbvec2siemensdvs: A function to generate a Siemens DVS file from a 
%                     BIDS-style bvec file
%
%USAGE: bidsbvec2siemensdvs(filename)
%
%filename - full path name to bvec file. If the specific bvec file is in
%           the current MATLAB working directory, then just the filename
%           is acceptable.
%
%The function read in a BIDS-stle bvec file, convert the format, and
%write a Siemens DVS file with header to the same directory. The BIDS bvec
%format is specified at http://bids.neuroimaging.io/
%
%version 1.0, released 7 Jan, 2019. Written by J. Luci
%
%CHANGES:
% version 1.01, released 7 Jan, 2019, J. Luci. Found and fixed pathname
%               bug. Corrected version string. Added to-do.
%
%TO-DO:
% add error checking for file reads, etc.
% add ability to normalize vector data if requested.
% add ability to visualize vectors.

versionString = 'v1.01';

%Read in BIDS bvec file
[pathname, filename, ext] = fileparts(inputFile);
fid=fopen([pathname, filename, ext], 'rt');
bvecCell=textscan(fid, '%f');
fclose(fid);

%Reformat cell array for easier & intuitive manipulations
%This could be done with a simple reformat call, but this is easier to read
%and follow for non-MATLAB practitioners.
bvecMat=bvecCell{1};
numDir = numel(bvecMat)/3;
partitions = 1:numel(bvecMat)/3:numel(bvecMat);
x = bvecMat(1:partitions(2)-1);
y = bvecMat(partitions(2):partitions(3)-1);
z = bvecMat(partitions(3):numel(bvecMat));
composed = [x,y,z];

%Compute number of b=0 scans for information
numB0 = numel(find(max(composed, [], 2) == 0));

%Create DVS file, and write the header
dvsFile = [pathname, filename, '.dvs'];
fid = fopen(dvsFile, 'wt');
fwrite(fid, ['[directions=', num2str(numDir), ']' newline], 'char');
fwrite(fid, ['CoordinateSystem = xyz', newline], 'char');
fwrite(fid, ['Normalization = none', newline], 'char');
fwrite(fid, ['# Converted by bidsbvec2siemensdvs ' versionString, newline]);
fwrite(fid, ['# Source file = ', filename, ext, newline]);

%Write the direction vectors to disk, and close the file when finished
for ii = 1:numDir
    fwrite(fid, ['Vector[', num2str(ii-1), '] = ( ' sprintf('%0.6f', x(ii)), ', ' sprintf('%0.6f', y(ii)), ', ' sprintf('%0.6f', z(ii)),  ' )', newline]); 
end
fclose(fid);

%Report to user what happened
disp(['Finished. A total of ' num2str(numDir) ' directions were parsed,']);
disp( [num2str(numDir-numB0), ' of which were DW scans, and ', num2str(numB0), ' were b=0 scans.', newline]);
end