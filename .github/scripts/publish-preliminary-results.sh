#!/usr/bin/env bash
# Publish only generated outputs, preserving updates made during a long run.
set -euo pipefail

branch=${1:-${GITHUB_REF_NAME:-}}
if [[ -z "$branch" ]]; then
  echo "Usage: publish-preliminary-results.sh BRANCH" >&2
  exit 1
fi
git check-ref-format "refs/heads/$branch"
base_revision=$(git rev-parse HEAD)
remote_ref="refs/remotes/origin/$branch"

git add -- data/splits/source_split.csv results/*.csv results/preliminary_figures/*.png
if git diff --cached --quiet; then
  echo "Preliminary results are already up to date."
  exit 0
fi
git commit -m "Add preliminary handcrafted SVM and YAMNet results"

for attempt in 1 2 3; do
  git fetch origin "refs/heads/$branch:$remote_ref"
  if ! git diff --quiet "$base_revision" "$remote_ref" -- \
      src tests .github/workflows/preliminary-matlab.yml; then
    echo "::warning::Experiment code changed during this run; results remain available in the preliminary-results artifact."
    exit 0
  fi
  if ! git rebase "$remote_ref"; then
    git rebase --abort
    echo "::warning::Results changed concurrently; keeping the remote results. This run's outputs remain available in the preliminary-results artifact."
    exit 0
  fi
  if git push origin "HEAD:refs/heads/$branch"; then
    echo "Published preliminary results on $branch."
    exit 0
  fi
  echo "Push attempt $attempt failed; checking the branch again."
done

echo "Unable to publish results after three attempts; download the preliminary-results artifact." >&2
exit 1
