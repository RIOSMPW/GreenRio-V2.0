#!/bin/bash

count=1
name="you"
path=$1
while(( $count<=$(($2))))
do
    make -C $path gen
    name="test""$count"".S"
    mv $path/output/test.S test/torture/src/$name
    let "count++"
done
