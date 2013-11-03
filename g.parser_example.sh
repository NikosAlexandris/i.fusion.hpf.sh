#!/bin/sh

############################################################################
#
# MODULE:       i.hpfsharpen
# AUTHOR(S):    Nikos Alexandris <nik@nikosalexandris.net>
#				Nikos Ves
# PURPOSE:      ...
# COPYRIGHT:    (C) 2013 by the GRASS Development Team
#
#               This program is free software under the GNU General Public
#               License (>=v2). Read the file COPYING that comes with GRASS
#               for details.
#
#############################################################################

# i.hpfsharpen Script for High Pass Filter based pan sharpening

#%module
#%  description: i.hpfsharpen test script   
#%end
#%flag
#%  key: l
#%  description: Use a Low value for the filter's center value
#%end
#%flag
#%  key: h
#%  description: Use a High value for the filter's center value
#%end
#%flag
#%  key: i
#%  description: Use the Minimum modulating factor for weighting the HPF image
#%end
#%flag
#%  key: a
#%  description: Use the Maximum modulating factor for weighting the HPF image
#%end
#%flag
#%  key: 2
#%  description: 2-Pass Processing (recommended) for large Resolution Ratio (>=5.5)
#%end
#%flag
#%  key: n
#%  description: Use the Minimum modulating factor for weighting the HPF image in the 2-Pass
#%end
#%flag
#%  key: x
#%  description: Use the Maximum modulating factor for weighting the HPF image in the 2-Pass
#%end
#%option
#% key: pan
#% type: string
#% gisprompt: old,cell,raster
#% description: High resolution Panchromatic image for sharpening multi-spectral image
#% required : yes
#%end
#%option
#% key: msx
#% type: string
#% gisprompt: old,cell,raster
#% description: Multi-Spectral image(s) to be pan-sharpened
#% required : yes
#% multiple : yes
#%end


if [ -z "$GISBASE" ] ; then
    echo "You must be in GRASS GIS to run this program." 1>&2
    exit 1
fi

if [ "$1" != "@ARGS_PARSED@" ] ; then
    exec g.parser "$0" "$@"
else
  g.message -w "No parameters given..."
fi

#### add your code below ####
g.message ""

# default center value
if [ $GIS_FLAG_L -eq 0 ] && [ $GIS_FLAG_H -eq 0 ]
  then g.message "Using a default center value"
  Center_Level="Default"
fi

# l
if [ $GIS_FLAG_L -eq 1 ] && [ $GIS_FLAG_H -eq 0 ]
  then g.message -i "Using a Low center value"
  Center_Level="Low"
else g.message "Flag -l not set"
fi

# h 
if [ $GIS_FLAG_H -eq 1 ] && [ $GIS_FLAG_L -eq 0 ]
  then g.message -i "Using a High center value"
  Center_Level="High"
else g.message "Flag -h not set"
fi

# conflicting flags?
if [ $GIS_FLAG_L -eq 1 ] && [ $GIS_FLAG_H -eq 1 ]
  then g.message -e "Requested both a Low and a High center value for the filter! Please, instruct only one of them."
  exit 1
fi

# default modulating factor
if [ $GIS_FLAG_I -eq 0 ] && [ $GIS_FLAG_A -eq 0 ]
  then g.message "Using the default modulating factor"
  Modulator_Level="Default"
fi

# i
if [ $GIS_FLAG_I -eq 1 ] && [ $GIS_FLAG_A -eq 0 ]
  then g.message -i "Using the Minimum modulating factor"
	Modulator_Level="Min"
  else g.message "Flag -i not set"
fi

# ma
if [ $GIS_FLAG_A -eq 1 ] && [ $GIS_FLAG_I -eq 0 ]
  then g.message -i "Using the Maximum modulating factor"
	Modulator_Level="Max"
  else g.message "Flag -a not set"
fi

# conflicting flags?
if [ $GIS_FLAG_I -eq 1 ] && [ $GIS_FLAG_A -eq 1 ]
  then g.message -e "Requested both a Min and a Max modulating factor for the weighting process! Please, instruct only one of them."
  exit 1
fi

# 2
if [ $GIS_FLAG_2 -eq 1 ]
  then g.message -i "Performing a 2-pass processing"

	# default modulating factor 2
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_N -eq 0 ] && [ $GIS_FLAG_X -eq 0 ]
	  then g.message "Using a default modulating factor for the 2-pass process"
	  Modulator_Level_2="Default"
	fi

	# n
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_N -eq 1 ] && [ $GIS_FLAG_X -eq 0 ]
	  then g.message -i "Using the Minimum modulating factor for the 2-pass process"
		Modulator_Level_2="Min"
	  else g.message "Flag -I not set"
	fi


	# x
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_X -eq 1 ] && [ $GIS_FLAG_N -eq 0 ]
	  then g.message -i "Using the Maximum modulating factor for the 2-pass process"
		Modulator_Level_2="Max"
	  else g.message "Flag -A not set"
	fi

	# conflicting flags?
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_N -eq 1 ] && [ $GIS_FLAG_X -eq 1 ]
	  then g.message -e "Requested both a Min and a Max modulating factor for the 2-pass weighting process! Please, instruct only one of them."
	  exit 1
	fi

  else g.message "Flag -2 not set"
  
	if [ $GIS_FLAG_2 -eq 0 ] && [ $GIS_FLAG_N -eq 1 ] && [ $GIS_FLAG_X -eq 0 ]
	then g.message -i "Please request the 2-pass process by instructing the -2 flag!"
	exit 1
	fi
	
	
	# x
	if [ $GIS_FLAG_2 -eq 0 ] && [ $GIS_FLAG_X -eq 1 ] && [ $GIS_FLAG_N -eq 0 ]
	then g.message -i "Please request the 2-pass process by instructing the -2 flag!"
	exit 1
	fi

fi



# The requested paramters
g.message -i "The requested parameters:"
g.message -i "* Center_Level: ${Center_Level}"
g.message -i "* Modulator_Level: ${Modulator_Level}"

if [ $GIS_FLAG_2 -eq 1 ]
  then g.message -i "* Modulator_Level_2: ${Modulator_Level_2}"
fi



#
g.message "The input high resolution Panchromatic image: ${GIS_OPT_PAN}"

# check if panchromatic image exists
eval `g.findfile element=cell file="${GIS_OPT_PAN}"`
if [ -z "$name" ]
  then g.message -e "image <${GIS_OPT_PAN}> not found."
  exit 1
fi

#
IFS=,
for Image in $GIS_OPT_MSX
  do
	# check if Image exists
	eval `g.findfile element=cell file="${Image}"`
	if [ -z "$name" ]
	  then g.message -e "image <${Image}> not found."
	  exit 1
	fi
	g.message "The input low resolution Multi-Spectral image: ${Image}"
done

# one more check -- necessary?
if [ "${GIS_OPT_PAN}" = "${Image}" ]
  then g.message "Input elevation map and output roughness map must have different names"
  exit 1
fi
