#!/bin/bash

#StorageManager.sh
#this program is in three parts
#part one

 df -g| awk '{print$3}' | cat >  /var/mobile/Media/Succession/StorageUsed.txt
#will need gawk, bc and sed from Bingner’s repo
#we remove the first line of our StorageUsed text file as it currently has a value we don’t need 
sed -i '1d' /var/mobile/Media/Succession/StorageUsed.txt
#we now add all the values in our StorageUsed.txt file and store it as a variable   
StorageUsed=`paste -sd+ /var/mobile/Media/Succession/StorageUsed.txt  | bc`

#part two
    
df  -g | awk '{print$4}' | cat >  /var/mobile/Media/Succession/StorageCapacity.txt
#we remove the first line of our StorageCapacity  text file as it currently has a value we don’t need 
sed -i '1d' /var/mobile/Media/Succession/StorageCapacity.txt
#we now add all the values in our StorageCapacity.txt file and store it as a variable   
StorageCapacity=`paste -sd+ /var/mobile/Media/Succession/StorageCapacity.txt  | bc`

#part three
echo  "scale=2; $StorageUsed / $StorageCapacity * 100" | bc

