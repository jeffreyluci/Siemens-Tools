# correctDatNames

**correctDatNames** - A fucntion that will change the filenames of dat files created 
using the WashU C2P NORDIC recon functor to be consistent with their corresponding 
DICOMs that were corrected with Siemens software and assigned a new UID that does 
not match that of the dat filenames.

# Usage:
`correctDatNames`

`correctDatNames(datDir, dicomDir)`

`correctDatNames(datDir, dicomDir, debug=true)`

**datDir:** path to the directory containing dat files needing corrections

**dicomDir:** path to the directory containing Siemens-corrected DICOM files

**options:** 

`debug = true/(false)` - logical (boolean) that, when set to true,  
         prevents any renaming of files, and instead forces text output  
         that reports the source and target names that would have been  
         used if set to false

# Discussion:

 This function is intended to fix a problem that arises when it becomes
 necessary to use either the WashU-sourced Pythod NIfTI construction
 pipeline or this author's dat2niix.m MATLAB function. Both of those
 pipelines use the series instance UID archived in the DICOM file to build 
 the names of their corresponding dat files. Unfortunately, when it becomes
 necessary to correct metadata for a series, that series is assigned a new 
 UID that does not correspond to the dat files names, leaving no way to
 connect the two.

 This function will rename a directory of dat files to correcpond to the
 new UID assigned to the corrected DICOMs so that both pipelines listed
 above will be able to process the data.

 When called without arguments, a GUI dialog box will be displayed that
 asks the user to select the directory containing the DICOMs. This method
 assumes that the dat files are in a directory one step above the one
 selected, and named, "dat". For instnace, if the directory
 /data/scan1/dicom is selected with the dialog box, the function assumes
 that the dat files are located in /data/scan1/dat. If they are not, an
 error message will result.

 When called specifying both datDir and dicomDir, the function will use
 those source directories, regardless of their hierarchical structures.

 If the user desires to check the planned file renaming without actually
 performing them, setting the debug option to true will list on the screen
 all the file renaming operations that would have been performed had the
 debug option been set to false, or not been set at all (false is the
 default)

# Acknowledgements:

The NORDIC reconstruction functor (pipeline) is available at 
 <a href="matlab:web('https://webclient.us.api.teamplay.siemens-healthineers.com/c2p')">The Siemens Teamplay C2P Exchange.</a>


# Version History:
20250117: Initial Release.
