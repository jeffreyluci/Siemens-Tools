# img4participant

This is a MATLAB function that will read a multi-frame DICOM
and produce an animated GIF of all the frames as well as a 
collection of PNG files of every other frame. Its intended 
use is to provide to research participants anonymous images 
of their brains that includes an embedded disclaimer regarding
non-use for medical/diagnostic purposes.

Usage:
img4participant

The function will open a file browsing box asking the user to
select a DICOM file. If the selected DICOM file is formatted
appropriately, two directories will be created in directory housing
the selected DICOM, named: PNG and GIF. The PNG directory will
contain serial images of every other frame. The GIF directory
will contain an animated GIF of all the frames in the DICOM (as
long as the DICOM contains more than one frame).

The disclaimer and warning header fields of the PNG files and
the comment field of the GIF header will all contain notes
admonishing against the use of the images for medical purposes.
The PNG header will also hold the name of the scanner location
as provided in the DICOM header.

While single-frame DICOMs (pre-XA platform on Siemens scanners)
can be used, only the PNG image will be saved.

While most MATALB functions on this repository are usually provided
as MATLAB M-files (source code), this one is only provided as an
encrypted P-file. This is meant to prevent editing/removing of the
warnings and disclaimers embedded in the image files produced. The
P-file can used the same as an M-file - simply place the P-file
somewhere on the MATALAB path, and call it on the command line.

Author: Jeffrey Luci, jeffrey.luci@rutgers.edu

##Version History:
20250707: Initial Release