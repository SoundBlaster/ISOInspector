#!/usr/bin/env python3
"""
Code Coverage Analysis Tool for FoundationUI
Analyzes source files and test files to estimate test coverage.

This tool uses repository-relative paths for cross-environment compatibility.
It can be executed from any directory and will resolve paths from the
repository root (identified by .git directory).
"""

import os
import sys
import re
import argparse
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

def find_repo_root():
    """
    Find the repository root by searching for .git directory.
    Starts from the current working directory and traverses upward.
    Falls back to script directory if .git is not found.
    """
    current_path = Path.cwd().resolve()

    # Try to find .git in current and parent directories
    while current_path != current_path.parent:
        if (current_path / '.git').exists():
            return current_path
        current_path = current_path.parent

    # Fallback to script directory's parent
    script_path = Path(__file__).resolve().parent
    if (script_path / '.git').exists():
        return script_path

    # Ultimate fallback: current working directory
    return Path.cwd().resolve()


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Analyze test coverage in the FoundationUI package.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python3 coverage_analysis.py                    # Analyze and report
  python3 coverage_analysis.py --threshold 0.67   # Check if coverage meets threshold
  python3 coverage_analysis.py --report coverage.txt  # Write report to file
        '''
    )
    parser.add_argument(
        '--threshold',
        type=float,
        default=None,
        help='Exit with non-zero code if coverage is below this threshold (0.0-1.0)'
    )
    parser.add_argument(
        '--report',
        type=str,
        default=None,
        help='Output report to file instead of stdout'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )

    args = parser.parse_args()

    # Find repository root
    repo_root = find_repo_root()
    base_path = repo_root / 'FoundationUI'
    sources_path = base_path / 'Sources' / 'FoundationUI'
    tests_path = base_path / 'Tests' / 'FoundationUITests'

    if args.verbose:
        print(f"Repository root: {repo_root}", file=sys.stderr)
        print(f"FoundationUI path: {base_path}", file=sys.stderr)
        print(f"Sources path: {sources_path}", file=sys.stderr)
        print(f"Tests path: {tests_path}", file=sys.stderr)
        print(file=sys.stderr)

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
    output_lines = []

    for layer_dir, layer_name in layers.items():
        layer_path = sources_path / layer_dir

        if not layer_path.exists():
            continue

        source_files = list(layer_path.glob('*.swift'))
        total_loc = 0
        total_actual_lines = 0
        total_constructs = defaultdict(int)

        output_lines.append(f"\n{'='*80}")
        output_lines.append(f"{layer_name}: {layer_dir}")
        output_lines.append(f"{'='*80}")

        for source_file in sorted(source_files):
            loc, actual_lines = count_lines_of_code(source_file)
            total_loc += loc
            total_actual_lines += actual_lines

            constructs = analyze_file(source_file)
            for key, value in constructs.items():
                total_constructs[key] += value

            output_lines.append(f"  {source_file.name:40s} {loc:5d} LOC ({actual_lines:5d} total)")

        output_lines.append(f"\n  {'TOTAL':40s} {total_loc:5d} LOC ({total_actual_lines:5d} total)")
        output_lines.append(f"\n  Constructs:")
        output_lines.append(f"    Functions:   {total_constructs['functions']}")
        output_lines.append(f"    Structs:     {total_constructs['structs']}")
        output_lines.append(f"    Classes:     {total_constructs['classes']}")
        output_lines.append(f"    Enums:       {total_constructs['enums']}")
        output_lines.append(f"    Extensions:  {total_constructs['extensions']}")
        output_lines.append(f"    Properties:  {total_constructs['properties']}")

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

                output_lines.append(f"\n  Test Files:")
                for test_file in sorted(test_files):
                    loc, actual_lines = count_lines_of_code(test_file)
                    test_loc += loc
                    test_actual_lines += actual_lines
                    output_lines.append(f"    {test_file.name:38s} {loc:5d} LOC ({actual_lines:5d} total)")

                output_lines.append(f"\n  {'TEST TOTAL':40s} {test_loc:5d} LOC ({test_actual_lines:5d} total)")

                # Calculate test/code ratio
                if total_loc > 0:
                    ratio = (test_loc / total_loc) * 100
                    output_lines.append(f"\n  Test/Code Ratio: {ratio:.1f}%")
                    output_lines.append(f"  Coverage Estimate: {'GOOD' if ratio > 50 else 'NEEDS IMPROVEMENT'}")

        results[layer_name] = {
            'source_loc': total_loc,
            'test_loc': test_loc if 'test_loc' in locals() else 0,
            'files': len(source_files)
        }

    # Summary
    output_lines.append(f"\n{'='*80}")
    output_lines.append("SUMMARY")
    output_lines.append(f"{'='*80}")

    total_source_loc = sum(r['source_loc'] for r in results.values())
    total_test_loc = sum(r['test_loc'] for r in results.values())

    output_lines.append(f"\nTotal Source LOC: {total_source_loc:,}")
    output_lines.append(f"Total Test LOC:   {total_test_loc:,}")

    # Calculate overall coverage ratio
    overall_ratio = 0.0
    if total_source_loc > 0:
        overall_ratio = (total_test_loc / total_source_loc)
        output_lines.append(f"Overall Test/Code Ratio: {overall_ratio*100:.1f}%")

    output_lines.append(f"\n{'Layer':<20s} {'Source LOC':>12s} {'Test LOC':>12s} {'Ratio':>10s}")
    output_lines.append(f"{'-'*60}")
    for layer_name, data in results.items():
        ratio = (data['test_loc'] / data['source_loc'] * 100) if data['source_loc'] > 0 else 0
        output_lines.append(f"{layer_name:<20s} {data['source_loc']:>12,d} {data['test_loc']:>12,d} {ratio:>9.1f}%")

    # Output report
    report_text = '\n'.join(output_lines)
    if args.report:
        with open(args.report, 'w') as f:
            f.write(report_text)
            f.write('\n')
        if args.verbose:
            print(f"Report written to: {args.report}", file=sys.stderr)
    else:
        print(report_text)

    # Check threshold if specified
    if args.threshold is not None:
        if overall_ratio >= args.threshold:
            if args.verbose:
                print(f"\n✅ Coverage {overall_ratio*100:.1f}% meets threshold {args.threshold*100:.1f}%", file=sys.stderr)
            sys.exit(0)
        else:
            print(f"\n❌ Coverage FAILED: {overall_ratio*100:.1f}% below threshold {args.threshold*100:.1f}%", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
