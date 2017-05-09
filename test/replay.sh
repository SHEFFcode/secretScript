#!/bin/bash

#video2img converts video to image
# $1 is the name of the video
# $2 is the path of the video
# $3 is the frequency of the snapshot
function video2img()
{
    ffmpeg -i $1 -vf fps=$3 $PWD/$2/$4%d.jpg
}

#pullImage returns the impage been pulled

function pullImage()
{
    #echo $client$3
    #curl -o "$PWD/$client$3/$client$3.mp4" $1
    echo $client$3
    curl -o "$PWD/$client/$client$3.mp4" $1
    numOfFiles=$(ls | wc -l)
    
}

#process is analysis the file and to determine what is needed.
# $1
function process()
{
    echo "$1"
    if [[ $1 != "http"* ]]; then
        client=$3
        #mkdir "${client}-qa"
        #mkdir "${client}-prod"
        mkdir $client
        #client=${1}
    fi
    if [[ $1 =~ "https://qa"* ]]; then
        echo "QA: $client"
        pullImage $1 $client "-qa"
    fi
    if [[ $1 =~ "https://replay"* ]]; then
        echo "Prod: $client"
        pullImage $1 $client "-prod"
    fi
}

# Examine videos
function ProdVsQa()
{
    # Search through each existing directory
    for d in */ ; do
        f=$(echo "$d" | sed -e 's/\///g')
        # Check if video in prod same as qa
        size4Prod=$(ffmpeg -i "$f/$f-prod.mp4" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        size4Qa=$(ffmpeg -i "$f/$f-qa.mp4" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        
        echo "Video size for ${f}-prod.mp4: $size4Prod"
        echo "Video size for ${f}-qa.mp4: $size4Qa"
        
        #if [ "$size4Prod" == "$size4Qa" ] 
        #then
            video2img "$PWD/$f/${f}-prod.mp4" $f "1/2" "${f}-prod"
            video2img "$PWD/$f/${f}-qa.mp4" $f "1/2" "${f}-qa"
            # Check how many images created
            cd "$PWD/$f"
            numOfFiles=$(ls | wc -l)
            totalFiles=$((${numOfFiles}/2))
            echo "number of files: ${numOfFiles} and divide by two: ${totalFiles}"
            for (( i=1; i<$totalFiles; i++ )); do
               node /Users/jeremy.shefer/personal/forAllan/resemble/index.js "${f}-prod${i}".jpg "${f}-qa${i}".jpg diff${i}.png
            done
            cd ..
        #else
         #   echo "Size of the video is not the same for ${f}-prod.mp4: $size4Prod and for ${f}-qa.mp4: $size4Qa"
        #fi
    done
}

# Read download file parameter
# E.g. bash replay.sh list.txt
filename="$1"
client=
find $filename -name '* *' -delete

while read -r line line2 line3
do
   COL="$line"
   COL2="$line2"
   COL3="$line3"
   process $COL $COL2 $COL3
done < "$filename"

ProdVsQa
