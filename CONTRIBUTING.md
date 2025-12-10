# Contributing to Microservices CI/CD Project

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs
1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, Docker version, etc.)

### Suggesting Enhancements
1. Open an issue describing:
   - The enhancement
   - Why it would be useful
   - Possible implementation approach

### Pull Requests
1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test locally with `./start.sh` and `./test-api.sh`
5. Commit with clear messages: `git commit -m "Add feature: description"`
6. Push to your fork: `git push origin feature/your-feature-name`
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/cicd.git
cd cicd

# Install all dependencies
npm run install-all

# Start services
npm start

# Test
npm test
```

## Code Style

- Use 2 spaces for indentation
- Use meaningful variable names
- Add comments for complex logic
- Follow existing code patterns

## Testing

Before submitting a PR:
- [ ] Test locally with Docker Compose
- [ ] Test all API endpoints
- [ ] Check logs for errors
- [ ] Verify inter-service communication works

## Documentation

If you add features, please update:
- README.md (if it affects usage)
- API_TESTING.md (if you add new endpoints)
- Relevant .md files

## Questions?

Feel free to open an issue with your questions!

Thank you for contributing! 🎉
