# Contributing to SnapPrint

## Getting set up

See [README.md](README.md) for how to run each subproject locally (backend, admin-web, mobile app).

## Workflow

1. Create a branch off `main` for your change.
2. Keep changes scoped to one subproject where possible (`backend/`, `admin-web/`, `snap_print/`, `admin/`).
3. Run the relevant checks before opening a PR:
   - Backend: `python -m py_compile` on changed files, or run the app locally against a test database.
   - Admin web: `npm run lint` and `npm run build` inside `admin-web/`.
   - Mobile app: `flutter analyze` inside `snap_print/`.
4. Open a pull request against `main` with a clear description of what changed and why.

## Commit messages

This repo follows [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, etc.) — please keep using that style.

## Reporting bugs

Open a GitHub issue with reproduction steps, expected vs. actual behavior, and which subproject is affected. For security vulnerabilities, see [SECURITY.md](SECURITY.md) instead of opening a public issue.
