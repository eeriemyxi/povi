const HELP_TEXT* = """
usage: povi [-h] [--debug] [-V] [-r] [-a] [-n] [words ...]

positional arguments:
  words          Words to search. You can specify multiple words by splitting
                 them by whitespace.

options:
  -h, --help     Show this help message and exit.
  --debug        Enable debug logs.
  -V, --version  Show program version.
  -r, --repl     Initiate a REPL session.
  -a, --altsc    Use alternate screen buffer for the REPL. 
                 Scrolling may not work.
  -n, --nosplit  Don't split the input into multiple words, 
                 instead treat it as one single word/phrase."""
