#!/bin/dash
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
	id;
	readonly CURRENT_USER="$(id \
		--user \
		--name \
	;)";
	readonly CURRENT_USER_ID="$(id \
		--user \
	;)";
	readonly CURRENT_GROUP="$(id \
		--group \
		--name \
	;)";
	readonly CURRENT_GROUP_ID="$(id \
		--group \
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

configure_translation_status () {
	return 0;
}

alias git_commit='git \
	commit \
	--all \
	--allow-empty \
';
alias git_log='git \
	--no-pager \
	log \
	--reverse \
	--color \
	--stat \
	--pretty=fuller \
';
alias git_author_date='git \
	log \
	--pretty="%ad" \
	-1 \
';
alias git_author_name='git \
	log \
	--pretty="%an" \
	-1 \
';
alias git_author_email='git \
	log \
	--pretty="%ae" \
	-1 \
';
alias git_comitter_date='git \
	log \
	--pretty="%cd" \
	-1 \
';
alias git_comitter_name='git \
	log \
	--pretty="%cn" \
	-1 \
';
alias git_comitter_email='git \
	log \
	--pretty="%ce" \
	-1 \
';

configure_git () {
	export GIT_AUTHOR_NAME="AYANOKOUZI, Ryuunosuke";
	export GIT_AUTHOR_EMAIL="i38w7i3@yahoo.co.jp";
	export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}";
	export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL}";
	return 0;
}

configure_git_repository () {
	readonly _GIT_REMOTE_ORIGIN_NAME='origin';
	readonly _GIT_REMOTE_ORIGIN_FETCH='https://salsa.debian.org/hertzog/debian-handbook.git';
	readonly _GIT_REMOTE_ORIGIN_PUSH="${_GIT_REMOTE_ORIGIN_FETCH}";
	readonly _GIT_REMOTE_ORIGIN_BRANCH='stretch/master';
	readonly _GIT_LOCAL_ORIGIN_BRANCH="${_GIT_REMOTE_ORIGIN_BRANCH}/translation/${_GIT_REMOTE_ORIGIN_NAME}";

	readonly _GIT_REMOTE_WEBLATE_NAME='weblate';
	readonly _GIT_REMOTE_WEBLATE_FETCH='git://git.weblate.org/debian-handbook.git';
	readonly _GIT_REMOTE_WEBLATE_PUSH="${_GIT_REMOTE_WEBLATE_FETCH}";
	readonly _GIT_REMOTE_WEBLATE_BRANCH='jessie/master';
	readonly _GIT_LOCAL_WEBLATE_BRANCH="${_GIT_REMOTE_WEBLATE_BRANCH}/translation/${_GIT_REMOTE_WEBLATE_NAME}";
	readonly _GIT_LOCAL_BUILD_BRANCH="stretch/master/build";

	readonly _GIT_REMOTE_TWEEK_NAME='tweek';
	readonly _GIT_REMOTE_TWEEK_FETCH='https://github.com/l/debian-handbook.git';
	readonly _GIT_REMOTE_TWEEK_PUSH="${_GIT_REMOTE_TWEEK_FETCH}";
	readonly _GIT_REMOTE_TWEEK_BRANCH_0='jessie/master/proposal/put_backcover_and_website_as_appendix';
	readonly _GIT_LOCAL_TWEEK_BRANCH_0="${_GIT_REMOTE_TWEEK_BRANCH_0}";

	readonly _GIT_REMOTE_GITHUB_KEY="${HOME}/.ssh/deploy_key";
	readonly _GIT_REMOTE_GITHUB_NAME='github';
	readonly _GIT_REMOTE_GITHUB_FETCH='https://github.com/l/debian-handbook-test.git';
	readonly _GIT_REMOTE_GITHUB_PUSH='git@github.com:l/debian-handbook-test.git';
	readonly _GIT_REMOTE_GITHUB_BRANCH='gh-pages';
	readonly _GIT_LOCAL_GITHUB_BRANCH="stretch/master/${_GIT_REMOTE_GITHUB_BRANCH}";

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

systems_host_test () {
	df \
		--human-readable \
		--all \
		--print-type \
	| sort \
		--key='7,7d' \
	;
	return 0;
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
	{
	cat << 'EOT'
// APT::Get::AllowUnauthenticated "true";
EOT
	} | tee \
		"/etc/apt/apt.conf.d/03allow-unauthenticated" \
	;
	apt_get_install \
		debian-keyring \
		debian-archive-keyring \
		debootstrap \
		schroot \
	;
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
	cat \
		'/etc/debian_version' \
	;
	apt-config \
		dump \
	| grep \
		--regexp='APT::Install-' \
		--regexp='DPkg::options' \
		--regexp='APT::Get::' \
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
		file \
		libxml2-utils \
		imagemagick \
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
		./bin/build-html \
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
	local _EXIT_STATUS=0;
	find \
		-maxdepth 1 \
		-type d \
		-name '??-??' \
		-printf '%f\n' \
	| sort \
		1>"${_LANGS_TXT}" \
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
		< "${_LANGS_TXT}" \
	;
	rm \
		"${_LANGS_TXT}" \
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
		: "merge NG!";
		git \
			checkout \
			"${_GIT_LOCAL_BASE_BRANCH}" \
		;
		return 1;
	fi
	: "merge OK!";
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
		: "rebase NG!";
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
	: "rebase OK!";
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
	&& GIT_AUTHOR_DATE="$(git_author_date "${_GIT_COMMIT_HASH}";)" \
	GIT_AUTHOR_NAME="$(git_author_name "${_GIT_COMMIT_HASH}";)" \
	GIT_AUTHOR_EMAIL="$(git_author_email "${_GIT_COMMIT_HASH}";)" \
	GIT_COMMITTER_DATE="$(git_comitter_date "${_GIT_COMMIT_HASH}";)" \
	GIT_COMMITTER_NAME="$(git_comitter_name "${_GIT_COMMIT_HASH}";)" \
	GIT_COMMITTER_EMAIL="$(git_comitter_email "${_GIT_COMMIT_HASH}";)" \
	git \
		commit \
		--no-verify \
		--allow-empty \
		--allow-empty-message \
		--reuse-message="${_GIT_COMMIT_HASH}" \
	;
	then
		return 0;
	fi
	: "cherry-pick NG!";
	git \
		reset \
		--hard \
		'HEAD' \
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
		#git_log \
		#	'-1' \
		#	"${_GIT_COMMIT_HASH}" \
		#;
		if ! git_cherry_pick \
			"${_GIT_COMMIT_HASH}" \
		&& ! git_cherry_pick \
			"${_GIT_COMMIT_HASH}" \
			--strategy=recursive \
			--strategy-option=ours \
		;
		then
			return 1;
		fi
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
		if ! setup_build_branch_merge \
			"${_GIT_LOCAL_BASE_BRANCH}" \
			"${_GIT_LOCAL_TOPIC_BRANCH}" \
		&& ! setup_build_branch_cherry_pick \
			"${_GIT_LOCAL_BASE_BRANCH}" \
			"${_GIT_LOCAL_TOPIC_BRANCH}" \
		;
		then
			echo merge, rebase, and cherry-pick is failed: "${_GIT_LOCAL_TOPIC_BRANCH}";
			return 1;
		fi
		#if setup_build_branch_rebase \
		#	"${_GIT_LOCAL_BASE_BRANCH}" \
		#	"${_GIT_LOCAL_TOPIC_BRANCH}" \
		#;
		#then
		#	continue;
		#fi
	done
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
	#ln \
	#	--force \
	#	--symbolic \
	#	"${_GIT_HOOKS_PRE_COMMIT}" \
	#	'.git/hooks/pre-commit' \
	#;
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
	GIT_AUTHOR_DATE="$(git_author_date 'HEAD';)" \
	GIT_COMMITTER_DATE="$(git_comitter_date 'HEAD';)" \
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
		"${_GIT_LOCAL_WEBLATE_BRANCH}" \
	;
	publican \
		update_pot \
	;
	GIT_AUTHOR_DATE="$(git_author_date 'HEAD';)" \
	GIT_COMMITTER_DATE="$(git_comitter_date 'HEAD';)" \
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
	GIT_AUTHOR_DATE="$(git_author_date 'HEAD';)" \
	GIT_COMMITTER_DATE="$(git_comitter_date 'HEAD';)" \
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
	#readonly _GIT_HOOKS_PRE_COMMIT="${2}";
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

generte_translation_status_lang () {
	local _LANG="${1}";
	local _LOG_DIR="log/${_LANG}/translation-status";
	mkdir \
		--parent \
		"${_LOG_DIR}" \
	;
	local _OUTPUT_HTML="${_LOG_DIR}/index.html";
	local _LOG_STDOUT="${_LOG_DIR}/stdout.log";
	local _LOG_STDERR="${_LOG_DIR}/stderr.log";
	local _EXIT_STATUS=0;
	if ! "${TRANSLATION_STATUS}" \
		"./${LANG}" \
		"${_OUTPUT_HTML}" \
		1> "${_LOG_STDOUT}" \
		2> "${_LOG_STDERR}" \
		;
	then
		cat \
			"${_LOG_STDOUT}" \
			"${_LOG_STDERR}" \
		;
		_EXIT_STATUS=1;
	fi
	return "${_EXIT_STATUS}";
}

generte_translation_status () {
	for LANG in $(echo [a-z][a-z]-[A-Z][A-Z]) ;
	do
		generte_translation_status_lang \
			"${LANG}" \
		;
	done
	return 0;
}

systems_build_repository_translation_status_pre () {
	readonly _GIT_WORK_TREE="${1}";
	#readonly _GIT_HOOKS_PRE_COMMIT="${2}";
	readonly TRANSLATION_STATUS="${2}";

	#configure_publican;
	#configure_git;
	#configure_git_repository;
	configure_translation_status

	return 0;
}

systems_build_repository_translation_status () {
	systems_build_repository_translation_status_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	generte_translation_status;
	cd \
		- \
	;
	return 0;
}

systems_build_repository_build_pre () {
	readonly _GIT_WORK_TREE="${1}";
	readonly _FIFO_DIR="${2}";
	readonly _LANGS_TXT="${_FIFO_DIR}/langs.txt";
	#readonly _LANGS_FIFO="${_FIFO_DIR}/langs.fifo";
	#mkfifo \
	#	"${_LANGS_FIFO}" \
	#;

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

systems_build_repository_build_targets_prepare_pre () {
	readonly _GIT_WORK_TREE="${1}";
	readonly _GIT_DIVERT_DIR="${2}";
	readonly _FIFO_DIR="${3}";
	readonly _FILES_TXT="${_FIFO_DIR}/files.txt";
	#readonly _FILES_FIFO="${_FIFO_DIR}/files.fifo";
	#mkfifo \
	#	"${_FILES_FIFO}" \
	#;
	return 0;
}

systems_build_repository_build_targets_prepare () {
	systems_build_repository_build_targets_prepare_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	find \
		publish \
		tmp \
		log \
		-name '*.html' \
	| sort \
		1>"${_FILES_TXT}" \
	;
	local _FILE_PATH='';
	while read _FILE_PATH;
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
					;;
				esac
			;;
		esac
	done \
		< "${_FILES_TXT}" \
	;
	rm \
		"${_FILES_TXT}" \
	;
	mv \
		publish \
		tmp \
		log \
		"${_GIT_DIVERT_DIR}" \
	;
	cd \
		- \
	;
	return 0;
}

systems_build_repository_build_results_push_pre () {
	readonly _GIT_WORK_TREE="${1}";
	readonly _GIT_DIVERT_DIR="${2}";
	readonly _TRAVIS_LOG_WEB="${3}";
	readonly _TRAVIS_LOG_RAW="${4}";
	readonly _GIT_DATE=$(TZ=GMT \
		date \
		"+%Y-%m-%dT%H:%M:%S%:z" \
	;);

	configure_git;
	configure_git_repository;

	return 0;
}

systems_build_repository_build_results_push () {
	systems_build_repository_build_results_push_pre \
		"${@}" \
	;
	cd \
		"${_GIT_WORK_TREE}" \
	;
	setup_remote_local \
		"${_GIT_REMOTE_GITHUB_NAME}" \
		"${_GIT_REMOTE_GITHUB_FETCH}" \
		"${_GIT_REMOTE_GITHUB_PUSH}" \
		"${_GIT_REMOTE_GITHUB_BRANCH}" \
		"${_GIT_LOCAL_GITHUB_BRANCH}" \
	;
	show_remote_branch;
	git \
		rm \
		--quiet \
		--ignore-unmatch \
		-r \
		-- \
		. \
	;
	git \
		clean \
		--force \
		-d \
		-x \
	;
	if ! find \
		"${_GIT_DIVERT_DIR}" \
		-mindepth 1 \
		-maxdepth 1 \
		-exec \
		mv \
		--target-directory='.' \
		-- \
		{} \
		\; \
	;
	then
		: "ERROR: ${?}: find";
	fi
	git \
		add \
		--all \
		-- \
		. \
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
	readonly TRANSLATION_STATUS="$(readlink \
		--canonicalize \
		"$(dirname \
			"${SELF}" \
		;)/translation-status.pl" \
	;)";
	#readonly _GIT_HOOKS_PRE_COMMIT="$(readlink \
	#	--canonicalize \
	#	"$(dirname \
	#		"${SELF}" \
	#	;)/../.git-hooks/pre-commit.sh" \
	#;)";
	readonly _TRAVIS_LOG_WEB="https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}";
	readonly _TRAVIS_LOG_RAW="https://api.travis-ci.org/jobs/${TRAVIS_JOB_ID}/log.txt";

	readonly _BASE_DIR="$(mktemp_directory \
		'base.XXXXXX' \
	;)";
	readonly _FIFO_DIR="${_BASE_DIR}/fifo";
	mkdir \
		--parent \
		"${_FIFO_DIR}" \
	;
	readonly _GIT_WORK_TREE="${_BASE_DIR}/build";
	mkdir \
		--parent \
		"${_GIT_WORK_TREE}" \
	;
	#readonly _GIT_WORK_TREE="$(mktemp_directory \
	#	'build.XXXXXX' \
	#;)";
	readonly _GIT_DIVERT_DIR="${_BASE_DIR}/divert";
	mkdir \
		--parent \
		"${_GIT_DIVERT_DIR}" \
	;
	#readonly _GIT_DIVERT_DIR="$(mktemp_directory \
	#	'divert.XXXXXX' \
	#;)";
	readonly _LOGGER_DIR="${_GIT_DIVERT_DIR}/logger";
	mkdir \
		--parent \
		"${_LOGGER_DIR}" \
	;
	readonly _LOGGER_FILE="${_LOGGER_DIR}/travis.log";

	return 0;
}

# https://docs.travis-ci.com/user/customizing-the-build/
travis_build_limitation () {
	local _I=0;
	for _I in $(seq \
		0 \
		1 \
		45 \
	;);
	do
		: \
			"travis_build_limitation: ${_I}" \
		;
		tail \
			"${_LOGGER_FILE}" \
		;
		sleep \
			60 \
		;
	done
	exit 100;
}

sighandler () {
	local _SIGNUM="${1}";

	: \
		"catch ${_SIGNUM}" \
	;
	tail \
		"${_LOGGER_FILE}" \
	;
	docker exec \
		--user travis \
		debian_unstable \
		"${SELF}" \
		'systems:build/repository/build/results/push' \
		"${_GIT_WORK_TREE}" \
		"${_GIT_DIVERT_DIR}" \
		"${_TRAVIS_LOG_WEB}" \
		"${_TRAVIS_LOG_RAW}" \
	;
	return 0;

	if test \
		-f \
		/home/travis/chroot/unstable_amd64_build/debootstrap/debootstrap.log \
	;
	then
		tail \
			/home/travis/chroot/unstable_amd64_build/debootstrap/debootstrap.log \
		;
	fi
	systems_host_test;
	schroot \
		--chroot="${CHROOT_ID}" \
		-- \
		"${SELF}" \
		'systems:build/repository/build/results/push' \
		"${_GIT_WORK_TREE}" \
		"${_GIT_DIVERT_DIR}" \
		"${_TRAVIS_LOG_WEB}" \
		"${_TRAVIS_LOG_RAW}" \
	;
		#1>"${_LOGGER_DIR}/systems_build_repository_build_results_push.log" \
		#2>&1 \
	return 0;
}

travis_signal_trap () {
	trap "_STATUS=\$?; trap - EXIT; sighandler EXIT; exit \${_STATUS};" EXIT;
	trap "trap - EXIT; sighandler HUP;  exit $((128 +  1));" HUP;
	trap "trap - EXIT; sighandler INT;  exit $((128 +  2));" INT;
	trap "trap - EXIT; sighandler QUIT; exit $((128 +  3));" QUIT;
	trap "trap - EXIT; sighandler TERM; exit $((128 + 15));" TERM;
	return 0;
}

travis () {
	travis_pre;
	# travis_build_limitation&
	local _EXIT_STATUS=0;
	{
		travis_signal_trap;
		systems_host_test;
		sudo \
			-- \
			"${SELF}" \
			'systems:host/setup' \
		;
		sudo \
			-- \
			"${SELF}" \
			'systems:host/mkimage' \
			"${CURRENT_USER}" \
			"${CURRENT_GROUP}" \
		;
		sudo \
			-- \
			schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			"${SELF}" \
			'systems:build/setup' \
		;
		schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			"${SELF}" \
			'systems:build/repository/setup' \
			"${_GIT_WORK_TREE}" \
			"${WEBLATE_SYNC}" \
		;
		schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			"${SELF}" \
			'systems:build/repository/translation/status' \
			"${_GIT_WORK_TREE}" \
			"${TRANSLATION_STATUS}" \
		;
		if ! schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			"${SELF}" \
			'systems:build/repository/build' \
			"${_GIT_WORK_TREE}" \
			"${_FIFO_DIR}" \
		;
		then
			_EXIT_STATUS=1;
		fi
		schroot \
			--chroot="${CHROOT_ID}" \
			-- \
			"${SELF}" \
			'systems:build/repository/build/targets/prepare' \
			"${_GIT_WORK_TREE}" \
			"${_GIT_DIVERT_DIR}" \
			"${_FIFO_DIR}" \
		;
	} \
		2>&1 \
	| tee \
		"${_LOGGER_FILE}" \
	;
	return "${_EXIT_STATUS}";
}

travis_docker () {
	travis_pre;
	local _EXIT_STATUS=0;
	{
		travis_signal_trap;
		systems_host_test;
		sudo \
			-- \
			"${SELF}" \
			'systems:host/setup' \
		;
		docker pull \
			debian:unstable \
		;
		docker run \
			--detach \
			--name debian_unstable \
			--volume /root/:/root/ \
			--volume /home/:/home/ \
			--rm \
			--interactive \
			--tty \
			debian:unstable \
			bash \
		;
		docker exec \
			debian_unstable \
			useradd \
			-u "${CURRENT_USER_ID}" \
			-d /home/travis \
			"${CURRENT_USER}" \
		;
		docker exec \
			debian_unstable \
			"${SELF}" \
			'systems:build/setup' \
		;
		docker exec \
			--user travis \
			debian_unstable \
			"${SELF}" \
			'systems:build/repository/setup' \
			"${_GIT_WORK_TREE}" \
			"${WEBLATE_SYNC}" \
		;
		docker exec \
			--user travis \
			debian_unstable \
			"${SELF}" \
			'systems:build/repository/translation/status' \
			"${_GIT_WORK_TREE}" \
			"${TRANSLATION_STATUS}" \
		;
		if ! docker exec \
			--user travis \
			debian_unstable \
			"${SELF}" \
			'systems:build/repository/build' \
			"${_GIT_WORK_TREE}" \
			"${_FIFO_DIR}" \
		;
		then
			_EXIT_STATUS=1;
		fi
		docker exec \
			--user travis \
			debian_unstable \
			"${SELF}" \
			'systems:build/repository/build/targets/prepare' \
			"${_GIT_WORK_TREE}" \
			"${_GIT_DIVERT_DIR}" \
			"${_FIFO_DIR}" \
		;
	} \
		2>&1 \
	| tee \
		"${_LOGGER_FILE}" \
	;
	return "${_EXIT_STATUS}";
}

main () {
	readonly MODE="${1}";
	shift 1;
	case "${MODE}" in
		'systems:host/test')
			systems_host_test  \
				"${@}" \
			;
		;;
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
		'systems:build/repository/translation/status')
			systems_build_repository_translation_status \
				"${@}" \
			;
		;;
		'systems:build/repository/build')
			systems_build_repository_build \
				"${@}" \
			;
		;;
		'systems:build/repository/build/targets/prepare')
			systems_build_repository_build_targets_prepare \
				"${@}" \
			;
		;;
		'systems:build/repository/build/results/push')
			systems_build_repository_build_results_push \
				"${@}" \
			;
		;;
		'travis')
			travis \
				"${@}" \
			;
		;;
		'travis-docker')
			travis_docker \_
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
