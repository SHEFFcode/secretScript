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
    echo "curl -o $PWD/$client/$client$3.mp4 $1"
    #curl -o "$PWD/$client$3/$client$3.mp4" $1
    echo $client$3
    URL=${1%$'\r'}
    curl -o "$PWD/$client/$client$3.mp4" $URL
    numOfFiles=$(ls | wc -l)
    
}

# Parsing json file result
function jsonval(){
temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop  | cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g' `
    echo ${temp##*|}
}

#process is analysis the file and to determine what is needed.
# $1
function process()
{
    echo "Parameter 1 : $1"
    if [[ $1 != "http"* ]]; then
        client=${5%$'\r'}
	#client='echo $client | sed 's/\(\[\|\]\)//g''
        echo "client: $client"
        # Check if this already created
        if [ -d "$client" ]; then
            count=1
            while [ -d "$client" ]
            do
                client="$client$count"
                (( count++ ))
            done
            mkdir $client
        else
            mkdir $client
        fi
        #client=${1}
    fi
    if [[ $1 =~ "https://qa"* ]]; then
    #if [[ $1 =~ "https://dev"* ]]; then
        echo "QA: $client"
        pullImage $1 $client "-qa"
        #pullImage $1 $client "-dev"
    fi
    if [[ $1 =~ "https://replay"* ]]; then
        echo "Prod: $client"
        pullImage $1 $client "-prod"
    fi
}

# Examine videos
function ProdVsQa()
{
    prop='misMatchPercentage'
    # Search through each existing directory
    cd ..
    root=$PWD
    cd test
    for d in */ ; do
        f=$(echo "$d" | sed -e 's/\///g')
        # Check if video in prod same as qa
        size4Prod=$(ffmpeg -i "$f/$f-prod.mp4" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        size4Qa=$(ffmpeg -i "$f/$f-qa.mp4" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        #size4Qa=$(ffmpeg -i "$f/$f-dev.mp4" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        
        echo "Video size for ${f}-prod.mp4: $size4Prod"
        echo "Video size for ${f}-qa.mp4: $size4Qa"
        #echo "Video size for ${f}-dev.mp4: $size4Qa"
        
        if [ "$size4Prod" == "$size4Qa" ] 
        then
            video2img "$PWD/$f/${f}-prod.mp4" $f "1/2" "${f}-prod"
            video2img "$PWD/$f/${f}-qa.mp4" $f "1/2" "${f}-qa"
            #video2img "$PWD/$f/${f}-dev.mp4" $f "1/2" "${f}-qa"
            # Check how many images created
            cd "$PWD/$f"
            numOfFiles=$(ls | wc -l)
            totalFiles=$((${numOfFiles}/2))
            echo "number of files: ${numOfFiles} and divide by two: ${totalFiles}"
            for (( i=1; i<$totalFiles; i++ )); do
               node "$root/index.js" "${f}-prod${i}".jpg "${f}-qa${i}".jpg ${i}
            done
            # Grabing each image results and determine pass or fail.
            for (( i=1; i<$totalFiles; i++ )); do
                json=$(cat "results${i}.json")
                percent=$(jsonval)
                percent=${percent%.*}
                if [[ $percent -lt "1" ]]; then                    
                    rm "diff${i}.png"
                    rm "results${i}.json"
                else
                    echo "$f percentage is: $percent"
                fi
            done
            name="diff*.png"
            ls -l $name > /dev/null
 
            if [ "$?" -eq "0" ]
            then
                echo "$f,Fail" >> $root/output.csv
            else
                echo "$f,Pass" >> $root/output.csv
            fi
            cd ..
        else
            echo "Size of the video is not the same for ${f}-prod.mp4: $size4Prod and for ${f}-qa.mp4: $size4Qa"
            #echo "Size of the video is not the same for ${f}-prod.mp4: $size4Prod and for ${f}-dev.mp4: $size4Qa"
        fi
    done
}

# Global Variables


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
