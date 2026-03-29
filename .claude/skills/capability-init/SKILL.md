# Capability Init

Initialize the standard folder structure for a new capability. Used by PM, Architect, or Lead when starting a new capability design.

## Usage

```
/capability-init <capability-slug> [--phases <N>] [--phase-names "name1,name2,name3"]
```

Example:
```
/capability-init agent-platform --phases 3 --phase-names "deal-scout,chrome-extension,agent-builder"
```

## What It Creates

```
docs/capabilities/<capability-slug>/
├── DECISION_LOG.md              # Chronological decision record with rationale
├── README.md                    # Overview: phases, status, folder map
├── inputs/                      # Stakeholder design inputs
│   └── .gitkeep
├── phase-1-<name>/              # One folder per phase
│   ├── PM_SPEC.md               # Product spec (ACs, stories, scope)
│   ├── TECHNICAL_DESIGN.md      # Architecture (models, APIs, ADRs)
│   └── STAKEHOLDER_REVIEW.md    # Consolidated review feedback
├── phase-2-<name>/
│   ├── PM_SPEC.md
│   ├── TECHNICAL_DESIGN.md
│   └── STAKEHOLDER_REVIEW.md
└── ...
```

## Standard Files

### DECISION_LOG.md
Chronological record of key decisions. Each entry has:
- **Date** and **context** (what prompted the decision)
- **Decision** (what was decided)
- **Influences** (who said what — persona inputs, CEO challenges, architect constraints)
- **Rationale** (why this over alternatives)

### README.md
- Phase table (name, status, description)
- Folder structure map
- Key decisions summary (links to DECISION_LOG)
- Links to all specs

### PM_SPEC.md (per phase)
- Problem statement
- User stories
- Acceptance criteria (numbered: XX-AC1, XX-AC2, ...)
- Scope (in/out)
- Dependencies
- Estimated effort (LOC, SP)

### TECHNICAL_DESIGN.md (per phase)
- Architecture diagram (ASCII)
- Data models (Pydantic)
- API specs
- ADRs for key technical decisions
- Risk assessment
- Implementation plan

### STAKEHOLDER_REVIEW.md (per phase)
- Reviewer, role, date
- Pass/Fail per acceptance criterion
- Concerns raised
- Changes requested
- Final sign-off

### inputs/ folder
Stakeholder inputs gathered before spec writing:
- `PERSONA_INPUT_<ROLE>.md` — persona requirements and validation
- `CEO_VISION_CHALLENGE.md` — premise, scope, ambition checks
- `ARCHITECT_TECHNICAL_EVALUATION.md` — feasibility, risks, LOC estimates

## Process

1. **Lead/PM invokes** `/capability-init` with slug and phases
2. **Skill creates** folder structure with template files
3. **Background agents gather inputs** → write to `inputs/`
4. **PM writes specs** → `phase-N/PM_SPEC.md` (reads all inputs first)
5. **Architect writes designs** → `phase-N/TECHNICAL_DESIGN.md`
6. **Stakeholders review** → `phase-N/STAKEHOLDER_REVIEW.md`
7. **Lead updates** `DECISION_LOG.md` at each major decision point

## Template Variables

When creating files, replace:
- `{{CAPABILITY_NAME}}` — human-readable name (e.g., "Agent Platform")
- `{{CAPABILITY_SLUG}}` — folder slug (e.g., "agent-platform")
- `{{PHASE_N}}` — phase number
- `{{PHASE_NAME}}` — phase name (e.g., "deal-scout")
- `{{DATE}}` — current date (YYYY-MM-DD)
