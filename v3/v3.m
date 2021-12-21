function v3(IM)

if isdeployed || ~exist('IM', 'var')
    %dirname = uigetdir('.', 'Select image directory . . .');
    [filename, pathname, ~] = uigetfile({'*.dcm; *.ima; *.nii', 'DICOM and NIfTI files'}, 'Pick 3D image file');
    listing = dir(pathname);

    if(isdicom(fullfile(pathname, filename)))
        imageNum=1;
        sliceOrder=[];
        fileList = {};
        waitfig=waitbar(0, 'Reading DICOM headers . . .');
        for ii = 3:numel(listing)
            curfile = fullfile(pathname, listing(ii).name);
            if(isdicom(curfile))
                fileList{numel(fileList)+1} = curfile;
                hdr=dicominfo(curfile);
                sliceOrder = [sliceOrder hdr.SliceLocation];
            end
            waitbar(ii/numel(listing), waitfig);
        end
        close(waitfig);
        sortedSliceOrder = sort(sliceOrder);
        IM=int16(zeros(hdr.Height, hdr.Width, numel(sliceOrder)));
        waitfig=waitbar(0, 'Importing DICOMs . . .');
        for ii = 1:numel(sliceOrder)
            IM(:,:,ii)=dicomread(fileList{find(sortedSliceOrder(ii)==sliceOrder)});
            waitbar(ii/numel(sliceOrder), waitfig);
        end
        close(waitfig);
    elseif(isnifti(fullfile(pathname, filename)))
        IM = niftiread(fullfile(pathname, filename));
    else
        error('Filetype not supported.');
    end
end

maxInt=max(IM, [], 'all');
minInt=min(IM, [], 'all');

rotateUndo =  [0 0 0];
rotateReset = [0 0 0];
sliceUndo = round(size(IM)/2);
method='crop';
viewList = [0 0 0];

fig = figure;
setappdata(fig, 'visCh', 'on');
pos=get(fig, 'Position');

set(fig,'Position',    [pos(1) pos(2) 1000 460], ...
        'Name',        ['View3d ' char(169) ' 2011-2021 Jeffrey Luci, ' ...
        'Rutgers University'], ...
        'ToolBar',     'none', ...
        'MenuBar',     'none', ...
        'NumberTitle', 'off', ...
        'Resize',      'off');
movegui(fig, 'center');

axis1 = subplot(1, 3, 1);
I1=imagesc(IM(:,:,round(size(IM,3)/2)),[minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
set(gca, 'NextPlot', 'replace');
P1=impoint(axis1, round(size(IM,2)/2), round(size(IM,1)/2));

axis2 = subplot(1, 3, 2);
I2=imagesc(squeeze(IM(:,round(size(IM,2)/2),:)), [minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
set(gca, 'NextPlot', 'replace');
P2=impoint(axis2, round(size(IM,3)/2), round(size(IM,1)/2));

axis3 = subplot(1, 3, 3);
I3=imagesc(squeeze(IM(round(size(IM,1)/2),:,:)), [minInt maxInt]);
colormap gray, axis image, axis off;
hold on;
set(gca, 'NextPlot', 'replace');
P3=impoint(axis3, round(size(IM,3)/2), round(size(IM,2)/2));

set(axis1, 'Position', [0.01  0.18 0.3 0.8]);
set(axis2, 'Position', [0.351 0.18 0.3 0.8]);
set(axis3, 'Position', [0.69  0.18 0.3 0.8]);

D1=addNewPositionCallback(P1, @updatePanel1);
D2=addNewPositionCallback(P2, @updatePanel2);
D3=addNewPositionCallback(P3, @updatePanel3);

pos1=getPosition(P1);
pos2=getPosition(P2);
pos3=getPosition(P3);

SCH = uicontrol(fig,            'Style',           'checkbox', ...
                                'Value',           0, ...
                                'String',          'Hide Crosshairs', ...
                                'Position',        [160 10 130 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'Callback',        @setCrosshairs);
              
cropRotate = uicontrol(fig,     'Style',           'checkbox', ...
                                'Value',           1, ...
                                'String',          'Crop Rotated Volume', ...
                                'Position',        [20 30 130 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400]);
                     
rotateResetButton=uicontrol(fig,'Style',           'pushbutton', ....
                                'String',          'Reset Rotations', ...
                                'Position',        [35 7 100 20], ...
                                'Callback',        @resetRotations);


rotateA1EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [100 60 40 20], ...
                                'Callback',        @rotateA1);
                   
rotateA2EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [440 60 40 20],...
                                'Callback',        @rotateA2);
                   
rotateA3EditBox = uicontrol(fig,'Style',           'Edit', ...
                                'String',          '0', ...
                                'Position',        [780 60 40 20],...
                                'Callback',        @rotateA3);



slice1EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,3)/2)),...
                                'Position',        [58 60 40 20], ...
                                'Callback',        @specifySlice1);

slice2EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,2)/2)),...
                                'Position',        [398 60 40 20], ...
                                'Callback',        @specifySlice2);
                            
slice3EditBox = uicontrol(fig,  'Style',           'Edit', ...
                                'String',          num2str(round(size(IM,1)/2)),...
                                'Position',        [738 60 40 20], ...
                                'Callback',        @specifySlice3);
                            
slice1Label = uicontrol(fig,    'Style',           'Text', ...
                                'Position',        [20 58 35 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'FontSize',        9, ...
                                'String',          'Slice:');
                            
slice2Label = uicontrol(fig,    'Style',           'Text', ...
                                'Position',        [360 58 35 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'FontSize',        9, ....
                                'String',          'Slice:');
                            
slice3Label = uicontrol(fig,    'Style',           'Text', ...
                                'Position',        [700 58 35 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'FontSize',        9, ...
                                'String',          'Slice:'); 
                   
rotate1Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [140 60 7 20], ...
                                'FontSize',        11, ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'String',          char(176));
                         
rotate2Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [480 60 7 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'FontSize',        11, ...
                                'String',          char(176)); 
                         
rotate3Label = uicontrol(fig,   'Style',           'Text', ...
                                'Position',        [820 60 7 20], ...
                                'BackgroundColor', [0.8 0.8 0.8], ...
                                'FontSize',        11, ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'String',          char(176));

reorient1Button =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Reorient View', ...
                                'Position',        [165 60 100 20], ...
                                'Callback',        @reorient1);

reorient2Button =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Reorient View', ...
                                'Position',        [505 60 100 20], ...
                                'Callback',        @reorient2);

reorient3Button =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Reorient View', ...
                                'Position',        [845 60 100 20], ...
                                'Callback',        @reorient3);
            
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
                                'Position',        [502 26 130 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'String',          'Maximum Intensity');
                         
minSliderLabel = uicontrol(fig, 'Style',           'Text', ...
                                'Position',        [500 6 130 20], ...
                                'BackgroundColor', [0.9400 0.9400 0.9400], ...
                                'String',          'Minimum Intensity');   

exportPDFButton =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Export PDF Views', ...
                                'Position',        [635 10 175 25], ...
                                'Callback',        @exportPDF);
                         
exportDataButton =uicontrol(fig,'Style',           'pushbutton', ...
                                'String',          'Export Volume to Workspace', ...
                                'Position',        [810 10 175 25], ...
                                'Callback',        @exportData);
                            
if isdeployed
    set(exportDataButton, 'Enable', 'off');
end


    function updatePanel1(pos1)
        pos2=getPosition(P2);
        pos3=getPosition(P3);
        imagesc(squeeze(IM(:,round(pos1(1)),:)), ...
            'Parent', axis2, [minInt maxInt]);
        axis(axis2, 'off', 'image'),colormap gray;
        P2=impoint(axis2, pos2(1), pos1(2));
        setCrosshairs;
        imagesc(squeeze(IM(round(pos1(2)),:,:)), ...
            'Parent', axis3, [minInt maxInt]);
        axis(axis3, 'off', 'image'),colormap gray;
        set(axis1, 'View', [viewList(1), 90]);
        set(axis2, 'View', [viewList(2), 90]);
        set(axis3, 'View', [viewList(3), 90]);
        set(slice2EditBox, 'String', num2str(round(pos1(1))));
        set(slice3EditBox, 'String', num2str(round(pos1(2))));
        P3=impoint(axis3, pos3(1), pos1(1));
        D2=addNewPositionCallback(P2, @updatePanel2);
        D3=addNewPositionCallback(P3, @updatePanel3);
    end

    function updatePanel2(pos2)
        pos1=getPosition(P1);
        pos3=getPosition(P3);
        imagesc(IM(:,:,round(pos2(1))), ...
            'Parent', axis1, [minInt maxInt]);
        axis(axis1, 'off', 'image'),colormap gray;
        P1=impoint(axis1, pos1(1), pos2(2));
        setCrosshairs;
        imagesc(squeeze(IM(round(pos2(2)),:,:)), ...
            'Parent', axis3, [minInt maxInt]);
        axis(axis3, 'off', 'image'),colormap gray;
        set(axis2, 'View', [viewList(2), 90]);
        set(axis1, 'View', [viewList(1), 90]);
        set(axis3, 'View', [viewList(3), 90]);
        set(slice1EditBox, 'String', num2str(round(pos2(1))));
        set(slice3EditBox, 'String', num2str(round(pos1(2))));
        P3=impoint(axis3, pos2(1), pos3(2));
        setCrosshairs;
        D1=addNewPositionCallback(P1, @updatePanel1);
        D3=addNewPositionCallback(P3, @updatePanel3);
    end

    function updatePanel3(pos3)
        pos1=getPosition(P1);
        pos2=getPosition(P2);
        imagesc(IM(:,:,round(pos3(1))), ...
            'Parent', axis1,[minInt maxInt]);
        axis(axis1, 'off', 'image'),colormap gray;
        P1=impoint(axis1, pos3(2), pos1(2));
        imagesc(squeeze(IM(:,round(pos3(2)),:)), ...
            'Parent', axis2, [minInt maxInt]);
        axis(axis2, 'off', 'image'),colormap gray;
        set(axis3, 'View', [viewList(3), 90]);
        set(axis1, 'View', [viewList(1), 90]);
        set(axis2, 'View', [viewList(2), 90]);
        set(slice1EditBox, 'String', num2str(round(pos2(1))));
        set(slice2EditBox, 'String', num2str(round(pos1(1))));
        P2=impoint(axis2, pos3(1), pos2(2));
        D1=addNewPositionCallback(P1, @updatePanel1);
        D2=addNewPositionCallback(P2, @updatePanel2);
    end

    function setCrosshairs(source, eventdata)
        if get(SCH, 'Value')==1
            set(P1, 'Visible', 'off');
            set(P2, 'Visible', 'off');
            set(P3, 'Visible', 'off');
        else
            set(P1, 'Visible', 'on');
            set(P2, 'Visible', 'on');
            set(P3, 'Visible', 'on');
        end
    end

    function scaleMaxInt(maxSlider, eventdata, handles)
        oldVal=maxInt;
        newVal=get(maxSlider, 'Value');
        if newVal <= get(minSlider, 'Value')
            set(maxSlider, 'Value', oldVal);
            return;
        else
            maxInt=newVal;
            updatePanel1(getPosition(P1));
            updatePanel2(getPosition(P2));
            updatePanel3(getPosition(P3));
        end
    end

    function scaleMinInt(minSlider, eventdata, handles)
        oldVal=minInt;
        newVal=get(minSlider, 'Value');
        if newVal >= get(maxSlider, 'Value')
            set(minSlider, 'Value', oldVal);
            return;
        else
            minInt=newVal;
            updatePanel1(getPosition(P1));
            updatePanel2(getPosition(P2));
            updatePanel3(getPosition(P3));
        end
    end

    function rotateA1(eventdata, handles)
        newVal=str2num(get(rotateA1EditBox, 'String'));
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
            for ii = 1:size(IM,3)
                temp(:,:,ii)=imrotate(IM(:,:,ii), newVal, 'bicubic', method);
                waitbar(ii/size(IM,3), wFig);
            end
            close(wFig);
            IM=temp;
            updatePanel1(getPosition(P1));
            updatePanel2(getPosition(P2));
            updatePanel3(getPosition(P3));
            clear temp;
            rotateReset(1) = rotateReset(1) + newVal;
            set(rotateA1EditBox, 'String', num2str(rotateReset(1)));
        end
    end
 
    function rotateA2(eventdata, handles)
        newVal=str2num(get(rotateA2EditBox, 'String'));
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
            updatePanel1(getPosition(P1));
            updatePanel2(getPosition(P2));
            updatePanel3(getPosition(P3));
            clear temp;
            rotateReset(2) = rotateReset(2) + newVal;
            set(rotateA2EditBox, 'String', num2str(rotateReset(2)));
        end
    end

    function rotateA3(eventdata, handles)
        newVal=str2num(get(rotateA3EditBox, 'String'));
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
            for ii = 1:size(IM,3)
                temp(:,:,ii)=imrotate(IM(:,:,ii), newVal, 'bicubic', method);
                waitbar(ii/size(IM,3), wFig);
            end
            close(wFig);
            IM=ipermute(temp, [3 2 1]);
            updatePanel1(getPosition(P1));
            updatePanel2(getPosition(P2));
            updatePanel3(getPosition(P3));
            clear temp;
            rotateReset(3) = rotateReset(3) + newVal;
            set(rotateA3EditBox, 'String', num2str(rotateReset(3)));
        end
    end

    function exportData(eventdata, handles)
        assignin('base', 'v3_volume', IM);
    end
        
    function resetRotations(eventdata, handles)
        numSteps=0; ii=0; jj=0; kk=0;
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
            for ii = 1:size(IM,3);
                IM(:,:,ii)=imrotate(IM(:,:,ii), -rotateReset(1), 'bicubic', method);
                waitbar(ii/numSteps, resettingWaitbar);
            end
        end
        if rotateReset(2) ~= 0
            IM=permute(IM, [1 3 2]);
            for jj = 1:size(IM,3);
                IM(:,:,jj)=imrotate(IM(:,:,jj), -rotateReset(2), 'bicubic', method);
                waitbar((ii+jj)/numSteps, resettingWaitbar);
            end
            IM=ipermute(IM, [1 3 2]);
        end
        if rotateReset(3) ~= 0
            IM=permute(IM, [3 2 1]);
            for kk = 1:size(IM,3);
                IM(:,:,kk)=imrotate(IM(:,:,kk), -rotateReset(3), 'bicubic', method);
                waitbar((ii+jj+kk)/numSteps, resettingWaitbar);
            end
            IM=ipermute(IM, [3 2 1]);
        end
        close(resettingWaitbar);
        updatePanel1(getPosition(P1));
        updatePanel2(getPosition(P2));
        rotateReset = [0 0 0];
        set(rotateA1EditBox, 'String', '0');
        set(rotateA2EditBox, 'String', '0');
        set(rotateA3EditBox, 'String', '0');
    end

    function specifySlice1(eventdata, handles)
        newVal=str2num(get(slice1EditBox, 'String'));
        if isempty(newVal)
            set(slice1EditBox, 'String', num2str(sliceUndo(3)));
        else
            pos1=getPosition(P1);
            pos2=getPosition(P2);
            pos3=getPosition(P3);
            pos2(1) = newVal;
            pos3(1) = newVal;
            imagesc(IM(:,:,round(pos2(1))), ...
                'Parent', axis1, [minInt maxInt]);
            axis(axis1, 'off', 'image'),colormap gray;
            P1=impoint(axis1, pos1(1), pos1(2));
            P2=impoint(axis2, pos2(1), pos2(2));
            P3=impoint(axis3, pos3(1), pos3(2));
            D1=addNewPositionCallback(P1, @updatePanel1);
            sliceUndo(3)=newVal;
            updatePanel1(pos1);
        end
    end

    function specifySlice2(eventdata, handles)
        newVal=str2num(get(slice2EditBox, 'String'));
        if isempty(newVal)
            set(slice2EditBox, 'String', num2str(sliceUndo(2)));
        else
            pos1=getPosition(P1);
            pos2=getPosition(P2);
            pos3=getPosition(P3);
            pos1(1) = newVal;
            pos3(2) = newVal;
            imagesc(squeeze(IM(:,round(pos1(1)),:)), ...
                'Parent', axis2, [minInt maxInt]);
            axis(axis2, 'off', 'image'),colormap gray;
            P1=impoint(axis1, pos1(1), pos1(2));
            P2=impoint(axis2, pos2(1), pos2(2));
            P3=impoint(axis3, pos3(1), pos3(2));
            D2=addNewPositionCallback(P2, @updatePanel2);
            sliceUndo(2)=newVal;
            updatePanel2(pos2);
        end
    end

    function specifySlice3(eventdata, handles)
        newVal=str2num(get(slice3EditBox, 'String'));
        if isempty(newVal)
            set(slice3EditBox, 'String', num2str(sliceUndo(1)));
        else
            pos1=getPosition(P1);
            pos2=getPosition(P2);
            pos3=getPosition(P3);
            pos1(2) = newVal;
            pos2(2) = newVal;
            imagesc(squeeze(IM(round(pos1(2)),:,:)), ...
                'Parent', axis3, [minInt maxInt]);
            axis(axis3, 'off', 'image'),colormap gray;
            P1=impoint(axis1, pos1(1), pos1(2));
            P2=impoint(axis2, pos2(1), pos2(2));
            P3=impoint(axis3, pos3(1), pos3(2));
            D3=addNewPositionCallback(P3, @updatePanel3);
            sliceUndo(1)=newVal;
            updatePanel3(pos3);
        end
    end

    function reorient1(~, ~)
        switch viewList(1)
            case 0
                viewList(1) = 90;
            case 90
                viewList(1) = 180;
            case 180
                viewList(1) = 270;
            case 270
                viewList(1) = 0;
        end
        updatePanel1(getPosition(P1));
        updatePanel2(getPosition(P2));
        updatePanel3(getPosition(P3));
    end

    function reorient2(~, ~)
        switch viewList(2)
            case 0
                viewList(2) = 90;
            case 90
                viewList(2) = 180;
            case 180
                viewList(2) = 270;
            case 270
                viewList(2) = 0;
        end
        updatePanel1(getPosition(P1));
        updatePanel2(getPosition(P2));
        updatePanel3(getPosition(P3));
    end

    function reorient3(~, ~)
        switch viewList(3)
            case 0
                viewList(3) = 90;
            case 90
                viewList(3) = 180;
            case 180
                viewList(3) = 270;
            case 270
                viewList(3) = 0;
        end
        updatePanel1(getPosition(P1));
        updatePanel2(getPosition(P2));
        updatePanel3(getPosition(P3));
    end

    function exportPDF(~,~)

        pdfTitle = inputdlg('Enter PDF Title. <Enter> for none.');
        
        pdfFig = figure('PaperType', 'usletter', ...
                        'PaperUnits', 'inches', ...
                         'PaperSize', [8.5 11], ...
                         'Position', [0 100 800 1050], ...
                         'Visible', 'off');

        pdfAxis1 = subplot(2,2,1);
        pos1=getPosition(P1);
        pos2=getPosition(P2);
        pos3=getPosition(P3);
        
        imagesc(IM(:,:,round(pos2(1))), ...
            'Parent', pdfAxis1, [minInt maxInt]);
        axis(pdfAxis1, 'off', 'image'),colormap gray;
        set(pdfAxis1, 'View', [viewList(1), 90]);

        pdfAxis2 = subplot(2,2,2);
        imagesc(squeeze(IM(:,round(pos3(2)),:)), ...
            'Parent', pdfAxis2, [minInt maxInt]);
        axis(pdfAxis2, 'off', 'image'),colormap gray;
        set(pdfAxis2, 'View', [viewList(2), 90]);

        pdfAxis3 = subplot(2,2,3);
        imagesc(squeeze(IM(round(pos1(2)),:,:)), ...
            'Parent', pdfAxis3, [minInt maxInt]);
        axis(pdfAxis3, 'off', 'image'),colormap gray;
        set(pdfAxis3, 'View', [viewList(3), 90]);

        set(pdfAxis3, 'Position', [0.25 0.025 0.425 0.425])
        set(pdfAxis2, 'Position', [0.55 0.45 0.425 0.425])
        set(pdfAxis1, 'Position', [0.025 0.45 0.425 0.425])

        if ~cellfun(@isempty, pdfTitle)
            sgtitle(pdfTitle, 'FontSize', 18)
        end

        print(pdfFig, '-dpdf', 'v3 printout.pdf')
        close(pdfFig);
        clear('pdfFig');

    end

end