function parseDicomDir(filePath, options)
%parseDicomDir - Parses a standard DICOM archive data directory structure
%                and reorganizes it into human-readable directories using
%                the same naming convention used in Siemens D and E-line
%                scanners for filesystem exports.
%
%Usage: parseDicomDir(pathToDicomDirectory)
%       parseDicomDir(pathToDicomDirectory, KeepOriginal=false)
%       parseDicomDir(pathToDicomDirectory, Verbose=true)
%       parseDicomDir(pathToDicomDirectory, DICOMDIRcheck=false)
%
%This function will use the DICOM index file (named "DICOMDIR") in the root
%of a DICOM archive directory structure to reoragnize the image-containing
%DICOMs into a human-readable directory structure. The naming convention of
%used for the new structure is the same as the one used on Siemens D and
%E-line MRI scanners when exporting DICOMs to a filesystem. This presumes
%that the DICOMs are Siemens enhanced DICOMs generated on XA-line scanners
%and later. Non-enhanced DICOMs are not supported. The function
%extractEnhancedDicomTags is required, and can be obtained from the links
%below. The reorganized directory is named "converted".
%
%Options:
%KeepOriginal=false will move the DICOMs from the old structure to the new.
%                   The originals will not be retained. This saves disk
%                   space but give up some data integrity. Do not use on
%                   the only copy of data. The default is true, which only
%                   copies the files with new names to the new directory.
%
%KeepConverted=true will move the new directory structure to the base path
%                   and remove the DICOM and converted directories as well
%                   as the DICOMDIR file. WARNING: This option will delete
%                   any non-DICOM files in the structure.
%
%Verbose=true will echo to the screen the progress of the process as it
%             works through each DICOM item listed in DICOMDIR. It is
%             generally not necessary unless troubleshooting is required.
%             The default is false.
%
%DICOMDIRcheck=false is necessary if the path to the archive structure
%                    includes the string "DICOMDIR" in any mixed case. The
%                    default is true and will stop the function if the path
%                    includes that string.
%
%This function is maintained at this URL:
%https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseDicomDir

% Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseDicomDir
% VERSION HISTORY:
%20230823: Initial Release.
%20240117: Added management of pesky DICOM VR Dictionay warnings.
%          Changed error stops to simple text on screen so that use in a 
%          loop does not halt the entire job.
%          Fixed bug that did not correctly use the full path to a DICOM
%          directory structure. Incorporated OS agnostic handling of file
%          separators in this fix.
%20240123: Fixed a bug that would halt the process upon encountering a
%          non-image DICOM.
%20260413: Updated tags for enhanced DICOMs to be consistent with
%          extractEnhancedDicomTags version 20260217.
%20260424: Updated to remove dpendency for extractEnhancedDicomTags, 
%          greatly (~100x) improve speed by directly parsing DICOM headers,
%          and switched verbose updates to not produce a line every time.
%20260427: Fixed bug in type casting of series numbers. Reduced preliminary
%          data read size to reduce memory requirements and further speed  
%          up the entire process.

arguments
    filePath char
    options.Verbose       (1,1) logical = false
    options.KeepOriginal  (1,1) logical = true
    options.DICOMDIRcheck (1,1) logical = true
    options.KeepConverted (1,1) logical = true
end

%Set this warning to off to avoid common but meaningless (in this use case)
% VR Dictionary issues.
warningDRState = warning('query', 'images:dicominfo:fileVRDoesNotMatchDictionary');
warning('off', 'images:dicominfo:fileVRDoesNotMatchDictionary');

%Check to ensure filePath directory exists
if ~exist(filePath, 'dir')
    if contains(filePath, 'DICOMDIR', 'IgnoreCase', true) && options.DICOMDIRcheck
        error(['You may have given the location of the DICOMDIR file', newline, ...
               'instead of the path to the directory. If not, use', newline, ...
               '"DICOMDIR=false" as an argument and check the file path.']);
    else
        error(['Cannot find the directory: ', filePath]);
    end
end

%Ensure filePath has trailing directory separator
if ~(strcmp(filePath(end), filesep))
    filePath = [filePath, filesep];
end
fileName = 'DICOMDIR';

%Check to ensure DICOMDIR file exists
if ~exist(fullfile(filePath, fileName), 'file')
    fprintf(2, 'Cannot find: %s.', DICOMDIR);
    return;
end

%check to make sure DICOMDIR is a readable DICOM file
if ~isdicom(fullfile(filePath, fileName))
    fprintf(2, '%s is not a DICOM file.', DICOMDIR);
    return;
end

%check to see if the "converted" directory exists
if ~exist([filePath, filesep, 'converted'], 'dir')
    mkdir(filePath, 'converted');
end

%initialize variable to keep track of update message length
prevMsgLen = 0;

%Parse DICOMDIR and figure out how much work there is to do
dicomDir = dicominfo(fullfile(filePath, fileName));
numItems = length(fieldnames(dicomDir.DirectoryRecordSequence));

%Begin to parse DICOM directory structure
%waitbarFig = waitbar(0, 'Reorganizing DICOM directory structure ...');
startTime = tic;
for ii = 1:numItems
    curItem = ['Item_', num2str(ii)];
    if options.Verbose
        fprintf(repmat('\b', 1, prevMsgLen));
        msg = sprintf('Processing item number: %d of %d items.\n', ii, numItems);
        fprintf('%s', msg);
        extraSpaces = prevMsgLen - length(msg);
        if extraSpaces > 0
            fprintf(repmat(' ', 1, extraSpaces));
            fprintf(repmat('\b', 1, extraSpaces));
        end
        prevMsgLen = length(msg);
    end
        
    %Get location of next DICOM file and read the enhanced DICOM header
    if isfield(dicomDir.DirectoryRecordSequence.(curItem), 'ReferencedFileID')
        curFile = fullfile(filePath, ...
                           dicomDir.DirectoryRecordSequence.(curItem).ReferencedFileID);
        curFile = replace(curFile, '\', filesep); %ensure OS agnostic
        try
            %curHdr = extractEnhancedDicomTags(curFile);
            curHdr = getDicomTags(curFile);
            curHdr.seriesNumber = str2double(curHdr.seriesNumber);
        catch
            continue;
        end
        %Replace blank spaces in the protocol name with underscores
        protocolName = regexprep(curHdr.protocolName, ' ', '_');
        
        %Construct the new human-readable names of directories and files
        scanFileName = [protocolName, '_', ...
                        sprintf('%04d', dicomDir.DirectoryRecordSequence.(curItem).InstanceNumber), ...
                        '.dcm'];
        scanDirName = [protocolName, '_', ...
                       sprintf('%04d', curHdr.seriesNumber)];
        if ~exist([filePath, filesep, ...
                   'converted', filesep, ...
                   scanDirName], 'dir')
            mkdir([filePath, 'converted'], scanDirName);
        end
        %Move or copy the files as indicated by the KeepOriginal flag
        if options.KeepOriginal
            copyfile(curFile, ...
                     fullfile(filePath, 'converted', scanDirName, scanFileName));
        else
            movefile(curFile, ...
                     fullfile(filePath, 'converted', scanDirName, scanFileName));
        end
    end
    %waitbar(ii/numItems, waitbarFig);
end
%close(waitbarFig);

%clean up converted and DICOM directories and DICOMDIR file if requested
if ~options.KeepConverted
    convDirList = dir([filePath, 'converted', filesep]);
    convDirList = convDirList(3:end);
    for ii = 1:numel(convDirList)
        movefile([filePath, 'converted', filesep, convDirList(ii).name], ...
                  filePath);
    end
    rmdir( [filePath, 'converted'], 's');
    rmdir( [filePath, 'DICOM'],     's');
    delete([filePath, 'DICOMDIR']);
end

%Reset the warning state(s) that might have been changed
warning(warningDRState(1).state, 'images:dicominfo:fileVRDoesNotMatchDictionary');

%Report how long the process took
endTime = toc(startTime);
fprintf('This took a total of %0.1f seconds, or %0.1f ms per file.\n', ...
    endTime, 1000*(endTime/numItems));



function hdr = getDicomTags(dicomFile)
fid = fopen(dicomFile, 'r');
data = fread(fid, 16000, 'uint8=>uint8')';
fclose(fid);

% Find Series Number (0020, 0011) - VR is usually IS (Integer String)
% Hex: 20 00 11 00
idx = strfind(data, uint8([32 0 17 0]));
hdr.seriesNumber = parseValue(data, idx);

% Find Protocol Name (0018, 1030) - VR is usually LO (Long String)
% Hex: 18 00 30 10
idx = strfind(data, uint8([24 0 48 16]));
hdr.protocolName = parseValue(data, idx);
end

function val = parseValue(data, idx)
    if isempty(idx), val = ''; 
        return; 
    end
    idx = idx(1); % Take first occurrence
    % Explicit VR: Tag(4) + VR(2) + Length(2)
    len = double(typecast(data(idx+6:idx+7), 'uint16'));
    val = char(data(idx+8 : idx+8+len-1));
    val = strtrim(val);
end

end
