# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6} pypy )
ES_VERSION="5.6.7"

inherit distutils-r1

MY_PN=${PN/-py/}
DESCRIPTION="official Python low-level client for Elasticsearch"
HOMEPAGE="https://github.com/elastic/elasticsearch-py"
SRC_URI="https://github.com/elasticsearch/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
	test? ( https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz )"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="examples doc test"

# tests fail in chroot
# https://github.com/elastic/elasticsearch/issues/12018
RESTRICT="test"

RDEPEND=">=dev-python/urllib3-1.21.1[${PYTHON_USEDEP}]
	<dev-python/urllib3-1.23[${PYTHON_USEDEP}]"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	>=dev-python/sphinx-1.3.1-r1[${PYTHON_USEDEP}]
	test? ( ${RDEPEND}
		>=dev-python/requests-2.0.0[${PYTHON_USEDEP}]
		<dev-python/requests-3.0.0[${PYTHON_USEDEP}]
		dev-python/nose[${PYTHON_USEDEP}]
		dev-python/coverage[${PYTHON_USEDEP}]
		dev-python/mock[${PYTHON_USEDEP}]
		dev-python/pretty-yaml[${PYTHON_USEDEP}]
		dev-python/nosexcover[${PYTHON_USEDEP}]
		virtual/jre:1.8 )"

python_prepare_all() {
	# 643684
	sed -i -e /urllib3/d setup.py || die

	distutils-r1_python_prepare_all
}

python_compile_all() {
	emake -C docs -j1 man $(usex doc html "")
}

# FEATURES="test -usersandbox" emerge dev-python/elasticsearch-py
python_test() {
	ES="${WORKDIR}/elasticsearch-${ES_VERSION}"
	ES_PORT="25124"
	ES_INSTANCE="gentoo-es-py-test"
	ES_LOG="${ES}/logs/${ES_INSTANCE}.log"
	PID="${ES}/elasticsearch.pid"

	# run Elasticsearch instance on custom port
	sed -i "s/#http.port: 9200/http.port: ${ES_PORT}/g; \
		s/#cluster.name: my-application/cluster.name: ${ES_INSTANCE}/g" \
		"${ES}/config/elasticsearch.yml" || die

	# start local instance of elasticsearch
	"${ES}"/bin/elasticsearch -d -p "${PID}" -Epath.repo=/ || die

	local i
	local es_started=0
	for i in {1..20}; do
		grep -q "started" ${ES_LOG} 2> /dev/null
		if [[ $? -eq 0 ]]; then
			einfo "Elasticsearch started"
			es_started=1
			eend 0
			break
		elif grep -q 'BindException\[Address already in use\]' "${ES_LOG}" 2>/dev/null; then
			eend 1
			eerror "Elasticsearch already running"
			die "Cannot start Elasticsearch for tests"
		else
			einfo "Waiting for Elasticsearch"
			eend 1
			sleep 2
			continue
		fi
	done

	[[ $es_started -eq 0 ]] && die "Elasticsearch failed to start"

	export TEST_ES_SERVER="localhost:${ES_PORT}"
	esetup.py test || die

	pkill -F ${PID}
}

python_install_all() {
	use doc && HTML_DOCS=( docs/_build/html/. )
	use examples && dodoc -r example
	doman docs/_build/man/*
	distutils-r1_python_install_all
}
