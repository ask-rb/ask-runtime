# Release Process — ask-runtime

Versioning rules (SemVer, patch increments, gemchain releases) live in
[VERSIONING.md](VERSIONING.md), the canonical versioning policy for this repo.

## Prerequisites

- All tests pass: `bundle exec rake test`
- `CHANGELOG.md` is updated with the release entries
- You have push access to rubygems.org

## Release Steps

1. Update the version in `lib/ask/runtime/version.rb`
2. Update `CHANGELOG.md` with the new version and date
3. Run tests: `bundle exec rake test`
4. Build: `bundle exec rake build`
5. Publish: `bundle exec rake release`

## Quick Reference

```bash
cd ask-runtime
bundle exec rake release
```
