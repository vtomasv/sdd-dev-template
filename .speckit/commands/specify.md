# /speckit.specify

## Description

Define the project specification including functional and non-functional requirements.

## Usage

```
/speckit.specify [description of what to build]
```

## Examples

```
/speckit.specify Build a REST API for task management with JWT authentication
```

```
/speckit.specify Create a web application that:
- Allows users to create and manage tasks
- Supports user authentication
- Has real-time notifications
- Works on mobile and desktop
```

## Behavior

1. Read the user's description of what to build
2. Extract functional requirements
3. Identify non-functional requirements
4. Determine technology stack
5. Save to `.speckit/memory/specification.md`
6. Confirm creation to user

## Output File

The command creates/updates `.speckit/memory/specification.md` with:

- Project title and description
- Functional Requirements (FR1, FR2, etc.)
- Non-Functional Requirements (NFR1, NFR2, etc.)
- Technology Stack
- Constraints and assumptions

## Integration

This command integrates with:
- **OpenCode**: Uses `spec.setSpecification` skill
- **Claude Code**: Reads `.claude/agents/spec-agent.md` for guidance
- **Constitution**: References principles from constitution.md

## Notes

- Should be run after `/speckit.constitution`
- Forms the basis for `/speckit.plan`
- Can be updated as requirements evolve
