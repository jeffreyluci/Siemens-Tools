# v3

   v3 is a simple 3-plane 3D image viewing tool for MATLAB.

   Usage:
   v3
   v3(IM)
   
   IM: a 3D matrix of raw image data without a header
   
   When called without arguments, v will prompt the user to select
   an image file. Both DICOMs and NIfTIs are supported. Both standard
   and enhanced DICOMs are supported. 
   
Author: Jeffrey Luci, jeffrey.luci@rutgers.edu
 
# Version History:

v1 (October, 2011): First release.

Multiple udocumented releases were distributed.

20260813: This is a complete overhaul of the code to make use of 
MATLAB's newer uifigure and uicontrol features. This is a faster
and more robust version with numerous bug fixes and added features.
