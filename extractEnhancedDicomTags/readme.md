# extractEnhancedDicomTags

   extractEnhancedDicomTags Parse an enhanced DICOM header into logical,
   human-readable struct.

   header = extractEnhancedDicomTags(filename) reads in an enhanced DICOM
   header, and parses it for the most commonly-needed MR parameters. This
   version assumes a Siemens file structure. Fields that do no exist are
   skipped and not created in the returned struct.

   header = extractEnhancedDicomTags(filename, verbose) enables the user
   to request verbose feedback. The argument verbose should be a logical 
   true or false. The default is false.

   It is recommended to use the function [parseMrProt](https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt), but it is not
   necessary. 
   
Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
 
Version History:

20200518: First release

20200522: Fixed typos that created redundant fields, added help text

20200528: Added verbosity option

20220119: Switched to try/catch format to account for different tags
existing or not depending on sequence/recon/etc options 
selected at scan time - created assignPar function

20220127: Fixed dynamic field naming problem and removed eval line in
           assignPar function. Cleared ToDo list.

20220120: Added extraction of mrProt into structure using companion
           function parseMrProt, if it exists. If not, mrProt is extracted
           as plain text. 
