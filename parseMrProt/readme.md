# parseMrProt

 parseMrProt - Parses MrProt from a DICOM acquired on a Siemens VB, VD,
 VE, or XA line MRI scanners.

 Usage:  mrprot = parseMrProt(input)
        [mrprot, zeroList] = parseMrProt(input)
 The input argument can be either the file location of the DICOM, or the
 DICOM header as provided by the MATLAB function dicominfo. The resulting 
 structure includes all fields included in MrProt, nested and indexed.
 
 Note that field indexes may not correspond to those in the native MrProt 
 as some Siemens arrays are numbered starting at 0, and others at 1. As a
 result, all indexes are renumbered from 1 to comply with MATLAB
 requirements. Those that are renumbered will be off by one. The optional 
 return  zeroList includes a list of all the renumbered fields. These 
 fields are usually nested below a parent field name.
 
 Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
 https://github.com/jeffreyluci/Siemens-Tools/tree/main/parseMrProt
 VERSION HISTORY:
 20230201 - Initial Release
 20230220 - Added sxupport for enhanced DICOMs, including the highly
            questionable choice by Siemens to use numbers as structure
            field names in some (inconsistent) cases. This made it
            necessary to convert hex values to decimal as opposed to
            maintaining the ascii encoded hex value which was the 
            convention in the previous version.   
