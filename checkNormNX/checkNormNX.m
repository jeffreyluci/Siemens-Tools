function [normalizeOn, normType] = checkNormNX(pathToDICOM)
%checkPNNX - Check if image is normalized for NX VA1x DICOMs
%
%Usage: [nonoff, normalizationType] = checkNNX(filename)
%filename = full path to filename of DICOM to check
%normalizeOn  = logical true/false if normalization is used
%normalizationType = (optional) returns the type of normalization used,
%                     empty if normalizeOn is false
%
%Version 0.1, released 26 April 2019, Jeffrey Luci.


getVerStr = @(txt) fliplr(strtok(fliplr(txt), ' '));

if ~exist(pathToDICOM, 'file')
    error([pathToDICOM ' does not exist.' newline]);
end

hdr = dicominfo(pathToDICOM);
if strcmp(getVerStr(hdr.SoftwareVersion), 'XA10') || strcmp(getVerStr(hdr.SoftwareVersion), 'XA11')
    normStr = hdr.PerFrameFunctionalGroupsSequence.Item_1.Private_0021_11fe.Item_1.Private_0021_1176;
    if contains(normStr, 'NormalizeAlgo')
        normalizeOn = true;
        splitNormStr = strsplit(normStr, '\');
        normDescription = splitNormStr{find(contains(splitNormStr, 'NormalizeAlgo:'))};
        [~,normType] = strtok(normDescription, ':');
        normType = normType(2:end);
    else
        normalizeOn = false;
        normType=[];
    end
else
    disp('This DICOM was created with an unsuported software version');
end

end