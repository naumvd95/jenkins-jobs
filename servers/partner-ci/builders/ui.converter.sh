#!/bin/bash
cat << CONTENT > converter.py
import xml.etree.ElementTree as xml
import sys

path_src = sys.argv[1]
path_dst = sys.argv[2]

tree = xml.parse(path_src)
root = tree.getroot()

suite_info = root[0].attrib
new_doc = xml.Element('testsuite', attrib={
    'name': 'nosetests',
    'tests': suite_info['tests'],
    'errors': suite_info['failures'],
    'failures': '0',
    'skip': suite_info['skipped'],
    'time': suite_info['time']
})

failed = 0
passed = 0
for tc in root.iter('testcase'):
    tc_info = tc.attrib
    new_tc = xml.SubElement(new_doc, 'testcase', attrib={
        'classname': tc_info['name'],
        'name': tc_info['name'],
        'time': tc_info['time'],
        'status': tc_info['status']
    })
    if tc_info['status'] != '0':
        failed += 1
        tc_err = tc[0].attrib
        err = xml.SubElement(new_tc, 'error', attrib={
            'type': tc_err['type'],
            'message': tc_err['message']
        })
        err.text = tc[0].text
    else:
        passed += 1

failures = int(suite_info['failures'])
if failed < failures:
    new_doc.attrib['failures'] = str(failures)
    new_doc.attrib['errors'] = str(passed - failures)

with open(path_dst, 'w') as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>')
    f.write(xml.tostring(new_doc, encoding='utf-8'))
CONTENT
