#!/bin/bash

data_dir=$1 # parent directory where cropped image dir can be found
data_list=$(ls $data_dir/crop)

# Uncomment to filter genomes related to test data out of this set
# exclude=(NA12878 NA12891 NA12892 
#          HG00512 HG00513 HG00514 
#          HG00731 HG00732 HG00733
#          NA19238 NA19239 NA19240) 
# exclude=$(echo ${exclude[@]} | tr " " "|") # construct regex from array
# data_list=$(echo "$data_list" | grep -E -v "$exclude")

# split into train/validation sets (by chromosome)
train_chrms=$(echo chr{{4..22},X,Y}_ | tr " " "|")
val_chrms=$(echo chr{1..3}_ | tr " " "|")

echo "$data_list" | grep -E "$train_chrms" | shuf > $data_dir/train.txt
echo "$data_list" | grep -E "$val_chrms" | shuf > $data_dir/val.txt

# ratio=0.90
# lines=$(echo "$data_list" | wc -l )
# train_lines=$(python -c "from math import ceil; print(ceil($ratio*$lines))")
# let test_lines=$lines-$train_lines
# data_list=$(echo "$data_list" | shuf)
# echo "$data_list" | head --lines=$train_lines > $data_dir/train.txt
# echo "$data_list" | tail --lines=$test_lines > $data_dir/val.txt