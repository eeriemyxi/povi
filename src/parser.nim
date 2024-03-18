import
    std/
        [
            htmlparser, re, xmltree, logging, options, terminal, strformat, strbasics,
            streams,
        ]
import constants, struct, util

proc cherrypick_node(
        node: XmlNode, cls: string, s: var seq[XmlNode], use_re: bool = false
) =
    for el in node:
        if el.kind != XmlNodeKind.xnElement:
            continue

        let cls_t = el.attr("class")

        let condition =
            if use_re:
                cls_t.contains(re(cls))
            else:
                cls == cls_t

        if condition:
            s.add(el)

        cherrypick_node(el, cls, s, use_re)

proc cherrypick_node(
        node: XmlNode, cls: string, use_re: bool = false
): Option[XmlNode] =
    for el in node:
        if el.kind != XmlNodeKind.xnElement:
            continue

        let cls_t = el.attr("class")

        let condition =
            if use_re:
                cls_t.contains(re(cls))
            else:
                cls == cls_t

        if condition:
            return some(el)

        let n = cherrypick_node(el, cls, use_re)
        if n.isSome:
            return n

    return none(XmlNode)

proc parse_a_tag(base_url: string, node: XmlNode): string =
    var parsed_txt = new_string_stream()

    var url = node.attr("href")
    if url != "" and not url.contains(re"http"):
        url = base_url & url

    parsed_txt.write(hyperlink(url, node.inner_text()))

    parsed_txt.set_position(0)

    return parsed_txt.read_all()

proc parse_strong_tag(node: XmlNode): string =
    var parsed_txt = new_string_stream()

    parsed_txt.write(ansi_style_code(style_bright), node.inner_text(), ansi_reset_code)

    parsed_txt.set_position(0)

    return parsed_txt.read_all()

proc parse_word_def(node: XmlNode): string =
    var parsed_txt = new_string_stream()

    for n in node:
        if n.kind == xnText:
            let t = n.inner_text()
            if t != "" and not t.contains(re"\n"):
                parsed_txt.write(t)
            else:
                debug fmt"Ignoring {t=} because it didn't meet the conditions"
        elif n.kind == xnElement:
            if n.tag == "a":
                parsed_txt.write(parse_a_tag($constants.BASE_URL, n))
            elif n.tag == "strong":
                parsed_txt.write(parse_strong_tag(n))
            elif n.tag == "span":
                if n.attr("class") == "b db":
                    parsed_txt.write(parse_strong_tag(n))
                else:
                    parsed_txt.write(parse_word_def(n))
            else:
                debug fmt"Reached else condition: {n.inner_text()=}"

    parsed_txt.set_position(0)

    var txt = parsed_txt.read_all()
    txt.strip(leading = false, chars = {' ', ':'})
    return txt

proc parse_example_texts(node: XmlNode): seq[string] =
    debug("Called parse_def_text")
    var examp_texts: seq[string]

    var examps: seq[XmlNode]
    cherrypick_node(node, "examp", examps, true)

    for exm in examps:
        let stripped_exm = cherrypick_node(exm, "eg", true)

        debug(&"{stripped_exm=}")

        if stripped_exm.is_none:
            continue

        let text = parse_word_def(stripped_exm.get())
        examp_texts.add(text)

    return examp_texts

proc parse_def_text(word_body: XmlNode): seq[struct.WordDefinition] =
    debug("Called parse_def_text")
    var def_texts: seq[struct.WordDefinition]

    var defs: seq[XmlNode]
    cherrypick_node(word_body, "ddef_block", defs, true)
    # debug &"{defs=}"

    for df in defs:
        let stripped_df = cherrypick_node(df, "ddef_d", true)

        debug(&"{stripped_df=}")

        if stripped_df.is_none:
            continue

        let txt = parse_word_def(stripped_df.get())
        let exm_texts = parse_example_texts(df)

        debug fmt"{txt=}"
        debug fmt"{exm_texts=}"

        def_texts.add struct.WordDefinition(text: txt, examples: exm_texts)

    return def_texts

proc parse_word_class(node: XmlNode): Option[WordClass] =
    var matches: array[2, string]
    let word_class = node.inner_text()
    var matched = word_class.match(constants.WORD_CLASS_RE, matches)
    if matched:
        let cls =
            if matches[0] != "":
                some(matches[0])
            else:
                none(string)
        let code =
            if matches[1] != "":
                some(matches[1])
            else:
                none(string)
        return some(WordClass(cls: cls, code: code))

proc parse_definitions*(html_txt: string, defs: var seq[WordBody]) =
    debug("Called parse_definitions")
    let html = parse_html(html_txt)

    for h_div in html.find_all("div"):
        if h_div.attr("class") != "pr entry-body__el":
            continue

        debug("Found pr entry-body__el div")

        debug(&"{h_div.len=}")

        var word_header = cherrypick_node(h_div, "pos-header dpos-h")
        var word_body = cherrypick_node(h_div, "pos-body")

        var
            word_title = ""
            word_class: Option[WordClass]

        if word_header.is_some:
            let word_title_h = cherrypick_node(word_header.get(), "di-title")
            if word_title_h.is_some:
                word_title = word_title_h.get().inner_text()

            let word_class_h =
                cherrypick_node(word_header.get(), "posgram dpos-g hdib lmr-5")
            if word_class_h.is_some:
                word_class = parse_word_class(word_class_h.get())

        debug(&"{word_title=}")
        debug(&"{word_class=}")

        if word_body.is_none:
            debug("Skipping because word body is none")
            continue

        let def_texts = parse_def_text(word_body.get())

        defs.add WordBody(
            word: word_title, word_class: word_class, def_texts: def_texts
        )
