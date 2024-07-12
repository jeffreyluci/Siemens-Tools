function hdr = extractEnhancedDicomTags(fileName, verbose)
%   extractEnhancedDicomTags Parse an enhanced DICOM header into logical,
%   human-readable struct.
%
%   header = extractEnhancedDicomTags(filename) reads in an enhanced DICOM
%   header, and parses it for the most commonly-needed MR parameters. This
%   version assumes a Siemens file structure. Fields that do no exist are
%   skipped and not created in the returned struct.
%
%   header = extractEnhancedDicomTags(filename, verbose) enables the user
%   to request verbose feedback. The argument verbose should be a logical 
%   true or false. The default is false.
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
%   It is recommended to use the function parseMrProt, but it is not
%   necessary. See comments for source material. If parseMrProt is not
%   installed, mrProt will be returned as an unparsed character array. 

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
% 20240712: Fixed field naming inconsistencies: phaseEncSteps and coilName
%
%To do:


%process verbosity for user junk
%default is no verbosity
if ~exist('verbose', 'var')
    verbose = false;
end

%check for string input for verbosity and correct fotmatting
if ~islogical(verbose)
    if strcmpi(verbose,'y') || strcmpi(verbose, 'yes')
        verbose = true;
    elseif strcmpi(verbose,'n') || strcmpi(verbose, 'no')
        verbose = false;
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
dcmHdr = dicominfo(fileName);

%check to make sure the DICOM is an enhanced DICOM by checking for a
%field that should always exist in an enhanced DICOM
if ~isfield(dcmHdr, 'SharedFunctionalGroupsSequence')
    error([fileName, ' is not an Enhanced DICOM.']);
end

%Initialize hdr struct with tags that should always exist, then switch to
%try/catch function for everything else to ensure error-free parsing.
hdr.format.bitsAllocated    = dcmHdr.BitsAllocated;
hdr.format.bitsStored       = dcmHdr.BitsStored;
hdr.format.highBit          = dcmHdr.HighBit;
hdr.format.dynamicRange     = dcmHdr.BitDepth;
assignPar('LossyImageCompression', 'format.lossyCompression');
assignPar('ColorType',             'format.colorType');
assignPar('SpecificCharacterSet',  'format.characterSet');
assignPar('ImageType',             'format.ImageType');

%PATIENT SECTION
assignPar('PatientName',            'patient.name'       );
assignPar('PatientID',              'patient.id'         );
assignPar('PatientBirthDate',       'patient.dob'        );
assignPar('PatientSex',             'patient.sex '       );
assignPar('PatientAge',             'patient.age '       );
assignPar('PatientSize',            'patient.height'     );
assignPar('PatientWeight',          'patient.weight'     );
assignPar('PatientIdentityRemoved', 'patient.anonymized' );

%SCANNER SECTION
assignPar('Modality',              'scanner.modality'        );
assignPar('MagneticFieldStrength', 'scanner.fieldStrength'   );
assignPar('Manufacturer',          'scanner.manufacturer'    );
assignPar('ManufacturerModelName', 'scanner.model'           );
assignPar('DeviceSerialNumber',    'scanner.serialNumber'    );
assignPar('SoftwareVersions',      'scanner.softwareVersion' );
assignPar('InstitutionName',       'scanner.institution'     );

%SESSION SECTION
assignPar('StudyDate',                    'session.studyDate'         );
assignPar('SeriesDate',                   'session.seriesDate'        );
assignPar('StudyTime',                    'session.studyTime'         );
assignPar('SeriesTime',                   'session.seriesTime'        );
assignPar('ContentTime',                  'session.contentTime'       );
assignPar('StudyDescription',             'session.studyDescription'  );
assignPar('StudyDescription',             'session.seriesDescription' );
assignPar('ProtocolName',                 'session.protocolName'      );
assignPar('OperatorsName',                'session.operator'          );
assignPar('ReferringPhysicianName',       'session.referringPhysician');
assignPar('NameOfPhysiciansReadingStudy', 'session.readingPhysician'  );
assignPar('SeriesNumber',                 'session.seriesNumber'      );
assignPar('BodyPartExamined',             'session.bodyPart'          );

%SEQUENCE SECTION
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
assignPar('NumberOfFrames',                                                                                            'encoding.slices'            );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.MRAcquisitionFrequencyEncodingSteps',    'encoding.freqEncSteps'      );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.MRAcquisitionPhaseEncodingStepsInPlane', 'encoding.phaseEncSteps'      );
assignPar('OversamplingPhase',                                                                                         'encoding.phaseOversampling' );
assignPar('GeometryOfKSpaceTraversal',                                                                                 'encoding.kSpaceTrajectory'  );
assignPar('SegmentedKSpaceTraversal',                                                                                  'encoding.segmentedKSpace'   );
assignPar('RectilinearPhaseEncodeReordering',                                                                          'encoding.phaseReordering'   );
assignPar('NumberOfKSpaceTrajectories',                                                                                'encoding.numTrajectories'   );

%GEOMETRY SECTION
assignPar('PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.SliceThickness',                       'geometry.sliceThickness'     );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing',                         'geometry.pixelSpacing'       );
assignPar('SpacingBetweenSlices',                                                                                      'geometry.sliceSpacing'       );
assignPar('PatientPosition',                                                                                           'geometry.patientPosition'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.PercentSampling',                        'geometry.percentSampling'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.PercentPhaseFieldOfView',                'geometry.percentPhaseFOV'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRFOVGeometrySequence.Item_1.InPlanePhaseEncodingDirection',          'geometry.inPlanePhaseEncDir' );

%CONTRAST SECTION
assignPar('AcquisitionContrast',                                                                          'contrast.acqContrast'             );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.MagnetizationTransfer', 'contrast.magetizationTransfer'    );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.BloodSignalNulling',    'contrast.bloodSignalNulling'      );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.Tagging',               'contrast.tagging'                 );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.InversionRecovery',            'contrast.inversionRecovery'       );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.FlowCompensation',             'contrast.flowCompensation'        );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.Spoiling',                     'contrast.spoiling'                );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.T2Preparation',                'contrast.t2Preparation'           );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.SpectrallySelectedExcitation', 'contrast.spectralSelectiveExcite' );
assignPar('SharedFunctionalGroupsSequence.Item_1.MRModifierSequence.Item_1.SpatialPresaturation',         'contrast.spatialPresaturation'    );
assignPar('PhaseContrast',                                                                                'contrast.phaseContrast'           );
assignPar('TimeOfFlightContrast',                                                                         'contrast.TOFContrast'             );

%RECON SECTION
assignPar('Rows',                  'recon.rows'                );
assignPar('Columns',               'recon.columns'             );
assignPar('KSpaceFiltering',       'recon.kSPaceFilter'        );
assignPar('PixelPresentation',     'recon.pixelRepresentation' );
assignPar('ComplexImageComponent', 'recon.complexComponent'    );
assignPar('VolumetricProperties',  'recon.volumetricProperties');

%COILS SECTION
assignPar('SharedFunctionalGroupsSequence.Item_1.MRReceiveCoilSequence.Item_1.ReceiveCoilName',                                         'coils.rx.coilName'              );
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
    if exist('parseMrProt', 'file')
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

elseif verbose
    disp('The proprietary section likely does not exist. Skipping.')
end

%DIFFUSION SECTION
assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionGradientDirectionSequence.Item_1', 'diffusion.gradientOrientation' );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionBMatrixSequence.Item_1',           'diffusion.bMatrix'             );
assignPar('PerFrameFunctionalGroupsSequence.Item_1.MRDiffusionSequence.Item_1.DiffusionBValue',                           'diffusion.bValue'              );



    function assignPar(dcmFieldName, fieldName)
        %assign fields to new struct using user-preferred names
        
        try
            dcmFieldName = split(dcmFieldName, '.');
            fieldName = split(fieldName, '.');
            hdr = setfield(hdr, fieldName{:}, getfield(dcmHdr, dcmFieldName{:}));
        catch
            if verbose
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


