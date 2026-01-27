#!/bin/bash
# =============================================================================
# Run All Linters Locally
# =============================================================================
# Runs the same linters as CI: RuboCop, Erblint, ESLint, Brakeman
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "========================================================"
echo "Running Linters"
echo "========================================================"
echo ""

# =============================================================================
# RuboCop
# =============================================================================
echo "1/4 Running RuboCop..."
if bundle exec rubocop; then
    echo "✅ RuboCop passed"
else
    echo "❌ RuboCop failed"
    exit 1
fi

echo ""

# =============================================================================
# Erblint
# =============================================================================
echo "2/4 Running Erblint..."
if bundle exec erb_lint ./app; then
    echo "✅ Erblint passed"
else
    echo "❌ Erblint failed"
    exit 1
fi

echo ""

# =============================================================================
# ESLint
# =============================================================================
echo "3/4 Running ESLint..."
if yarn eslint; then
    echo "✅ ESLint passed"
else
    echo "❌ ESLint failed"
    exit 1
fi

echo ""

# =============================================================================
# Brakeman
# =============================================================================
echo "4/4 Running Brakeman..."
if bundle exec brakeman -q --exit-on-warn; then
    echo "✅ Brakeman passed"
else
    echo "❌ Brakeman failed"
    exit 1
fi

echo ""
echo "========================================================"
echo "All linters passed! ✅"
echo "========================================================"
echo ""
