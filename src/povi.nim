import std/[httpclient, parseopt, options, logging, strformat]
import util, parser, http, struct

var LOG_LEVEL = lvlInfo

proc handle_cli(): seq[string] =
    var p = initOptParser()
    var words: seq[string]

    for (kind, key, val) in p.getopt():
        case kind
        of cmdEnd:
            break
        of cmdLongOption, cmdShortOption:
            if key == "debug":
                LOG_LEVEL = lvlDebug
        of cmdArgument:
            words.add(key)

    return words

var words: seq[string] = handle_cli()

let log = newConsoleLogger(LOG_LEVEL)
addHandler(log)

proc exit_gracefully(client: HttpClient, code: int) =
    client.close()
    quit(code)

proc handle_word(client: HttpClient, word: string) =
    util.inform_searching_word(word)
    let html: string = http.get_word_file(client, word)
    if html == "":
        util.inform_invalid_word(word)
        exit_gracefully(client, 1)

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

when isMainModule:
    let client = httpclient.newHttpClient(maxRedirects = 0)

    debug(&"{words=}")

    for word in words:
        let word: string = util.serialize_word(word)
        handle_word(client, word)

    exit_gracefully(client, 0)
