# Contributing to InterviewAI

Thank you for your interest in contributing! This guide will help you get started.

感谢你对贡献代码的兴趣！本指南将帮助你快速上手。

## Getting Started / 开始之前

1. **Fork** this repository
2. **Clone** your fork locally
3. Create a new **branch** for your changes
4. Make your changes and **test** them
5. Submit a **Pull Request**

## Development Setup / 开发环境

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later
- No third-party dependencies required

```bash
git clone https://github.com/<your-username>/interviewai.git
cd interviewai
open interviewai.xcodeproj
```

## Code Style / 代码规范

- **Architecture**: Strict MVVM — Views should not contain business logic, ViewModels should not import SwiftUI views or present UI directly
- **Language**: All UI text, comments, and commit messages must be in **English**
- **File headers**: Use the format `Created by <Name> on YYYY/MM/DD.`
- **Formatting**: Follow the existing code style (Swift standard conventions)
- **Keep it simple**: Avoid over-engineering, unnecessary abstractions, or speculative features

## Commit Messages / 提交信息

Use the following format:

```
type: short description
```

Types:

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring (no behavior change) |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no logic change) |
| `test` | Adding or updating tests |
| `chore` | Build, config, or tooling changes |

Examples:

```
feat: add keyword highlighting in match results
fix: speech recognition not stopping on session end
docs: update algorithm section in README
```

## Pull Request Guidelines / PR 规范

- **One PR per feature or fix** — keep changes focused
- **Describe what and why** — explain the problem and your solution
- **Test your changes** — make sure the app builds and runs correctly
- **Keep commits clean** — squash work-in-progress commits before submitting

## Reporting Issues / 提交 Issue

When reporting a bug, please include:

- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if applicable (Xcode → Debug → Console)

For feature requests, describe the use case and why it would be useful.

## Architecture Overview / 架构概览

```
Models      → Data structures, no logic
Services    → Core functionality (Speech, Audio, Matching, Storage)
Managers    → Orchestration layer between Services
ViewModels  → Observable state, business logic for Views
Views       → SwiftUI, presentation only
```

Key rules:

- **Views** bind to ViewModels, never call Services directly
- **ViewModels** use Services/Managers, never import AppKit/UIKit for UI operations
- **Services** are stateless or self-contained, no dependency on ViewModels

## License / 许可证

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
