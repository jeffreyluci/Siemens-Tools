function correctDatName(datDir, dicomDir, options)
%correctDatNames - A fucntion that will change the filenames of dat files
%                  created using the WashU C2P NORDIC recon functor to be 
%                  consistent with their corresponding DICOMs that were 
%                  corrected with Siemens software and assigned a new UID 
%                  that does not match that of the dat filenames.
%
%Usage: correctDatNames
%       correctDatNames(datDir, dicomDir)
%       correctDatNames(datDir, dicomDir, debug=true)
%
%datDir: path to the directory containing dat files needing corrections
%
%dicomDir: path to the directory containing Siemens-corrected DICOM files
%
%options: debug = true/(false) - logical (boolean) that, when set to true,  
%         prevents any renaming of files, and instead forces text output  
%         that reports the source and target names that would have been  
%         used if set to false
%
% This function is intended to fix a problem that arises when it becomes
% necessary to use either the WashU-sourced Pythod NIfTI construction
% pipeline or this author's dat2niix.m MATLAB function. Both of those
% pipelines use the series instance UID archived in the DICOM file to build 
% the names of their corresponding dat files. Unfortunately, when it becomes
% necessary to correct metadata for a series, that series is assigned a new 
% UID that does not correspond to the dat files names, leaving no way to
% connect the two.
%
% This function will rename a directory of dat files to correcpond to the
% new UID assigned to the corrected DICOMs so that both pipelines listed
% above will be able to process the data.
%
% When called without arguments, a GUI dialog box will be displayed that
% asks the user to select the directory containing the DICOMs. This method
% assumes that the dat files are in a directory one step above the one
% selected, and named, "dat". For instnace, if the directory
% /data/scan1/dicom is selected with the dialog box, the function assumes
% that the dat files are located in /data/scan1/dat. If they are not, an
% error message will result.
%
% When called specifying both datDir and dicomDir, the function will use
% those source directories, regardless of their hierarchical structures.
%
% If the user desires to check the planned file renaming without actually
% performing them, setting the debug option to true will list on the screen
% all the file renaming operations that would have been performed had the
% debug option been set to false, or not been set at all (false is the
% default)
%
%The NORDIC reconstruction functor (pipeline) is available at 
% <a href="matlab:web('https://webclient.us.api.teamplay.siemens-healthineers.com/c2p')">The Siemens Teamplay C2P Exchange.</a>
%
% This function is maintained <a href="matlab:web('https://github.com/jeffreyluci/Siemens-Tools/tree/main/correctDatName')">at this URL.</a>:
% Version: 20250117

% Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/correctDatName
% VERSION HISTORY:
% 20250117: Initial Release.

% parse the input arguments
arguments
    datDir char = ''
    dicomDir char= ''
    options.debug (1,1) logical = false;
end

% if no aruments provided, employ a dialog box to obtain the location of
% the directory of DICOMs
if isempty(dicomDir)
    uiwait(msgbox('Navigate to the DICOM directory of the scan to be corrected.', ...
                  'Instructions', 'modal'));
    dicomDir = uigetdir('/media/inline/ME_Data', 'Select DICOM folder');
    if isnumeric(dicomDir)
        return;
    end
    dicomDir = [dicomDir, filesep];
    dicomDirListing = dir(dicomDir);
    dicomDirListing = dicomDirListing(3:end);
    if ~isdicom([dicomDir, dicomDirListing(1).name])
        error(['It appears that ', dicomDir, ' does not have DICOM files in it.']);
    else
        [status, dirInfo] = fileattrib(dicomDir); %get absolute paths
        if status
            splitDirName = split(dirInfo.Name, filesep);
            splitDirName = splitDirName(1:end-1);
            splitDirName(end+1) = {'dat'};
            datDir = cell2mat(join(splitDirName, filesep));
        else
            error('There was an error reading the DICOM directory.');
        end
    end
end

% report the directories enumerated
disp(['DICOM Dir = ', dicomDir, newline, ' Dat Dir = ', datDir]);

% ensure the directory paths are formetted correctly
if ~strcmp(datDir(end), filesep)
    datDir = [datDir, filesep];
end
if ~strcmp(dicomDir(end), filesep)
    dicomDir = [dicomDir, filesep];
end

% get the DICOM header information
d = dir(dicomDir);

ii=3;
while ~exist('hdr', 'var')
    curDicom = [dicomDir, d(ii).name];
    if isdicom(curDicom)
        hdr = dicominfo(curDicom);
    end
    ii = ii+1;
end

% using the new series UID, rename the dat files to correspond with DICOMs 
d=dir(datDir);
for ii = 3:numel(d)
    curFile = [datDir, d(ii).name];
    [~,~,ext] = fileparts(curFile);
    if strcmp(ext, '.dat')
        if ~exist([datDir, '..', filesep, 'datchange.log'], 'file')
            fid = fopen([datDir, '..', filesep, 'datchange.log'], 'wt');
            fwrite(fid, ['Changed ', curFile, ' to use: ', hdr.SeriesInstanceUID, newline], 'char');
            fclose(fid);
        end
        F = split(d(ii).name, '_');
        F{2} = hdr.SeriesInstanceUID;
        newFile = [datDir, cell2mat(join(F,'_'))];
        if options.debug
            disp(['Command: movefile(', curFile, ', ', newFile, ');']);
        else
            movefile(curFile, newFile);
        end
    end
end


end