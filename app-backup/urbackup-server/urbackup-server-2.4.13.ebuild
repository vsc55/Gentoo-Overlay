# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6
inherit eutils user systemd

DESCRIPTION="Servidor UrBackup, permite hacer copias de sguridad de documentos de todos los puestos de la red."
HOMEPAGE="http://www.urbackup.org"
SRC_URI="https://hndl.urbackup.org/Server/${PV}/${P}.tar.gz"
S="${WORKDIR}/${P}"

SLOT="0"
LICENSE="AGPL-3"
KEYWORDS="x86 amd64"
IUSE="-systemd crypt hardened fuse mail zlib logrotate"


RDEPEND="
	dev-db/sqlite
	>=sys-devel/gcc-4.1.1
	>=sys-libs/glibc-2.28
	crypt? ( dev-libs/crypto++ )
	fuse? ( >=sys-fs/fuse-2.6 )
	mail? ( >=net-misc/curl-7.23.1[ssl] )
	zlib? ( >=sys-libs/zlib-1.1.4 )
"
DEPEND="${RDEPEND}"


PATCHES=(
	"${FILESDIR}/urbackup-server-2.4.1x-autoupdate-code.patch"
	"${FILESDIR}/urbackup-server-2.4.1x-autoupdate-config.patch"
	"${FILESDIR}/urbackup-server-2.4.1x-autoupdate-ui.patch"
	"${FILESDIR}/urbackup-server-2.4.1x-autoupdate-datafiles-gcc-fortify.patch"
)


INIT_SCRIPT_OLD="${ROOT}/etc/init.d/urbackup_srv"
INIT_SCRIPT="${ROOT}/etc/init.d/urbackupsrv"


src_configure() {
	cd "${S}"
	econf \
	$(use_with crypt crypto) \
	$(use_enable hardened fortify) \
	$(use_with fuse mountvhd) \
	$(use_with mail) \
	$(use_with zlib) \
	--enable-packaging
}

# src_compile() {
#	cd "${S}"
#	emake DESTDIR="${D}"

# die "D ES ${D}    - WORKDIR: ${WORKDIR}"
# }

src_install() {
	cd "${S}"

	emake DESTDIR="${D}" install

	dodir "${EPREFIX}"/usr/share/man/man1
	
	if use logrotate; then
		insinto "${EPREFIX}"/etc/logrotate.d
		newins "${FILESDIR}"/urbackupsrv.logrotate urbackupsrv
	fi
	
	insinto "${EPREFIX}"/etc/urbackup
	newins "${FILESDIR}"/urbackupsrv.conf_v3 urbackupsrv.conf
	
	newconfd "${FILESDIR}"/urbackupsrv.conf_v4 urbackupsrv
	newinitd "${FILESDIR}"/urbackupsrv.init_v4 urbackupsrv
	
	if use systemd; then
		systemd_newunit ${FILESDIR}/urbackup-server.service_v3 urbackup-server.service
	fi
	
	fowners -R urbackup:urbackup "${EPREFIX}/var/lib/urbackup"
	fowners -R urbackup:urbackup "${EPREFIX}/usr/share/urbackup/www"	
}

urbackup_service_stop() {
	# Mata el proceso antes de copiar la nueva version de programa al HD.
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT_OLD}" ]; then
		${INIT_SCRIPT_OLD} stop
	fi
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_preinst() {
	enewgroup urbackup
	enewuser urbackup -1 /bin/bash "${EPREFIX}"/var/lib/urbackup urbackup
	
	urbackup_service_stop
}

pkg_prerm() {
	urbackup_service_stop
}

pkg_postinst() {
	einfo ""
	elog "Browse to http://localhost:55414 and setup an admin user and the backup storage path."
	elog ""
	elog "Setup auto start daemon:"
	elog "# rc-update add urbackupsrv default"
	elog ""
	elog "Start service:"
	elog "# /etc/init.d/urbackupsrv start"
	elog ""
	elog "Firewall Ports:"
	elog " - TCP > 55413-55415"
	elog " - UDP > 35623"
	elog ""
	
	if use systemd; then
		elog "Setup auto start daemon:"
		elog "# systemctl enable urbackup-server.service"
		elog ""
	fi
	
	#If your distribution is not Debian or Debian based you have to either build your own init script or just put /usr/local/sbin/urbackupsrv run -d into /etc/rc.local.
}