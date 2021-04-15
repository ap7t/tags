#!/bin/bash

# Get the changes between 2 tags.
function get_changes_between_tags() {
    git fetch origin &> /dev/null
    # Get the newest tag and the one that came before it, for comparison
    NEWEST_2_TAGS="$(git tag --merged origin/master --sort=creatordate | tail -n 2)"
    FROM_TAG=${1:-"$(echo "$NEWEST_2_TAGS" | head -n 1)"}
    TO_TAG=${2:-"$(echo "$NEWEST_2_TAGS" | tail -n 1)"}
    # Find the merge commit hashes between the two tags (in the last release)
    MERGE_HASHES="$(git log $FROM_TAG...$TO_TAG --pretty='format:%H')"
    # Get the last 40 PRs, in the format num=hash=title
    PULL_REQUESTS="$(hub pr list -s merged -o updated -L 40 -f '%I!;%sm!;%t!;%U%n')"
    # Filter to PRs which were merged in the last release. Exclude PRs starting with 'release'
    PULL_REQUESTS="$(echo "$PULL_REQUESTS" | grep "$MERGE_HASHES" | grep -vi '!;deploy' | grep -vi '!;projectsapigo@')"
    # Format the PRs into markdown changes, in the format "title [#num](pr-url)"
    CHANGES="$(echo "$PULL_REQUESTS" | sed -E "s/([0-9]*)!;([0-9a-f]*)!;(.*)!;(.*)/* \3 [#\1](\4)/")"
    # Output the changes if there are any
    if [ -n "$CHANGES" ]; then
        echo "$CHANGES"
    fi
}

# Get the changes for branch:develop based on the most recent tag.
function get_changes() {
    git fetch origin &> /dev/null
    # Get lastest tag currenty in production. Help find latest changes based on this tag.
    LATEST_TAG="$(git tag --merged origin/master --sort=creatordate | tail -n 1)"
    # Find the merge commit hashes between the tag and head.
    MERGE_HASHES="$(git log $LATEST_TAG..origin/develop --pretty='format:%H')"
    # echo "$MERGE_HASHES"
    # Get the last 40 PRs, in the format num=hash=title
    PULL_REQUESTS="$(hub pr list -s merged -o updated -L 40 -f '%I!;%sm!;%t!;%U%n')"
    # Filter to PRs which were merged in the last release. Exclude PRs starting with 'release'
    PULL_REQUESTS="$(echo "$PULL_REQUESTS" | grep "$MERGE_HASHES" | grep -vi '!;deploy' | grep -vi '!;tags@')"
    # Format the PRs into markdown changes, in the format "title [#num](pr-url)"
    CHANGES="$(echo "$PULL_REQUESTS" | sed -E "s/([0-9]*)!;([0-9a-f]*)!;(.*)!;(.*)/* \3 [#\1](\4)/")"
    # Output the changes if there are any
    if [ -n "$CHANGES" ]; then
        echo "$CHANGES"
    fi
}

if [ -n "$1" ]; then
    get_changes $1
else
    get_changes
    # Alternatively can add your path to projectsapigo repo.
    # ( cd "/Users/teamwork/go/src/github.com/teamwork/projectsapigo" && get_changes )
fi