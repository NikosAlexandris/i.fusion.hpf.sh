#!/bin/bash

# November 2013
# Trikala, Greece

# Based on Nikos Ve's one-liner:
  # ...


# The center cell value
if [ -z $2 ]
then HPF_Center_Value=18
else HPF_Center_Value=$2
fi

#
Matrix_Dimension=5

# Rows and Cols
# Rows=${Matrix_Dimension}
# Columns=${Matrix_Dimension}

# The filter's center cell is:
  # (( "${Row}" == "${Col}" ))
  # (( "${Cell}" == `echo "(${Col} + 1 ) / 2" | bc` ))


# Basic Logic
# if (( "${Row}" == "${Col}" )) && (( "${Cell}" == `echo "(${Col} + 1 ) / 2" | bc` )) ; then echo "${HPF_C}" ; else echo "1" ; fi

# create a function for the cell value
HPF_Cell_Value(){
  if (( "${Row}" == "${Col}" )) && (( "${Col}" == `echo "(${Matrix_Dimension} + 1 ) / 2" | bc` )) ; then echo "${HPF_Center_Value} " ; else echo "-1 " ; fi
}

# construct the row for Cols 1 to N
HPF_Row(){
  for Col in `seq ${Matrix_Dimension}`
    do
	  echo -n "$(HPF_Cell_Value)"
  done
}

# Put that in a loop
HPF_Matrix(){
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
