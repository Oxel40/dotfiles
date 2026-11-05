#!/usr/bin/env python3
"""draw.io helpers for confluence.sh (stdlib only).

  drawio.py macros < storage.xml   \x1f-separated: pageId-or-empty, name, revision, heading
  drawio.py summary FILE           Shapes and connections as text
  drawio.py render FILE OUT.png    Render with headless Chrome; prints "WIDTH HEIGHT"
  drawio.py set-macro NAME REV W H [ANCHOR] < storage > storage
                                   Point the drawio macro NAME at attachment version REV,
                                   or insert it after ANCHOR (exact storage snippet) if missing
"""
import base64, html, json, os, re, subprocess, sys, tempfile, urllib.parse, zlib
import xml.etree.ElementTree as ET

MACRO = re.compile(r'<ac:structured-macro ac:name="(?:inc-)?drawio".*?</ac:structured-macro>', re.S)
HEADING = re.compile(r'<h[1-6][^>]*>(.*?)</h[1-6]>', re.S)
PARAM = re.compile(r'<ac:parameter ac:name="(\w+)">([^<]*)</ac:parameter>')
ENDS = {'ERone': '1', 'ERmandOne': '1', 'ERzeroToOne': '0..1', 'ERmany': '*',
        'ERoneToMany': '1..*', 'ERzeroToMany': '0..*'}


def text(value):
    value = re.sub(r'<br\s*/?>|</(div|p|li)>', ' ', value or '', flags=re.I)
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', value))).strip()


def field(value):
    return re.sub(r'[\x1f\r\n]+', ' ', value)


def macros(storage):
    for m in MACRO.finditer(storage):
        params = {k: html.unescape(v) for k, v in PARAM.findall(m.group(0))}
        headings = HEADING.findall(storage, 0, m.start())
        page_id = params.get('pageId', '')
        revision = params.get('revision', '')
        # Untrusted page content: only pass through well-formed IDs/versions.
        print('\x1f'.join([page_id if page_id.isdigit() else '',
                         field(params.get('diagramName', '')),
                         revision if revision.isdigit() else '',
                         field(text(headings[-1]) if headings else '')]))


def models(path):
    for diagram in ET.parse(path).getroot().iter('diagram'):
        model = diagram.find('mxGraphModel')
        if model is None and (diagram.text or '').strip():
            # Compressed form: base64 -> raw deflate -> URL-encoded XML.
            raw = zlib.decompress(base64.b64decode(diagram.text.strip()), -15)
            model = ET.fromstring(urllib.parse.unquote(raw.decode()))
        if model is not None:
            yield diagram.get('name', ''), model


def cells(model):
    """id -> attribute dict; <object>/<UserObject> wrappers hold id and label."""
    out = {}
    for el in model.iter():
        if el.tag in ('object', 'UserObject'):
            inner = el.find('mxCell')
            attrs = dict(inner.attrib if inner is not None else {})
            attrs.update(id=el.get('id'), value=el.get('label', ''))
        elif el.tag == 'mxCell' and el.get('id'):  # wrapped mxCells have no id
            attrs = dict(el.attrib)
        else:
            continue
        out[attrs['id']] = attrs
    return out


def summary(path):
    for name, model in models(path):
        c = cells(model)
        print(f'## Diagram page: {name}')
        edges = [x for x in c.values() if x.get('edge') == '1']
        labels = {}  # edge id -> label cells sitting on the edge
        for x in c.values():
            parent = c.get(x.get('parent'), {})
            if x.get('vertex') == '1' and parent.get('edge') == '1' and text(x.get('value')):
                labels.setdefault(parent['id'], []).append(text(x['value']))

        def name_of(cid):
            if cid not in c:
                return '(unconnected)'
            x, hops = c[cid], 0
            # Unlabeled shapes (e.g. sequence activation bars): use labeled ancestor.
            while not text(x.get('value')) and x.get('parent') in c and hops < 50:
                x, hops = c[x['parent']], hops + 1
            return text(x.get('value')) or f'[unlabeled {cid}]'

        def depth(x):
            d, p = 0, c.get(x.get('parent'))
            while p is not None and p.get('vertex') == '1' and d < 50:
                d, p = d + 1, c.get(p.get('parent'))
            return d

        print('Shapes (indented = inside container):')
        for x in c.values():
            parent = c.get(x.get('parent'), {})
            if x.get('vertex') == '1' and parent.get('edge') != '1' and text(x.get('value')):
                print(f"{'  ' * (depth(x) + 1)}- {text(x['value'])}")
        print('Connections:')
        for e in edges:
            style = dict(p.split('=', 1) for p in (e.get('style') or '').split(';') if '=' in p)
            start = ENDS.get(style.get('startArrow', ''), '')
            end = ENDS.get(style.get('endArrow', ''), '')
            label = ' / '.join(filter(None, [text(e.get('value'))] + labels.get(e['id'], [])))
            line = f"  - {name_of(e.get('source'))} -> {name_of(e.get('target'))}"
            if label:
                line += f' : {label}'
            if start or end:
                line += f" [cardinality {start or '-'} : {end or '-'}]"
            print(line)
        print()


VIEWER_URL = 'https://viewer.diagrams.net/js/viewer-static.min.js'
CHROME = os.environ.get('CHROME_BIN', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
MARGIN = 10


def bounds(model):
    """Box around top-level shapes; edge waypoints are ignored."""
    c = cells(model)
    layers = {i for i, x in c.items() if x.get('parent') == '0'}
    boxes = []
    for el in model.iter('mxCell'):
        g = el.find('mxGeometry')
        if el.get('vertex') == '1' and el.get('parent') in layers and g is not None:
            x, y = float(g.get('x', 0)), float(g.get('y', 0))
            boxes.append((x, y, x + float(g.get('width', 0)), y + float(g.get('height', 0))))
    if not boxes:
        sys.exit('render: diagram has no shapes')
    return [f(b[i] for b in boxes) for f, i in ((min, 0), (min, 1), (max, 2), (max, 3))]


def render(path, out):
    _, model = next(models(path))
    x0, y0, x1, y1 = bounds(model)
    # The viewer needs some room beyond border + bounds; extra whitespace beats clipping.
    w, h = int(x1 - x0) + 2 * MARGIN + 20, int(y1 - y0) + 2 * MARGIN + 40
    tmp = os.environ.get('TMPDIR', '/tmp')
    viewer = os.path.join(tmp, 'drawio-viewer-static.min.js')
    if not os.path.exists(viewer):
        # curl, not urllib: the CDN rejects Python's user agent.
        subprocess.run(['curl', '-q', '-sSf', '--max-time', '60', '-o', viewer, VIEWER_URL], check=True)
    cfg = {'highlight': 'none', 'nav': False, 'resize': False, 'toolbar': '', 'border': MARGIN,
           'xml': open(path).read()}
    with tempfile.TemporaryDirectory(dir=tmp) as d:
        page = os.path.join(d, 'diagram.html')
        # charset matters: the viewer has non-ASCII regexes.
        open(page, 'w').write(f'<html><head><meta charset="utf-8"></head><body style="margin:0;background:#fff">'
                              f'<div class="mxgraph" data-mxgraph="{html.escape(json.dumps(cfg))}"></div>'
                              f'<script src="file://{viewer}"></script></body></html>')
        subprocess.run([CHROME, '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-crash-reporter',
                        f'--user-data-dir={d}/profile', '--hide-scrollbars', '--allow-file-access-from-files',
                        '--virtual-time-budget=20000', f'--window-size={w},{h}',
                        f'--screenshot={os.path.abspath(out)}', f'file://{page}'],
                       check=True, capture_output=True, timeout=120)
    if not os.path.getsize(out):
        sys.exit('render: empty screenshot')
    print(w, h)


def set_macro(storage, name, rev, width, height, anchor=None):
    params = {'revision': rev, 'diagramWidth': width, 'height': height}
    for m in MACRO.finditer(storage):
        found = {k: html.unescape(v) for k, v in PARAM.findall(m.group(0))}
        if found.get('diagramName') != name:
            continue
        macro = m.group(0)
        for k, v in params.items():
            new = f'<ac:parameter ac:name="{k}">{v}</ac:parameter>'
            macro, n = re.subn(rf'<ac:parameter ac:name="{k}">[^<]*</ac:parameter>', new, macro)
            if not n:
                macro = macro.replace('</ac:structured-macro>', new + '</ac:structured-macro>')
        return storage[:m.start()] + macro + storage[m.end():]
    if anchor is None:
        sys.exit(f'set-macro: no drawio macro named {name!r} on the page; pass an anchor to insert one')
    if storage.count(anchor) != 1:
        sys.exit(f'set-macro: anchor must occur exactly once, found {storage.count(anchor)}')
    p = lambda k, v: f'<ac:parameter ac:name="{k}">{v}</ac:parameter>'
    macro = ('<p><ac:structured-macro ac:name="drawio" ac:schema-version="1">' + p('border', 'true')
             + p('diagramName', html.escape(name, quote=False)) + p('simpleViewer', 'false') + p('links', 'auto')
             + p('tbstyle', 'top') + p('lbox', 'true') + ''.join(p(k, v) for k, v in params.items())
             + '</ac:structured-macro></p>')
    return storage.replace(anchor, anchor + macro)


if __name__ == '__main__':
    if sys.argv[1:] == ['macros']:
        macros(sys.stdin.read())
    elif len(sys.argv) == 3 and sys.argv[1] == 'summary':
        summary(sys.argv[2])
    elif len(sys.argv) == 4 and sys.argv[1] == 'render':
        render(sys.argv[2], sys.argv[3])
    elif len(sys.argv) in (6, 7) and sys.argv[1] == 'set-macro' and all(a.isdigit() for a in sys.argv[3:6]):
        sys.stdout.write(set_macro(sys.stdin.read(), *sys.argv[2:]))
    else:
        sys.exit(__doc__)
