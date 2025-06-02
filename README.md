# OpenLIFU Software Tracking

This repository contains scripts that trace software requirements for the
OpenLIFU integrated software platform for ultrasound research. OpenLIFU
encompasses multiple coordinated repositories
([SlicerOpenLIFU](https://github.com/OpenwaterHealth/SlicerOpenLIFU),
[OpenLIFU-python](https://github.com/OpenwaterHealth/OpenLIFU-python), and
[OpenLIFU-app](https://github.com/OpenwaterHealth/OpenLIFU-app)), combining
ultrasound control, visualization, and analysis for experimentation on human
subjects and tissue models.

The repository exists to implement an auditable and consistent traceability
process that aligns code changes with formal software requirements (SOFTREQ)
under [Openwater](https://www.openwater.health)'s requirements management
framework. See
[SlicerOpenLIFU#359](https://github.com/OpenwaterHealth/SlicerOpenLIFU/issues/359).

## Repository Goals

- Identify issues referenced in commits across OpenLIFU repositories.
- Generate a traceability report or matching between issues and software
  requirements to support gap analyses and audits.
- Determine whether issues are not yet linked to corresponding SOFTREQ
  requirements.
- Provide a format to link issues to SOFTREQ items in a standardized format.
- Support review and closure of SOFTREQ items once associated development work
  is complete.

## Scripts

This repository includes scripts that extract commit and issue data from GitHub
to support requirement traceability:

### `extract_commits.sh`

Clones a GitHub repository and saves commit messages into
`commits/<repository>/`, one file per commit hash.

**Output schema (per file):**

```sh
<full commit message as plain text>
```

### `extract_commit_linked_issues.sh`

Parses commit messages in `commits/<repository>/`, extracts referenced issues
(e.g., `#123`), and retrieves issue details into
`commit-linked-issues/<repository>/`.

**Output schema (TSV):**

```sh
repo	issue_number	title	body	labels	assignees	state	created_at	updated_at	comments
```

### `extract_softreq_issues.sh`

Extracts issues tagged with `SOFTREQ` or labeled `requirement` from a repository
and outputs TSV files to `softreq-issues/<repository>/`.

**Output schema (TSV):**

```sh
repo	issue_number	title	body	labels	assignees	state	created_at	updated_at	comments
```

## Questions

Please direct questions about the OpenLIFU project to:

### **Openwater**

- Peter Hollender —
  [phollender@openwater.health](mailto:phollender@openwater.health)
- Soren Konecky — [soren@openwater.health](mailto:soren@openwater.health)
- George Vigelette — [george@openwater.cc](mailto:george@openwater.cc)

### **Kitware**

- Ebrahim Ebrahim —
  [ebrahim.ebrahim@kitware.com](mailto:ebrahim.ebrahim@kitware.com)
- Sam Horvath — [sam.horvath@kitware.com](mailto:sam.horvath@kitware.com)
- Andrew Howe — [andrew.howe@kitware.com](mailto:andrew.howe@kitware.com)
- Sadhana Ravikumar —
  [sadhana.ravikumar@kitware.com](mailto:sadhana.ravikumar@kitware.com)
