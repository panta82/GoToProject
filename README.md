# GoToProject

A simple bash command to help developers navigate between projects. Tested on Bash 4.3+.

## Usage:

```bash
# Jump to /dev/projects/php/softdrink
gd softdrink

# But also works with
gd sdr # fuzzy match
gd php # most recent PHP project

# Or just enter
gd
# to jump to the most recently modified project
```

The target directory is determined by:
- Direct or partial match of the directory name
- Fuzzy pattern match (prj -> project)
- Existence of .git repository
- Date of last change

GoToProject just picks the most likely match and `cd`-s there. It's that simple.

**TIP:** Set env. variable `GTP_DEBUG` to 1 to see debugging output.

## Installation

Clone the repository and run `install.sh`

## Licence

MIT
