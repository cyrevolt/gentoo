# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils gnome2-utils qmake-utils

DESCRIPTION="A peg solitaire game"
HOMEPAGE="https://gottcode.org/peg-e/"
SRC_URI="https://gottcode.org/peg-e/${P}-src.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
"
DEPEND="${RDEPEND}
	dev-qt/linguist-tools:5
"

src_configure() {
	eqmake5
}

src_install() {
	dobin ${PN}
	doicon -s 48 icons/hicolor/48x48/apps/${PN}.png
	domenu icons/${PN}.desktop
	dodoc CREDITS ChangeLog
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
