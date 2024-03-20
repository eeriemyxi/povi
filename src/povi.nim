import
    std/[httpclient, parseopt, options, logging, rdstdin, strformat, unicode, envvars]
import util, parser, http, struct, constants

var LOG_LEVEL = lvl_info

proc handle_cli(): seq[string] =
    var p = init_opt_parser()
    var words: seq[string]

    for (kind, key, val) in p.get_opt():
        case kind
        of cmd_end:
            break
        of cmd_long_option, cmd_short_option:
            if key == "help" or key == "h":
                echo constants.HELP_TEXT
                quit(0)
            if key == "debug":
                LOG_LEVEL = lvl_debug
            if key == "version" or key == "V":
                echo constants.VERSION
                quit(0)
            if key == "repl" or key == "r":
                put_env("POVI_USE_REPL", "1")
            if key == "altsc" or key == "a":
                put_env("POVI_ALTSC", "1")
        of cmd_argument:
            words.add(key)

    return words

var words: seq[string] = handle_cli()

let log = new_console_logger(LOG_LEVEL)
logging.add_handler(log)

proc exit_gracefully(client: HttpClient, code: int) =
    alternate_screen_end()
    client.close()
    quit(code)

proc handle_word(client: HttpClient, word: string): int =
    debug(&"{word=}")

    util.inform_searching_word(word)
    let html: string = http.get_word_file(client, word)
    if html == "":
        util.inform_invalid_word(word)
        return 1

    inform_found_word(word)

    var defs: seq[WordBody]
    parser.parse_definitions(html, defs)

    for df in defs:
        output_word(df.word, " ")
        if df.word_class.is_some:
            output_word_class(df.word_class.get())
        else:
            stdout.write('\n')
        for dt in df.def_texts:
            output_word_def(dt.text, 4)
            for exm in dt.examples:
                output_def_example(exm, 8)

    debug fmt"{defs=}"
    return 0

proc repl() =
    alternate_screen_start()
    stderr.write_line("Type :exit to quit. Or :e. Or <C-d>. Or <C-c>.")
    let client = make_http_client()
    var line: string

    while true:
        let ok = read_line_from_stdin(constants.REPL_PROMPT, line)

        if not ok:
            exit_gracefully(client, 0)
            break

        line = strip(line)

        if line == ":exit" or line == ":e":
            exit_gracefully(client, 0)

        let words = line.split_whitespace()

        for word in words:
            let word = util.serialize_word(word)
            discard handle_word(client, word)

proc main(words: seq[string]) =
    let client = make_http_client()
    var code = 0

    for word in words:
        let word: string = util.serialize_word(word)
        code = if handle_word(client, word) == 1: 1 else: code

    exit_gracefully(client, code)

when is_main_module:
    if exists_env("POVI_USE_REPL") and get_env("POVI_USE_REPL") == "1":
        repl()
    else:
        main(words)
