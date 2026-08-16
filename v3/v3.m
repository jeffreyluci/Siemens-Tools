function v3(IM)
%v3 - 3 Pane volume grayscale image viewer
%
%Usage: v3
%       v3(img)
%
%       img: (optional) scaled 3D volume image of any appropriate calss
%
%v3 is a light weight 3-pane viewer for general purpose viewing and 
%inspection of scaled (monochrome) 3D vlume images. Without arguments, the
%user will be presented with a file browser and propmted to select an image
%file. Both NIfTIs and DICOMs are supported. If the DICOM is enhanced, v3
%assumes it is multi-frame and imports all the image data from the one
%file. If, however, the DICOM is not enhanced, it will assume that all
%DICOM files in the same directory are part of the same volume, and
%attempts to read use them all. If there are any DICOMs in that directory
%that are NOT part of the same volume, a fatal error may result.
%
%The user may choose to export the volume as it appears to the MATLAB
%workspace. This is useful if some manual image rotation is necessary to
%generate a pleasing orientation for presentation purposes.

% Written by J. Luci: jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/v3
% Version History:
%v1.0: (October, 2011) Initial Release
%Numerous undocumented versions released, up to v3.2.
%20260813: This is a complete overhaul of the code to make use of MATLAB's 
% newer uifigure and uicontrol features. This is a faster and more robust 
% version with numerous bug fixes and added features.
%20260816: Enabled window rescaling. Added series UID checks to gracefully
%fail if non-enhanced DICOMs of multiple different scans are detected in
%the directory specified.

if isdeployed || ~exist('IM', 'var')
    [fileName, dirName] = uigetfile({'*.dcm';'*.dicom';'*.ima';'*.nii';'*.nii.gz'}, 'Select Image File . . .');
    [~,~,ext] = fileparts(fileName);
    if strcmpi(ext, '.dcm') || strcmpi(ext, '.dicom') || strcmp(ext, '.ima')
        listing = dir([dirName, '*', ext]);
        listing = listing(3:end);
        hdr = dicominfo(fullfile(dirName, fileName));
        UID = hdr.SeriesInstanceUID;
        if numel(listing) > 1 && ~strcmp(hdr.SOPClassUID, '1.2.840.10008.5.1.4.1.1.4.1')
            IM = dicomread(fullfile(dirName, fileName));
            imgClass = class(IM);
            IM = cast(zeros(size(IM,1), size(IM,2), numel(listing)), imgClass);
            hdr(numel(listing)) = hdr;
            for ii = 1:numel(listing) %#ok<*FXUP>
                IM(:,:,ii) = dicomread(fullfile(dirName, listing(ii).name));
                hdr(ii)    = dicominfo(fullfile(dirName, listing(ii).name));
                if strcmp(hdr(ii).SOPInstanceUID, UID)
                    error('DICOMs of mutliple scans detected in the directory.');
                end
            end
            sliceLocs = [hdr.SliceLocation];
            [~,sliceOrder] = sort(sliceLocs);
            IM = IM(:,:,sliceOrder);
        else
            IM = squeeze(dicomread(fullfile(dirName, fileName)));
        end
    elseif strcmp(ext, '.nii') || strcmp(ext, '.gz')
        IM = squeeze(niftiread(fullfile(dirName, fileName)));
    else
        error('Unsupported filetype.');
    end
end

maxInt=max(IM(:));
minInt=min(IM(:));

rotateUndo =  [0 0 0];
rotateReset = [0 0 0];
sliceUndo = round(size(IM)/2);
method='crop';

fig = figure;
setappdata(fig, 'visCh', 'on');
pos=get(fig, 'Position');

set(fig,'Position',    [pos(1) pos(2) 1000 460], ...
        'Name',        ['View3d ' char(169) ' 2011-2026 Jeffrey Luci, ' ...
        'Rutgers University'], ...
        'ToolBar',     'none', ...
        'MenuBar',     'none', ...
        'NumberTitle', 'off', ...
        'Resize',      'on');
movegui(fig, 'center');
bkgColor = get(fig, 'Color');

axis1 = subplot(1, 3, 1);
I1 = imagesc(IM(:,:,round(size(IM,3)/2)),[minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
P1 = drawpoint(axis1, 'Position', [round(size(IM,2)/2), round(size(IM,1)/2)], ...
                      'Color',       'r', ...
                      'MarkerSize',  3, ...
                      'LineWidth',   0.25, ...
                      'Deletable',   false, ...
                      'DrawingArea', [1,1,size(IM,1)-1,size(IM,2)-1], ...
                      'InteractionsAllowed', 'translate');

axis2 = subplot(1, 3, 2);
I2 = imagesc(squeeze(IM(:,round(size(IM,2)/2),:)), [minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
P2 = drawpoint(axis2, 'Position', [round(size(IM,3)/2), round(size(IM,1)/2)], ...
                      'Color',       'r', ...
                      'MarkerSize',  3, ...
                      'LineWidth',   0.25, ...
                      'Deletable',   false, ...
                      'DrawingArea', [1,1,size(IM,3)-1,size(IM,1)-1], ...
                      'InteractionsAllowed', 'translate');

axis3 = subplot(1, 3, 3);
I3 = imagesc(squeeze(IM(round(size(IM,1)/2),:,:)), [minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
P3 = drawpoint(axis3, 'Position', [round(size(IM,3)/2), round(size(IM,2)/2)], ...
                      'Color',       'r', ...
                      'MarkerSize',  3, ...
                      'LineWidth',   0.25, ...
                      'Deletable',   false, ...
                      'DrawingArea', [1,1,size(IM,3)-1,size(IM,2)-1], ...
                      'InteractionsAllowed', 'translate');

set(axis1, 'Position', [0.01  0.18 0.3 0.8]);
set(axis2, 'Position', [0.351 0.18 0.3 0.8]);
set(axis3, 'Position', [0.69  0.18 0.3 0.8]);

addlistener(P1, 'MovingROI', @updatePanel1);
addlistener(P2, 'MovingROI', @updatePanel2);
addlistener(P3, 'MovingROI', @updatePanel3);

pos1=get(P1, 'Position');
pos2=get(P2, 'Position');
pos3=get(P3, 'Position');

l1v = line(axis1, [pos1(2),pos1(2)], [1,size(IM,1)],    'Color', [0,0.4470,0.7410]);
l1h = line(axis1, [1,size(IM,2)],    [pos1(1),pos1(1)], 'Color', [0,0.4470,0.7410]);
l2v = line(axis2, [pos2(1),pos2(1)], [1,size(IM,1)],    'Color', [0,0.4470,0.7410]);
l2h = line(axis2, [1,size(IM,3)],    [pos2(2),pos2(2)], 'Color', [0,0.4470,0.7410]);
l3v = line(axis3, [pos3(1),pos3(1)], [1,size(IM,2)],    'Color', [0,0.4470,0.7410]);
l3h = line(axis3, [1,size(IM,3)],    [pos3(2),pos3(2)], 'Color', [0,0.4470,0.7410]);
uistack(P1, 'top');
uistack(P2, 'top');
uistack(P3, 'top');

SCH = uicontrol(fig,            'Style',           'checkbox', ...
                                'Value',           0, ...
                                'String',          'Hide Crosshairs', ...
                                'Position',        [160 10 130 20], ...
                                'BackgroundColor', bkgColor, ...
                                'Callback',        @setCrosshairs);
              
cropRotate = uicontrol(fig,     'Style',           'checkbox', ...
                                'Value',           1, ...
                                'String',          'Crop Rotated Volume', ...
                                'Position',        [20 30 130 20], ...
                                'BackgroundColor', bkgColor);
                     
rotateResetButton=uicontrol(fig,'Style',           'pushbutton', ....
                                'String',          'Reset Rotations', ...
                                'Position',        [35 7 100 20], ...
                                'Enable',          'off', ...
                                'Callback',        @resetRotations);


rotateA1EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [140 60 40 20], ...
                                'Callback',        @rotateA1);
                   
rotateA2EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [480 60 40 20],...
                                'Callback',        @rotateA2);
                   
rotateA3EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [820 60 40 20],...
                                'Callback',        @rotateA3);
                            
slice1EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,3)/2)),...
                                'Position',        [98 60 40 20], ...
                                'Callback',        @specifySlice1);

slice2EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,2)/2)),...
                                'Position',        [438 60 40 20], ...
                                'Callback',        @specifySlice2);
                            
slice3EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,1)/2)),...
                                'Position',        [778 60 40 20], ...
                                'Callback',        @specifySlice3);
                            
slice1Label = uicontrol(fig,    'Style',           'Text', ... 
                                'Position',        [60 58 35 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        9, ...
                                'String',          'Slice:'); %#ok<*NASGU>
                            
slice2Label = uicontrol(fig,    'Style',           'Text', ...
                                'Position',        [400 58 35 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        9, ...
                                'String',          'Slice:');
                            
slice3Label = uicontrol(fig,    'Style',           'Text', ...
                                'Position',        [740 58 35 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        9, ...
                                'String',          'Slice:'); 
                   
rotate1Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [180 60 7 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        11, ...
                                'String',          char(176));
                         
rotate2Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [520 60 7 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        11, ...
                                'String',          char(176)); 
                         
rotate3Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [860 60 7 20], ...
                                'BackgroundColor', bkgColor, ...
                                'FontSize',        11, ...
                                'String',          char(176));

              
maxSlider = uicontrol(fig,      'Style',           'Slider', ...
                                'Position',        [300 30 200 20], ...
                                'Max',             max(IM(:))*1.01, ...
                                'Min',             min(IM(:)), ...
                                'Value',           max(IM(:)), ...                        
                                'Callback',        @scaleMaxInt);

minSlider = uicontrol(fig,      'Style',           'Slider', ...
                                'Position',        [300 10 200 20], ...
                                'Max',             max(IM(:))*1.01, ...
                                'Min',             min(IM(:)), ...
                                'Value',           min(IM(:)), ...
                                'Callback',        @scaleMinInt);
                    
maxSliderLabel = uicontrol(fig, 'Style',           'Text', ...
                                'Position',        [500 26 130 20], ...
                                'BackgroundColor', bkgColor, ...
                                'String',          'Maximum Intensity');
                         
minSliderLabel = uicontrol(fig, 'Style',           'Text', ...
                                'Position',        [500 6 130 20], ...
                                'BackgroundColor', bkgColor, ...
                                'String',          'Minimum Intensity');   
                         
exportDataButton =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Export Volume to Workspace', ...
                                'Position',        [800 10 175 25], ...
                                'Callback',        @exportData);
                            
if isdeployed
    set(exportDataButton, 'Enable', 'off');
end


    function updatePanel1(~,~)
        pos1=get(P1, 'Position');
        pos2=get(P2, 'Position');
        pos3=get(P3, 'Position');
        I2.CData = squeeze(IM(:,round(pos1(1)),:));
        set(P2, 'Position', [pos2(1), pos1(2)]);
        set(P3, 'Position', [pos3(1), pos1(1)]);
        I3.CData= squeeze(IM(round(pos1(2)),:,:));
        set(slice2EditBox, 'String', num2str(round(pos1(1))));
        set(slice3EditBox, 'String', num2str(round(pos1(2))));
        setCrosshairs;
        drawnow;
    end

    function updatePanel2(~,~)
        pos1=round(get(P1, 'Position'));
        pos2=round(get(P2, 'Position'));
        pos3=round(get(P3, 'Position'));
        I1.CData = squeeze(IM(:,:,round(pos2(1))));
        set(P1, 'Position', [pos1(1), pos2(2)]);
        set(P3, 'Position', [pos2(1), pos3(2)]);
        I3.CData = squeeze(IM(round(pos2(2)),:,:));
        set(slice1EditBox, 'String', num2str(round(pos2(1))));
        set(slice3EditBox, 'String', num2str(round(pos1(2))));
        setCrosshairs;
        drawnow;
    end

    function updatePanel3(~,~)
        pos1=round(get(P1, 'Position'));
        pos2=round(get(P2, 'Position'));
        pos3=round(get(P3, 'Position'));
        I1.CData = squeeze(IM(:,:,round(pos3(1))));
        set(P1, 'Position', [pos3(2), pos1(2)]);
        set(P2, 'Position', [pos3(1), pos2(2)]);
        I2.CData = squeeze(IM(:,round(pos3(2)),:));
        set(slice1EditBox, 'String', num2str(round(pos2(1))));
        set(slice2EditBox, 'String', num2str(round(pos1(1))));
        setCrosshairs;
        drawnow;
    end

    function setCrosshairs(~, ~)
        if get(SCH, 'Value')==1
            set(P1,  'Visible', 'off');
            set(P2,  'Visible', 'off');
            set(P3,  'Visible', 'off');
            set(l1v, 'Visible', 'off');
            set(l1h, 'Visible', 'off');
            set(l2v, 'Visible', 'off');
            set(l2h, 'Visible', 'off');
            set(l3v, 'Visible', 'off');
            set(l3h, 'Visible', 'off');
        else
            set(P1,  'Visible', 'on');
            set(P2,  'Visible', 'on');
            set(P3,  'Visible', 'on');
            set(l1v, 'Visible', 'on');
            set(l1h, 'Visible', 'on');
            set(l2v, 'Visible', 'on');
            set(l2h, 'Visible', 'on');
            set(l3v, 'Visible', 'on');
            set(l3h, 'Visible', 'on');
            set(l1v, 'XData', [pos1(1),pos1(1)], 'YData', [1,size(IM,1)]);
            set(l1h, 'XData', [1,size(IM,2)], 'YData', [pos1(2),pos1(2)]);

            set(l2v, 'XData', [pos2(1),pos2(1)], 'YData', [1,size(IM,1)]);
            set(l2h, 'XData', [1,size(IM,3)], 'YData', [pos2(2),pos2(2)]);

            set(l3v, 'XData', [pos3(1),pos3(1)], 'YData', [1,size(IM,2)]);
            set(l3h, 'XData', [1,size(IM,3)], 'YData', [pos3(2),pos3(2)]);
        end
    end

    function scaleMaxInt(maxSlider, ~, ~)
        oldVal=maxInt;
        newVal=get(maxSlider, 'Value');
        if newVal <= get(minSlider, 'Value')
            set(maxSlider, 'Value', oldVal);
            return;
        else
            maxInt=newVal;
            set(axis1, 'CLim', [minInt, maxInt]);
            set(axis2, 'CLim', [minInt, maxInt]);
            set(axis3, 'CLim', [minInt, maxInt]);
        end
    end

    function scaleMinInt(minSlider, ~, ~)
        oldVal=minInt;
        newVal=get(minSlider, 'Value');
        if newVal >= get(maxSlider, 'Value')
            set(minSlider, 'Value', oldVal);
            return;
        else
            minInt=newVal;
            set(axis1, 'CLim', [minInt, maxInt]);
            set(axis2, 'CLim', [minInt, maxInt]);
            set(axis3, 'CLim', [minInt, maxInt]);
            set(rotateResetButton, 'Enable', 'on');
        end
    end

    function rotateA1(~, ~)
        newVal=str2double(get(rotateA1EditBox, 'String'));
        if isempty(newVal)
            set(rotateA1EditBox, 'String', num2str(rotateUndo(1)));
        else
            rotateUndo(1)=newVal;
            if get(cropRotate, 'Value')
                temp=zeros(size(IM));
                method='crop';
            else
                temp=imrotate(IM(:,:,1), newVal, 'bicubic', 'loose');
                temp=zeros(size(temp,1), size(temp,2), size(IM,3));
                method='loose';
            end
            wFig=waitbar(0, 'Performing 3D Rotation . . .');
            for image3DRotationCounter = 1:size(IM,3)
                temp(:,:,image3DRotationCounter)=imrotate(IM(:,:,image3DRotationCounter), newVal, 'bicubic', method);
                waitbar(image3DRotationCounter/size(IM,3), wFig);
            end
            close(wFig);
            IM=temp;
            clear temp;
            rotateReset(1) = rotateReset(1) + newVal;
            set(rotateA1EditBox, 'String', num2str(rotateReset(1)));
            set(P1, 'DrawingArea', [1,1,size(IM,2)-1,size(IM,1)-1]);
            set(P2, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,1)-1]);
            set(P3, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,2)-1]);
            updatePanel1;
            updatePanel2;
            updatePanel3;
            set(rotateResetButton, 'Enable', 'on');
        end
    end
 
    function rotateA2(~, ~)
        newVal=str2double(get(rotateA2EditBox, 'String'));
        if isempty(newVal)
            set(rotateA2EditBox, 'String', rotateUndo(2));
        else
            rotateUndo(2) = newVal;
            IM=permute(IM, [1 3 2]);
            if get(cropRotate, 'Value')
                temp=zeros(size(IM));
                method='crop';
            else
                temp=imrotate(IM(:,:,1), newVal, 'bicubic', 'loose');
                temp=zeros(size(temp,1), size(temp,2), size(IM,3));
                method='loose';
            end
            wFig=waitbar(0, 'Performing 3D Rotation . . .');
            for ii = 1:size(IM,3)
                temp(:,:,ii)=imrotate(IM(:,:,ii), newVal, 'bicubic', method);
                waitbar(ii/size(IM,3), wFig);
            end
            close(wFig);
            IM=ipermute(temp, [1 3 2]);
            clear temp;
            rotateReset(2) = rotateReset(2) + newVal;
            set(rotateA2EditBox, 'String', num2str(rotateReset(2)));
            set(P1, 'DrawingArea', [1,1,size(IM,2)-1,size(IM,1)-1]);
            set(P2, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,1)-1]);
            set(P3, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,2)-1]);
            updatePanel1;
            updatePanel2;
            updatePanel3;
            set(rotateResetButton, 'Enable', 'on');
        end
    end

    function rotateA3(~, ~)
        newVal=str2double(get(rotateA3EditBox, 'String'));
        if isempty(newVal)
            set(rotateA3EditBox, 'String', num2str(rotateUndo(3)));
        else
            rotateUndo(3) = newVal;
            IM=permute(IM, [3 2 1]);
            if get(cropRotate, 'Value')
                temp=zeros(size(IM));
                method='crop';
            else
                temp=imrotate(IM(:,:,1), newVal, 'bicubic', 'loose');
                temp=zeros(size(temp,1), size(temp,2), size(IM,3));
                method='loose';
            end
            wFig=waitbar(0, 'Performing 3D Rotation . . .');
            for imageRotateCounter = 1:size(IM,3)
                temp(:,:,imageRotateCounter)=imrotate(IM(:,:,imageRotateCounter), newVal, 'bicubic', method);
                waitbar(imageRotateCounter/size(IM,3), wFig);
            end
            close(wFig);
            IM=ipermute(temp, [3 2 1]);
            clear temp;
            rotateReset(3) = rotateReset(3) + newVal;
            set(rotateA3EditBox, 'String', num2str(rotateReset(3)));
            set(P1, 'DrawingArea', [1,1,size(IM,2)-1,size(IM,1)-1])
            set(P2, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,1)-1])
            set(P3, 'DrawingArea', [1,1,size(IM,3)-1,size(IM,2)-1])
            updatePanel1;
            updatePanel2;
            updatePanel3;
        end
    end

    function exportData(~, ~)
        assignin('base', 'v3_volume', IM);
    end
        
    function resetRotations(~, ~)
        numSteps=0;
        if rotateReset(1) ~= 0
            numSteps=size(IM,3);
        end
        if rotateReset(2) ~= 0
            numSteps=numSteps+size(IM,2);
        end
        if rotateReset(3) ~= 0
            numSteps=numSteps+size(IM,1);
        end
        resettingWaitbar=waitbar(0, 'Resetting the Rotations . . .');
        if rotateReset(1) ~= 0
            for imageRotateResetCounter = 1:size(IM,3)
                IM(:,:,imageRotateResetCounter)=imrotate(IM(:,:,imageRotateResetCounter), -rotateReset(1), 'bicubic', method);
                waitbar(imageRotateResetCounter/numSteps, resettingWaitbar);
            end
        end
        if rotateReset(2) ~= 0
            IM=permute(IM, [1 3 2]);
            for jj = 1:size(IM,3)
                IM(:,:,jj)=imrotate(IM(:,:,jj), -rotateReset(2), 'bicubic', method);
                waitbar((ii+jj)/numSteps, resettingWaitbar);
            end
            IM=ipermute(IM, [1 3 2]);
        end
        if rotateReset(3) ~= 0
            IM=permute(IM, [3 2 1]);
            for kk = 1:size(IM,3)
                IM(:,:,kk)=imrotate(IM(:,:,kk), -rotateReset(3), 'bicubic', method);
                waitbar((ii+jj+kk)/numSteps, resettingWaitbar);
            end
            IM=ipermute(IM, [3 2 1]);
        end
        close(resettingWaitbar);
        updatePanel1;
        updatePanel2;
        rotateReset = [0 0 0];
        set(rotateA1EditBox, 'String', '0');
        set(rotateA2EditBox, 'String', '0');
        set(rotateA3EditBox, 'String', '0');
    end

    function specifySlice1(~, ~)
        newVal=round(str2double(get(slice1EditBox, 'String')));
        if isempty(newVal) || newVal<1 || newVal>size(IM,3)
            set(slice1EditBox, 'String', num2str(sliceUndo(3)));
        else
            pos1=get(P1, 'Position');
            pos2=get(P2, 'Position');
            pos3=get(P3, 'Position');
            pos2(1) = newVal;
            pos3(1) = newVal;
            set(P2, 'Position', [pos2(1), pos2(2)]);
            set(P3, 'Position', [pos3(1), pos3(2)]);
            updatePanel2;
            sliceUndo(3)=newVal;
        end
    end

    function specifySlice2(~, ~)
        newVal=round(str2double(get(slice2EditBox, 'String')));
        if isempty(newVal) || newVal<1 || newVal>size(IM,2)
            set(slice2EditBox, 'String', num2str(sliceUndo(2)));
        else
            pos1=get(P1, 'Position');
            pos2=get(P2, 'Position');
            pos3=get(P3, 'Position');
            pos1(1) = newVal;
            pos3(2) = newVal;
            set(P1, 'Position', [pos1(1), pos1(2)]);
            set(P3, 'Position', [pos3(1), pos3(2)]);
            updatePanel1;
            sliceUndo(2)=newVal;
        end
    end

    function specifySlice3(~, ~)
        newVal=round(str2double(get(slice3EditBox, 'String')));
        if isempty(newVal) || newVal<1 || newVal>size(IM,2)
            set(slice3EditBox, 'String', num2str(sliceUndo(1)));
        else
            pos1=get(P1, 'Position');
            pos2=get(P2, 'Position');
            pos3=get(P3, 'Position');
            pos1(2) = newVal;
            pos2(2) = newVal;
            set(P1, 'Position', [pos1(1), pos1(2)]);
            set(P2, 'Position', [pos2(1), pos2(2)]);
            updatePanel1;
            sliceUndo(1)=newVal;
        end
    end

    function p1Moved(~,~) %#ok<*DEFNU>
        updatePanel1;
        pos1=get(P1, 'Position');
        sliceUndo(1) = pos1(1);
        sliceUndo(2) = pos1(2);
    end

    function p2Moved(~,~) 
        updatePanel2;
        pos2=get(P2, 'Position');
        sliceUndo(1) = pos2(1);
        sliceUndo(3) = pos2(2);
    end

    function p3Moved(~,~) 
        updatePanel3;
        pos3=get(P3, 'Position');
        sliceUndo(2) = pos3(1);
        sliceUndo(3) = pos3(2);
    end

end