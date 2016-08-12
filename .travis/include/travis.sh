alias travis_id='openssl \
		rand \
		-hex 4 \
';

alias travis_time='date \
	"+%s%N" \
';

travis_time_start () {
	local _TRAVIS_TIMER_ID="${1}";
	echo \
		-n \
		"travis_time:start:${_TRAVIS_TIMER_ID}\r" \
	;
	return 0;
}

travis_time_end () {
	local _TRAVIS_TIMER_ID="${1}";
	local _TRAVIS_TIMER_START="${2}";
	local _TRAVIS_TIMER_FINISH="${3}";
	local _TRAVIS_TIMER_DURATION="$(echo \
		"${_TRAVIS_TIMER_FINISH}" - "${_TRAVIS_TIMER_START}" \
	| bc \
	;)";
	echo \
		-n \
		"travis_time:end:${_TRAVIS_TIMER_ID}:start=${_TRAVIS_TIMER_START},finish=${_TRAVIS_TIMER_FINISH},duration=${_TRAVIS_TIMER_DURATION}\r" \
	;
	return 0;
}

travis_fold_start () {
	local _TRAVIS_FOLD_ID="${1}";
	echo \
		-n \
		"travis_fold:start:${_TRAVIS_FOLD_ID}\r" \
	;
	return 0;
}

travis_fold_end () {
	local _TRAVIS_FOLD_ID="${1}";
	echo \
		-n \
		"travis_fold:end:${_TRAVIS_FOLD_ID}\r" \
	;
	return 0;
}

travis_block_start () {
	local _TRAVIS_BLOCK_NAME="${1}";
	local _TRAVIS_BLOCK_ID="${2}";
	{
		travis_fold_start \
			"${_TRAVIS_BLOCK_NAME}" \
		;
		travis_time_start \
			"${_TRAVIS_BLOCK_ID}" \
		;
	} \
		2>/dev/null \
	;
	return 0;
}

travis_block_end () {
	local _TRAVIS_BLOCK_NAME="${1}";
	local _TRAVIS_BLOCK_ID="${2}";
	local _TRAVIS_BLOCK_START="${3}";
	local _TRAVIS_BLOCK_END="$(travis_time;)";
	{
		travis_time_end \
			"${_TRAVIS_BLOCK_ID}" \
			"${_TRAVIS_BLOCK_START}" \
			"${_TRAVIS_BLOCK_END}" \
		;
		travis_fold_end \
			"${_TRAVIS_BLOCK_NAME}" \
		;
	} \
		2>/dev/null \
	;
	return 0;
}

travis_block_wrap () {
	local _TRAVIS_BLOCK_NAME="${1}";
	shift 1;
	local _TRAVIS_BLOCK_ID="$(travis_id;)";
	local _TRAVIS_BLOCK_START="$(travis_time;)";
	travis_block_start \
		"${_TRAVIS_BLOCK_NAME}" \
		"${_TRAVIS_BLOCK_ID}" \
		"${_TRAVIS_BLOCK_START}" \
	;
	local _EXIT_STATUS=0;
	if ! "${@}" \
	;
	then
		_EXIT_STATUS=1;
	fi
	local _TRAVIS_BLOCK_FINISH="$(travis_time;)";
	travis_block_end \
		"${_TRAVIS_BLOCK_NAME}" \
		"${_TRAVIS_BLOCK_ID}" \
		"${_TRAVIS_BLOCK_START}" \
		"${_TRAVIS_BLOCK_FINISH}" \
	;
	return "${_EXIT_STATUS}";
}
