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
%The required function extractEnhancedDicomTags is available from this URL:
%https://github.com/jeffreyluci/Siemens-Tools/tree/main/extractEnhancedDicomTags
%
%This function is maintained at this URL:
%https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseDicomDir

% Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseDicomDir
% VERSION HISTORY:
%20230823: Initial Release.
%20240117: Added management of pesky DICOM VR Dictionay warnings.
%          Changed error stops to simple text on screen so that use in a a
%             loop does not halt the entire job.
%          Fixed bug that did not correctly use the full path to a DICOM
%          directory structure. Incorporated OS agnostic handling of file
%          separators in this fix.

arguments
    filePath char
    options.Verbose (1,1) logical = false
    options.KeepOriginal (1,1) logical = true
    options.DICOMDIRcheck (1,1) logical = true
end

%Set this warning to off to avoid common but meaningless (in this use case)
% VR Dictionary issues.
warningDRState = warning('query', 'images:dicominfo:fileVRDoesNotMatchDictionary');
if strcmp(warningDRState(1).state, 'on')
    warning('off', 'images:dicominfo:fileVRDoesNotMatchDictionary');
end

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

%Parse DICOMDIR and figure out how much work there is to do
dicomDir = dicominfo(fullfile(filePath, fileName));
numItems = length(fieldnames(dicomDir.DirectoryRecordSequence));

%Begin to parse DICOM directory structure
waitbarFig = waitbar(0, 'Reorganizing DICOM directory structure ...');
startTime = tic;
for ii = 1:numItems
    curItem = ['Item_', num2str(ii)];
    if options.Verbose
        fprintf('Processing item number: %d of %d items.\n\n', ii, numItems);
    end
    %Get location of next DICOM file and read the enhanced DICOM header
    if isfield(dicomDir.DirectoryRecordSequence.(curItem), 'ReferencedFileID')
        curFile = fullfile(filePath, ...
                           dicomDir.DirectoryRecordSequence.(curItem).ReferencedFileID);
        curFile = replace(curFile, '\', filesep); %ensure OS agnostic
        try
            curHdr = extractEnhancedDicomTags(curFile);
        catch
            break;
        end
        %Replace blank spaces in the protocol name with underscores
        protocolName = regexprep(curHdr.session.protocolName, ' ', '_');
        
        %Construct the new human-readable names of directories and files
        scanFileName = [protocolName, '_', ...
                        sprintf('%04d', dicomDir.DirectoryRecordSequence.(curItem).InstanceNumber), ...
                        '.dcm'];
        scanDirName = [protocolName, '_', ...
                       sprintf('%04d', curHdr.session.seriesNumber)];
        if ~exist([filePath, filesep, ...
                   'converted', filesep, ...
                   scanDirName], 'dir')
            mkdir([filePath, filesep, 'converted'], scanDirName);
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
    waitbar(ii/numItems, waitbarFig);
end
endTime = toc(startTime);
close(waitbarFig);

%Reset the warning state(s) that might have been changed
warning(warningDRState(1).state, 'images:dicominfo:fileVRDoesNotMatchDictionary');

%Report how long the process took
fprintf('This took a total of %0.1f seconds, or %0.1f seconds per file.\n', ...
         endTime, endTime/numItems);


end
