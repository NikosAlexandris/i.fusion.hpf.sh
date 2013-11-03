#!/bin/bash

RATIO=2

if
  [[ $( echo "1 < ${RATIO}" | bc ) -eq 1 ]] && \
  [[ $( echo "${RATIO} < 2.5" | bc ) -eq 1 ]]

  then
  
	# kernel size
	Kernel_Size=5

	# potential center values
	Center_Default=24	;	Center_Low=28	;	Center_High=32
	
	# setting center value
# 	if
#		Center_Level=Default
		then
		  eval Center_Cell="Center_${Center_Level}"
		else
		  # ask for Low or High
# 	fi
	
	eval Center_Cell="Center_${Center_Level}"
	echo "* The Filter's Center Cell Value is set to ${!HPF_Center_Cell}"
	
	# modulation Factor
	Modulator_Min=0.3	;	Modulator_Default=0.25	;	Modulator_Max=0.20
	
	# setting modulation value
#	if
#		Modulator_Value=Default
#		then
#			eval Modulation_Factor="Modulator_${Modulator_Value}"
#		else
#			eval 
	# ask for Low or High
	# 	fi
	eval Modulator_Factor="Modulator_${Modulator_Value}"
	
  # the Matrix
  HPF_Matrix ${Kernel_Size} ${HPF_Center_Cell}

	# Default will be:

	#   HPF_MATRIX=\
	# "MATRIX    5
	# -1 -1 -1 -1 -1
	# -1 -1 -1 -1 -1
	# -1 -1 $(echo ${Center_Cell}) -1 -1
	# -1 -1 -1 -1 -1
	# -1 -1 -1 -1 -1
	# DIVISOR   1
	# TYPE      P"

fi
