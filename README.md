`i.fusion.hpf` is a GRASS-GIS module to combine high-resolution 
panchromatic data with lower resolution multispectral data, resulting in an 
output with both excellent detail and a realistic representation of original 
multispectral scene colors.

The process involves a convolution using a High Pass Filter (HPF) on the high 
resolution data, then combining this with the lower resolution multispectral 
data.

Optionally, a linear histogram matching technique is performed in a way that 
matches the resulting Pan-Sharpened imaged to them statistical mean and standard 
deviation of the original multi-spectral image.

Source: Gangkofner, 2008

Algorithm description
=====================

1.  Computing ratio of low (Multi-Spectral) to high (Panchromatic) resolutions

2.  High Pass Filtering the Panchromatic Image

3.  Resampling MSX image to the higher resolution

4.  Adding weighted High-Pass-Filetred image to the upsampled MSX image

5.  Optionally, matching histogram of Pansharpened image to the one of the 
original MSX image

Implementation
==============

-   started on 29. October 2013 | working state reached on 07. November 2013

-   bash script for GRASS-GIS ver. 6.4

-   easy converting for GRASS-GIS ver. 7

-   should be easy to convert into Python

-   needless to say, badly implemented by a non-programer!

Remarks
-------

-   currently requires manual color rebalancing (e.g. by using i.landsat.rgb)
-   easy to use, i.e.:
 * for one band `i.fusion.hpf pan=Panchromatic msx=${Band}`
 * for multiple bands `i.fusion.hpf pan=Panchromatic msx=Red,Green,Blue,NIR`
-   easy to test various parameters that define the High-Pass filter’s *kernel 
size* and *center value*
-   should work with **any** kind of imagery (think of bitness)

To Do
-----

1. convert to Python script

2. integrate in `i.pansharpen`?  

2. ~~automatic looping over multiple Multi-Spectral images so as to render 
needless the task for manual loops~~

3.  ~~linear histogram matching option (as explained in the related 
publication)~~ *Does it work properly?*

4.  ~~works only for integers – with minor tweaking it can work with
`r.mfilter.fp` to crunch Floating Points as well~~

Questions
---------

-   Utilise the existing histogram matching code in `i.pansharpen`? 
It performs histogram matching using the Standard Deviation and Mean of the 
reference image.

-   Integrate in `i.pansharpen`?

References
==========

Gangkofner, U. G., Pradhan, P. S., and Holcomb, D. W. (2008). Op-
timizing the high-pass filter addition technique for image fusion.
PHOTOGRAMMETRIC ENGINEERING & REMOTE SENSING,
74(9):1107–1118.
