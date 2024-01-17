# parseDicomDir

parseDicomDir - Parses a standard DICOM archive data directory structure
                and reorganizes it into human-readable directories using
                the same naming convention used in Siemens D and E-line
                scanners for filesystem exports.

Usage: parseDicomDir(pathToDicomDirectory)
       parseDicomDir(pathToDicomDirectory, KeepOriginal=false)
       parseDicomDir(pathToDicomDirectory, Verbose=true)
       parseDicomDir(pathToDicomDirectory, DICOMDIRcheck=false)

This function will use the DICOM index file (named "DICOMDIR") in the root
of a DICOM archive directory structure to reoragnize the image-containing
DICOMs into a human-readable directory structure. The naming convention of
used for the new structure is the same as the one used on Siemens D and
E-line MRI scanners when exporting DICOMs to a filesystem. This presumes
that the DICOMs are Siemens enhanced DICOMs generated on XA-line scanners
and later. Non-enhanced DICOMs are not supported. The function
extractEnhancedDicomTags is required, and can be obtained from the links
below. The reorganized directory is named "converted".

Options:
KeepOriginal=false will move the DICOMs from the old structure to the new.
                   The originals will not be retained. This saves disk
                   space but give up some data integrity. Do not use on
                   the only copy of data. The default is true, which only
                   copies the files with new names to the new directory.

Verbose=true will echo to the screen the progress of the process as it
             works through each DICOM item listed in DICOMDIR. It is
             generally not necessary unless troubleshooting is required.
             The default is false.

DICOMDIRcheck=false is necessary if the path to the archive structure
                    includes the string "DICOMDIR" in any mixed case. The
                    default is true and will stop the function if the path
                    includes that string.

The required function extractEnhancedDicomTags is available from this URL:
https://github.com/jeffreyluci/Siemens-Tools/tree/main/extractEnhancedDicomTags

Author: Jeffrey Luci, jeffrey.luci@rutgers.edu

## Version History:
20230823:  Initial Release.

20240117:  Added management of pesky DICOM VR Dictionay warnings. Changed 
error stops to simple text on screen so that use in a a loop does not halt 
the entire job. Fixed bug that did not correctly use the full path to a DICOM
directory structure. Incorporated OS agnostic handling of file separators in 
this fix.
