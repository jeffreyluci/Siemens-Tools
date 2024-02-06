# splitSiemensScans

**splitSiemensScans - Split unstructured Siemens DICOM directory into directories
                      named based on series.

# Usage
`splitSiemensScans(D)`

**D:** (Optional) Path to a directory of DICOMs to be organized. If D is unspecified, 
       a user interface is provided for the user to browse to such a directory.

# Discussion

This function will take a directory of DICOMs, and move them into directories named
for their respective series names and appended with the series number. This mimics
the behavior of the filesystem export feature on Siemens VB/VD/Ve-line MR scanners. 

Any non-DICOM files contained in the parent directory will be left untouched.

WARNING: Very little error checking is performed in this version.  Any
unusual directory formats or mixed-mode files might be treated
improperly.  In such a case, the data should be intact, but the file's
location might be in any subdirectory created.

# Version History

20150710: Initial Release
