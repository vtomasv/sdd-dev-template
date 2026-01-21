# /speckit.constitution

## Description

Create or update the project constitution with core principles and rules that guide all development decisions.

## Usage

```
/speckit.constitution [description of principles]
```

## Examples

```
/speckit.constitution Create principles focused on code quality, testing, and security
```

```
/speckit.constitution Establish principles for:
- Clean, maintainable code following SOLID principles
- Mandatory testing with 80% coverage minimum
- Security-first approach
- Clear documentation
```

## Behavior

1. Read the user's input describing desired principles
2. Generate a structured constitution document
3. Save to `.speckit/memory/constitution.md`
4. Confirm creation to user

## Output File

The command creates/updates `.speckit/memory/constitution.md` with:

- Core Principles section
- Rules section
- Guidelines for development
- Timestamp of creation/update

## Integration

This command integrates with:
- **OpenCode**: Uses `spec.setConstitution` skill
- **Claude Code**: Reads `.claude/agents/spec-agent.md` for guidance
- **HITL**: May create checkpoint for approval if principles are critical

## Notes

- The constitution serves as the foundation for all other specifications
- It should be created before `/speckit.specify`
- Changes to constitution may require re-evaluation of existing specs
