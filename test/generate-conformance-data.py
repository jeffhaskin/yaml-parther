#!/usr/bin/env python3
"""Generate conformance test data from yaml-test-suite for Common Lisp.

This script reads the yaml-test-suite YAML files and outputs a Lisp-loadable
file containing all test cases as S-expressions.

Usage:
    python3 generate-conformance-data.py > conformance-data.lisp
"""

import os
import sys
import json
import yaml
from pathlib import Path

SUITE_DIR = Path(__file__).parent.parent / "tests" / "yaml-test-suite" / "src"

def escape_lisp_string(s):
    """Escape a string for Lisp literal representation."""
    if s is None:
        return 'nil'
    s = str(s)
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    return f'"{s}"'

def generate_tests():
    """Generate all test cases from the suite."""
    tests = []

    for yaml_file in sorted(SUITE_DIR.glob("*.yaml")):
        test_id = yaml_file.stem

        try:
            with open(yaml_file, 'r', encoding='utf-8') as f:
                docs = list(yaml.safe_load_all(f))
        except Exception as e:
            print(f";; Error loading {yaml_file}: {e}", file=sys.stderr)
            continue

        for doc in docs:
            if not isinstance(doc, list):
                doc = [doc]

            for idx, test in enumerate(doc):
                if not isinstance(test, dict):
                    continue

                case_id = f"{test_id}" if len(doc) == 1 else f"{test_id}/{idx:02d}"
                name = test.get('name', case_id)
                yaml_input = test.get('yaml', '')
                json_output = test.get('json')
                tree_output = test.get('tree', '')
                fail_flag = test.get('fail', False)
                tags = test.get('tags', '')

                tests.append({
                    'id': case_id,
                    'name': name,
                    'yaml': yaml_input,
                    'json': json_output,
                    'tree': tree_output,
                    'fail': fail_flag,
                    'tags': tags,
                })

    return tests

def main():
    tests = generate_tests()

    print(';;;; conformance-data.lisp --- Auto-generated conformance test data.')
    print(';;;; DO NOT EDIT. Regenerate with: python3 generate-conformance-data.py')
    print()
    print('(in-package #:yaml-parther/test)')
    print()
    print('(defparameter *conformance-tests*')
    print("  '(")

    for t in tests:
        json_str = json.dumps(t['json']) if t['json'] is not None else 'nil'
        fail_str = 't' if t['fail'] else 'nil'

        print(f'    (:id {escape_lisp_string(t["id"])}')
        print(f'     :name {escape_lisp_string(t["name"])}')
        print(f'     :yaml {escape_lisp_string(t["yaml"])}')
        print(f'     :json {escape_lisp_string(json_str) if t["json"] is not None else "nil"}')
        print(f'     :fail {fail_str}')
        print(f'     :tags {escape_lisp_string(t["tags"])})')

    print('    )')
    print('  "Conformance test cases from yaml-test-suite.")')
    print()
    print(f';; Total: {len(tests)} test cases')
    print(f';; Expected failures: {sum(1 for t in tests if t["fail"])}')

if __name__ == '__main__':
    main()
