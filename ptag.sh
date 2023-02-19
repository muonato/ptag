#!/bin/bash
# muonato/ptag @ GitHub (27-JAN-2022)
#
# Bash script for text overlay on graphics images
#
# Using dialog where installed (e.g. 'apt info dialog')
# otherwise, prompts for input as follows:
#
#       Source: <path to graphics file or directory>
#       Id Tag: <identification tag for the file>
#       Coords: <location where created>
#       Author: <copyright owner>
#       Target: <path to target directory>
#
# Input parameters are recycled to/from 'ptag.dat' file
# Requires 'convert' from the ImageMagick suite
#
DIR=$(dirname $0)       # script root directory
WIN="/DCIM/100OLYMP"    # windows source folder

# Determine suitable pointsize for watermark font
fn_fontpts() {
    local path=$1
    echo $(identify -format '%w' $path|awk '{print int($1/72+0.5)}')
}

# Print datetime of creation for given file
fn_filetime() {
    local path=$1
    echo $(stat -c %Y ${path} | awk '{print strftime("%d.%m.%Y %H:%M", $path)}')
}

# Identify graphics type for given file
fn_isimage() {
    local path=$1
    echo $(file $path | grep -o -P "^.+: \w+ image")
}

# Windows drive letter to images sub-folder
fn_wslmnt() {
    sudo mount -t drvfs $1 $DIR/images

    if [[ $? -eq 0 ]]; then
        echo "${DIR}/images"$WIN
    else
        echo ""
    fi
}

fn_dialog() {
    exec 3>&1
    PARM=$(dialog --title "PICTURE TAG" --form "Fill in tag description below" 15 80 0 \
        "Source:"  1 1 "$SRC" 1 8 80 0 \
        "Id Tag:"  2 1 "$TAG" 2 8 80 0 \
        "Coords:"  3 1 "$LOC" 3 8 80 0 \
        "Author:"  4 1 "$USR" 4 8 80 0 \
        "Target:"  5 1 "$TGT" 5 8 80 0 2>&1 1>&3)
    RET=$? # Read dialog button return value
    clear

    exec 3>&-

    # Abort when user cancelled dialog
    if [[ $RET -gt 0 ]]; then exit; fi

    # Assign variables from dialog form fields
    IFS=$'\n'   # Internal Field Separator
    read -r -d '' SRC TAG LOC USR TGT <<< "$PARM"
}

# BEGIN __main__

if [[ -n $(convert -version|grep -o "ImageMagick") ]]; then
    IFS=$'\n' # Read previous values from history file
    read -r -d '' SRC TAG LOC USR TGT < $DIR/ptag.dat
else
    echo "ImageMagick is missing but required, sorry."
    exit
fi

if [[ -n $1 ]]; then
    # Set source to W10 drive letter and path if supplied
    SRC=$(fn_wslmnt $1)
fi

if [[ -n $(which dialog) ]]; then
    # Read input arguments using dialog (where installed)
    fn_dialog
else
    IFS=$" " # Read input arguments using terminal prompt
    read -p "Source [$SRC]: " ARG1
    read -p "Tag Id [$TAG]: " ARG2
    read -p "Coords [$LOC]: " ARG3
    read -p "Author [$USR]: " ARG4
    read -p "Target [$TGT]: " ARG5

    SRC=${ARG1:-$SRC}   # source file or dir
    TAG=${ARG2:-$TAG}   # tag id
    LOC=${ARG3:-$LOC}   # coords / address
    USR=${ARG4:-$USR}   # author id
    TGT=${ARG5:-$TGT}   # target file folder
fi

# Write parameters to history file
cat <<- _EOF_ > $DIR/ptag.dat
    $SRC
    $TAG
    $LOC
    $USR
    $TGT
_EOF_

if [[ ! -d $TGT ]]; then
    echo "Missing valid path to target folder"
    exit
fi

if [[ -d $SRC ]]; then
    # Add wildcard when source given as folder
    SRC="${SRC%/}/*"
fi

for f in $SRC; do # Add watermark text to image(s)
    OK="Y"

    # Strip trailing slash + add 'pic-' to filename
    IMG=${TGT%/}/ptag-${f##*/}
    if [[ -f $IMG ]]; then
        read -p "Overwrite $IMG ? [Y/n]: " OK
    fi

    # Skip convert if not an image or target exists
    if [[ -n $(fn_isimage $f) && $OK == "Y" ]]; then
        echo "Tagging $IMG"
        convert $f \
            -background "#FFFFFF88" \
            -size $(identify -format '%w' $f)x$(fn_fontpts $f) \
            -pointsize $(fn_fontpts $f) \
            -fill "#00000088" \
            -gravity south \
            label:"$TAG  $LOC $(fn_filetime $f)  $USR" \
            -composite \
            $IMG 
    else
        echo "Skipped $f"
    fi
done

# END __main__
