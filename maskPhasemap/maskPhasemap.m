function maskPhasemap(magImageFile, phaseImageFile, thresholdScale)
%maskPhasemap - A function that reads in NIfTI files of a magnitude and 
%               phase difference map from Siemens MRI scanners and masks
%               the phase image using a threshold value. The output is a
%               NIfTI file of the phase difference image that is compressed
%               or not, depending on the status of the input NIfTI file.
%
%Usage: maskPhasemap(magnitudeNifti, phaseNifti, <threshold>)
%
%       magnitudeNifti = location of the NIfTI with the magnitude images
%       phaseNifti = location of the NIfTI with the phase difference images
%       threshold = fraction of the maximum magnitudepixel value to use for
%                   the mask threshold. Optional. Default = 0.09

%Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
%Version: 20230613 - initial release

%Check to make sure the NIfTI files are readable
if ~exist(magImageFile, 'file')
    error('The magnitude volume is not found.');
end
if ~exist(phaseImageFile, 'file')
    error('The phase volume is not found.');
end

%Check to see if the files are compressed 
[outputFilePath, outputFileBase, outputFileExtension] = fileparts(phaseImageFile);
if strcmp(outputFileExtension, '.gz')
    outputFileBase = strcat(outputFileBase(1:length(outputFileBase)-4), '_masked');
    compressedFlag = true;
else
    outputFileBase = strcat(outputFileBase, '_masked');
    compressedFlag = false;
end

%Set the threshold value if the user did not specify as a function argument
if ~exist('thresholdScale', 'var')
    thresholdScale = 0.09;
end

%read in the images and the phase difference header
magImage    = niftiread(magImageFile);
phaseImage  = niftiread(phaseImageFile);
phaseHeader = niftiinfo(phaseImageFile);

%Apply the threashold to the phase difference images
threshold = thresholdScale*max(magImage, [], 'all');
mask = magImage > threshold;
mask = imfill(mask, 'holes');
phaseImage(~mask) = 0;

%write the new NIfTI recycling the phase difference header on the new file
niftiwrite(phaseImage, strcat(outputFilePath, filesep, outputFileBase), ...
           phaseHeader, "Compressed", compressedFlag);



end