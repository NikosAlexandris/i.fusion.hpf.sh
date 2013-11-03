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
