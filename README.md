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

Installation
============

Requirements
------------

see [GRASS Addons SVN repository, README file, Installation - Code Compilation](https://svn.osgeo.org/grass/grass-addons/README)

Installation steps
------------------

Making the script `i.fusion.hpf` available from within any GRASS-GIS ver. 6.4 session, may be done via the following steps:

1.  launch a GRASS-GIS’ ver. 6.4 session

2.  navigate into the script’s source directory

3.  execute `make MODULE_TOPDIR=$GISBASE`

Usage
=====

After installation, from within a GRASS-GIS session, see help details via `i.fusion.hpf --help` -- also provided here:

```
Description:
 Fuses a High-Resolution Panchromatic with its corresponding Low Resolution Multi-Spectral image based on the High-Pass Filter Addition technique

Keywords:
 imagery, fusion, HPF, HPFA

Usage:
 i.fusion.hpf [-l2] pan=string msx=string[,string,...]
   outputprefix=string [ratio=value] [center=string] [center2=string]
   [modulator=string] [modulator2=string] [--verbose] [--quiet]

Flags:
  -l   Linearly match histograms of the HPF Pan-sharpened output(s) to the Multi-Spectral input(s)
  -2   2-Pass Processing (recommended) for large Resolution Ratio (>=5.5)
 --v   Verbose module output
 --q   Quiet module output

Parameters:
           pan   High resolution panchromatic image
           msx   Low resolution multi-spectral image(s)
  outputprefix   Prefix for the Pan-Sharpened Multi-Spectral image(s)
                 default: hpf
         ratio   Custom defined ratio to override standard calculation
                 options: 1-10
        center   Center cell value of the High-Pass-Filter
                 options: low,mid,high
                 default: low
                  low: Low center cell value
                  mid: Mid center value
                  high: High center value
       center2   Center cell value for the second pass of the High-Pass-Filter
                 options: low,mid,high
                 default: low
                  low: Low center cell value
                  mid: Mid center value
                  high: High center value
     modulator   Level of modulating factor weighting the HPF image to determine crispness
                 options: min,mid,max
                 default: mid
                  min: Minimum modulating factor
                  mid: Mid modulating factor
                  max: Maximum modulating factor
    modulator2   Level of modulating factor weighting the HPF image in the second pass to determine crispness
                 options: min,mid,max
                 default: mid
                  min: Minimum modulating factor (0.25) for the 2nd pass
                  mid: Mid modulating factor (0.35) for the 2nd pass
                  max: Maximum modulating factor (0.5) for 2nd pass
```
  
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

1. ~~convert to Python script~~

2. integrate in `i.pansharpen`? Checking options...

2. ~~automatic looping over multiple Multi-Spectral images so as to render 
needless the task for manual loops~~

3.  ~~linear histogram matching option (as explained in the related 
publication)~~ *Does it work properly?*

4.  ~~works only for integers – with minor tweaking it can work with
`r.mfilter.fp` to crunch Floating Points as well~~

5. consider [Have backticks (i.e. `cmd`) in *sh shells been deprecated?](http://unix.stackexchange.com/q/126927/13011)

6. what about [Why should eval be avoided in Bash, and what should I use instead?](http://stackoverflow.com/q/17529220/1172302)

7. identically named pan-sharpened images won't be overwritten -- advice to use `--o Allow output files to overwrite existing files`  <- needs to be shown while `i.fusion.hpf --help`!

Questions
---------

-   Utilise the existing histogram matching code in `i.pansharpen`? 
It performs histogram matching using the Standard Deviation and Mean of the 
reference image.


References
==========

Gangkofner, U. G., Pradhan, P. S., and Holcomb, D. W. (2008). Op-
timizing the high-pass filter addition technique for image fusion.
PHOTOGRAMMETRIC ENGINEERING & REMOTE SENSING,
74(9):1107–1118.
