#!/usr/bin/bash


# Workflow > Protocol > Step(Process)(Stage)
# enter the workflow protocol or step that you changed to get a list of everything it affects
# -w workflow -p protocol -s step 

while [[ $# > 0 ]] #number of arguments passed through cmd line
do
key="$1"

case $key in #check key agains this list of options
	-w|--workflow)
	WORKFLOW="$2"
	shift # passes the argument
	;;
	-p|--protocol)
	PROTOCOL="$2"
	shift
	;;
	-s|--step)
	STEP="$2"
	shift
	;;
	-v | --verbose) #Will print a comman seperated list of 2 degree seperation from query
	VERB="TRUE"
	shift
	;;
	-t | --tree) #Will print out all workflows
	TREE="TRUE"
	;;
	-h|--help)
	echo "Structure command as: bash findRelated.sh -w \"workflow\" OR -p \"protocol\" OR -s \"step\" OR -t \"tree\" OR -v \"verbose\""
	shift
	;;
esac
shift #If the arg didnt' match any of the above, then it's skipped?
done

# Build a list of workflows
# $1 = name of a protocol
# #2 = if present prints as a comma seprated list, if not, prints normal

function buildWorkflows () {
	local RAW=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/workflows | grep "<workflow status=\"ACTIVE\"")
	
	if [ -z "$2" ]; then
		echo " "
		echo "The Workflows that this Protocol is a part of is/are:"
	fi
	
	while read -r line; do
		## Go to URL
		local url=$(echo "$line" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
		local name=$(echo "$line" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		#echo "$url"
		hit=$(curl -s --user admin:'Pgdx!01' "$url" | grep "$1" )
		if [ -n "$hit" ]; then
			if [ -z "$2" ]; then
				echo -e "$name \t\t $url"
			else
				echo -e -n "$name, "
			fi
			#echo "$hit"
		fi
	done <<< "$RAW"
}

# Build an array a list of protcols
# $1 = name of a step
function buildProtocols () {
	local RAW=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/protocols | grep "<protocol uri=")
	
	echo ""
	echo "The Protocols that this Step is a part of is/are:"
	while read -r line; do
		## Go to URL
		local url=$(echo "$line" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
		local name=$(echo "$line" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		#echo "$url"
		hit=$(curl -s --user admin:'Pgdx!01' "$url" | grep "$1" )
		if [ -n "$hit" ]; then
			echo -e "$name \t\t $url"
			#echo "$hit"
		fi
	done <<< "$RAW"
	
}

#Build the list of protocols that go with the step, but also show workdflows associated with those protocols
function buildProtocolsVerby () {
	local RAW=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/protocols | grep "<protocol uri=")
	
	echo " "
	echo "The Protocols that this Step ($STEP) is a part of is/are: (Protocol/URL/WorkflowsAssociatedWithProtocol)"
	while read -r line; do
		## Go to URL
		local url=$(echo "$line" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
		local name=$(echo "$line" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		#echo "$url"
		hit=$(curl -s --user admin:'Pgdx!01' "$url" | grep "$1" )
		if [ -n "$hit" ]; then
			local relations=$(buildWorkflows $name "true")
			echo -e "$name \t\t $url \t\t $relations"
			#echo "$hit"
		fi
	done <<< "$RAW"
	
}

# $1 = a list of all the protocols
function buildWorkflowDownVerby () {
		#ONLY PULLS ACTIVE WORKFLOWS
		local RAW=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/protocols | grep "<protocol uri=")
		echo " "
		#echo "The Protocols that are a part of this Workflow ($WORKFLOW):(Protocol/url/stepAssociatedWithProtocol)"
		echo -e "Workflow \t Protocol \t Step"
		echo "$2"
		while read -r line; do
 
			#url and name of one Protocol line
			local url=$(echo "$line" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
			local name=$(echo "$line" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
			#test each of the protocols in the $1 list of protocols against one line of RAW 
			while read -r line2; do

				if [ "$line2" = "$name" ]; then
					#removed > here
					echo -e "\t$name"
						local protocolURL=$(curl -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/protocols | tail -r | tail -r| grep "$name" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
						#echo "The steps associated with this protocol ($PROTOCOL) are:"
						#Removed: | sed -e 's/^/>>/'| 
						curl -s --user admin:'Pgdx!01' $protocolURL | grep "step protocol-uri" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g' | sed -e 's/^/		/'
				fi
			done <<< "$1"

		done <<< "$RAW"
}
		#echo "The steps associated with this protocol ($PROTOCOL) are:"
		#curl -s --user admin:'Pgdx!01' $PURL | grep "step protocol-uri" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g'

function trees () {
		
	local RAW=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/workflows | grep "<workflow status=\"ACTIVE\"")
	
	echo ""
	echo "The Current view of Clarity LIMS is:"
	while read -r line; do
		## Go to URL
		local url=$(echo "$line" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
		local name=$(echo "$line" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		
		local metaProtNames=$(curl  -s --user admin:'Pgdx!01' $url | grep "<protocol" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		
		buildWorkflowDownVerby "$metaProtNames" "$name"
		##echo "$url"
		#hit=$(curl -s --user admin:'Pgdx!01' "$url" | grep "$1" )
		#if [ -n "$hit" ]; then
			#echo -e "$name \t\t $url"
			##echo "$hit"
		#fi
	done <<< "$RAW"
	
}


if [ -n "$PROTOCOL" ]; then	
	
	#Determine steps associated witht this protocol 
	PURL=$(curl -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/protocols | tail -r | tail -r| grep "$PROTOCOL" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')
	echo "The steps associated with this protocol ($PROTOCOL) are:"
	curl -s --user admin:'Pgdx!01' "$PURL" | grep "step protocol-uri" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g'
	echo "The URL for this protocol is: $PURL"	
	
	#dermine the workflows this protocol is a part of
	echo ""
	echo "Determining Workflows..."
	buildWorkflows "$PROTOCOL"
 
fi
	
if [ -n "$WORKFLOW" ]; then
	#Determine Protocols associated witht this workflow
	WURL=$(curl  -s --user admin:'Pgdx!01' https://pgdx-lims-devel/api/v2/configuration/workflows | tail -r | tail -r | grep "$WORKFLOW" | grep -o '"http.*"' | sed 's/"//g' | grep -o '^\S*')

		echo "The protocols associated with this workflow ($WORKFLOW) are:"
		protNames=$(curl  -s --user admin:'Pgdx!01' $WURL | grep "<protocol" | grep -o "name=\".*" | grep -o "\".*\"" | sed 's/"//g')
		if [ -z "$VERB" ]; then
			echo "$protNames"
			echo "The URL for this Workflow is: $WURL"
		else
			echo "Determining Protocols and thier relations..."
			buildWorkflowDownVerby "$protNames" "$WORKFLOW"
			
			echo "The URL for this Workflow is: $WURL"
		fi 
	#buildWorkflows
	
fi



if [ -n "$STEP" ]; then

	if [ -n "$VERB" ]; then
	
		echo "words words words"
		echo "Determining Protocols and their relations..."
		buildProtocolsVerby "$STEP"
	
	else
	
		# go through every protocol, look for the step, record it if it's found
		echo "Determining Protocols..."
		buildProtocols "$STEP"
		
	fi
	
	
fi

if [ -n "$TREE" ]; then
#ONLY PRINTS ACTIVE WORKFLOWS

			trees

fi


# Notes: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
