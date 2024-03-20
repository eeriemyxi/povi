import std/[httpclient, parseopt, options, logging, strformat]
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
        of cmd_argument:
            words.add(key)

    return words

var words: seq[string] = handle_cli()

let log = new_console_logger(LOG_LEVEL)
logging.add_handler(log)

proc exit_gracefully(client: HttpClient, code: int) =
    client.close()
    quit(code)

proc handle_word(client: HttpClient, word: string): int =
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

when is_main_module:
    let client = httpclient.new_http_client(max_redirects = 0)
    var code = 0

    debug(&"{words=}")

    for word in words:
        let word: string = util.serialize_word(word)
        code = if handle_word(client, word) == 1: 1 else: code

    exit_gracefully(client, code)
