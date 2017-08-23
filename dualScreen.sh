#!/bin/bash

# Script with the good parameters to set a dualscreen with a HiDPI main screen
# with xrandr with this resolution 3200x1800 

# The following options are available : above, left-of and right-of
# The resolution can be set also

# Usage function
function usage(){
    echo -e "Usage : $0 [options]"
    echo -e "\nOptions :"
    echo -e "\t-p <above,left,right>\tSet the position of the second screen. Default : right"
    echo -e "\t-r <resolution>\t\tSet the resolution of the second screen. Default : 1920x1080"
    echo -e "\nResolutions available for $output:"
    echo -e "$res_available"
    exit 1
}

# Check if the resolution is available from the start
# $1 contains the resolution given in argument
function check_resolution(){
    for res in ${res_available[@]}
    do
	if [ $1 == $res ]; then
	    return 1
	fi
    done
    return 0
}

# Name of the screens
main=eDP1
output=HDMI1

# This variable contains all the resolutions available for the output 
res_available="$(xrandr | grep -A 15 $output |  egrep '\s[0-9]+x[0-9]+\s' | awk '{print $1}')"

# Default parameters
position="right"
resolution="1920x1080"
scale=2

#Size of the main screen 
width_s1=3200
height_s1=1800

# Size by default of the second screen
width_s2=1920
height_s2=1080


# Check options
while getopts ":p:r:h" opt; do
    case $opt in
	h)
	    usage
	    exit 1
	    ;;
	p)
	    if [ "$OPTARG" != "right" ] &&
	       [ "$OPTARG" != "left" ] &&
	       [ "$OPTARG" != "above" ]; then
		echo "Wrong argument : $OPTARG"
		usage
	    else
		position="$OPTARG"
	    fi
	    ;;
	r)
	    if [[ "$OPTARG" =~ ([0-9]{3,})x([0-9]{3,}) && $(check_resolution $OPTARG; echo $?) -eq 1 ]]; then
		resolution=$OPTARG
		width=${BASH_REMATCH[1]}
		height=${BASH_REMATCH[2]}
	    else
		echo "Wrong resolution : $OPTARG"
		usage
	    fi
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG"
	    usage
	    ;;
	:)
	    echo "Missing arg after -$OPTARG"
	    usage
	    ;;
    esac
done

# Right
if [ $position == "right" ]; then
    painning="$(( $width_s2 * $scale ))x$(( $height_s2 * $scale))+$width_s1+0"
    echo "xrandr --output eDP1 --auto --output  HDMI1 --auto --panning $painning --scale ${scale}x$scale --right-of eDP1"
    xrandr --output $main --auto --output $output --auto --panning $painning --scale ${scale}x$scale --right-of $main

# Left
elif [ $position == "left" ]; then
    fb="$(( $width_s2 * $scale + $width_s1 ))x$(( $height * $scale ))"
    echo "xrandr --output HDMI1 --scale ${scale}x$scale --auto --pos 0x0 --output eDP1 --auto --pos 3840x0 --fb $fb"
    xrandr --output $output --scale ${scale}x$scale --auto --pos 0x0 --output $main --auto --pos 3840x0 --fb $fb

# Above
else
    max_width=$(( $width_s1 > $width_s2 * $scale ? $width_s1 : $width_s2 * $scale ))
    fb="${max_width}x$(( $height_s1 + $height_s2 * $scale))"
    echo "xrandr --output eDP1 --auto --pos 0x$(( $height_s2 * $scale)) --output HDMI1 --scale ${scale}x$scale --auto --pos 0x0 --fb $fb"
    xrandr --output $main --auto --pos 0x$(( $height_s2 * $scale)) --output $output --scale ${scale}x$scale --auto --pos 0x0 --fb $fb
fi
