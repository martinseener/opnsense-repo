#!/bin/sh
#
# Build all plugins listed in plugins.conf and create the pkg repository in public/.
# Runs on FreeBSD (the GitHub workflow starts a VM for it); needs git and pkg.

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="${ROOT}/work"
PUBLIC="${ROOT}/public"
REPO="${PUBLIC}/repo"
# the build framework (Mk/, Templates/) of the official plugins
PLUGINS_URL="https://github.com/opnsense/plugins"
PLUGINS_REF="${PLUGINS_REF:-master}"

rm -rf "${WORK}" "${PUBLIC}"
mkdir -p "${WORK}/src" "${REPO}/All"

git clone -q --depth 1 --branch "${PLUGINS_REF}" "${PLUGINS_URL}" "${WORK}/plugins"

grep -v -e '^#' -e '^[[:space:]]*$' "${ROOT}/plugins.conf" | while read -r DIR URL REF; do
	echo ">>> ${DIR} from ${URL} ${REF}"
	SRC="${WORK}/src/$(echo "${DIR}" | tr / _)"
	git clone -q --depth 1 --branch "${REF}" "${URL}" "${SRC}"
	HASH="$(git -C "${SRC}" rev-parse --short=9 HEAD)"

	# drop it into the official tree, so it builds exactly like an official plugin
	rm -rf "${WORK}/plugins/${DIR}"
	mkdir -p "$(dirname "${WORK}/plugins/${DIR}")"
	cp -R "${SRC}/${DIR}" "${WORK}/plugins/${DIR}"
	# PHP and Python versions only go into informational metadata here
	make -C "${WORK}/plugins/${DIR}" package PLUGIN_HASH="${HASH}" PLUGIN_PHP=84 PLUGIN_PYTHON=311
	cp "${WORK}/plugins/${DIR}"/work/pkg/*.pkg "${REPO}/All/"
done

pkg repo "${REPO}"

cp "${ROOT}/martinseener.conf" "${PUBLIC}/martinseener.conf"
{
	echo '<!doctype html><meta charset="utf-8"><title>martinseener OPNsense repository</title>'
	echo '<h1>martinseener OPNsense repository</h1>'
	echo '<p>See <a href="https://github.com/martinseener/opnsense-repo">github.com/martinseener/opnsense-repo</a> for how to add it.</p>'
	echo '<h2>Packages</h2><ul>'
	for PKG in "${REPO}"/All/*.pkg; do
		echo "<li>$(basename "${PKG}")</li>"
	done
	echo '</ul>'
} > "${PUBLIC}/index.html"

ls -l "${REPO}" "${REPO}/All"
