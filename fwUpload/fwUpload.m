function fwUpload

fig = uifigure('Name', ['fwUpload v0.1 ' char(169) '2024 Jeffrey Luci, ' ...
                        'Rutgers University'], ...
                'Position',  [1 1 800 900]);
screenSize = get(0, 'screensize');
if screenSize(4) < 900
    set(fig, 'scrollable', 'on');
end
% fig = figure;
% set(fig, 'Name',   ['fwUpload v0.1 ' char(169) '2024 Jeffrey Luci, ' ...
%                     'Rutgers University'], ...
%     'NumberTitle',  'off', ...
%     'MenuBar',      'none', ...
%     'ToolBar',      'figure', ...
%     'Position',     [1 1 800 900], ...
%     'Renderer',     'OpenGL');

%customizeToolbar(fig);
movegui(fig, 'center');


niftiDirectory =[];
groupID        =[];
projectID      = [];
subjectID      = [];
sessionID      = [];
acqID          = [];

% letters = ['a':'z', newline];
% testString = letters(randi(27, [1 2000]));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Build GUI Elements                                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

directoryGroup = uipanel('Parent', fig, ...
    'Title', 'Directories', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Position',  [25 770 750 110]);
    %'Position', [0.02 0.87 .96 .12]);

niftiDirBrowseBtn = uicontrol(directoryGroup, 'Style', 'pushbutton', ...
    'Position',  [15 10 205 30], ...
    'String', 'Browse to NIfTI Directory', ...
    'FontSize', 12, ...
    'Callback', @updateNiftiDirectory);

niftiDirTextBox = uicontrol(directoryGroup, 'Style', 'text', ...
    'Position',  [225 10 500 30], ...
    'String', '<--- Specify NIfTI Directory', ...
    'FontSize', 12, ...
    'Enable', 'on', ...
    'Callback', @manualSelect);

dicomDirBrowseBtn = uicontrol(directoryGroup, 'Style', 'pushbutton', ...
    'Position',  [15 50 205 30], ...
    'String', 'Browse to DICOM Directory', ...
    'FontSize', 12, ...
    'Callback', @updateDicomDirectory);

dicomDirTextBox = uicontrol(directoryGroup, 'Style', 'text', ...
    'Position',  [225 50 500 30], ...
    'String', '<--- Specify DICOM Directory', ...
    'FontSize', 12, ...
    'Enable', 'on', ...
    'Callback', @manualSelect);


studyGroup = uipanel('Parent', fig, ...
    'Title', 'Study Info', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Position', [25 610 750 150]);
    %'Position', [0.02 0.71 .96 .16]);

groupText = uicontrol(studyGroup, 'Style', 'text', ...
    'Position',  [15 90 340 25], ...
    'BackgroundColor', [1 1 1], ...
    'String', 'Group:', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 12);

projectText = uicontrol(studyGroup, 'Style', 'text', ...
    'Position',  [375 90 340 25], ...
    'BackgroundColor', [1 1 1], ...
    'String', 'Project:', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 12);

subjectText = uicontrol(studyGroup, 'Style', 'text', ...
    'Position',  [15 55 340 25], ...
    'BackgroundColor', [1 1 1], ...
    'String', 'Subject ID:', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 12);

sessionText = uicontrol(studyGroup, 'Style', 'text', ...
    'Position',  [375 55 340 25], ...
    'BackgroundColor', [1 1 1], ...
    'String', 'Session #:', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 12);

acqText = uicontrol(studyGroup, 'Style', 'text', ...
    'Position',  [15 15 700 25], ...
    'BackgroundColor', [1 1 1], ...
    'String', 'Acquisition:', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 12);

uploadGroup = uipanel('Parent', fig, ...
    'Title', 'Upload Files', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Position', [25 200 750 400]);
    %'Position', [0.02 0.14 .96 .57]);

uploadList = uilistbox('Parent', uploadGroup, ...
     'Position', [15 15 720 350], ...
     'FontSize', 14, ...
     'Items', {' '}, ...
     'Multiselect', 'on', ...
     'ValueChangedFcn', @updateUploadList);



flywheelGroup = uipanel('Parent', fig, ...
    'Title', 'Flywheel', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Position', [25 15 750 175]);
    %'Position', [0.02 0.02 .96 .12]);

generateBashScriptButton = uicontrol(flywheelGroup, ...
    'Style', 'pushbutton', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'String', 'Generate Bash Script', ...
    'FontSize', 12, ...
    'Position', [15 15 200, 30], ...
    'Enable', 'off', ...
    'Callback', @generateBashScript);

uploadButton = uicontrol(flywheelGroup, ...
    'Style', 'pushbutton', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'String', 'Upload Selected Files', ...
    'FontSize', 12, ...
    'Position', [15 50 200, 30], ...
    'Enable', 'off', ...
    'Callback', @uploadFiles);

fwOutputTextBox = uitextarea(flywheelGroup, ...
    'BackgroundColor', [1 1 1], ...
    'FontSize', 10, ...
    'Position', [225, 15, 510 125], ...
    'Value', [' ']);



% if exist('homeDirectory', 'var')
%     updateDicomDirectory;
% end



disp('breakpoint');


    function updateNiftiDirectory(~,~)
        if isempty(niftiDirectory)
            niftiDirectory = uigetdir('./', 'Browse to NIfTI Directory');
        end
        if isnumeric(niftiDirectory) && niftiDirectory == 0
            return;
        end

        d=dir(niftiDirectory);
        listLength = 0;
        for ii = 3:numel(d)
            curFile = [niftiDirectory, filesep, d(ii).name];
            [~,~,ext] = fileparts(curFile);
            switch ext
                case '.nii'
                    listLength = listLength + 1;
                    niftiList(listLength).FQN = curFile;
                    niftiList(listLength).name = d(ii).name;
                    niftiList(listLength).nii = true;
                    niftiList(listLength).gz = false;
                    niftiList(listLength).json = false;
                case '.gz'
                    listLength = listLength + 1;
                    niftiList(listLength).FQN = curFile;
                    niftiList(listLength).name = d(ii).name;
                    niftiList(listLength).nii = false;
                    niftiList(listLength).gz = true;
                    niftiList(listLength).json = false;
                case '.json'
                    listLength = listLength + 1;
                    niftiList(listLength).FQN = curFile;
                    niftiList(listLength).name = d(ii).name;
                    niftiList(listLength).nii = false;
                    niftiList(listLength).gz = false;
                    niftiList(listLength).json = true;
            end
        end
        if listLength > 0
            niftiDirTextBox.String = niftiDirectory;
            checkList = {niftiList.name};
            uploadList.Items = checkList;
            uploadList.Value = checkList;


        end
        figure(fig);



    end




    function updateDicomDirectory(~,~)

        dicomDirectory = uigetdir('./', 'Browse to DICOM Directory');
        if isnumeric(dicomDirectory) && dicomDirectory == 0
            return;
        end

        d = dir(dicomDirectory);
        for ii = 3:numel(d)
            curFile = [dicomDirectory, filesep, d(ii).name];
            if isdicom(curFile)
                dicomFile = curFile;
                break;
            end
        end
        if exist('dicomFile', 'var')
            dicomDirTextBox.String = dicomDirectory;
            parseDicomInfo(dicomFile);
        else
            warndlg('No DICOM files found.', 'Warning');
        end
        splitDicomDirectory = split(dicomDirectory, filesep);
        if isempty(splitDicomDirectory{end})
            splitDicomDirectory{end-1} = 'nifti';
        else
            splitDicomDirectory{end} = 'nifti';
        end
        
        niftiDirectory = join(splitDicomDirectory, filesep);
        niftiDirectory = niftiDirectory{:};
        if ~exist(niftiDirectory, 'file')
            clear('niftiDirectory');
        else
            updateNiftiDirectory;
        end
        updateUploadList;
        figure(fig);

    end


    function updateUploadList(~,~)
        if numel(uploadList.Value) > 0
            set(generateBashScriptButton, 'Enable', 'on');
        else
            set(generateBashScriptButton, 'Enable', 'off');
        end
    end


    function generateBashScript(~,~)
        bashScriptText = ['#!/usr/bin/env bash', newline];
        for ii = 1:numel(uploadList.Value)
            bashScriptText = [bashScriptText, ...
                              'fw upload "', niftiDirectory, filesep, uploadList.Value{ii}, '"', ...
                              ' "fw://', groupID, '/', projectID, '/', ...
                              subjectID, '/', sessionID, '/', acqID, '"', newline];
        end

        [bashFileName, bashPathName, ~] = uiputfile({'*.*', '*.sh'}, 'Save Bash Script');
        fid = fopen([bashPathName, bashFileName], 'wt');
        if fid == 0
            warndlg(['Unable to write to ', [bashPathName, bashFileName]], 'Warning');
            return;
        end
        fwrite(fid, bashScriptText, 'char');
        fclose(fid);
        
    end


    function uploadFiles
        for ii = 1:numel(uploadList.Value)
            [~, STDOUT] = system(['junk upload "', niftiDirectory, filesep, uploadList.Value{ii}, '"', ...
                              ' "fw://', groupID, '/', projectID, '/', ...
                              subjectID, '/', sessionID, '/', acqID, '"']);
            fwOutputTextBox.String = [fwOutputTextBox.Value, newline, STDOUT];
            scroll(fwOutputTextBox, 'bottom');
        end




    end



    function parseDicomInfo(pathToDicomFile)
        if ~exist(pathToDicomFile, 'file')
            error([dicomFile, ' not found']);
        end

        hdr = dicominfo(pathToDicomFile);
        studyString = hdr.PatientComments;
        splitString = split(studyString, '/');
        groupID     = splitString{3};
        projectID   = splitString{4};
        subjectID   = splitString{5};
        sessionID   = splitString{6};
        acqID       = hdr.ProtocolName;

        groupText.String   = ['Group: ', groupID];
        projectText.String = ['Project: ' projectID];
        subjectText.String = ['Subject ID: ', subjectID];
        sessionText.String = ['Session #: ', sessionID];
        acqText.String     = ['Acquisition: ' acqID];

    end



end

    function customizeToolbar(fig)
       a = findall(fig); 
       b = findall(a, 'ToolTipString', 'Save Figure');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'New Figure');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Open File');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Rotate 3D');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Data Cursor');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Brush/Select Data');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Link Plot');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Insert Colorbar');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Insert Legend');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Hide Plot Tools');
       set(b, 'Visible', 'off');
       b = findall(a, 'ToolTipString', 'Show Plot Tools and Dock Figure');
       set(b, 'Visible', 'off');     
        
    end