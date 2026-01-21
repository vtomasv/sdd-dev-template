# /speckit.tasks

## Description

Generate a list of implementation tasks based on the technical plan.

## Usage

```
/speckit.tasks [optional: specific area to focus on]
```

## Examples

```
/speckit.tasks
```

```
/speckit.tasks Focus on backend API tasks first
```

```
/speckit.tasks Generate tasks for Phase 1 only
```

## Behavior

1. Read the current plan from `.speckit/memory/plan.md`
2. Read the specification from `.speckit/memory/specification.md`
3. Break down phases into actionable tasks
4. Prioritize tasks
5. Save to `.speckit/memory/tasks.md`
6. Confirm creation to user

## Output File

The command creates/updates `.speckit/memory/tasks.md` with:

- Pending tasks with checkboxes
- In Progress section
- Completed section
- Task IDs (T1, T2, etc.)
- Priority indicators

## Integration

This command integrates with:
- **OpenCode**: Uses `spec.setTasks` skill
- **Claude Code**: Reads `.claude/agents/dev-agent.md` for guidance
- **Plan**: Directly references plan.md

## Notes

- Should be run after `/speckit.plan`
- Tasks can be updated as work progresses
- Forms the basis for `/speckit.implement`
