#!/usr/bin/env python3
"""draw.io helpers for confluence.sh (stdlib only).

  drawio.py macros < storage.xml   \x1f-separated: pageId-or-empty, name, revision, heading
  drawio.py summary FILE           Shapes and connections as text
"""
import base64, html, re, sys, urllib.parse, zlib
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


if __name__ == '__main__':
    if sys.argv[1:] == ['macros']:
        macros(sys.stdin.read())
    elif len(sys.argv) == 3 and sys.argv[1] == 'summary':
        summary(sys.argv[2])
    else:
        sys.exit(__doc__)
