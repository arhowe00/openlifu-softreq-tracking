#!/bin/bash

#
# extract_softreq_issues.sh
#
# Given a repository name, extracts all issues that are soft requirements:
# either containing SOFTREQ in title/body, or labeled with 'requirement'.
# Outputs files in softreq-issues/repository/ formatted for spreadsheet input.
#

if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install GitHub CLI first."
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 repository_name"
    exit 1
fi

REPO_NAME="$1"
OUTPUT_DIR="softreq-issues/$REPO_NAME"
mkdir -p "$OUTPUT_DIR"

# gh issue list is paginated to 30 by default.
gh issue list --repo "OpenwaterHealth/$REPO_NAME" --limit 999999 --state all --json number,title,state \
| jq -c '.[]' \
| while read -r issue; do
    ISSUE_NUM=$(echo "$issue" | jq '.number')
    TITLE=$(echo "$issue" | jq -r '.title')
    STATE=$(echo "$issue" | jq -r '.state')

    MATCH_REQ=0

    if echo "$TITLE" | grep -qi "SOFTREQ"; then
        MATCH_REQ=1
    fi

    LABELS=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json labels | jq -r '[.labels[].name] | join(",")')
    if echo "$LABELS" | grep -q "requirement"; then
        MATCH_REQ=1
    fi

    if [ "$MATCH_REQ" -eq 0 ]; then
        continue
    fi

    # ---- Filter out SOFTREQs closed as duplicates ----
    ISSUE_DATA=$(gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json labels,stateReason)
    REASON=$(echo "$ISSUE_DATA" | jq -r '.stateReason')
    LABELS_STR=$(echo "$ISSUE_DATA" | jq -r '[.labels[].name] | join(",")')

    if echo "$BODY $REASON $COMMENTS $LABELS_STR" | grep -iq "duplicate"; then
        echo "Skipping SOFTREQ issue #$ISSUE_NUM: marked as duplicate."
        continue
    fi
    # --------------------------------------------------

    OUTPUT_FILE="$OUTPUT_DIR/#${ISSUE_NUM}.tsv"

    # Write header first
    echo -e "repo\tissue_number\ttitle\tbody\tlabels\tassignees\tstate\tcreated_at\tupdated_at\tcomments" > "$OUTPUT_FILE"

    # Append issue information. Make sure to replace all escaped newlines with
    # actual newlines
    gh issue view "$ISSUE_NUM" --repo "OpenwaterHealth/$REPO_NAME" --json number,title,body,labels,assignees,state,createdAt,updatedAt,comments \
    | jq -r --arg repo "$REPO_NAME" '
        [
            $repo,
            "#" + (.number|tostring),
            (.title|gsub("\t";"    ")|gsub("\n";" ")|gsub("\\|";" ")),
            (.body|gsub("\t";"    ")|gsub("\\|";" ")),
            ([.labels[].name]|join(",")),
            ([.assignees[].login]|join(",")),
            .state,
            .createdAt,
            .updatedAt,
            (
                [.comments[] | "@\(.author.login)\n\(.body | gsub("\\t";"    ") | gsub("\\|";" "))\n---"]
                | join("\n")
            )
        ] | @tsv' \
    >> "$OUTPUT_FILE"
done
