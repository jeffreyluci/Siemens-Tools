function hdr = extractEnhancedDicomTags(fileName, options)
%   extractEnhancedDicomTags Parse an enhanced DICOM header into logical,
%   human-readable struct.
%
%   header = extractEnhancedDicomTags(filename) reads in an enhanced DICOM
%   header, and parses it for the most commonly-needed MR parameters. This
%   version assumes a Siemens file structure. Fields that do no exist are
%   skipped and not created in the returned struct.
%
%   Some application-specific tags and parameters are parsed when deemed
%   applicable using logical checks and contents of the ImageType tag. User
%   can force parsing of these supported tags and parameters with the
%   options arument.
%
%   header = extractEnhancedDicomTags(filename, options) enables the user
%   to request non-default behavior. Arguments should be logical true or 
%   false. The default for all options is false. Possible options include:
%   verbose=true, which turns on verbose feedback; forceDiffusion = true, always
%   process diffusion tags and parameters - even if data do not appear to be
%   diffusion-related; forceASL=true, always process ASL-related tags and
%   parameters; forceSpectro=true, always process spectroscopy-related tags
%   and parameters; forceMrProt=true will include mrProt in the output.
%
%   If mrProt exists, it will be included in the structre in the field named
%   "mrProt". If parseMrProt is installed (see below), the field mrProt
%   will be a parsed structure. If not, the entire contents of the proprietary
%   tag will be included as plain text, which will include more than mrProt.
% 
%   Note that mrProt may not be archived in all DICOMs based on the specific
%   software version, whether or not a PACS has touched the data, if is has
%   been de-identified in a certain way, or some other unusual use cases.
%   If mrProt does not exist, it will not be returned.
% 
%   If parseMrProt does not exist on the path, mrProt will be treated as an 
%   unparsed character array. It is recommended to use the function 
%   parseMrProt, but it is not necessary. See comments for source material. 
%   If mrProt is not forced to be returned in the options, mrProt will not 
%   be returned in the output at all.

% Written by J. Luci: jeffrey.luci@rutgers.edu
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/extractEnhancedDicomTags
% https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt
% Version History:
% 20200518: First release
% 20200522: Fixed typos that created redundant fields, added help text
% 20200528: Added verbosity option
% 20220119: Switched to try/catch format to account for different tags
%           existing or not depending on sequence/recon/etc options 
%           selected at scan time - created assignPar function
% 20220127: Fixed dynamic field naming problem and removed eval line in
%           assignPar function. Cleared ToDo list.
% 20230120: Added extraction of mrProt into structure using companion
%           function parseMrProt, if it exists. If not, mrProt is extracted
%           as plain text. the function parseMrProt is available at:
%           https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt
% 20230228: Improved reliability of extracting mrProt when marseMrProt is
%           not installed. Various minor speed improvements.
% 20230814: Fixed bug that did not account for missing CSA header in
%           Numaris X (e.g. XA11A and XA30A) DICOMs.
% 20230919: Fixed misnamed variable phaseEncStep -> phaseEncSteps
% 20241001: Added several parameter entries, including ASL and study
%           groups.
% 20250908: Added ASL data from LOFT C2P ASL sequences (PLDs, reps, and
%           bvalues, if they exist).
% 20260217: Numerous niche bug fixes. Fixed Study/SeriesDescrioption mixup.
%           Added Spectro sections. Chaged default behavior to only parse
%           application-specific sections when appropriate. Added options
%           to argument list. Moved verbose argument to options list. Added
%           forceDiffusion, forceASL, and forceSpectro to options which
%           will force application-specific parsing. Changed verification
%           of enhanced DICOM type by checking SOPClassUID, whcih should be
%           authoritative. Switched default behavior to not include mrProt
%           in the output unless forced with new option. Moved the private
%           tags in the proprietary header up one field for simplicity
%           (i.e. eliminated the field tag0021_10fe).


arguments
    fileName                     char
    options.verbose        (1,1) logical = false
    options.forceDiffusion (1,1) logical = false
    options.forceASL       (1,1) logical = false
    options.forceSpectro   (1,1) logical = false
    options.forceMrProt    (1,1) logical = false
end

%check for string input for verbosity and correct fotmatting
if ~islogical(options.verbose)
    if strcmpi(options.verbose,'y') || strcmpi(options.verbose, 'yes')
        options.verbose = true;
    elseif strcmpi(options.verbose,'n') || strcmpi(options.verbose, 'no')
        options.verbose = false;
    else
        error('Verbose argument should be a logical T/F');
    end
end

%check to make sure file exists
if ~exist(fileName, 'file')
    error([fileName, ' does not exist.']);
end

%check to make sure file is a DICOM
if ~isdicom(fileName)
    error([fileName, ' is not a DICOM.']);
end

%read in the DICOM header
dcmHdr = dicominfo(fileName, 'UseDictionaryVR', true);

%check to make sure the DICOM is an enhanced DICOM by checking for the
%correct COP Class UID
if ~strcmp(dcmHdr.SOPClassUID, '1.2.840.10008.5.1.4.1.1.4.1')
    error([fileName, ' is not an enhanced DICOM.']);
end


%Initialize hdr struct with tag that should always exist, then switch to
%try/catch function for everything else to ensure error-free parsing.
hdr.format.fileFormat = dcmHdr.Format;

%FORMAT SECTION
assignPar('FormatVersion',         'format.formatVersion'    );
assignPar('LossyImageCompression', 'format.lossyCompression' );
assignPar('ColorType',             'format.colorType'        );
assignPar('SpecificCharacterSet',  'format.characterSet'     );
assignPar('ImageType',             'format.ImageType'        );
assignPar('SoftwareVersions',      'format.softwareVersions' );
assignPar('BitsAllocated',         'format.bitsAllocated'    );
assignPar('BitsStored',            'format.bitStored'        );
assignPar('HighBit',               'format.highBit'          );
assignPar('BitDepth',              'format.dynamicRange'     );

%UID SECTION
assignPar('StudyInstanceUID',           'UID.studyInstanceUID'           );
assignPar('FrameOfReferenceUID',        'UID.frameOfReferenceUID'        );
assignPar('SeriesInstanceUID',          'UID.seriesInstanceUID'          );
assignPar('SeriesInstanceUID',          'UID.seriesInstanceUID'          );
assignPar('MediaStorageSOPClassUID',    'UID.mediaStorageSOPClassUID'    );
assignPar('MediaStorageSOPInstanceUID', 'UID.mediaStorageSOPInstanceUID' );
assignPar('TransferSyntaxUID',          'UID.transferSyntaxUID'          );
assignPar('ImplementationClassUID',     'UID.implementationClassUID'     );
assignPar('SOPClassUID',                'UID.SOPClassUID'                );
assignPar('SOPInstanceUID',             'UID.SOPInstanceUID'             );

%PATIENT SECTION
assignPar('PatientName',            'patient.name'       );
assignPar('PatientID',              'patient.id'         );
assignPar('PatientBirthDate',       'patient.dob'        );
assignPar('PatientSex',             'patient.sex '       );
assignPar('PatientAge',             'patient.age '       );
assignPar('PatientSize',            'patient.height'     );
assignPar('PatientWeight',          'patient.weight'     );
assignPar('PatientIdentityRemoved', 'patient.anonymized' );
assignPar('BodyPartExamined',       'patient.bodyPart'   );
assignPar('PatientComments',        'patient.comments'   );

%SCANNER SECTION
assignPar('Modality',              'scanner.modality'        );
assignPar('MagneticFieldStrength', 'scanner.fieldStrength'   );
assignPar('Manufacturer',          'scanner.manufacturer'    );
assignPar('ManufacturerModelName', 'scanner.model'           );
assignPar('DeviceSerialNumber',    'scanner.serialNumber'    );
assignPar('SoftwareVersions',      'scanner.softwareVersion' );
assignPar('InstitutionName',       'scanner.institution'     );

%STUDY SECTION
assignPar('StudyID',          'study.studyID'          );
assignPar('StudyDate',        'study.studyDate'        );
assignPar('StudyTime',        'study.studyTime'        );
assignPar('StudyDescription', 'study.studyDescription' );

%SERIES SECTION
assignPar('SeriesDate',                  'series.seriesDate'         );
assignPar('SeriesTime',                  'series.seriesTime'         );
assignPar('ContentTime',                 'series.contentTime'        );
assignPar('SeriesDescription',           'series.seriesDescription'  );
assignPar('ProtocolName',                'series.protocolName'       );
assignPar('OperatorsName',               'series.operator'           );
assignPar('ReferringPhysicianName',      'series.referringPhysician' );
assignPar('NameOfPhysicianReadingStudy', 'series.readingPhysician'   );
assignPar('SeriesNumber',                'series.seriesNumber'       );
assignPar('BodyPartExamined',            'series.bodyPart'           );
assignPar('AcquisitionNumber',           'series.acquisitionNumber'  );
assignPar('InstanceNumber',              'series.instanceNumber'     );
assignPar('ImageComments',               'series.imageComments'      );

%SEQUENCE SECTION
assignPar('PulseSequenceName',              'sequence.pulseSequenceName'        );
assignPar('ContentQualification',           'sequence.qualification'            );
assignPar('EchoPulseSequence',              'sequence.family'                   );
assignPar('MultiPlanarExcitation',          'sequence.multiPlanarExtitation'    );
assignPar('SteadyStatePulseSequence',       'sequence.steadyState'              );
assignPar('EchoPlanarPulseSequence',        'sequence.echoPlanar'               );
assignPar('SaturationRecovery',             'sequence.saturationRecovery'       );
assignPar('SpectrallySelectedSuppression',  'sequence.freqSelectiveSuppression' );
assignPar('B1rms',                          'sequence.B1rms'                    );
assignPar('ApplicableSafetyStandardAgency', 'sequence.safetyStandard'           );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.OperatingModeSequence.Item_1', 'sequence.gradientMode'           );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.GradientOutputType',           'sequence.gradientOutputLimiting' );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.GradientOutput',               'sequence.gradientOutput'         );

%ACQ SECTION 
assignPar('MRAcquisitionType',                                                                                 'acq.acqType'                 );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.RepetitionTime',  'acq.TR'                      );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.MREchoSequence.Item_1.EffectiveEchoTime',                   'acq.TE'                      );
assignPar('MRAcquisitionType',                                                                                 'acq.dimensionality'          );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRAveragesSequence.Item_1.NumberOfAverages',                'acq.averages'                );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.PixelBandwidth',             'acq.pixelBandwidth'          );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.TransmitterFrequency',       'acq.transmitterFrequency'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.FlipAngle',       'acq.flipAngle'               );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.EchoTrainLength', 'acq.echoTrainLength'         );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.PartialFourier',                    'acq.partialFourier'          );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.PartialFourierDirection',           'acq.partialFourierDirection' );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.ParallelReductionFactorInPlane',    'acq.iPatInPlaneFactor'       );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.ParallelReductionFactorOutOfPlane', 'acq.iPatOutOfPlaneFactor'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.ParallelAcquisition',               'acq.parallelAcq '            );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.ParallelAcquisitionTechnique',      'acq.parallelAcqTechnique'    );
assignPar('AcquisitionDuration',                                                                               'acq.duration'                );

%ENCODING SECTION
assignPar('NumberOfFrames',                                                                                            'encoding.slices'               );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.MRAcquisitionFrequencyEncodingSteps',    'encoding.freqEncSteps'         );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.MRAcquisitionPhaseEncodingStepsInPlane', 'encoding.phaseEncSteps'        );
assignPar('OversamplingPhase',                                                                                         'encoding.phaseOversampling'    );
assignPar('GeometryOfKSpaceTraversal',                                                                                 'encoding.kSpaceTrajectory'     );
assignPar('SegmentedKSpaceTraversal',                                                                                  'encoding.segmentedKSpace'      );
assignPar('RectilinearPhaseEncodeReordering',                                                                          'encoding.phaseReordering'      );
assignPar('NumberOfKSpaceTrajectories',                                                                                'encoding.numTrajectories'      );
assignPar('NumberOfTemporalPositions',                                                                                 'encoding.numTemporalPositions' );
assignPar('ResonantNucleus',                                                                                           'encoding.observeNucleus'       );

%GEOMETRY SECTION
assignPar('PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.SliceThickness',              'geometry.sliceThickness'     );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing',                'geometry.pixelSpacing'       );
assignPar('SpacingBetweenSlices',                                                                             'geometry.sliceSpacing'       );
assignPar('PatientPosition',                                                                                  'geometry.patientPosition'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.PercentSampling',               'geometry.percentSampling'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.PercentPhaseFieldOfView',       'geometry.percentPhaseFOV'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.InPlanePhaseEncodingDirection', 'geometry.inPlanePhaseEncDir' );

%CONTRAST SECTION
assignPar('AcquisitionContrast',                                                                          'contrast.acqContrast'                   );
assignPar('SpectrallySelectedSuppression',                                                                'contrast.spectrallySelectedSuppression' );
assignPar('SaturationRecovery',                                                                           'contrast.saturationRecovery'            );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.MagnetizationTransfer', 'contrast.magetizationTransfer'          );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.BloodSignalNulling',    'contrast.bloodSignalNulling'            );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.Tagging',               'contrast.tagging'                       );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.InversionRecovery',            'contrast.inversionRecovery'             );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.FlowCompensation',             'contrast.flowCompensation'              );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.Spoiling',                     'contrast.spoiling'                      );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.T2Preparation',                'contrast.t2Preparation'                 );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.SpectrallySelectedExcitation', 'contrast.spectralSelectiveExcite'       );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.SpatialPresaturation',         'contrast.spatialPresaturation'          );
assignPar('PhaseContrast',                                                                                'contrast.phaseContrast'                 );
assignPar('TimeOfFlightContrast',                                                                         'contrast.TOFContrast'                   );
assignPar('ArterialSpinLabelingContrast',                                                                 'contrast.ASLContrast'                   );

%RECON SECTION
assignPar('Rows',                  'recon.rows'                );
assignPar('Columns',               'recon.columns'             );
assignPar('KSpaceFiltering',       'recon.kSPaceFilter'        );
assignPar('PixelPresentation',     'recon.pixelRepresentation' );
assignPar('ComplexImageComponent', 'recon.complexComponent'    );
assignPar('VolumetricProperties',  'recon.volumetricProperties');
assignPar('BurnedInAnnotation',    'recon.burnedInAnnotation'  );

%COILS SECTION
assignPar('SharedFunctionalGroupsSequence.Item_1.MRReceiveCoilSequence.Item_1.ReceiveCoilName',                                         'coils.rx.CoilName'              );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRReceiveCoilSequence.Item_1.ReceiveCoilType',                                         'coils.rx.coilType'              );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRReceiveCoilSequence.Item_1.QuadratureReceiveCoil',                                   'coils.rx.quadRxCoil'            );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRReceiveCoilSequence.Item_1.MultiCoilDefinitionSequence.Item_1.MultiCoilElementUsed', 'coils.rx.multiCoilElementsUsed' );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTransmitCoilSequence.Item_1.TransmitCoilName',                                       'coils.tx.coilName'              );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRTransmitCoilSequence.Item_1.TransmitCoilType',                                       'coils.tx.coilType'              );

%PROPRIETARY SECTION
% May not be available based on software version, whether or not it was
% touched by a PACS, and specific exporting use cases. If it doesn't exist,
% skip it.
mrProt = readFullFile(fileName);
if isfield(dcmHdr.SharedFunctionalGroupsSequence.Item_1, 'Private_0021_10fe')
    assignPar('SharedFunctionalGroupsSequence.Item_1.Private_0021_10fe.Item_1', 'proprietary.tag0021_10fe');
    hdr.proprietary = hdr.proprietary.tag0021_10fe;
    if exist('parseMrProt', 'file') == 2
        try
            hdr.mrProt = parseMrProt(mrProt);
        catch
            disp('The proprietary section likely does not exist. Skipping.');
        end
    else   
        if ~isempty(mrProt)
            hdr.mrProt.textDump = mrProt;
        end
    end

elseif ~isempty(mrProt)
    hdr.mrProt.textDump = mrProt;

elseif options.verbose
    disp('The proprietary section likely does not exist. Skipping.')
end

%DIFFUSION SECTION
if contains(dcmHdr.ImageType, 'DIFFUSION') || options.forceDiffusion
    assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionGradientDirectionSequence.Item_1', 'diffusion.gradientOrientation' );
    assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionBMatrixSequence.Item_1',           'diffusion.bMatrix'             );
    assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionBValue',                           'diffusion.bValue'              );
end

%ASL SECTION
if (isfield(hdr.mrProt, 'sAsl') && contains(dcmHdr.ImageType, 'ASL')) || options.forceASL
    assignMrProtPar('mrProt.sAsl.ulMode',             'asl.mode'            );
    assignMrProtPar('mrProt.sAsl,ulSuppressionMode',  'asl.suppressionMode' );
    assignMrProtPar('mrProt.sAsl.ulArrayLength',      'asl.arrayLength'     );
    assignMrProtPar('mrProt.sAsl.ulLabelingDuration', 'asl.labelingDuration');
    assignMrProtPar('mrProt.sAsl.ulDelayArraySize',   'asl.delayArraySize'  );
    assignMrProtPar('mrProt.sAsl.sPostLabelingDelay', 'asl.PLD'             );

    %Check if the sequence is a C2P from LOFT. This check is **NOT**
    %exclusive, and not guaranteed to be accurate.
    if strcmp(hdr.sequence.qualification, 'RESEARCH') && (isfield(hdr.mrProt, 'sWipMemBlock')) ...
            && (hdr.mrProt.sAsl.ulMode ~= 1) && contains(hdr.sequence.pulseSequenceName, 'tgse3d1')
        try
            hdr.asl.LOFT.PLD  = hdr.mrProt.sWipMemBlock.alFree(1:5);
            hdr.asl.LOFT.reps = hdr.mrProt.sWipMemBlock.alFree(7:11);
            hdr.asl.LOFT.bval = hdr.mrProt.sWipMemBlock.alFree(13:17);
        catch
            disp('C2P ASL section not recognized. Skipping.');
        end
    end
end

%SPECTRO SECTION
if (isfield(hdr.mrProt, 'sSpecPara') && contains(dcmHdr.ImageType, 'SPECTROSCOPY')) || options.forceSpectro
    assignMrProtPar('mrProt.sSpecPara.lPhaseCyclingType',      'spectro.phaseCyclingType'      );
    assignMrProtPar('mrProt.sSpecPara.lPhaseEncodingType',     'spectro.phaseEncodingType'     );
    assignMrProtPar('mrProt.sSpecPara.lRFExcitationBandwidth', 'spectro.RFExcitationBandwidth' );
    assignMrProtPar('mrProt.sSpecPara.ucRemoveOversampling',   'spectro.removeOversampling'    );
    assignMrProtPar('mrProt.sSpecPara.lAutoRefScanMode',       'spectro.autoRefScanMode'       );
    assignMrProtPar('mrProt.sSpecPara.lAutoRefScanNo',         'spectro.autoRefScanNo'         );
    assignMrProtPar('mrProt.sSpecPara.lDecouplingType',        'spectro.decouplingType'        );
    assignMrProtPar('mrProt.sSpecPara.lNOEType',               'spectro.NOEType'               );
    assignMrProtPar('mrProt.sSpecPara.lExcitationType',        'spectro.excitationType'        );
    assignMrProtPar('mrProt.sSpecPara.lSpecAppl',              'spectro.specAppl'              );
    assignMrProtPar('mrProt.sSpecPara.lSpectralSuppression',   'spectro.spectralSuppression'   );
end

%MRPROT SECTION
if isfield(hdr, 'mrProt') && ~options.forceMrProt
    %remove mrProt if not specifically requested
    hdr = rmfield(hdr, 'mrProt');
elseif isfield(hdr, 'mrProt')
    %include mrProt, but ensure it is last in the structure name list
    allFieldNames = fieldnames(hdr);
    otherFieldNames = allFieldNames(~strcmp(allFieldNames, 'mrProt'));
    newFieldOrder = [otherFieldNames; {'mrProt'}];
    hdr = orderfields(hdr, newFieldOrder);
end






    function assignPar(dcmFieldName, fieldName)
        %assign fields to new struct using user-preferred names
        
        try
            dcmFieldName = split(dcmFieldName, '.');
            fieldName = split(fieldName, '.');
            hdr = setfield(hdr, fieldName{:}, getfield(dcmHdr, dcmFieldName{:}));
        catch
            if options.verbose
                disp(['The parameter ', horzcat(fieldName{:}), ' likely does not exist in the DICOM. Skipping.']);
            end
        end

    end

    function assignMrProtPar(mrProtFieldName, fieldName)
        %assign field to new struct from the MrProt struct using
        %preferred names

        try
            mrProtFieldName = split(mrProtFieldName, '.');
            fieldName = split(fieldName, '.');
            hdr = setfield(hdr, fieldName{:}, getfield(hdr, mrProtFieldName{:}));
        catch
            if options.verbose
                disp(['The parameter ', horzcat(fieldName{:}), ' likely does not exist in the DICOM. Skipping.']);
            end
        end

    end

    function mrProt = readFullFile(fileName)
        fid = fopen(fileName, 'rt');
        fileDump = fread(fid, inf, 'uint8=>char')';
        fclose(fid);
        startString = strfind(fileDump, 'ASCCONV BEGIN');
        endString   = strfind(fileDump, 'ASCCONV END');
        mrProt  = fileDump(startString:endString+10);
        clear('fileDump');
    end

end
