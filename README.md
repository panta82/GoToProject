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

Paste this into your terminal and follow the on-screen instructions:

```
wget -O- -q https://raw.githubusercontent.com/panta82/GoToProject/master/install.sh | bash
```

Alternatively, if you're a jaded untrusting soul, you could clone the repository, inspect the content and *then* run `install.sh`,

## Version history

Version|Description
-------|-----------
0.1    | Initial release
0.2    | Better fuzzy parsing when used with multiple arguments. Eg. `gd word1 word2`
0.3    | Better installer, safety. Mac/BSD support

## TODO

- Install as own file, instead of polluting user's `.bashrc` or `.bash_profile`.

## Licence

MIT
