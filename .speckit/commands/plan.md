# /speckit.plan

## Description

Create a technical implementation plan based on the specification.

## Usage

```
/speckit.plan [additional guidance or constraints]
```

## Examples

```
/speckit.plan Use FastAPI with PostgreSQL and deploy to AWS
```

```
/speckit.plan Create a plan that:
- Uses microservices architecture
- Implements CI/CD from day one
- Includes monitoring and logging
```

## Behavior

1. Read the current specification from `.speckit/memory/specification.md`
2. Read the constitution from `.speckit/memory/constitution.md`
3. Generate architecture design
4. Define implementation phases
5. Set milestones
6. Save to `.speckit/memory/plan.md`
7. Confirm creation to user

## Output File

The command creates/updates `.speckit/memory/plan.md` with:

- Architecture overview
- Component diagram (text-based)
- Implementation phases
- Milestones with checkboxes
- Dependencies and risks

## Integration

This command integrates with:
- **OpenCode**: Uses `spec.setPlan` skill
- **Claude Code**: Reads `.claude/agents/plan-agent.md` for guidance
- **Specification**: Directly references specification.md

## Notes

- Should be run after `/speckit.specify`
- Forms the basis for `/speckit.tasks`
- May create HITL checkpoint for architecture approval
