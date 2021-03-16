# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).


# 0.1.0 - 2021-03-16
## Added
- Started with version numbering
- Docker-multiarch build process

## Fixed

## Changed
- Updated OS to Debian buster-slim
- Updated build process (separate builder)
- Use a more modern shallot (which builds on recent systems and behaves better:
  Fewer crashes, better recovery on bad RSA keys, …), imported as submodule
- Container no longer sets its own time; requires that host has correct time
  (should hopefully be default by now)
