import std/[uri, os, re, terminal]
import struct

const
    BASE_URL* = parse_uri("https://dictionary.cambridge.org/")
    CODES_LINK* = BASE_URL / "help/codes.html"
    USER_AGENT* =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " &
        "(KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"
    LANGUAGE* = struct.SupportedLanguage.ENGLISH
    REPL_PROMPT* =
        ansi_foreground_color_code(fg_yellow) & ansi_style_code(style_bright) & "povi > " &
        ansi_reset_code

include includes/version
include includes/help_text

let
    SCRIPT_DIR* = os.get_app_dir()
    WORD_CLASS_RE* = re(r"\W*(?<word>\w*)\W*?(?:\[?\W*?(?<code>\w)\W*?\])?")
