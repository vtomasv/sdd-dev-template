# Project Constitution

> This file defines the core principles and rules that guide all development decisions.
> Update this file using `/speckit.constitution` command.

## Core Principles

### 1. Code Quality
- Write clean, readable, and maintainable code
- Follow SOLID principles
- Use meaningful names for variables, functions, and classes
- Keep functions small and focused on a single responsibility

### 2. Testing
- Maintain minimum 80% code coverage
- Write unit tests for all business logic
- Include integration tests for APIs
- Test edge cases and error scenarios

### 3. Documentation
- Keep README up to date
- Document all public APIs
- Include inline comments for complex logic
- Maintain changelog for all releases

### 4. Security
- Validate all user inputs
- Use parameterized queries for database operations
- Store secrets securely (never in code)
- Follow principle of least privilege

### 5. Performance
- Optimize database queries
- Implement caching where appropriate
- Monitor and profile regularly
- Set performance budgets

## Rules

1. No code merge without code review
2. No deployment without passing tests
3. All changes must be logged in audit trail
4. Critical operations require HITL approval
5. Follow semantic versioning for releases

## Guidelines

- Prefer composition over inheritance
- Use dependency injection for testability
- Handle errors gracefully with proper logging
- Keep dependencies up to date

---
*Template initialized by SDD Development Template*
*Update with: /speckit.constitution*
