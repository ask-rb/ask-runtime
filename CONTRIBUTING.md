# Contributing to ask-runtime

## Development Setup

```bash
git clone <repo-url> && cd ask-rb/ask-runtime
bundle install
```

### Local Dependencies

Sibling gems (ask-core, ask-agent, ask-mcp, and others) are loaded from their
local `lib/` directories in the monorepo during development. The
`test_helper.rb` file handles the local load path for this gem.

## Running Tests

```bash
# Run all tests
bundle exec rake test

# Run a single test file
bundle exec ruby -Ilib -Itest test/foo_test.rb

# Run with verbose output
bundle exec rake test TESTOPTS="--verbose"
```

## Code Style

- Follow the existing code style in the gem
- Use `# frozen_string_literal: true` in all Ruby files
- Run `rubocop -a` if the gem has RuboCop configured

## Pull Request Guidelines

1. Keep PRs focused on a single concern
2. Include tests for new functionality
3. Update `CHANGELOG.md` with your changes
4. Ensure all existing tests pass
5. Open an issue first for new features or significant changes

## Testing Philosophy

This gem owns the runtime value objects, event types, and executor contract.
Tests should cover that public boundary without duplicating behavior owned by
ask-core or executor integrations such as ask-agent and ask-mcp.

## Release

See `RELEASE.md` for the release process.
