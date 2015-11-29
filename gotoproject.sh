go_to_project() {
	local query="${1,,}"
	local quality_A="$query"
	local quality_B="[\\b/_-.]$query[\\b/_-.]"
	local quality_C="[\\b/]$query[\\b/]"
	local quality_D="^$query$"
	local debug_info=""
	local res_quality=0

	local fuzzy_match=
	for (( i=0; i<${#query}; i++ )); do
		fuzzy_match="${fuzzy_match}([^/]*)${query:$i:1}"
	done
	[[ $DEBUG > 0 ]] && echo "Fuzzy match: $fuzzy_match" && echo "----------------------------------"

	export go_to_project_res_dir="."
	while read dir; do
		# Remove the timestamp prefix: "1382563122 /a/b/c" -> "/a/b/c"
		dir="${dir:11}"
		dir=${dir,,}

		# For empty query, just go to the most recent project
		if [[ -z "$query" ]]; then
			[[ $DEBUG > 0 ]] && "Empty query, picking the last changed dir (first provided)"
			export go_to_project_res_dir="$dir"
			break
		fi

		debug_info=""

		local file_name="${dir:$_GO_TO_PROJECT_FILE_NAME_CUTOFF_LENGTH}"
		file_name=${file_name,,}
		
		local quality=0

		if [[ $file_name =~ $quality_A ]]; then 
			quality=$((100))
			debug_info="${debug_info}[A->$quality]"
		fi

		if [[ $file_name =~ $quality_B ]]; then 
			quality=$((103))
			debug_info="${debug_info}[B->$quality]"
		fi

		if [[ $file_name =~ $quality_C ]]; then
			quality=$((107))
			debug_info="${debug_info}[C->$quality]"
		fi

		if [[ $file_name =~ $quality_D ]]; then
			quality=$((110))
			debug_info="${debug_info}[D->$quality]"
		fi
		
		# Fuzzy search if no direct match was found
		if [[ $quality -le 0 ]] && [[ $file_name =~ $fuzzy_match ]]; then
			local middle_words="${BASH_REMATCH[@]:1}"
			quality=$(expr 100 - ${#middle_words})
			debug_info="${debug_info}[FUZZY:${middle_words}(${#middle_words})->$quality]"
		fi

		# Give a little boost to git repositories
		if [[ -d "$dir/.git" ]] && [[ $quality -gt 0 ]]; then
			quality=$(expr $quality + 11)
			debug_info="${debug_info}[GIT->$quality]"
		fi

		[[ $DEBUG > 0 ]] && printf "%-60s | %-30s | %s\n" "$dir" "$debug_info" "$quality"
		
		# If better quality than existing, replace
		if [[ $quality -gt $res_quality ]]; then
			res_quality="$quality"
			export go_to_project_res_dir="$dir"
		fi
	done < <(find $GO_TO_PROJECT_ROOT -maxdepth $GO_TO_PROJECT_DEPTH -type d -exec stat -c '%Y %n' '{}' + | sort -gr)

	[[ $DEBUG > 0 ]] && echo "----------------------------------" && echo "Destination: $go_to_project_res_dir"
	cd "$go_to_project_res_dir"
}
