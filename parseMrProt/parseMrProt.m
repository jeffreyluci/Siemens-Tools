function [mrProt, jsonContents, zeroList] = parseMrProt(inputArg, jsonFileName)
% parseMrProt - Parses MrProt from a DICOM acquired on a Siemens VB, VD,
% VE, or XA line MRI scanners.
%
% Usage:  mrprot = parseMrProt(input)
%        [mrprot, json] = parseMrProt(input, jsonFileName)
%        [mrprot, json, zeroList] = parseMrProt(input)
% The input argument can be the file location of the DICOM, the DICOM 
% header as provided by the MATLAB function dicominfo, or the plain text of
% the DICOM tag (which supports input from the function 
% extractEnahncedDicomTags). The resulting structure includes all fields 
% included in MrProt, nested and indexed.
%
% The optional jsonFileName, if provided, will be overwritten with mrProt
% parsed into JSON syntax. The JSON file contents are also available as an
% optional return on the command line in the variable json. The JSON file 
% will maintain the native Siemens array indexing, as opposed to the 
% renumbered version used in MATLAB matricies (see last paragraph below).
%
% Parsing is most robust when the DICOM file location is given. This is the
% preferred method of using this function since the other two can fail in
% certain situaions and use cases. If mrProt exists in the DICOM file, 
% parseMrProt should reliably find it. 
% 
% Note that mrProt may not be archived in all DICOMs based on the specific
% software version, whether or not a PACS has touched the data, if is has
% been de-identified in a certain way, or some other unusual use cases.
% If mrProt does not exist, it will not be returned. If mrProt is not 
% archived in the input argument, parseMrProt will return an error.
% 
% Note that field indicies may not correspond to those in the native MrProt 
% as some Siemens arrays are numbered starting at 0, and others at 1. As a
% result, all indicies are renumbered from 1 to comply with MATLAB
% requirements. Those that are renumbered will be off by one, relative to 
% the native formatting. The optional return  zeroList includes a list of 
% all the renumbered fields. These fields are usually nested below a parent
% field name.

% Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt
% VERSION HISTORY:
% 20230201 - Initial Release
% 20230220 - Added support for enhanced DICOMs, including the highly
%            questionable choice by Siemens to use numbers as structure
%            field names in some (inconsistent) cases. This made it
%            necessary to convert hex values to decimal as opposed to
%            maintaining the ascii encoded hex value which was the 
%            convention in the previous version.
% 20230227 - Returned support for maintaining class of hexadecimal values
%            that was temporarily removed in the last version. Improved 
%            tag searching in DICOM file. If a DICOM has mrProt, then this 
%            method should find it always. Therefore, providing the DICOM
%            filename is now the preferred method to parse.
% 20230301 - Added support for JSON file dumps and command line return.
% 20230714 - Added support for use case where Siemens uses ASCCONV END 
%            multiple times in the proprietary header. This solution will 
%            only work if there is only one ASCCONV BEGIN, but as far as I
%            can tell, that should always be true.

%check to see if the input is a dicom or a header structure
if ischar(inputArg)
    if contains(inputArg, 'ASCCONV')
        tagFullText = inputArg;
    elseif isdicom(inputArg)
        fileDump = readFullFile(inputArg);
        if ~contains(fileDump, 'ASCCONV')
            error(['No DICOM tag with MrProt located.', newline, 'Possibly de-identified?']);
        else
            tagFullText = fileDump;
        end
    end
else
    if isstruct(inputArg)
        hdr = inputArg;
    end
end

%check to make sure order of input arguments is correct
if exist('jsonFileName', 'var')
    if islogical(jsonFileName)
        error('Check the order of input arguments and classes.')
    end
end

if ~exist('tagFullText', 'var')
    if isfield(hdr, 'Private_0029_1020')
        tagFullText = char(hdr.Private_0029_1020)';
    elseif isfield(hdr, 'Private_0029_1120')
        tagFullText = char(hdr.Private_0029_1120)';
    elseif isfield(hdr.SharedFunctionalGroupsSequence.Item_1.Private_0021_10fe.Item_1, 'Private_0021_1019')
        tagFullText = char(hdr.SharedFunctionalGroupsSequence.Item_1.Private_0021_10fe.Item_1.Private_0021_1019)';
    else
        error(['No DICOM tag with MrProt located.', newline, 'Possibly de-identified or DICOM tag renamed?']);
    end
end



clear('inputArg');

%initialize mrProt & jsonContents
mrProt = struct;
jsonContents = ['{', newline];

%create text list that records which arrays' numbering start at 0 instead of 1
zeroList = '';

%find beginning of mrprot in the text stream
locationsCR  = strfind(tagFullText, newline);
startString = strfind(tagFullText, 'ASCCONV BEGIN');

lastSkippedCR = find(locationsCR > startString, 1 );
startOfMrProt = locationsCR(lastSkippedCR) + 1;

%find end of mrprot in the text stream
endString = strfind(tagFullText, 'ASCCONV END');
endString = min(endString(endString>startString)); %Sometimes, there is more than one of these.
lastKeptCR = find(locationsCR < endString, 1, 'last' );
endOfMrProt = locationsCR(lastKeptCR);

%Strip off all extra text, leaving only mrprot
mrProtText = tagFullText(startOfMrProt:endOfMrProt);
mrProtText = [newline, mrProtText, newline];            %add CR to start and end
mrProtText = replace(mrProtText, char(9), '');          %strip tabs
mrProtText = replace(mrProtText, '""', '"');            %strip escaped double quotes
mrProtText = replace(mrProtText, '__', '');             %strip out __
mrProtLocationsCR = strfind(mrProtText, newline);

for ii = 1:numel(mrProtLocationsCR)-2                   % minus 2 accounts for added CRs in previous block
    %select next line of text, format it, and split opposite '='
    curLine = mrProtText(mrProtLocationsCR(ii):mrProtLocationsCR(ii+1));
    curLine = curLine(2:end-1);                         %strip out leading/trailing CR

    %yank comments out of each line
    curLine = strsplit(curLine, '#');
    curLine = strtrim(curLine{1});
    if isempty(curLine)
        continue;
    end

    %begin parsing now
    curLineSplit = strtrim(strsplit(curLine, '='));
    assignmentVar = strsplit(curLineSplit{1}, '.');

    %fix Siemens STUPID use of numbers as field names
    % add number in square brackets to end of last fieldname to maintain
    % consistency with every other time Siemens uses an arrayed field.
    if ~isnan(str2double(assignmentVar{end}))
        assignmentVar{end-1} = [assignmentVar{end-1},'[', assignmentVar{end}, ']'];
        assignmentVar(end) = [];
    end

    for jj = 1:numel(assignmentVar)
        %parse structure format of left side assignment
        if contains(assignmentVar{1,jj}, '[')
            assignmentVar{2,jj} = {str2double(regexp(assignmentVar{1,jj}, '\d\d?\d?\d?(?=\])', 'match'))};
            assignmentVar{1,jj} = cell2mat(regexp(assignmentVar{1,jj}, '^[^\[]+', 'match'));
            %check to see if the array index needs to be renumbered
            if cell2mat(assignmentVar{2,jj}) == 0 || contains(zeroList, assignmentVar{1,jj})
                assignmentVar{2,jj} = {cell2mat(assignmentVar{2,jj}) + 1};
                if ~contains(zeroList, assignmentVar{1,jj})
                    zeroList = [zeroList, assignmentVar{1,jj}, newline];
                end
            end
        else
            assignmentVar{2,jj} = {1};
        end
    end
    %check if this is a struct size initializer. If so, skip it.
    if strcmp(assignmentVar{1,end}, 'size')
        continue
    end


    %Determine if right side is string or not, make appropriate assigment
    %process hexadecimal values as strings to maintain class
    if contains(curLineSplit{2}, '"') || contains(curLineSplit{2}, '0x')
        assignmentVar{end} = {1:length(curLineSplit{2})};
        mrProt = setfield(mrProt, assignmentVar{:}, curLineSplit{2});
    else
        mrProt = setfield(mrProt, assignmentVar{:}, str2double(curLineSplit{2}));
    end
    
    %prepare json file contents
    if contains(curLineSplit{2}, '0x')
        curLineSplit{2} = ['"\u', curLineSplit{2}, '"'];
    end
    jsonContents = [jsonContents, '   "', curLineSplit{1}, '": ', curLineSplit{2}, ',', newline];
end

jsonContents = [jsonContents, '}', newline];

% make sure zeroList exists, even if empty
if ~isempty(zeroList)
    zeroList = strtrim(zeroList);
end

%write json file if requested
if exist('jsonFileName', 'var')
    fid = fopen(jsonFileName, 'wt');
    fwrite(fid, jsonContents, 'char');
    fclose(fid);
end

    function fileDump = readFullFile(inputArg)
        fid = fopen(inputArg, 'rt');
        fileDump = fread(fid, inf, 'uint8=>char')';
        fclose(fid);
    end

end
