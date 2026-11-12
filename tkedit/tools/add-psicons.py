"""Copies glyphs from the Fluent UI System Icons font into fonts/PsIcons.ttf, at their own codepoints.

vendor/tkControls draws some of its own icons -- the message box's question / info icon and its
close X -- at FluentSystemIcons-Regular.ttf codepoints, and tkEdit gives its controls PsIcons.ttf,
which holds only the glyphs tkEdit asked for. This adds the ones a vendor control needs, so tkEdit
keeps one small icon font instead of shipping the 2.9 MB Fluent one.

    python tools/add-psicons.py <FluentSystemIcons-Regular.ttf> [hex codepoint ...]

With no codepoints: F63D (question), F4A3 (info), F369 (close), F2AA / F2B0 (chevron left /
right: the tab strip's scroll buttons), F582 / F373 (open / contract_down_left: the Form Designer's
float and dock), F3DD (edit: its event rows' go-to-the-code). A codepoint PsIcons already maps
is left alone. Both fonts are 500 units per em with TrueType outlines; anything else is refused.
Needs fontTools (pip install fonttools). Same licence as the rest of PsIcons: MIT, Fluent's.
"""
import os
import sys

from fontTools.ttLib import TTFont

DEFAULT = [0xF63D, 0xF4A3, 0xF369, 0xF2AA, 0xF2B0, 0xF582, 0xF373, 0xF3DD]


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    here = os.path.dirname(os.path.abspath(__file__))
    target = os.path.join(here, '..', 'fonts', 'PsIcons.ttf')
    ps, fl = TTFont(target), TTFont(sys.argv[1])
    cps = [int(a, 16) for a in sys.argv[2:]] or DEFAULT
    for f, n in ((ps, 'PsIcons'), (fl, 'Fluent')):
        if f['head'].unitsPerEm != 500 or 'glyf' not in f:
            sys.exit('%s: not 500 units per em with TrueType outlines' % n)
    flmap, psmap = fl.getBestCmap(), ps.getBestCmap()
    order = ps.getGlyphOrder()
    added = []
    for cp in cps:
        if cp in psmap:
            print('U+%04X: already in PsIcons as %s' % (cp, psmap[cp]))
            continue
        name = flmap.get(cp)
        if name is None:
            sys.exit('U+%04X: not in the Fluent font' % cp)
        glyph = fl['glyf'][name]
        if glyph.isComposite():
            sys.exit('U+%04X (%s): a composite glyph; not handled' % (cp, name))
        if name not in order:
            order.append(name)
            ps.setGlyphOrder(order)
            ps['glyf'][name] = glyph
            ps['hmtx'][name] = fl['hmtx'][name]
        for t in ps['cmap'].tables:
            if t.isUnicode():
                t.cmap[cp] = name
        added.append('U+%04X %s' % (cp, name))
    if not added:
        print('nothing to add')
        return
    ps['maxp'].numGlyphs = len(order)
    ps.save(target)
    print('added to %s:' % os.path.normpath(target))
    for a in added:
        print('  ' + a)


if __name__ == '__main__':
    main()
