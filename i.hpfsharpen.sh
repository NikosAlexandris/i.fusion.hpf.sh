#!/bin/bash


# Started: 29. Oct. 2013
# Currently testing for G64


############################################################################
#
# MODULE:       i.hpfsharpen
# AUTHOR(S):    Nikos Alexandris <nik@nikosalexandris.net>
#				Nikos Ves <>
# PURPOSE:		HPF Resolution Merge -- Algorithm Replication in GRASS GIS
#
# 				Module to combine high-resolution panchromatic data with
# 				lower resolution multispectral data, resulting in an output
# 				with both excellent detail and a realistic representation of
# 				original multispectral scene colors.
#
# 				The process involves a convolution using a High Pass Filter
# 				(HPF) on the high resolution data, then combining this with
# 				the lower resolution multispectral data.
#
# 				Source: "Optimizing the High-Pass Filter Addition Technique for
# 				Image Fusion", Ute G. Gangkofner, Pushkar S. Pradhan,
# 				and Derrold W. Holcomb (2008)
#
# COPYRIGHT:    (C) 2013 by the GRASS Development Team
#
#               This program is free software under the GNU General Public
#               License (>=v2). Read the file COPYING that comes with GRASS
#               for details.
#
#############################################################################

# i.hpfsharpen Script for High Pass Filter based pan sharpening

#%module
#%  description: High-Pass Filter Additive Pan-Sharpening method
#%end
#%flag
#%  key: m
#%  description: Linearly match histograms of the HPF Pan-sharpened output(s) to the Multi-Spectral input(s)
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
#% gisprompt: old,double,raster
#% description: High resolution Panchromatic image for sharpening multi-spectral image
#% required : yes
#%end
#%option
#% key: msx
#% type: string
#% gisprompt: old,double,raster
#% description: Multi-Spectral image(s) to be pan-sharpened
#% required : yes
#% multiple : yes
#%end
#%option
#% key: output_suffix
#% type: string
#% gisprompt: old,double,raster
#% description: HPF Pan-Sharpened Multi-Spectral image(s)
#% required : yes
#% answer : HPF_Filtered
#%end

# Various checks -------------------------------------------------------------

# inside a GRASSy environent?
if [ -z "$GISBASE" ] ; then
    g.message -e "You must be in GRASS GIS to run this program." 1>&2
    exit 1
fi

# save command line
if [ "$1" != "@ARGS_PARSED@" ]
  then CMDLINE=`basename "$0"`
	for arg in "$@"
	  do CMDLINE="$CMDLINE \"$arg\""
	done
  export CMDLINE
  exec g.parser "$0" "$@"
fi

# # parsing?
# if [ "$1" != "@ARGS_PARSED@" ] ; then
#     exec g.parser "$0" "$@"
# else
#   g.message -w "No parameters given..."
# fi

# cleanup()
# {
#   #remove temporary region file
#   unset WIND_OVERRIDE
#   g.remove region="i.hpfsharpen.$TMPPID" --quiet
#   }

# what to do in case of user break:
exitprocedure()
{
  g.message -e message='User break!'
  cleanup
  exit 1
  }

# shell check for user break (signal list: trap -l)
trap "exitprocedure" 2 3 15


# bc available?
SCRIPT=`basename $0`
if [ ! -x "`which bc`" ]
  then g.message -i "${SCRIPT}: bc required, please install it first" 2>&1
  exit 1
fi

# # clone current region
# g.region save="i.hpfsharpen.$TMPPID"


# Flags requesting various parameters for the HPF Matrix and the Process -----
echo ""

# perform linear histogram matching?
if [ $GIS_FLAG_M -eq 1 ]
  then g.message "Will linearly match histograms to adapt StdDev and Mean of the HPF Pan-Sharpened output to those of the Multi-Spectral input."
fi

# default center cell value
if [ $GIS_FLAG_L -eq 0 ] && [ $GIS_FLAG_H -eq 0 ]
  then g.message "Using a default center value"
  Center_Level="Default"
fi

# l - low center cell value
if [ $GIS_FLAG_L -eq 1 ] && [ $GIS_FLAG_H -eq 0 ]
  then g.message -i "Using a Low center value"
  Center_Level="Low"
else g.message -v "Flag -l not set"
fi

# h - high center cell value
if [ $GIS_FLAG_H -eq 1 ] && [ $GIS_FLAG_L -eq 0 ]
  then g.message -i "Using a High center value"
  Center_Level="High"
else g.message -v "Flag -h not set"
fi

	# conflicting flags?
	if [ $GIS_FLAG_L -eq 1 ] && [ $GIS_FLAG_H -eq 1 ]
	then g.message -e "Requested both a Low and a High center value for the filter! Please, instruct only one of them."
	exit 1
  fi

# default modulating factor
if [ $GIS_FLAG_I -eq 0 ] && [ $GIS_FLAG_A -eq 0 ]
  then g.message -v "Using the default modulating factor"
  Modulating_Level="Default"
fi

# i - minimum modulating factor
if [ $GIS_FLAG_I -eq 1 ] && [ $GIS_FLAG_A -eq 0 ]
  then g.message -i "Using the minimum modulating factor"
	Modulating_Level="Min"
  else g.message -v "Minimum modulating factor (-i flag) not requested"
fi

# a - maximum modulating factor
if [ $GIS_FLAG_A -eq 1 ] && [ $GIS_FLAG_I -eq 0 ]
  then g.message -i "Using the Maximum modulating factor"
	Modulating_Level="Max"
  else g.message -v "Maximum modulating factor (-a flag) not requested"
fi

	# conflicting flags?
	if [ $GIS_FLAG_I -eq 1 ] && [ $GIS_FLAG_A -eq 1 ]
	then g.message -e "Requested both a Min and a Max modulating factor for the weighting process! Please, instruct only one of them."
	exit 1
  fi

# 2-pass process for large ratios
if [ $GIS_FLAG_2 -eq 1 ]
  then g.message -i "Performing a 2-pass processing -- Not Implemented!"

	# default modulating factor 2
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_N -eq 0 ] && [ $GIS_FLAG_X -eq 0 ]
	  then g.message "Using a default modulating factor for the 2-pass process"
	  Modulating_Level_2="Default"
	fi

	# n
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_N -eq 1 ] && [ $GIS_FLAG_X -eq 0 ]
	  then g.message -i "Using the Minimum modulating factor for the 2-pass process"
		Modulating_Level_2="Min"
	  else g.message "Flag -I not set"
	fi

	# x
	if [ $GIS_FLAG_2 -eq 1 ] && [ $GIS_FLAG_X -eq 1 ] && [ $GIS_FLAG_N -eq 0 ]
	  then g.message -i "Using the Maximum modulating factor for the 2-pass process"
		Modulating_Level_2="Max"
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


# What was requested? ----------------------------------------------------------

# Flags/Parameters
g.message -v " "
g.message -v "Requested parameters:"
g.message -v "* Center Cell Level: ${Center_Level}"
g.message -v "* Modulating Factor Level: ${Modulating_Level}"

if [ $GIS_FLAG_2 -eq 1 ]
  then g.message -i "* Modulating Factor Level_2: ${Modulator_Level_2}"
fi


# Input Images
g.message -v " "
g.message -v "Images to be fused:"


# check if input panchromatic image exists
eval `g.findfile element=cell file="${GIS_OPT_PAN}"`
if [ -z "$name" ]
  then g.message -e "can't find the <${GIS_OPT_PAN}> image."
	exit 1
  else g.message -v "* High resolution image:	${GIS_OPT_PAN}"
fi

# check if input multi-spectral image exists

# save default IFS
Default_IFS=$IFS

# set to comma
IFS=,

# loop over...
for Image in ${GIS_OPT_MSX}
  do
	# check if Image exists
	eval `g.findfile element=cell file="${Image}"`
	if [ -z "$name" ]
	  then g.message -e "can't find the <${Image}> image."
		exit 1
	  else g.message -v "* Low resolution image:	${Image}"
	fi
done

# reset IFS
IFS=${Default_IFS}



# Implementation in GRASS GIS ################################################

#
# 1. Read pixel sizes from Image files and calculate R, the ratio of
# multispectral cell size to high-resolution cell size
# ----------------------------------------------------------------------------

g.message -i " "
g.message -i "Step 1. Computing Ratio of MSX to Pan Image"

# First, check & warn user about "ns == ew" resolution of current region

# eval current region's ns, ew resolutions
eval `g.region -g | grep ns`
eval `g.region -g | grep ew`

# check & warn if ns == ew
if [ $( echo "${nsres} != ${ewres}" | bc ) -eq 1 ]
  then g.message -w "The region's North:South and East:West resolutions do not match."
fi

# eval images resolutions: `r.info -s` for G64 || `-g` for G7

# PAN resolution
eval `r.info ${GIS_OPT_PAN} -s | grep nsres`
eval PAN_RESOLUTION="${nsres}"

# MSX resolution
eval `r.info ${GIS_OPT_MSX} -s | grep nsres`
eval MSX_RESOLUTION="${nsres}"

# Next, compute the Ratio of the Pan and MSX image resolutions
RATIO=$( echo "${MSX_RESOLUTION} / ${PAN_RESOLUTION}" | bc -l )
g.message -v "* Ratio of image resolutions is: ${RATIO}."




#
# 2. Apply the High-pass filter to the high spatial resolution image.
# ----------------------------------------------------------------------------

g.message -i " "
g.message -i "Step 2. High Pass Filtering the Pan Image"

# Respect current region -- Change the resolution
g.region res=${PAN_RESOLUTION}

# a High Pass Filter Matrix (of Matrix_Dimension^2) Constructor
function hpf_matrix {

  # Positional Parameters
  eval Matrix_Dimension="${1}"
  eval Center_Cell_Value="${2}"

  # Define the cell value(s)
  function hpf_cell_value {
	if (( ${Row} == ${Column} )) && (( ${Column} == `echo "( ${Matrix_Dimension} + 1 ) / 2" | bc` ))
	  then echo "${Center_Cell_Value} "
	  else echo "-1 "
	fi
  }

  # Construct the Row for Cols 1 to "Matrix_Dimension"
  function hpf_row {
	for Column in `seq ${Matrix_Dimension}`
	  do echo -n "$(hpf_cell_value)"
	done
  }

  # Construct the Matrix
  echo "MATRIX    ${Matrix_Dimension}"
  for Row in `seq ${Matrix_Dimension}`
  	do echo "$(hpf_row)"
  done
  echo "DIVISOR   1"
  echo "TYPE      P"
}



# Kernel Size, Center Value & Some Modulation Factor depend on Resolution Ratio

  # 1 < RATIO < 2.5 then 5x5
  if
  [[ $( echo "1 < ${RATIO}" | bc ) -eq 1 ]] && \
	[[ $( echo "${RATIO} < 2.5" | bc ) -eq 1 ]]

  then

  # kernel size
  Kernel_Size=5

  # potential center values
  Center_Default=24	;	Center_Low=28	;	Center_High=32
  eval Center_Cell="Center_${Center_Level}"

  # modulation Factor
  Modulator_Min=0.3	;	Modulator_Default=0.25	;	Modulator_Max=0.20
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  # Default will be:
					  #   HPF_MATRIX=\
					  # "MATRIX    5
					  # -1 -1 -1 -1 -1
					  # -1 -1 -1 -1 -1
					  # -1 -1 $(echo ${!Center_Cell}) -1 -1
					  # -1 -1 -1 -1 -1
					  # -1 -1 -1 -1 -1
					  # DIVISOR   1
					  # TYPE      P"

  fi

  # 2.5 <= RATIO < 3.5 then 7x7
  if

  [[ $( echo "2.5 < ${RATIO}" | bc ) -eq 1 ]] && \
	[[ $( echo "${RATIO} < 3.5" | bc ) -eq 1 ]]
  then

  # kernel size
  Kernel_Size=7 #&& echo ${Kernel_Size}

  # center values
  Center_Default=48	;	Center_Low=56	;	Center_High=64
  eval Center_Cell="Center_${Center_Level}"

  # modulation factor
  Modulator_Min=0.65 ; Modulator_Default=0.50 ; Modulator_Max=0.35
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  fi

  # 3.5 <= RATIO < 5.5 then 9x9
  if

  [[ $( echo "3.5 < ${RATIO}" | bc ) -eq 1 ]] && \
	[[ $( echo "${RATIO} < 5.5" | bc ) -eq 1 ]]
  then

  # kernel size
  Kernel_Size=9 #&& echo ${Kernel_Size}

  # center values 
  Center_Default=80	;	Center_Low=96	;	Center_High=106
  eval Center_Cell="Center_${Center_Level}"

  # modulation factor
  Modulator_Min=0.65 ; Modulator_Default=0.50 ; Modulator_Max=0.35
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  fi

  # 5.5 <= RATIO < 7.5 then 11x11
  if

  [[ $( echo "5.5 < ${RATIO}" | bc ) -eq 1 ]] && \
	[[ $( echo "${RATIO} < 7.5" | bc ) -eq 1 ]]
  then

  # kernel size
  Kernel_Size=11 #&& echo ${Kernel_Size}

  # center values
  Center_Default=120 ; Center_Low=150 ; Center_High=180
  eval Center_Cell="Center_${Center_Level}"

  # modulation factor
  Modulator_Min=1.0 ; Modulator_Default=0.65 ; Modulator_Max=0.50
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  fi

  # 7.5 <= RATIO < 9.5 then 13x13
  if

  [[ $( echo "7.5 < ${RATIO}" | bc ) -eq 1 ]] && \
	[[ $( echo "${RATIO} < 9.5" | bc ) -eq 1 ]]
  then

  # kernel size
  Kernel_Size=13 #&& echo ${Kernel_Size}

  # center values
  Center_Default=168	;	Center_Low=210	;	Center_High=252
  eval Center_Cell="Center_${Center_Level}"

  # modulation factor
  Modulator_Min=1.4 ; Modulator_Default=1.0 ; Modulator_Max=0.65
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  fi

  # RATIO >= 9.5 then 15x15
  if

  [[ $( echo "9.5 <= ${RATIO}" | bc ) -eq 1 ]]
  then

  # kernel size
  Kernel_Size=15 #&& echo ${Kernel_Size}

  # center values
  Center_Default=336	;	Center_Low=392	;	Center_High=448
  eval Center_Cell="Center_${Center_Level}"

  # modulation factor
  Modulator_Min=2.0 ; Modulator_Default=1.35 ; Modulator_Max=1.0
  eval Modulating_Factor="Modulator_${Modulating_Level}"

  # the Matrix
  HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
  g.message -v " "
  g.message -v "The filter is:"
  g.message -v "${HPF_MATRIX_ASCII}"

  fi

  # create (temporary) filter ASCII file
  Temporary_ASCII_HPF_Matrix_File="i.hpfsharpen.tmp.$$"
  if [ $? -ne 0 ] || [ -z "$Temporary_ASCII_HPF_Matrix_File" ]
	then g.message -e "unable to create temporary files"
	  exit 1
	else echo "${HPF_MATRIX_ASCII}" > "${Temporary_ASCII_HPF_Matrix_File}"
  fi


  ### ADD Additional Checks ? ###

  g.message -v " "
  g.message -v "High Pass Filter created with the following parameters:"
  g.message -v "Kernel Size: ${Kernel_Size}; Center Value: ${!Center_Cell}"

  # create a temp file -- maybe I have misunderstood the use of g.tempfile!?
  Temporary_HPF="i.hpfsharpen.tmp.$$"
  if [ $? -ne 0 ] || [ -z "$Temporary_HPF" ]
	then g.message -e "unable to create temporary files"
	exit 1
  fi

## ###


  # apply filter (for G64 -- for G7 use r.mfilter?)
  r.mfilter \
  input="${GIS_OPT_PAN}" \
  filter="${Temporary_ASCII_HPF_Matrix_File}" \
  output="${Temporary_HPF}" \
  title="High Pass Filtered Panchromatic Image"

  # write cmd history
# r.support "" history="${CMDLINE}"
# r.support "$GIS_OPT_" history="${CMDLINE}"
# r.support "$GIS_OPT_" history="${CMDLINE}"

  # Remove this! ######################################################### ###
  g.copy rast="${Temporary_HPF}","HPF_Filtered_${GIS_OPT_PAN}"
  ###


#
# 3. Resample the Multi-Spectral image to the pixel size of the high-pass image.
# Note, bilinear resampling required (4 nearest neighbours)!
# ----------------------------------------------------------------------------

g.message -i " "
g.message -i "Step 3. Resampling MSX image to the higher resolution"

  # create a temp file
  Temporary_MSBLNR="i.hpfsharpen.tmp.$$"
  if [ $? -ne 0 ] || [ -z "$Temporary_MSBLNR" ]
	then g.message -e "unable to create temporary files"
	exit 1
  fi

  # resample -- named "linear" in G7
  r.resamp.interp \
  method="bilinear" \
  input="${GIS_OPT_MSX}" \
  output="${Temporary_MSBLNR}"

  # write cmd history
# r.support "" history="${CMDLINE}"
# r.support "$GIS_OPT_" history="${CMDLINE}"
# r.support "$GIS_OPT_" history="${CMDLINE}"

  # Remove this! ######################################################### ###
  g.copy rast="${Temporary_MSBLNR}","HPF_Resampled_${GIS_OPT_MSX}"
  ###



#
# 4. Add the HPF image weighted relative to the global standard deviation of
# the Multi-Spectral band.
# ----------------------------------------------------------------------------

g.message -i " "
g.message -i "Step 4. Adding weighted HPF image to the resampled MSX image"


# The weighting formula is: W = ( SD(MS) / SD(HPF) x M )
  # where:
	# SD(MS) and SD(HPF) are the Standard Deviations of the MS and HPF images
	# M is a Modulator value
	
g.message -v "        The weighting formula is: ..."
g.message -v "Weight = StdDev (MSX) / StdDev (HPF) * Modulating Factor"

  # get Standard Deviations
  g.message -v " "

	# of Multi-Spectral Image(s)
	eval `r.univar ${GIS_OPT_MSX} -g | grep stddev`
	eval MSX_StdDev="${stddev}"
	g.message -v "MSX' StdDev: ${MSX_StdDev}"

	# *and* the HPF Image
	eval `r.univar ${Temporary_HPF} -g | grep stddev`
	eval HPF_StdDev="${stddev}"
	g.message -v "HPF's StdDev: ${HPF_StdDev}"
	
	# the modulating factor
	g.message -v "The Modulating Factor is set to: ${!Modulating_Factor:-None}"

  # compute weighting
  Weighting=$( echo "( ${MSX_StdDev} / ${HPF_StdDev} * ${!Modulating_Factor} )" | bc -l )
  g.message -v "${Weighting} = ${MSX_StdDev} / ${HPF_StdDev} * ${!Modulating_Factor}"

  # create temporary file
  Temporary_MSHPF="i.hpfsharpen.tmp.$$"
  if [ $? -ne 0 ] || [ -z "$Temporary_MSHPF" ]
	then g.message -e "unable to create temporary files"
	exit 1
  fi

  # Add weighted HPF image to the bilinearly resampled Multi-Spectral band
  r.mapcalc "${Temporary_MSHPF} = ${Temporary_MSBLNR} + ${Temporary_HPF} * ${Weighting}"

  # write cmd history
# r.support "" history="${CMDLINE}"

  # Remove this! ######################################################### ###
  g.copy rast="${Temporary_MSHPF}","HPF_Sharpened_${GIS_OPT_MSX}"
  ###

#
# 5. Stretch linearly the new HPF-Sharpened image to match the mean and
# standard deviation of the input Multi-Sectral image.
# ----------------------------------------------------------------------------

g.message -i "Step 5. Optionally, matching histogram of Pansharpened image to the one of the original MSX image"
g.message -i "...not implemented"

# if [ $GIS_FLAG_M -eq 0 ]
#   then g.rename rast=${Temporary_MSHPF},${GIS_OPT_MSX}_${GIS_OPT_OUTPUT_SUFFIX}
#   else g.message -i "Matching histograms..." # linear hisogram matching to adapt output StdDev and Mean to the input-ted ones
#   # r.mapcalc
#   # input=${Temporary_MSHPF} \
#   # output=${GIS_OPT_MSX}_${GIS_OPT_OUTPUT_SUFFIX} \
# 	
# fi



#
# Clean up
#

# g.message -v "Restoring region settings."
# cleanup

# Remove temporary files
g.remove ${Temporary_HPF}
g.remove ${Temporary_MSBLNR}
g.remove ${Temporary_MSHPF}



#
# Inform how to...
#

# g.message -v "To visualize output, run:"
