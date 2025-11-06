#!/usr/bin/env python3
"""
Code Coverage Analysis Tool for FoundationUI
Analyzes source files and test files to estimate test coverage.
"""

import os
import re
from pathlib import Path
from collections import defaultdict

def count_lines_of_code(file_path):
    """Count lines of code (excluding comments and blank lines)"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        code_lines = 0
        in_multiline_comment = False

        for line in lines:
            stripped = line.strip()

            # Skip blank lines
            if not stripped:
                continue

            # Handle multiline comments
            if '/*' in stripped:
                in_multiline_comment = True
            if '*/' in stripped:
                in_multiline_comment = False
                continue
            if in_multiline_comment:
                continue

            # Skip single-line comments
            if stripped.startswith('//'):
                continue

            # Count as code line
            code_lines += 1

        return code_lines, len(lines)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0, 0

def analyze_file(file_path):
    """Analyze a Swift file for functions, structs, classes, etc."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Count various Swift constructs
        funcs = len(re.findall(r'\bfunc\s+\w+', content))
        structs = len(re.findall(r'\bstruct\s+\w+', content))
        classes = len(re.findall(r'\bclass\s+\w+', content))
        enums = len(re.findall(r'\benum\s+\w+', content))
        extensions = len(re.findall(r'\bextension\s+\w+', content))
        properties = len(re.findall(r'\b(var|let)\s+\w+', content))

        return {
            'functions': funcs,
            'structs': structs,
            'classes': classes,
            'enums': enums,
            'extensions': extensions,
            'properties': properties
        }
    except Exception as e:
        print(f"Error analyzing {file_path}: {e}")
        return {}

def main():
    base_path = Path('/home/user/ISOInspector/FoundationUI')
    sources_path = base_path / 'Sources' / 'FoundationUI'
    tests_path = base_path / 'Tests' / 'FoundationUITests'

    # Layers to analyze
    layers = {
        'DesignTokens': 'Layer 0',
        'Modifiers': 'Layer 1',
        'Components': 'Layer 2',
        'Patterns': 'Layer 3',
        'Contexts': 'Layer 4',
        'Utilities': 'Utilities'
    }

    results = {}

    for layer_dir, layer_name in layers.items():
        layer_path = sources_path / layer_dir

        if not layer_path.exists():
            continue

        source_files = list(layer_path.glob('*.swift'))
        total_loc = 0
        total_actual_lines = 0
        total_constructs = defaultdict(int)

        print(f"\n{'='*80}")
        print(f"{layer_name}: {layer_dir}")
        print(f"{'='*80}")

        for source_file in sorted(source_files):
            loc, actual_lines = count_lines_of_code(source_file)
            total_loc += loc
            total_actual_lines += actual_lines

            constructs = analyze_file(source_file)
            for key, value in constructs.items():
                total_constructs[key] += value

            print(f"  {source_file.name:40s} {loc:5d} LOC ({actual_lines:5d} total)")

        print(f"\n  {'TOTAL':40s} {total_loc:5d} LOC ({total_actual_lines:5d} total)")
        print(f"\n  Constructs:")
        print(f"    Functions:   {total_constructs['functions']}")
        print(f"    Structs:     {total_constructs['structs']}")
        print(f"    Classes:     {total_constructs['classes']}")
        print(f"    Enums:       {total_constructs['enums']}")
        print(f"    Extensions:  {total_constructs['extensions']}")
        print(f"    Properties:  {total_constructs['properties']}")

        # Analyze corresponding test files
        test_subdirs = {
            'DesignTokens': 'DesignTokensTests',
            'Modifiers': 'ModifiersTests',
            'Components': 'ComponentsTests',
            'Patterns': 'PatternsTests',
            'Contexts': 'ContextsTests',
            'Utilities': 'UtilitiesTests'
        }

        test_dir = test_subdirs.get(layer_dir)
        if test_dir:
            test_layer_path = tests_path / test_dir
            if test_layer_path.exists():
                test_files = list(test_layer_path.glob('*Tests.swift'))
                test_loc = 0
                test_actual_lines = 0

                print(f"\n  Test Files:")
                for test_file in sorted(test_files):
                    loc, actual_lines = count_lines_of_code(test_file)
                    test_loc += loc
                    test_actual_lines += actual_lines
                    print(f"    {test_file.name:38s} {loc:5d} LOC ({actual_lines:5d} total)")

                print(f"\n  {'TEST TOTAL':40s} {test_loc:5d} LOC ({test_actual_lines:5d} total)")

                # Calculate test/code ratio
                if total_loc > 0:
                    ratio = (test_loc / total_loc) * 100
                    print(f"\n  Test/Code Ratio: {ratio:.1f}%")
                    print(f"  Coverage Estimate: {'GOOD' if ratio > 50 else 'NEEDS IMPROVEMENT'}")

        results[layer_name] = {
            'source_loc': total_loc,
            'test_loc': test_loc if 'test_loc' in locals() else 0,
            'files': len(source_files)
        }

    # Summary
    print(f"\n{'='*80}")
    print("SUMMARY")
    print(f"{'='*80}")

    total_source_loc = sum(r['source_loc'] for r in results.values())
    total_test_loc = sum(r['test_loc'] for r in results.values())

    print(f"\nTotal Source LOC: {total_source_loc:,}")
    print(f"Total Test LOC:   {total_test_loc:,}")
    print(f"Overall Test/Code Ratio: {(total_test_loc/total_source_loc)*100:.1f}%")

    print(f"\n{'Layer':<20s} {'Source LOC':>12s} {'Test LOC':>12s} {'Ratio':>10s}")
    print(f"{'-'*60}")
    for layer_name, data in results.items():
        ratio = (data['test_loc'] / data['source_loc'] * 100) if data['source_loc'] > 0 else 0
        print(f"{layer_name:<20s} {data['source_loc']:>12,d} {data['test_loc']:>12,d} {ratio:>9.1f}%")

if __name__ == '__main__':
    main()
