#!/bin/bash
function jsonval(){
temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop  | cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g' `
    echo ${temp##*|}
}

#json='{"isSameDimensions":true,"dimensionDifference":{"width":0,"height":0},"rawMisMatchPercentage":0.9385850694444444,"misMatchPercentage":"0.94","diffBounds":{"top":37,"left":105,"bottom":575,"right":463},"analysisTime":23}'
json=$1
prop='misMatchPercentage'
jsonval
