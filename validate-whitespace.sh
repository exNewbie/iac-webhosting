#!/bin/bash
ALL_EXIT=0

function is_cf_template() {
	output=$(jq -e -r '.AWSTemplateFormatVersion' $1)
	result=$?
	case $result in
		4) # json parse error
			>&2 echo ERROR: $1 - json parse failed
			let "ALL_EXIT |= $result"
			;;
		1) # null -> not CF
			echo SKIPPED: $1 - not CF template
			;;
		0) # CF template
			echo FOUND: $1 - CF v$output
	esac
	return $result
}

function is_valid_cf() {
	[[ -n $1 ]] || return
	{
		aws cloudformation validate-template --template-body file://$1 >/dev/null && \
		echo VALID: $1
	} || {
		>&2 echo ERROR: $1 - CF validation failed
		let 'ALL_EXIT |= 1'
	}
}


# Primitive whitespace style check
#
# ' {2, }' 		Tabs not spaces
# ' [:,]' 		No space before ':' or ','
# '["}][:,]["{]'	Space after ':' or ',' when separating elements
# '\s+$' 		No trailing whitespace
#
if find . -name '*.json' | xargs grep -nE '(^ {2,}| [:,]|["}][:,]["{]|\s+$)' 1>&2; then
	let 'ALL_EXIT |= 1'
	>&2 cat <<-EOF
	ERROR: Incorrect whitespace detected, see errors above. Check:
	* Tabs not spaces
	* No space before ':' or ','
	* Space after ':' or ',' when separating elements
	* No trailing whitespace
	EOF
fi
# Auto fix for last 3 violations:
# sed -i ''
# 	-e 's/ \([:,]\)/\1/g'
#	-e 's/\(["}]\)\([:,]\)\(["{]\)/\1\2 \3/g'
# 	-e 's/[[:blank:]]*$//g'
# TODO: turn above into an autofixer (eg: -a argument)

exit

for fn in $(find . -name '*.json'); do
	if is_cf_template $fn; then
		is_valid_cf $fn
	fi
done

exit $ALL_EXIT
