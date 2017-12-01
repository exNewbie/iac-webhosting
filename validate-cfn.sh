#! /bin/bash


function usage() {
	echo -e "Usage: $(basename "$0") [-h] -f JSONFILE\n"
	echo "Invokes the AWS cloudformation validate-template on the JSONFILE"
	echo "	-f: The stack definition JSON file."
	echo "	-h: Display this help message."
}

while getopts "hf:" option; do
	case $option in
		h)
			usage
			exit 0
			;;
		f)
			FILE_NAME="$OPTARG"
			;;
		*)
			usage
			exit 1
			;;
	esac
done

if [ -z "$FILE_NAME" ]; then
	echo "JSONFILE is mandatory and must be set."
	usage
	exit 2
fi

if [ ! -e "$FILE_NAME" ]; then
	echo "${FILE_NAME} must exist."
	usage
	exit 3
fi

echo aws cloudformation validate-template --template-body file://${FILE_NAME}
aws cloudformation validate-template --template-body file://${FILE_NAME}