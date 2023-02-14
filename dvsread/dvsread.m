function [vectors, coordSys, normalization, comments] = dvsread(fileName)
%DVSREAD - Parse Siemens Diffusion Vector Set file for MRI systems.
%
%   vectors = dvsread(fileName);
%
% vectors is an 3xn matrix where n is the number of directional vectors
% found in the dvs file. fileName is the location and name of the dvs file.
%
%   [vectors, coordSys, normalization, comments] = dvsread(fileName)
%
% coordSys is the coordinate system used. Valid entirs are 'xyz' and 'prs'.
% normalization is the normalization directive. Valid values are, 'unity',
%'maximum', and 'none'. comments captures all the comments in the file, 
% wether they be lines that start with a hash symbol (#) or formally
% assigend using a comment directive. Comment lines using the hash notaion
% preserve the hash in order to differnetiate from those that used the
% comment directive.
%
% To be consistent with the Siemens DVS file specification found in the
% Neuro Manual provided with each software level, there is no case
% sensitivity in the processing of these files. Additionally, spaces and
% tabulation marks are ignored. Lines in the DVS file that do not
% correspond to valid DVS entries are ignored. So are blank lines. Note
% that dvsread does not support files with multiple vector sets - only
% single ones.

%To do list:
% - Add error feedback for files with syntax errors
% - Check to ensure file has only one vector set
% - Add support for DVS files with multiple vector sets

%Author: Jeff Luci, jeffrey.luci@rutgers.edu
%Released: February 14, 2023
%
%Version History:
%20230214: Initial Release


%Read in entire DVS file as text
fid = fopen(fileName, 'rt');
dvsFile = fread(fid, inf, 'uint8=>char')';
fclose(fid);

%Break up text into individual lines and initialize variables
dvsLines = strtrim(strsplit(dvsFile, newline));
comments = [];
coordSys = [];
normalization = [];

%step through each line, and parse according to file specification
for ii = 1:numel(dvsLines)

    curLine = lower(dvsLines{ii});

    %skip blank lines
    if isempty(curLine)
        continue;

    %extract vector number and values    
    elseif strcmp(curLine(1:7), 'vector[')
        curLine(isspace(curLine)) = '';
        curLineSplit = strsplit(curLine, '=');
        vectorNumber = sscanf(curLineSplit{1}, 'vector\133%d\135') + 1;
        vectors(:,vectorNumber) = sscanf(curLineSplit{2}, '\050%f,%f,%f\051'); %#ok

    %add hash comment to string    
    elseif strcmp(curLine(1), '#')
        comments = [comments, newline, curLine]; %#ok

    %initialize the vectors variable    
    elseif strcmp(curLine(1:11), '[directions')
        curLine(isspace(curLine)) = '';
        numDir = sscanf(curLine, '[directions=%d]');
        vectors = zeros(3,numDir);

    %parse the coordiante system
    elseif strcmp(curLine(1:16), 'coordinatesystem')
        curLine(isspace(curLine)) = '';
        coordSys = sscanf(curLine, 'coordinatesystem=%s');

    %parse the normalization
    elseif strcmp(curLine(1:13), 'normalisation')
        curLine(isspace(curLine)) = '';
        normalization = sscanf(curLine, 'normalisation=%s');

    %add directive comment to string    
    elseif strcmp(curLine(1:7), 'comment')
        curLine = strsplit(curLine, '=');
        curLine = strtrim(curLine{2});
        comments = [comments, newline, curLine, newline]; %#ok
        
    else
        continue;

    end

end

if ~isempty(comments)
    comments = strtrim(comments);
end

end