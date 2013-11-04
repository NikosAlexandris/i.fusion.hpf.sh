#!/bin/bash
# check for command arguments/parameters -- use for Low/High HPF Center Cell Level!

# source HPF_Matrix_Constructor_Function.sh

# defaults
Kernel_Size=5
Center_Cell=18

#
while [ "$*" != "" ]
  do
	case $* in
	  -cl | --center-low )		Center_Level="Low"
									;;
	  -ch | --center-high ) 		Center_Level="High"
									;;
	  -mi | --modulator-min )		Modulator_Value="Min"
									;;
	  -ma | --modulator-max )		Modulator_Value="Max"
									;;
# 	  -h | --help )					usage
# 									exit
# 									;;
# 	  * )							usage
# 									exit 1
	esac
done

echo "Center Cell Value: ${Center_Level}; Modulator Factor: ${Modulator_Value}"
# HPF_Matrix ${Kernel_Size} ${Center_Cell}
