function maskPhasemap(magImageFile, phaseImageFile, thresholdScale)
%maskPhasemap - A function that reads in NIfTI files of a magnitude and 
%               phase difference map from Siemens MRI scanners and masks
%               the phase image using a threshold value. The output is a
%               NIfTI file of the phase difference image that is compressed
%               or not, depending on the status of the input NIfTI file.
%               The output file will be named the same as the phase NIfTI
%               file, with "_masked" appended.
%
%Usage: maskPhasemap(magnitudeNifti, phaseNifti, <threshold>)
%
%       magnitudeNifti = location of the NIfTI with the magnitude images
%       phaseNifti = location of the NIfTI with the phase difference images
%       threshold = fraction of the maximum magnitude pixel value to use
%                   for the mask threshold. Optional. Default = 0.1

%Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
%Version: 20230613 - initial release
%Version: 20230614 - code consistency improvements, switched from 3D ROI to
%                    2D filling for better results, NIfTI header description
%                    notation for provenance, default thresh 0.09->0.1,
%                    and help text additions.

version = '20230614';

%Check to make sure the NIfTI files are readable
if ~exist(magImageFile, 'file')
    error('The magnitude volume is not found.');
end
if ~exist(phaseImageFile, 'file')
    error('The phase volume is not found.');
end

%Check to see if the phase file is compressed, set flag appropriately 
[outputFilePath, outputFileBase, outputFileExtension] = fileparts(phaseImageFile);
if strcmp(outputFileExtension, '.gz')
    [~, outputFileBase, ~] = fileparts(outputFileBase);
    compressedFlag = true;
else
    compressedFlag = false;
end

%Append the output file name to designate the change
outputFileBase = strcat(outputFileBase, '_masked');

%Set the threshold value if the user did not specify as a function argument
if ~exist('thresholdScale', 'var')
    thresholdScale = 0.1;
end

%read in the images and the phase difference header
magImage    = niftiread(magImageFile);
phaseImage  = niftiread(phaseImageFile);
phaseHeader = niftiinfo(phaseImageFile);

%Note the processing step in the NIfTI header description
if isfield(phaseHeader, 'Description')
    phaseHeader.Description = strcat(phaseHeader.Description, ...
                              ';Masked using maskPhasemap.m version: ', ...
                              version);
else
    phaseHeader.Description = strcat('Masked using maskPhasemap.m version: ', ...
                              version);
end

%Apply the threshold to the phase difference images
threshold = thresholdScale*max(magImage, [], 'all');
mask = magImage > threshold;
for ii = 1:size(mask, 3)
    mask(:,:,ii) = imfill(mask(:,:,ii), 'holes');
end
phaseImage(~mask) = 0;

%write the new NIfTI recycling the phase difference header on the new file
niftiwrite(phaseImage, fullfile(outputFilePath, outputFileBase), ...
           phaseHeader, "Compressed", compressedFlag);

end