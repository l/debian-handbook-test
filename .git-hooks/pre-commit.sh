#!/bin/sh
set -x;
set -eu;

alias _file_get_type='file \
	--brief \
	--mime-type \
';

alias _file_validate_xml='xmllint \
	--noout \
';

alias _file_reformat_xml='xmllint \
	--pretty 2 \
	--output \
';

alias git_cached_files_get='git \
	diff \
	--name-only \
	--cached \
';

alias git_add='git \
	add \
';

git_cached_files_update () {
	local _FILE_PATH='';

	for _FILE_PATH in $(git_cached_files_get;);
	do
		case "${_FILE_PATH}" in
			*.html)
				case "$(_file_get_type \
					"${_FILE_PATH}" \
				;)" in
					'application/xml'|'text/xml')
						_file_validate_xml \
							"${_FILE_PATH}" \
						;
						_file_reformat_xml \
							"${_FILE_PATH}" \
							"${_FILE_PATH}" \
						;
						git_add \
							"${_FILE_PATH}" \
						;
					;;
				esac
			;;
		esac
	done

	return 0;
}

main () {
	git_cached_files_update \
		"${@}" \
	;

	return 0;
}

main \
	"${@}" \
;

exit 0;
