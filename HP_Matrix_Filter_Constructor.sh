#!/bin/bash

# November 2013
# Trikala, Greece

# Based on Nikos Ve's one-liner:
# for row in $(seq $DIM)  ;  do  echo $(for col in $(seq $DIM)  ;  do if [ $row -eq $col ] && [ $row == $(echo "$DIM/2+1" | bc) ]; then echo " yaw"  ;  else echo -n " -1" ; fi  ;  done)  ;  done



# Try to integrate error-checks... !?

# # The Matrix Filter Constructor requires at least one Parameter
# ARGS=1
# E_BADARGS=85
# 
# # 
# if [ $# -ne "$ARGS" ]
#   then
# 	echo "Usage: `basename $0` Matrix Dimension [5, 7, 9, 11, 13, 15] Alternative Level of Filter's Center Value [Low or High]*"
# 	echo "[*] Default Filter's Center Value depends on the Resolution Ration \"High Resolution\" / \"Low Resolution\""
# 	echo "Example 1:  `basename $0` 7 "
# 	echo "Example 2:  `basename $0` 5 Low"
# 	echo "Example 3:  `basename $0` 9 High"
#   else
# 	exit $E_BADARGS
# fi



# Matrix Dimension(s)
if [ -z $1 ]
  then
	Matrix_Dimension=5
	echo "* Constructing a ${Matrix_Dimension}x${Matrix_Dimension} Matrix Filter"
  else
	Matrix_Dimension=$1
	echo "* Constructing a ${Matrix_Dimension}x${Matrix_Dimension} Matrix Filter"
fi



# The center cell value
if [ -z $2 ]
  then
	HPF_Center_Value=18
	echo "* The Filter's Center Cell Value will be ${HPF_Center_Value}"
  else
	HPF_Center_Value=$2
	echo "* The Filter's Center Cell Value will be ${HPF_Center_Value}"
fi



# Some echo
echo -e



# Rows and Cols
# Rows=${Matrix_Dimension}
# Columns=${Matrix_Dimension}

# The filter's center cell is:
  # (( "${Row}" == "${Col}" ))
  # (( "${Cell}" == `echo "(${Col} + 1 ) / 2" | bc` ))


# Basic Logic
# if (( "${Row}" == "${Col}" )) && (( "${Cell}" == `echo "(${Col} + 1 ) / 2" | bc` )) ; then echo "${HPF_C}" ; else echo "1" ; fi


# Construct a High Pass Filter Matrix (of Matrix_Dimension^2)
HPF_Matrix(){

  # Define the cell value(s)
  HPF_Cell_Value(){
	if (( "${Row}" == "${Col}" )) && (( "${Col}" == `echo "(${Matrix_Dimension} + 1 ) / 2" | bc` ))
	then echo "${HPF_Center_Value} "
	else echo "-1 " ; fi
  }

  # Construct the Row for Cols 1 to "Matrix_Dimension"
  HPF_Row(){
	for Col in `seq ${Matrix_Dimension}`
	  do
		echo -n "$(HPF_Cell_Value)"
	done
  }

  # Construct the Matrix
  Matrix_Dimension="${1}"
  HPF_Center_Value="${2}"
  echo "MATRIX    ${Matrix_Dimension}"
  for Row in `seq "${Matrix_Dimension}"`
    do
      echo "$(HPF_Row)"
  done
  echo "DIVISOR   1"
  echo "TYPE      P"
}

HPF_Matrix $1 $2
