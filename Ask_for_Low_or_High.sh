# 
# select yn in "Yes" "No"; do
#   case $yn in
# 	Yes ) select lh in "Low" "High"; do
# 	  case $lh in 
# 		Low ) HPF_CENTER_VALUE_LEVEL="LOW"
# 		High ) HPF_CENTER_VALUE_LEVEL="HIGH"
# 	  esac
# 	No ) exit;;
#   esac
# 
# done

echo "Do you wish to use an alternative level for the High Pass Filter's center Cell value?"
select lh in "Low" "High"; do
    case $lh in
        Low ) HPF_CENTER_VALUE_LEVEL="LOW"; echo ${HPF_CENTER_VALUE_LEVEL}; break;;
        High ) HPF_CENTER_VALUE_LEVEL="HIGH"; echo ${HPF_CENTER_VALUE_LEVEL}; break;;
    esac
done
