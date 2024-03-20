import std/[re, terminal, options, strformat, strutils]
import struct, constants

proc serialize_word*(word: string): string =
    word.replace(re" ", "-")

proc hyperlink*(url: string, label: string): string =
    return &"\e]8;;{url}\e\\{label}\e]8;;\e\\"

proc inform_invalid_word*(word: string) =
    stdout.styled_write_line(
        fgRed, styleBright, &"{struct.Emoji.WARNING} Could not find word: {word}"
    )

proc inform_searching_word*(word: string) =
    stdout.styled_write_line(
        fgGreen, styleBright, &"{struct.Emoji.DIM_BUTTON} Searching for: {word}"
    )

proc inform_found_word*(word: string) =
    stdout.styled_write_line(
        fgGreen, styleBright, &"{struct.Emoji.HEARTS}  Found word: {word}"
    )

proc output_word*(word, end_with: string) =
    stdout.styled_write(
        ansi_reset_code,
        fg_green,
        style_bright,
        fmt"{struct.Emoji.SMALL_BLUE_DIAMOND}{word}" & end_with,
    )

proc output_word_class*(class: WordClass) =
    if class.cls.is_some:
        stdout.write(
            ansi_foreground_color_code(fg_yellow),
            ansi_style_code(style_bright),
            fmt"({class.cls.get()})",
        )

    if class.code.is_some:
        stdout.write(
            ansi_foreground_color_code(fg_red),
            " [",
            ansi_foreground_color_code(fg_yellow),
            hyperlink($constants.CODES_LINK, class.code.get()),
            ansi_foreground_color_code(fg_red),
            "]",
        )

    stdout.write('\n')

proc output_word_def*(def: string, indent: int) =
    stdout.write_line(
        ansi_reset_code,
        ansi_foreground_color_code(fg_white),
        ansi_style_code(style_bright),
        " ".repeat(indent),
        fmt"{struct.Emoji.SMALL_ORANGE_DIAMOND}{def}",
        ansi_reset_code,
    )

proc output_def_example*(exm: string, indent: int) =
    stdout.write_line(
        ansi_reset_code,
        ansi_style_code(style_italic),
        ansi_foreground_color_code(fg_white),
        " ".repeat(indent),
        exm.replace(
            ansi_reset_code,
            ansi_reset_code & ansi_style_code(style_italic) &
                ansi_foreground_color_code(fg_white),
        ),
        ansi_reset_code,
    )
