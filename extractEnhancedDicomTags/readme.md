# extractEnhancedDicomTags

   extractEnhancedDicomTags Parse an enhanced DICOM header into logical,
   human-readable struct.

   header = extractEnhancedDicomTags(filename) reads in an enhanced DICOM
   header, and parses it for the most commonly-needed MR parameters. This
   version assumes a Siemens file structure. Fields that do not exist are
   skipped and not created in the returned structure.
   
   Some application-specific tags and parameters are parsed when deemed
   applicable using logical checks and contents of the ImageType tag. User
   can force parsing of these supported tags and parameters with the
   options arument.

   header = extractEnhancedDicomTags(filename, options) enables the user
   to request non-default behavior. Arguments should be logical true or 
   false. The default for all options is false. Possible options include:
   verbose=true, which turns on verbose feedback; forceDiffusion = true, always
   process diffusion tags and parameters - even if data do not appear to be
   diffusion-related; forceASL=true, always process ASL-related tags and
   parameters; forceSpectro=true, always process spectroscopy-related tags
   and parameters; forceMrProt=true will include mrProt in the output.
   
   If mrProt exists, it will be included in the structre in the field named
   "mrProt". If parseMrProt is installed (see below), the field mrProt
   will be a parsed structure. If not, the entire contents of the proprietary
   tag will be included as plain text, which will include more than mrProt.
 
   Note that mrProt may not be archived in all DICOMs based on the specific
   software version, whether or not a PACS has touched the data, if is has
   been de-identified in a certain way, or some other unusual use cases.
   If mrProt does not exist, it will not be returned.
 
   If parseMrProt does not exist on the path, mrProt will be treated as an 
   unparsed character array. It is recommended to use the function 
   parseMrProt, but it is not necessary. See comments for source material. 
   If mrProt is not forced to be returned in the options, mrProt will not 
   be returned in the output at all.

   It is recommended to use the function [parseMrProt](https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt), but it is not
   necessary. 
   
   [Test data](https://github.com/jeffreyluci/Siemens-Tools/tree/main/Test%20Data) are avilable to confirm proper function.
   
Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
 
# Version History:

20200518: First release.

20200522: Fixed typos that created redundant fields, added help text.

20200528: Added verbosity option.

20220119: Switched to try/catch format to account for different tags
          existing or not depending on sequence/recon/etc options 
          selected at scan time - created assignPar function
          
20220127: Fixed dynamic field naming problem and removed eval line in
          assignPar function. Cleared ToDo list.
          
20220120: Added extraction of mrProt into structure using companion
          function parseMrProt, if it exists. If not, mrProt is extracted
          as plain text. 

20230228: Improved reliability of extracting mrProt when marseMrProt is
          not installed. Various minor speed improvements.

20230814: Fixed bug that did not account for missing CSA header in
          Numaris X (e.g. XA11A and XA30A) DICOMs.
		  
20240712: Fixed parameter naming inconsistencies: coilName and phaseEncSteps.

20241001: Added several parameter entries, including ASL and study groups.

20250908: Added metadata for LOFT ASL sequences (PLDs, reps and b-values, it they exist)

20260217: Numerous niche bug fixes. Fixed Study/SeriesDescrioption mixup.
          Added Spectro sections. Changed default behavior to only parse
          application-specific sections when appropriate. Added options
          to argument list. Moved verbose argument to options list. Added
          forceDiffusion, forceASL, and forceSpectro to options which
          will force application-specific parsing. Changed verification
          of enhanced DICOM type by checking SOPClassUID, which should be
          authoritative. Switched default behavior to not include mrProt
          in the output unless forced with new option. Moved the private
          tags in the proprietary header up one field for simplicity
          (i.e. eliminated the field tag0021_10fe).
