#!/bin/bash

for i in {1..100}
do
    printf "\rprocess %3d %%" $i
    sleep 1
done

# print a new line
echo
