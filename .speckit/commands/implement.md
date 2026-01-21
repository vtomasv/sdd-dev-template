# /speckit.implement

## Description

Execute implementation of tasks following the plan and specification.

## Usage

```
/speckit.implement [optional: specific task or area]
```

## Examples

```
/speckit.implement
```

```
/speckit.implement Start with T1: Setup project structure
```

```
/speckit.implement Implement all authentication tasks
```

## Behavior

1. Read tasks from `.speckit/memory/tasks.md`
2. Read plan from `.speckit/memory/plan.md`
3. Read constitution from `.speckit/memory/constitution.md`
4. For each task:
   - Create HITL checkpoint if critical
   - Implement the task
   - Log decision to audit
   - Update task status
5. Report progress to user

## HITL Integration

The implement command creates checkpoints for:
- File deletions
- Configuration changes
- Security-related code
- Database migrations
- External API integrations

## Audit Integration

All implementation decisions are logged:
- What was implemented
- Why (reasoning)
- What files were changed
- Status (success/failure)

## Integration

This command integrates with:
- **OpenCode**: Uses all skills (hitl, audit, spec)
- **Claude Code**: Reads `.claude/agents/dev-agent.md` for guidance
- **Review**: May trigger `/speckit.review` after implementation

## Notes

- Should be run after `/speckit.tasks`
- May be run multiple times for iterative development
- Always follows constitution principles
- Creates audit trail for all changes
