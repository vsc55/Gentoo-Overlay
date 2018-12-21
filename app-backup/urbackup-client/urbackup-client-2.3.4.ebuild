# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

inherit eutils user wxwidgets l10n systemd

PLOCALES="cs da de es fa fr it nl pl pt_BR ru sk uk zh_CN zh_TW"
PLOCALE_BACKUP="en"

DESCRIPTION="Client for UrBackup server"
HOMEPAGE="http://www.urbackup.org"
SRC_URI="https://hndl.urbackup.org/Client/${PV}/${P}.tar.gz"
S=${WORKDIR}/${P}.0
INIT_SCRIPT="${ROOT}/etc/init.d/urbackupclient"

SLOT="0"
LICENSE="AGPL-3"
KEYWORDS="x86 amd64"
IUSE="systemd hardened X zlib linguas_cs linguas_da linguas_de linguas_es linguas_fa linguas_fr linguas_it linguas_nl linguas_pl linguas_pt_BR linguas_ru linguas_sk linguas_uk linguas_zh_CN linguas_zh_TW"


RDEPEND="
	dev-db/sqlite
	X? ( x11-libs/wxGTK )
	dev-libs/crypto++
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}"

#PATCHES=(
#	"${FILESDIR}/${P}-gcc-fortify.patch"
#	"${FILESDIR}/${P}-autoupdate.patch"
#	"${FILESDIR}/${P}-manpage.patch"
#	"${FILESDIR}/${P}-conf.patch"
#	"${FILESDIR}/${P}-locale.patch"
#	"${FILESDIR}/${P}-etc-perms.patch"
#)

PATCHES=(
	"${FILESDIR}/${P}-conf.patch"
	"${FILESDIR}/${P}-Makefile.patch"
)

src_configure() {
	econf \
	$(use_enable hardened fortify) \
	$(use_enable !X headless) \
	$(use_with zlib) \
	--disable-clientupdate
}

src_install() {
	cd "${S}"
	
	dodir "${EPREFIX}"/usr/share/man/man1
	install_locale_docs() {
	local locale_doc="client/data/lang/$1/urbackup.mo"
		insinto "${EPREFIX}"/usr/share/locale/$1/LC_MESSAGES
		[[ ! -e ${locale_doc} ]] || doins ${locale_doc}
		}
	emake DESTDIR="${D}" install
	if use X
		then l10n_for_each_locale_do install_locale_docs
	fi
	
	insinto "${EPREFIX}"/etc/logrotate.d
	if use systemd; then
		newins "${FILESDIR}"/logrotate_urbackupclient.systemd urbackupclient
	#else
		#newins "${FILESDIR}"/urbackupsrv.logrotate urbackupclient
	fi
	
	newconfd defaults_client urbackupclient
	doinitd "${FILESDIR}"/urbackupclient
	if use systemd; then
		systemd_dounit "${FILESDIR}"/urbackup-client.service
	fi
	
	dodir "${EPREFIX}"/etc/urbackup
	insinto "${EPREFIX}"/etc/urbackup
	doins "${FILESDIR}"/snapshot.cfg
	insinto "${EPREFIX}"/usr/share/urbackup/scripts
	insopts -m0700
	doins "${FILESDIR}"/btrfs_create_filesystem_snapshot
	doins "${FILESDIR}"/btrfs_remove_filesystem_snapshot
	doins "${FILESDIR}"/dattobd_create_filesystem_snapshot
	doins "${FILESDIR}"/dattobd_remove_filesystem_snapshot
	doins "${FILESDIR}"/lvm_create_filesystem_snapshot
	doins "${FILESDIR}"/lvm_remove_filesystem_snapshot
}

pkg_preinst() {
	# Mata el proceso antes de copiar la nueva version de programa al HD.
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_prerm() {
	# Mata el proceso antes de desintalar.
	einfo "Stopping running instances of UrBackup Client"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_postinst() {
	einfo ""
	elog "Setup auto start daemon:"
	elog "# rc-update add urbackupclient default"
	elog ""
	elog "Start service:"
	elog "# /etc/init.d/urbackupclient start"
	einfo ""
	elog "Start the UrBackup client frontend and setup your paths by executing:"
	elog "# urbackupclientgui"
	elog "and clicking on the tray icon and add paths. You can also do that on the server."
	einfo ""
}
