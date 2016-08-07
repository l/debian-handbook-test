#!/bin/sh
set -x;
set -eu;

configure_apt () {
	export DEBIAN_FRONTEND=noninteractive;
	export DEBCONF_NONINTERACTIVE_SEEN=true;
	return 0;
}

configure_locale () {
	export LC_ALL=C;
	export LANGUAGE=C;
	export LANG=C;
	return 0;
}

configure_timezone () {
	export TZ=GMT;
	return 0;
}

configure_chroot () {
	readonly CHROOT_USER="${1:-root}";
	readonly CHROOT_GROUP="${2:-root}";
	readonly CHROOT_POOL_DIR="${HOME}/chroot";
	readonly CHROOT_SUITE='unstable';
	readonly CHROOT_ARCH='amd64';
	readonly CHROOT_INFO='build';
	readonly CHROOT_VARIANT='minbase';
	readonly CHROOT_ID="${CHROOT_SUITE}_${CHROOT_ARCH}_${CHROOT_INFO}";
	readonly CHROOT_DIR="${CHROOT_POOL_DIR}/${CHROOT_ID}";
	readonly CHROOT_MIRROR='http://deb.debian.org/debian';
	return 0;
}

configure_identity () {
	readonly CURRENT_USER="$(id \
		--user \
		--name \
	;)";
	readonly CURRENT_GROUP="$(id \
		--group \
		--name \
		 "${CURRENT_USER}" \
	;)";
	readonly CURRENT_HOST="$(hostname \
	;)";
	return 0;
}

configure_publican () {
	readonly _PUBLICAN_SURNAME="AYANOKOUZI";
	readonly _PUBLICAN_FIRSTNAME="Ryuunosuke";
	readonly _PUBLICAN_EMAIL="i38w7i3@yahoo.co.jp";
	return 0;
}

configure_git () {
	export GIT_AUTHOR_NAME="AYANOKOUZI, Ryuunosuke";
	export GIT_AUTHOR_EMAIL="i38w7i3@yahoo.co.jp";
	export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}";
	export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL}";
	return 0;
}

configure_git_repository () {
	readonly _GIT_REMOTE_ORIGIN_NAME='origin';
	readonly _GIT_REMOTE_ORIGIN_FETCH='git://anonscm.debian.org/debian-handbook/debian-handbook.git';
	readonly _GIT_REMOTE_ORIGIN_PUSH="${_GIT_REMOTE_ORIGIN_FETCH}";
	readonly _GIT_REMOTE_ORIGIN_BRANCH='jessie/master';
	readonly _GIT_LOCAL_ORIGIN_BRANCH="${_GIT_REMOTE_ORIGIN_BRANCH}/translation/${_GIT_REMOTE_ORIGIN_NAME}";

	readonly _GIT_REMOTE_WEBLATE_NAME='weblate';
	readonly _GIT_REMOTE_WEBLATE_FETCH='git://git.weblate.org/debian-handbook.git';
	readonly _GIT_REMOTE_WEBLATE_PUSH="${_GIT_REMOTE_WEBLATE_FETCH}";
	readonly _GIT_REMOTE_WEBLATE_BRANCH='jessie/master';
	readonly _GIT_LOCAL_WEBLATE_BRANCH="${_GIT_REMOTE_WEBLATE_BRANCH}/translation/${_GIT_REMOTE_WEBLATE_NAME}";
	readonly _GIT_LOCAL_BUILD_BRANCH="jessie/master/build";

	readonly _GIT_REMOTE_TWEEK_NAME='tweek';
	readonly _GIT_REMOTE_TWEEK_FETCH='https://github.com/l/debian-handbook.git';
	readonly _GIT_REMOTE_TWEEK_PUSH="${_GIT_REMOTE_TWEEK_FETCH}";
	readonly _GIT_REMOTE_TWEEK_BRANCH_0='jessie/master/proposal/put_backcover_and_website_as_appendix';
	readonly _GIT_LOCAL_TWEEK_BRANCH_0="${_GIT_REMOTE_TWEEK_BRANCH_0}";
	readonly _GIT_REMOTE_TWEEK_BRANCH_1='jessie/master/proposal/stop_runtime_dependent_id_generation';
	readonly _GIT_LOCAL_TWEEK_BRANCH_1="${_GIT_REMOTE_TWEEK_BRANCH_1}";

	readonly _GIT_REMOTE_GITHUB_KEY="${HOME}/.ssh/deploy_key";
	readonly _GIT_REMOTE_GITHUB_NAME='github';
	readonly _GIT_REMOTE_GITHUB_FETCH='https://github.com/l/debian-handbook-test.git';
	readonly _GIT_REMOTE_GITHUB_PUSH='git@github.com:l/debian-handbook-test.git';
	readonly _GIT_REMOTE_GITHUB_BRANCH='gh-pages';
	readonly _GIT_LOCAL_GITHUB_BRANCH="jessie/master/${_GIT_REMOTE_GITHUB_BRANCH}";

	return 0;
}

mktemp_wrapper () {
	local _MODE="${1}";
	local _MKTEMP_TEMPLATE="${HOME}/tmp/${2}";
	local _MKTEMP_OPTS='';
	mkdir \
		--parent \
		"$(dirname \
			"${_MKTEMP_TEMPLATE}" \
		;)" \
	;
	case "${_MODE}" in
		'directory')
			_MKTEMP_OPTS="${_MKTEMP_OPTS} --directory";
		;;
		'file')
			_MKTEMP_OPTS="${_MKTEMP_OPTS}";
		;;
		*)
			return 1;
		;;
	esac;
	mktemp \
		${_MKTEMP_OPTS} \
		"${_MKTEMP_TEMPLATE}" \
	;
	return 0;
}

mktemp_file () {
	local _MKTEMP_TEMPLATE="${1}";
	mktemp_wrapper \
		'file' \
		"${_MKTEMP_TEMPLATE}" \
	;
	return 0;
}

mktemp_directory () {
	local _MKTEMP_TEMPLATE="${1}";
	mktemp_wrapper \
		'directory' \
		"${_MKTEMP_TEMPLATE}" \
	;
	return 0;
}

travis_id () {
	openssl \
		rand \
		-hex 4 \
	;
	return 0;
}

travis_time () {
	date \
		'+%s%N' \
	;
	return 0;
}

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

systems_host_setup_pre () {
	configure_apt;
	configure_locale;
	configure_timezone;
	configure_identity;
	return 0;
}

systems_host_setup () {
	systems_host_setup_pre \
		"${@}" \
	;
	if test "root" != "${CURRENT_USER}" ;
	then
		return 1;
	fi
	service \
		--status-all \
	;
	{
	cat << 'EOT'
#!/bin/dash
{
	set -eux;
	if expr \
		"${1}" : "postgresql.*" \
	;
	then
		service \
			postgresql \
			stop \
		;
	fi
	exit 0;
} \
	1>&2 \
;
EOT
	} | tee \
		'/usr/sbin/policy-rc.d' \
	;
	chmod \
		'a+x' \
		'/usr/sbin/policy-rc.d' \
	;
	{
	cat << 'EOT'
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOT
	} | tee \
		'/etc/apt/apt.conf.d/01norecommend' \
	;
	{
	cat << 'EOT'
DPkg::options { "--force-confdef"; "--force-confnew"; }
EOT
	} | tee \
		'/etc/apt/apt.conf.d/02force-conf' \
	;
	apt_get_install_pre;
	apt_get_install \
		debian-keyring \
		debian-archive-keyring \
		debootstrap \
		schroot \
	;
	apt_get_install_post;
	return 0;
}

systems_host_mkimage_pre () {
	configure_apt;
	configure_locale;
	configure_timezone;
	configure_identity;
	configure_chroot \
		"${@}" \
	;
	return 0;
}

systems_host_mkimage () {
	systems_host_mkimage_pre \
		"${@}" \
	;
	if test "root" != "${CURRENT_USER}" ;
	then
		return 1;
	fi
	mkdir \
		--parent \
		"$(dirname "${CHROOT_DIR}")" \
	;
	{
	cat << EOT
[${CHROOT_ID}]
description=Debian ${CHROOT_SUITE} ${CHROOT_ARCH} for ${CHROOT_INFO} (${CHROOT_VARIANT})
type=directory
directory=${CHROOT_DIR}
users=${CHROOT_USER}
groups=${CHROOT_GROUP}
root-groups=root
EOT
	} | tee \
		"/etc/schroot/chroot.d/${CHROOT_ID}.conf" \
	;
	schroot \
		--chroot="${CHROOT_ID}" \
		--info \
	;
	if true;
	then
		debootstrap \
			--verbose \
			--arch="${CHROOT_ARCH}" \
			--variant="${CHROOT_VARIANT}" \
			"${CHROOT_SUITE}" \
			"${CHROOT_DIR}" \
			"${CHROOT_MIRROR}" \
		;
	else
		debootstrap \
			--verbose \
			--foreign \
			--arch="${CHROOT_ARCH}" \
			--variant="${CHROOT_VARIANT}" \
			"${CHROOT_SUITE}" \
			"${CHROOT_DIR}" \
			"${CHROOT_MIRROR}" \
		;
		schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			/debootstrap/debootstrap \
			--verbose \
			--second-stage \
		;
		{
		cat << EOT
deb ${CHROOT_MIRROR} ${CHROOT_SUITE} main
EOT
		} | tee \
			"${CHROOT_DIR}/etc/apt/sources.list.d/01${CHROOT_SUITE}.list" \
		;
	fi
	{
	cat << 'EOT'
#!/bin/dash
{
	set -eux;
	exit 101;
} \
	1>&2 \
;
EOT
	} | tee \
		"${CHROOT_DIR}/usr/sbin/policy-rc.d" \
	;
	chmod \
		'a+x' \
		"${CHROOT_DIR}/usr/sbin/policy-rc.d" \
	;
	{
	cat << 'EOT'
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOT
	} | tee \
		"${CHROOT_DIR}/etc/apt/apt.conf.d/01norecommend" \
	;
	{
	cat << 'EOT'
DPkg::options { "--force-confdef"; "--force-confnew"; }
EOT
	} | tee \
		"${CHROOT_DIR}/etc/apt/apt.conf.d/02force-conf" \
	;
	return 0;
}

apt_get_install_pre () {
	echo cat \
		'/etc/debian_version' \
	;
	apt-config \
		dump \
	| grep \
		--regexp='APT::Install-' \
		--regexp='DPkg::options' \
	;
	apt-cache \
		policy \
	;
	if ! apt-key \
		list \
	;
	then
		echo "INFO: ${?}: apt-key: error";
	fi
	apt-get \
		update \
	;
	apt-get \
		--assume-yes \
		upgrade \
	;
	apt-get \
		--assume-yes \
		dist-upgrade \
	;
	return 0;
}

apt_get_install_post () {
	apt-get \
		--assume-yes \
		upgrade \
	;
	apt-get \
		--assume-yes \
		autoremove \
	;
	apt-get \
		clean \
	;
	return 0;
}

apt_get_install () {
	apt_get_install_pre;
	apt-get \
		--assume-yes \
		install \
		"${@}" \
	;
	apt_get_install_post;
	return 0;
}

systems_build_setup_pre () {
	configure_apt;
	configure_locale;
	configure_timezone;
	configure_identity;
	return 0;
}

systems_build_setup () {
	systems_build_setup_pre \
		"${@}" \
	;
	if test "root" != "${CURRENT_USER}" ;
	then
		return 1;
	fi
	apt_get_install \
		git \
		publican \
		publican-debian \
		openssh-client \
	;
	return 0;
}

print_line_separator () {
	echo \
		"======================================================" \
	;
	return 0;
}

build_html_lang_stderr_tidy () {
	local _LANG="${1}";
	local _LOG_STDERR="${2}";
	local _LINE='';
	while read _LINE; 
	do
		local _FILE="${_LINE%%:*}";
		_FILE="tmp/${_LANG}/xml/${_FILE}";
		if ! test \
			-f \
			"${_FILE}" \
		;
		then
			continue;
		fi
		local _POS="${_LINE#*:}";
		if ! printf \
			'%d' \
			"${_POS%%:*}" \
			> /dev/null \
		;
		then
			continue;
		fi
		_POS=$(printf '%d' "${_POS%%:*}");
		local _POS_A=$((_POS - 1));
		local _POS_B=$((_POS + 10));
		print_line_separator;
		echo \
			"${_LINE}" \
		;
		print_line_separator;
		cat \
			--number \
			"${_FILE}" \
		| sed \
			--silent \
			--expression="${_POS_A},${_POS_B}p" \
		;
		print_line_separator;
	done \
		< "${_LOG_STDERR}" \
	;
	return 0;
}

build_html_lang () {
	local _LANG="${1}";
	local _LOG_DIR="log/${_LANG}/build-html";
	mkdir \
		--parent \
		"${_LOG_DIR}" \
	;
	local _LOG_STDOUT="${_LOG_DIR}/stdout.log";
	local _LOG_STDERR="${_LOG_DIR}/stderr.log";
	local _EXIT_STATUS=0;
	if ! sh \
		-eu \
		./build/build-html \
		--opts='--quiet' \
		--lang="${_LANG}" \
		1> "${_LOG_STDOUT}" \
		2> "${_LOG_STDERR}" \
		;
	then
		cat \
			"${_LOG_STDOUT}" \
			"${_LOG_STDERR}" \
		;
		build_html_lang_stderr_tidy \
			"${_LANG}" \
			"${_LOG_STDERR}" \
			2> /dev/null \
		;
		_EXIT_STATUS=1;
	fi
	return "${_EXIT_STATUS}";
}

build_html_all () {
	local _LANG_LIST="$(mktemp_file \
		'lang.list.XXXXXX' \
	;)";
	local _EXIT_STATUS=0;
	find \
		-maxdepth 1 \
		-type d \
		-name '??-??' \
		-printf '%f\n' \
	| sort \
		> "${_LANG_LIST}" \
	;
	local _LANG='';
	while read _LANG; 
	do
		if ! build_html_lang \
			"${_LANG}" \
		;
		then
			_EXIT_STATUS=1;
		fi
	done \
		< "${_LANG_LIST}" \
	;
	rm \
		"${_LANG_LIST}" \
	;
	return "${_EXIT_STATUS}";
}

setup_remote_local () {
	local _GIT_REMOTE_NAME="${1}";
	local _GIT_REMOTE_FETCH="${2}";
	local _GIT_REMOTE_PUSH="${3}";
	shift 3;
	git \
		remote \
		add \
		"${_GIT_REMOTE_NAME}" \
		"${_GIT_REMOTE_FETCH}" \
	;
	if test \
		"${_GIT_REMOTE_FETCH}" != "${_GIT_REMOTE_PUSH}" \
	;
	then
		git \
			remote \
			'set-url' \
			--push \
			"${_GIT_REMOTE_NAME}" \
			"${_GIT_REMOTE_PUSH}" \
		;
	fi
	while test \
		$# -ne 0 \
	;
	do
		local _GIT_REMOTE_BRANCH="${1}";
		local _GIT_LOCAL_BRANCH="${2}";
		shift 2;
	if git \
		fetch \
		"${_GIT_REMOTE_NAME}" \
		"${_GIT_REMOTE_BRANCH}" \
	;
	then
		git \
			checkout \
			-b "${_GIT_LOCAL_BRANCH}" \
			"${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
		;
		git \
			branch \
			--set-upstream-to="${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
		;
	else
		git \
			checkout \
			--orphan \
			"${_GIT_LOCAL_BRANCH}" \
		;
		git \
			rm \
			-r \
			--force \
			. \
		;
	fi
	done
	return 0;
}

setup_build_branch_merge () {
	local _GIT_LOCAL_BASE_BRANCH="${1}";
	local _GIT_LOCAL_TOPIC_BRANCH="${2}";
	git \
		checkout \
		"${_GIT_LOCAL_BASE_BRANCH}" \
	;
	if ! git \
		merge \
		--verbose \
		--ff-only \
		"${_GIT_LOCAL_BASE_BRANCH}" \
		"${_GIT_LOCAL_TOPIC_BRANCH}" \
	;
	then
		echo merge NG!;
		git \
			checkout \
			"${_GIT_LOCAL_BASE_BRANCH}" \
		;
		return 1;
	fi
	echo merge OK!;
	return 0;
}

setup_build_branch_rebase () {
	local _GIT_LOCAL_BASE_BRANCH="${1}";
	local _GIT_LOCAL_TOPIC_BRANCH="${2}";
	local _GIT_LOCAL_TEMP_BRANCH='tmp/rebase';
	git \
		branch \
		"${_GIT_LOCAL_TEMP_BRANCH}" \
		"${_GIT_LOCAL_TOPIC_BRANCH}" \
	;
	if ! git \
		rebase \
		"${_GIT_LOCAL_BASE_BRANCH}" \
		"${_GIT_LOCAL_TEMP_BRANCH}" \
	;
	then
		echo rebase NG!;
		git \
			rebase \
			--abort \
		;
		git \
			checkout \
			"${_GIT_LOCAL_BASE_BRANCH}" \
		;
		return 1;
	fi
	echo rebase OK!;
	git \
		branch \
		--set-upstream-to="$(git \
			rev-parse \
			--abbrev-ref \
			"${_GIT_LOCAL_BASE_BRANCH}@{upstream}" \
		;)" \
	;
	git \
		branch \
		--move \
		--force \
		"${_GIT_LOCAL_TEMP_BRANCH}" \
		"${_GIT_LOCAL_BASE_BRANCH}" \
	;
	return 0;
}

git_cherry_pick () {
	local _GIT_COMMIT_HASH="${1}";
	shift 1;
	if git \
		cherry-pick \
		--no-commit \
		--keep-redundant-commits \
		--allow-empty \
		"${@}" \
		"${_GIT_COMMIT_HASH}" \
	;
	then
		GIT_AUTHOR_DATE=$(git log --pretty='%ad' -1 ${_GIT_COMMIT_HASH}) \
		GIT_AUTHOR_NAME=$(git log --pretty='%an' -1 ${_GIT_COMMIT_HASH}) \
		GIT_AUTHOR_EMAIL=$(git log --pretty='%ae' -1 ${_GIT_COMMIT_HASH}) \
		GIT_COMMITTER_DATE=$(git log --pretty='%cd' -1 ${_GIT_COMMIT_HASH}) \
		GIT_COMMITTER_NAME=$(git log --pretty='%cn' -1 ${_GIT_COMMIT_HASH}) \
		GIT_COMMITTER_EMAIL=$(git log --pretty='%ce' -1 ${_GIT_COMMIT_HASH}) \
		git \
			commit \
			--no-verify \
			--allow-empty \
			--allow-empty-message \
			--reuse-message="${_GIT_COMMIT_HASH}" \
		;
		echo cherry-pick OK!;
		return 0;
	fi
	echo cherry-pick NG!;
	git \
		reset \
		--hard \
		HEAD \
	;
	return 1;

	git \
		cherry-pick \
		--abort \
	;
	return 1;
}

setup_build_branch_cherry_pick () {
	local _GIT_LOCAL_BASE_BRANCH="${1}";
	local _GIT_LOCAL_TOPIC_BRANCH="${2}";
	local _GIT_COMMIT_HASH;
	for _GIT_COMMIT_HASH in $(git \
		log \
		--no-merges \
		--reverse \
		--pretty='format:%H' \
		"${_GIT_LOCAL_BASE_BRANCH}".."${_GIT_LOCAL_TOPIC_BRANCH}" \
		;)
	do
		git_log \
			'-1' \
			"${_GIT_COMMIT_HASH}" \
		;
		if git_cherry_pick \
			"${_GIT_COMMIT_HASH}" \
		;
		then
			git_log \
				'-1' \
			;
			continue;
		fi

		if git_cherry_pick \
			"${_GIT_COMMIT_HASH}" \
			--strategy=recursive \
			--strategy-option=ours \
		;
		then
			git_log \
				'-1' \
			;
			continue;
		fi
		return 1;
	done
	return 0;
}

setup_build_branch () {
	local _GIT_REMOTE_NAME="${1}";
	local _GIT_REMOTE_BRANCH="${2}";
	local _GIT_LOCAL_BASE_BRANCH="${3}";
	shift 3;
	git \
		checkout \
		-b "${_GIT_LOCAL_BASE_BRANCH}" \
		"${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
	;
	local _GIT_LOCAL_TOPIC_BRANCH;
	for _GIT_LOCAL_TOPIC_BRANCH in "${@}";
	do
		if setup_build_branch_merge \
			"${_GIT_LOCAL_BASE_BRANCH}" \
			"${_GIT_LOCAL_TOPIC_BRANCH}" \
		;
		then
			continue;
		fi
		#if setup_build_branch_rebase \
		#	"${_GIT_LOCAL_BASE_BRANCH}" \
		#	"${_GIT_LOCAL_TOPIC_BRANCH}" \
		#;
		#then
		#	continue;
		#fi
		if setup_build_branch_cherry_pick \
			"${_GIT_LOCAL_BASE_BRANCH}" \
			"${_GIT_LOCAL_TOPIC_BRANCH}" \
		;
		then
			continue;
		fi
		echo merge, rebase, and cherry-pick is failed: "${_GIT_LOCAL_TOPIC_BRANCH}";
		return 1;
	done
	return 0;
}

git_commit () {
	git \
		commit \
		--all \
		--allow-empty \
		"${@}" \
	;
	return 0;
}

git_log () {
	git \
		--no-pager \
		log \
		--reverse \
		--color \
		--stat \
		--pretty=fuller \
		"${@}" \
	;
	return 0;
}

show_remote_branch () {
	git \
		remote \
		--verbose \
		--verbose \
	;
	git \
		branch \
		--all \
		--verbose \
		--verbose \
	;
	return 0;
}

setup_build_dir () {
	git \
		init \
	;
	setup_remote_local \
		"${_GIT_REMOTE_WEBLATE_NAME}" \
		"${_GIT_REMOTE_WEBLATE_FETCH}" \
		"${_GIT_REMOTE_WEBLATE_PUSH}" \
		"${_GIT_REMOTE_WEBLATE_BRANCH}" \
		"${_GIT_LOCAL_WEBLATE_BRANCH}" \
	;
	"${WEBLATE_SYNC}" \
		'./' \
	;
	GIT_AUTHOR_DATE=$(git log --pretty='%ad' -1 HEAD) \
	GIT_COMMITTER_DATE=$(git log --pretty='%cd' -1 HEAD) \
	git_commit \
		--message='Sync PO files to Weblate' \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	setup_remote_local \
		"${_GIT_REMOTE_ORIGIN_NAME}" \
		"${_GIT_REMOTE_ORIGIN_FETCH}" \
		"${_GIT_REMOTE_ORIGIN_PUSH}" \
		"${_GIT_REMOTE_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_ORIGIN_BRANCH}" \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	setup_remote_local \
		"${_GIT_REMOTE_TWEEK_NAME}" \
		"${_GIT_REMOTE_TWEEK_FETCH}" \
		"${_GIT_REMOTE_TWEEK_PUSH}" \
		"${_GIT_REMOTE_TWEEK_BRANCH_0}" \
		"${_GIT_LOCAL_TWEEK_BRANCH_0}" \
		"${_GIT_REMOTE_TWEEK_BRANCH_1}" \
		"${_GIT_LOCAL_TWEEK_BRANCH_1}" \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	setup_build_branch \
		"${_GIT_REMOTE_ORIGIN_NAME}" \
		"${_GIT_REMOTE_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_BUILD_BRANCH}" \
		"${_GIT_LOCAL_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_TWEEK_BRANCH_0}" \
		"${_GIT_LOCAL_TWEEK_BRANCH_1}" \
		"${_GIT_LOCAL_WEBLATE_BRANCH}" \
	;
	publican \
		update_pot \
	;
	GIT_AUTHOR_DATE=$(git log --pretty='%ad' -1 HEAD) \
	GIT_COMMITTER_DATE=$(git log --pretty='%cd' -1 HEAD) \
	git_commit \
		--message="Update POT files

$ publican \\
	update_pot \\
;
" \
	;
	publican \
		update_po \
		--msgmerge \
		--previous \
		--langs='all' \
		--firstname="${_PUBLICAN_FIRSTNAME}" \
		--surname="${_PUBLICAN_SURNAME}" \
		--email="${_PUBLICAN_EMAIL}" \
	;
	GIT_AUTHOR_DATE=$(git log --pretty='%ad' -1 HEAD) \
	GIT_COMMITTER_DATE=$(git log --pretty='%cd' -1 HEAD) \
	git_commit \
		--message="Update PO files

$ publican \\
	update_po \\
	--msgmerge \\
	--previous \\
	--langs='all' \\
	--firstname='${_PUBLICAN_FIRSTNAME}' \\
	--surname='${_PUBLICAN_SURNAME}' \\
	--email='${_PUBLICAN_EMAIL}' \\
;
" \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	git \
		clean \
		--force \
		-d \
		-x \
	;
	return 0;
}

systems_build_repository_setup_pre () {
	readonly _GIT_WORK_TREE="${1}";
	readonly WEBLATE_SYNC="${2}";

	configure_publican;
	configure_git;
	configure_git_repository;

	return 0;
}

systems_build_repository_setup () {
	systems_build_repository_setup_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	setup_build_dir;
	show_remote_branch;
	cd \
		- \
	;
	return 0;
}

systems_build_repository_build_pre () {
	readonly _GIT_WORK_TREE="${1}";

	configure_git;
	configure_git_repository

	return 0;
}

systems_build_repository_build () {
	systems_build_repository_build_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	git \
		checkout \
		"${_GIT_LOCAL_BUILD_BRANCH}" \
	;
	local _EXIT_STATUS=0;
	if ! build_html_all;
	then
		_EXIT_STATUS=1;
	fi
	git \
		clean \
		--dry-run \
		--force \
		-d \
		-x \
	;
	cd \
		- \
	;
	return "${_EXIT_STATUS}";
}

systems_build_repository_push_pre () {
	readonly _GIT_WORK_TREE="${1}";
	readonly _TRAVIS_LOG_WEB="${2}"
	readonly _TRAVIS_LOG_RAW="${3}"
	readonly _GIT_DIVERT_DIR="$(mktemp_directory \
		'divert.XXXXXX' \
	;)";
	readonly _GIT_DATE=$(TZ=GMT \
		date \
		"+%Y-%m-%dT%H:%M:%S%:z" \
	;);

	configure_git;
	configure_git_repository

	return 0;
}

systems_build_repository_push () {
	systems_build_repository_push_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	mv \
		publish \
		tmp \
		log \
		"${_GIT_DIVERT_DIR}" \
	;
	setup_remote_local \
		"${_GIT_REMOTE_GITHUB_NAME}" \
		"${_GIT_REMOTE_GITHUB_FETCH}" \
		"${_GIT_REMOTE_GITHUB_PUSH}" \
		"${_GIT_REMOTE_GITHUB_BRANCH}" \
		"${_GIT_LOCAL_GITHUB_BRANCH}" \
	;
	show_remote_branch;
	if rm \
		--force \
		--recursive \
		publish \
		tmp \
		log \
	;
	then
		:;
	fi
	mv \
		"${_GIT_DIVERT_DIR}/publish" \
		"${_GIT_DIVERT_DIR}/tmp" \
		"${_GIT_DIVERT_DIR}/log" \
		. \
	;
	git \
		add \
		publish \
		tmp \
		log \
	;
	git_commit \
		--message="Save buid result at ${_GIT_DATE}

* Travis-Web: ${_TRAVIS_LOG_WEB}
* Travis-Raw: ${_TRAVIS_LOG_RAW}
" \
	;
	show_remote_branch;
	GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -i ${_GIT_REMOTE_GITHUB_KEY}" \
	git \
		push \
		--force \
		"${_GIT_REMOTE_GITHUB_NAME}" \
		"${_GIT_LOCAL_GITHUB_BRANCH}:${_GIT_REMOTE_GITHUB_BRANCH}" \
	;
	cd \
		- \
	;
	return 0;
}

travis_pre () {
	configure_identity;
	configure_chroot;

	readonly SELF="$(readlink \
		--canonicalize \
		"${0}" \
	;)";
	readonly WEBLATE_SYNC="$(readlink \
		--canonicalize \
		"$(dirname \
			"${SELF}" \
		;)/weblate-sync.pl" \
	;)";
	readonly _TRAVIS_LOG_WEB="https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}";
	readonly _TRAVIS_LOG_RAW="https://api.travis-ci.org/jobs/${TRAVIS_JOB_ID}/log.txt";

	readonly _GIT_WORK_TREE="$(mktemp_directory \
		'build.XXXXXX' \
	;)";

	return 0;
}

travis () {
	travis_pre;
	travis_block_wrap \
		'systems_host_setup' \
		sudo \
		-- \
		"${SELF}" \
		'systems:host/setup' \
	;
	travis_block_wrap \
		'systems_host_mkimage' \
		sudo \
		-- \
		"${SELF}" \
		'systems:host/mkimage' \
		"${CURRENT_USER}" \
		"${CURRENT_GROUP}" \
	;
	travis_block_wrap \
		'systems_build_setup' \
		sudo \
		-- \
		schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${SELF}" \
		'systems:build/setup' \
	;
	travis_block_wrap \
		'systems_build_repository_setup' \
		schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${SELF}" \
		'systems:build/repository/setup' \
		"${_GIT_WORK_TREE}" \
		"${WEBLATE_SYNC}" \
	;
	local _EXIT_STATUS=0;
	if ! travis_block_wrap \
		'systems_build_repository_build' \
		schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${SELF}" \
		'systems:build/repository/build' \
		"${_GIT_WORK_TREE}" \
	;
	then
		_EXIT_STATUS=1;
	fi
	travis_block_wrap \
		'systems_build_repository_push' \
		schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${SELF}" \
		'systems:build/repository/push' \
		"${_GIT_WORK_TREE}" \
		"${_TRAVIS_LOG_WEB}" \
		"${_TRAVIS_LOG_RAW}" \
	;
	return "${_EXIT_STATUS}";
}

main () {
	readonly MODE="${1}";
	shift 1;
	case "${MODE}" in
		'systems:host/setup')
			systems_host_setup  \
				"${@}" \
			;
		;;
		'systems:host/mkimage')
			systems_host_mkimage \
				"${@}" \
			;
		;;
		'systems:build/setup')
			systems_build_setup \
				"${@}" \
			;
		;;
		'systems:build/repository/setup')
			systems_build_repository_setup \
				"${@}" \
			;
		;;
		'systems:build/repository/build')
			systems_build_repository_build \
				"${@}" \
			;
		;;
		'systems:build/repository/push')
			systems_build_repository_push \
				"${@}" \
			;
		;;
		'travis')
			travis \
				"${@}" \
			;
		;;
		*)
			return 1;
		;;
	esac;
	return 0;
}

main \
	"${@}" \
;

exit 0;
