#!/bin/sh
set -eux;

configure () {
	export DEBIAN_FRONTEND=noninteractive;
	export DEBCONF_NONINTERACTIVE_SEEN=true;
	export LC_ALL=C;
	export LANGUAGE=C;
	export LANG=C;
	export TZ=GMT;

	readonly CHROOT_POOL_DIR="${HOME}/chroot";
	readonly CHROOT_SUITE='unstable';
	readonly CHROOT_ARCH='amd64';
	readonly CHROOT_INFO='build';
	readonly CHROOT_VARIANT='minbase';
	readonly CHROOT_ID="${CHROOT_SUITE}_${CHROOT_ARCH}_${CHROOT_INFO}";
	readonly CHROOT_DIR="${CHROOT_POOL_DIR}/${CHROOT_ID}";
	readonly CHROOT_MIRROR='http://deb.debian.org/debian';
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

	export GIT_AUTHOR_NAME="${CURRENT_USER}";
	export GIT_AUTHOR_EMAIL="${CURRENT_USER}@${CURRENT_HOST}";
	export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}";
	export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL}";

	readonly BIN="$(readlink \
		--canonicalize \
		"${0}" \
	;)";
	readonly WEBLATE_SYNC="$(readlink \
		--canonicalize \
		"$(dirname \
			"${BIN}" \
		;)/weblate-sync.pl" \
	;)";
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

setup_system_base () {
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
	apt-config \
		dump \
	| grep \
		--regexp='APT::Install-' \
		--regexp='DPkg::options' \
	;
	apt-cache \
		policy \
	;
	apt-key \
		list \
	;
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
	apt-get \
		--assume-yes \
		install \
		debian-keyring \
		debian-archive-keyring \
		debootstrap \
		schroot \
	;
	apt-get \
		--assume-yes \
		autoremove \
	;
	service \
		--status-all \
	;
	return 0;
}

setup_system_build_init () {
	readonly _CHROOT_USER="${1}";
	readonly _CHROOT_GROUP="${2}";
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
users=${_CHROOT_USER}
groups=${_CHROOT_GROUP}
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

setup_system_build_conf () {
	if test "root" != "${CURRENT_USER}" ;
	then
		return 1;
	fi
	apt-get update;
	#apt-get -y upgrade;
	#apt-get autoremove;
	#apt-get clean;

	echo apt-config \
		dump \
	;
	echo cat \
		'/etc/debian_version' \
	;
	echo id \
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
	apt-get \
		--assume-yes \
		install \
		git \
		publican \
		publican-debian \
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
	local _LOG_STDOUT="$(mktemp_file \
		'log.stdout.XXXXXX' \
	;)";
	local _LOG_STDERR="$(mktemp_file \
		'log.stderr.XXXXXX' \
	;)";
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
	rm \
		"${_LOG_STDOUT}" \
		"${_LOG_STDERR}" \
	;
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
	local _GIT_REMOTE_URL="${2}";
	local _GIT_REMOTE_BRANCH="${3}";
	local _GIT_LOCAL_BRANCH="${4}";
	git \
		remote \
		add \
		"${_GIT_REMOTE_NAME}" \
		"${_GIT_REMOTE_URL}" \
	;
	git \
		fetch \
		"${_GIT_REMOTE_NAME}" \
		"${_GIT_REMOTE_BRANCH}" \
	;
	git \
		checkout \
		-b "${_GIT_LOCAL_BRANCH}" \
		"${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
	;
	git \
		branch \
		--set-upstream-to="${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
	;
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

setup_build_branch () {
	local _GIT_REMOTE_NAME="${1}";
	local _GIT_REMOTE_BRANCH="${2}";
	local _GIT_LOCAL_BUILD_BRANCH="${3}";
	shift 3;
	git \
		checkout \
		-b "${_GIT_LOCAL_BUILD_BRANCH}" \
		"${_GIT_REMOTE_NAME}/${_GIT_REMOTE_BRANCH}" \
	;
	local _GIT_LOCAL_BRANCH;
	for _GIT_LOCAL_BRANCH in "${@}";
	do
		if setup_build_branch_merge \
			"${_GIT_LOCAL_BUILD_BRANCH}" \
			"${_GIT_LOCAL_BRANCH}" \
		;
		then
			continue;
		fi
		if setup_build_branch_rebase \
			"${_GIT_LOCAL_BUILD_BRANCH}" \
			"${_GIT_LOCAL_BRANCH}" \
		;
		then
			continue;
		fi
		echo merge and rebase is failed: "${_GIT_LOCAL_BRANCH}";
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

setup_build_dir () {
	local _GIT_REMOTE_ORIGIN_NAME='origin';
	local _GIT_REMOTE_ORIGIN_URL='git://anonscm.debian.org/debian-handbook/debian-handbook.git';
	local _GIT_REMOTE_ORIGIN_BRANCH='jessie/master';
	local _GIT_LOCAL_ORIGIN_BRANCH="${_GIT_REMOTE_ORIGIN_BRANCH}/translation/${_GIT_REMOTE_ORIGIN_NAME}";
	local _GIT_REMOTE_WEBLATE_NAME='weblate';
	local _GIT_REMOTE_WEBLATE_URL='git://git.weblate.org/debian-handbook.git';
	local _GIT_REMOTE_WEBLATE_BRANCH='jessie/master';
	local _GIT_LOCAL_WEBLATE_BRANCH="${_GIT_REMOTE_WEBLATE_BRANCH}/translation/${_GIT_REMOTE_WEBLATE_NAME}";
	local _GIT_LOCAL_BUILD_BRANCH="jessie/master/build";
	local _GIT_WORK_TREE="$(mktemp_directory \
		'build.XXXXXX' \
	;)";

	cd \
		"${_GIT_WORK_TREE}" \
	;
	git \
		init \
	;
	setup_remote_local \
		"${_GIT_REMOTE_WEBLATE_NAME}" \
		"${_GIT_REMOTE_WEBLATE_URL}" \
		"${_GIT_REMOTE_WEBLATE_BRANCH}" \
		"${_GIT_LOCAL_WEBLATE_BRANCH}" \
	;
	"${WEBLATE_SYNC}" \
		'./' \
	;
	git_commit \
		--message='Sync PO files to Weblate' \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	setup_remote_local \
		"${_GIT_REMOTE_ORIGIN_NAME}" \
		"${_GIT_REMOTE_ORIGIN_URL}" \
		"${_GIT_REMOTE_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_ORIGIN_BRANCH}" \
	;
	publican \
		update_pot \
	;
	git_commit \
		--message="Update POT files

$ publican \\
	update_pot \\
;
" \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	setup_build_branch \
		"${_GIT_REMOTE_ORIGIN_NAME}" \
		"${_GIT_REMOTE_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_BUILD_BRANCH}" \
		"${_GIT_LOCAL_ORIGIN_BRANCH}" \
		"${_GIT_LOCAL_WEBLATE_BRANCH}" \
	;
	publican \
		update_po \
		--msgmerge \
		--previous \
		--langs='all' \
		--firstname="${CURRENT_USER}" \
		--surname="${CURRENT_USER}" \
		--email="${CURRENT_USER}@${CURRENT_HOST}" \
	;
	git_commit \
		--message="Update PO files

$ publican \\
	update_po \\
	--msgmerge \\
	--previous \\
	--langs='all' \\
	--firstname='${CURRENT_USER}' \\
	--surname='${CURRENT_USER}' \\
	--email='${CURRENT_USER}@${CURRENT_HOST}' \\
;
" \
	;
	git_log	\
		"@{upstream}..HEAD" \
	;
	return 0;
}

build () {
	local _EXIT_STATUS=0;
	setup_build_dir;
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
	if ! build_html_all;
	then
		_EXIT_STATUS=1;
	fi
	return "${_EXIT_STATUS}";
}

travis () {
	sudo \
		-- \
		"${BIN}" \
		'setup/system/base' \
	;
	sudo \
		-- \
		"${BIN}" \
		'setup/system/build/init' \
		"${CURRENT_USER}" \
		"${CURRENT_GROUP}" \
	;
	sudo \
		-- \
		schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${BIN}" \
		'setup/system/build/conf' \
	;
	schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${BIN}" \
		'build' \
	;
	return 0;
}


configure;
readonly MODE="${1}";
case "${MODE}" in
	'setup/system/base')
		setup_system_base;
	;;
	'setup/system/build/init')
		setup_system_build_init \
			"${2}" \
			"${3}" \
		;
	;;
	'setup/system/build/conf')
		setup_system_build_conf;
	;;
	'build')
		build;
	;;
	'travis')
		travis;
	;;
	*)
		exit 1;
	;;
esac;

exit 0;
