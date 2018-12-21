# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils user

DESCRIPTION="Cliente UrBackup, permite hacer copias de sguridad de documentos de todos los puestos de la red."
HOMEPAGE="http://www.urbackup.org"
KEYWORDS="x86 amd64"
SRC_URI="https://hndl.urbackup.org/Client/${PV}/${P}.tar.gz"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

RDEPEND="dev-libs/crypto++ 
	     x11-libs/wxGTK"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${P}"

src_configure() {
	cd "${S}"
	econf
	
	einfo "Patching Startup..."
		epatch "${FILESDIR}"/start_urbackup_client.patch || die "Error Fix"
}

src_compile() {
	cd "${S}"
	emake DESTDIR="${D}"
}

src_install() {
	cd "${S}"
	emake DESTDIR="${D}" install
	
	insinto /etc/conf.d ; newins ${FILESDIR}/urbackup_client.conf urbackup_client
	exeinto /etc/init.d ; newexe ${FILESDIR}/urbackup_client.init urbackup_client
}

pkg_postinst() {
	einfo ""
	elog "Texto info inid.d/run etc...."
	ewarn "Texto Warngin!!!"
	einfo ""
}
