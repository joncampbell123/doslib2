#!/bin/bash
#
# Rename all files in the current directory to lowercase.
# Jonathan Campbell
tolower() {
	l=`echo "$1" | tr [A-Z] [a-z]`
	if [[ x"$l" != x"$1" ]]; then
		mv -vn "$1" "$l" || return 1
	fi

	return 0
}

# NTS: The '.' is required in case we are run under OS X Darwin,
#      while GNU/Linux versions of 'find' don't require it.
find | while read X; do tolower "$X" || break; done

