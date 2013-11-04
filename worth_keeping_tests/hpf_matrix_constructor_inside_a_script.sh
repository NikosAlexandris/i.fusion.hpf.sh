#!/bin/bash

# a High Pass Filter Matrix (of Matrix_Dimension^2) Constructor Function
function hpf_matrix {

  # Positional Parameters
  Matrix_Dimension="${1}"
  Center_Cell_Value="${2}"

  # Define the cell value(s)
  function hpf_cell_value {
	if (( ${Row} == ${Column} )) && (( ${Column} == `echo "( ${Matrix_Dimension} + 1 ) / 2" | bc` ));
	  then echo "${Center_Cell_Value} ";
	  else echo "-1 ";
	fi
  }

  # Construct the Row for Cols 1 to "Matrix_Dimension"
  function hpf_row {
	for Column in $(seq ${Matrix_Dimension});
	  do echo -n "$(hpf_cell_value)";
	done
  }

  # Construct the Matrix
  echo "MATRIX    ${Matrix_Dimension}"
  for Row in $(seq ${Matrix_Dimension});
	do echo "$(hpf_row)";
  done
  echo "DIVISOR   1"
  echo "TYPE      P"
}

Kernel_Size=5
Center_Cell_Default=18 ; Center_Level=Default
eval Center_Cell="Center_Cell_${Center_Level}"

HPF_MATRIX_ASCII=`hpf_matrix ${Kernel_Size} ${!Center_Cell}`
echo "${HPF_MATRIX_ASCII}"
