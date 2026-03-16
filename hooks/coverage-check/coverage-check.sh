#!/bin/bash
# Coverage Check Hook for Claude Code
# Automatically runs test coverage after task completion.
# Detects vitest/jest and checks against configurable thresholds.
#
# Install: copy to .claude/hooks/ and add to .claude/settings.json
# Thresholds: set LINE_THRESHOLD / BRANCH_THRESHOLD env vars (defaults: 70/60)

set -e

LINE_THRESHOLD="${LINE_THRESHOLD:-70}"
BRANCH_THRESHOLD="${BRANCH_THRESHOLD:-60}"

# Skip if no package.json (not a JS/TS project)
if [ ! -f "package.json" ]; then
  exit 0
fi

# Detect test runner
if grep -q '"vitest"' package.json 2>/dev/null; then
  RUNNER="npx vitest run --coverage --coverage.reporter=json-summary --coverage.reporter=text-summary"
elif grep -q '"jest"' package.json 2>/dev/null; then
  RUNNER="npx jest --coverage --coverageReporters=json-summary --coverageReporters=text-summary"
else
  exit 0
fi

echo ""
echo "📊 Running test coverage check..."
echo ""

# Run tests with coverage
eval $RUNNER 2>&1 || {
  echo "❌ Tests failed! Fix failing tests before checking coverage."
  exit 1
}

# Parse coverage
COVERAGE_FILE="coverage/coverage-summary.json"
if [ ! -f "$COVERAGE_FILE" ]; then
  echo "⚠️  Coverage summary not found at $COVERAGE_FILE"
  exit 0
fi

# Check thresholds
node -e "
  const summary = require('./$COVERAGE_FILE');
  const total = summary.total;
  const lines = total.lines.pct;
  const branches = total.branches.pct;
  const functions = total.functions.pct;
  const lineThreshold = ${LINE_THRESHOLD};
  const branchThreshold = ${BRANCH_THRESHOLD};

  console.log('📊 Coverage Results:');
  console.log('  Lines:      ' + lines + '%' + (lines >= lineThreshold ? ' ✅' : ' ❌ (need >= ' + lineThreshold + '%)'));
  console.log('  Branches:   ' + branches + '%' + (branches >= branchThreshold ? ' ✅' : ' ❌ (need >= ' + branchThreshold + '%)'));
  console.log('  Functions:  ' + functions + '%');
  console.log('');

  const pass = lines >= lineThreshold && branches >= branchThreshold;
  if (pass) {
    console.log('✅ Coverage check PASSED');
  } else {
    console.log('⚠️  Coverage below threshold! Please add more tests.');
    console.log('');
    console.log('📋 Files below threshold:');
    Object.entries(summary).forEach(([file, cov]) => {
      if (file === 'total') return;
      if (cov.lines.pct < lineThreshold || cov.branches.pct < branchThreshold) {
        const shortFile = file.replace(process.cwd() + '/', '');
        console.log('  ' + shortFile + ' — Lines: ' + cov.lines.pct + '%, Branches: ' + cov.branches.pct + '%');
      }
    });
  }
"
