# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils user

DESCRIPTION="Servidor UrBackup, permite hacer copias de sguridad de documentos de todos los puestos de la red."
HOMEPAGE="http://www.urbackup.org"
KEYWORDS="x86 amd64"
SRC_URI="https://hndl.urbackup.org/Server/${PV}/${P}.tar.gz"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

RDEPEND="dev-libs/crypto++"
DEPEND="${RDEPEND}"

INIT_SCRIPT="${ROOT}/etc/init.d/urbackup_srv"
S="${WORKDIR}/${P}"

pkg_setup() {
	enewgroup urbackup
	enewuser urbackup -1 -1 /var/lib/urbackup  urbackup --system
}

src_configure() {
	cd "${S}"
	econf
}

src_compile() {
	cd "${S}"
	emake DESTDIR="${D}"
}

src_install() {
	cd "${S}"
	emake DESTDIR="${D}" install
	
	insinto /etc/conf.d ; newins ${FILESDIR}/urbackup_srv.conf urbackup_srv
	exeinto /etc/init.d ; newexe ${FILESDIR}/urbackup_srv.init urbackup_srv
}

pkg_preinst() {
	# Mata el proceso antes de copiar la nueva version de programa al HD.
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
	
	einfo "patching startup"
	# apply patch for start_pms to use the new config file
		cd usr/sbin
		epatch "${FILESDIR}"/start_urbackup_server.patch
		cd ../..
}

pkg_prerm() {
	# Mata el proceso antes de desintalar.
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_postinst() {
	einfo ""
	elog "Texto info inid.d/run etc...."
	ewarn "Texto Warngin!!!"
	einfo ""
}
