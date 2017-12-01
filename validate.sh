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

function is_cf_yml_template() {
	OUTPUT=$(head -n 1 $1 | cut -d\: -f1)
	RESULT=0
	if [[ "$OUTPUT" == "AWSTemplateFormatVersion" ]]; then
		VERSION=$(head -n 1 $1 | cut -d\" -f2)
		echo Found: $1 - YML CFN Template v$VERSION
	else
		echo SKIPPED: $1 not YML CFN Template
		RESULT=1
	fi
	return $RESULT
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
if find . -name '*.json' | xargs grep -nE '( {2,}| [:,]|["}][:,]["{]|\s+$)' 1>&2; then
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

for fn in $(find . -name '*.json'); do
	if is_cf_template $fn; then
		is_valid_cf $fn
		sleep 0.5
	fi
done

for fn in $(find . -name '*.yml'); do
	if is_cf_yml_template $fn; then
		is_valid_cf $fn
		sleep 0.5
	fi
done

for fn in $(find . -name '*.yaml'); do
	if is_cf_yml_template $fn; then
		is_valid_cf $fn
		sleep 0.5
	fi
done

exit $ALL_EXIT
