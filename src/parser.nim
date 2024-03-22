import
    std/[
        htmlparser, re, xmltree, logging, options, terminal, strformat, strbasics,
        streams, strutils, tables,
    ]
import constants, struct, util

proc cherrypick_node(
        node: XmlNode, cls: string, s: var seq[XmlNode], use_re: bool = false
) =
    for el in node:
        if el.kind != XmlNodeKind.xn_element:
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
        if el.kind != XmlNodeKind.xn_element:
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
        if n.is_some:
            return n

    return none(XmlNode)

proc parse_a_tag(base_url: string, node: XmlNode): string =
    var parsed_txt = new_string_stream()

    var url = node.attr("href")
    if url != "" and not url.contains(re"^http"):
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
        if n.kind == xn_text:
            let t = n.inner_text()
            if t != "" and not t.contains(re"\n"):
                parsed_txt.write(t)
            else:
                debug fmt"Ignoring {t=} because it didn't meet the conditions"
        elif n.kind == xn_element:
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

proc text_until(node: XmlNode, tag: string): string =
    var text = ""
    for ch in node:
        if ch.kind == xn_element:
            if ch.tag == tag:
                break

        text = text & ch.inner_text()

    debug fmt"{text=}"

    return text

proc parse_word_class(node: XmlNode, do_until: bool = true): Option[WordClass] =
    debug "called parse_word_class"
    var matches: array[2, string]
    var word_class = ""
    if do_until:
        word_class = node.text_until("div")
    else:
        word_class = node.inner_text()
    var matched = word_class.match(constants.WORD_CLASS_RE, matches)

    debug fmt"{matches=} {matched=}"

    if matched:
        var cls =
            if matches[0] != "":
                some(strutils.strip(matches[0]))
            else:
                none(string)
        let code =
            if matches[1] != "":
                some(strutils.strip(matches[1]).replace(re" +", " "))
            else:
                none(string)

        debug fmt"{cls=} {code=}"

        return some(WordClass(cls: cls, code: code))

proc parse_definitions*(html_txt: string, defs: var seq[WordBody]) =
    let html = parse_html(html_txt)
    var bodies: seq[XmlNode]

    html.cherrypick_node(r"entry-body__el", bodies, true)
    if bodies.len == 0:
        html.cherrypick_node(r"pr di superentry", bodies, true)

    for h_div in bodies:
        debug("Found entry body div")

        debug(&"{h_div.len=}")

        # may fail if di-info is priotised
        var word_header = cherrypick_node(h_div, r"pos-header", true)
        if word_header.is_none:
            debug "if triggered"
            word_header = cherrypick_node(h_div, r"di-info", true)
        debug fmt"{word_header=}"

        var word_body = cherrypick_node(h_div, "pos-body|pv-body|idiom-body", true)

        var
            word_title = ""
            word_header_text = ""
            word_class: Option[WordClass]

        let word_title_h = cherrypick_node(h_div, "di-title")
        if word_title_h.is_some:
            word_title = word_title_h.get().inner_text()

        if word_header.is_some:
            word_header_text = word_header.get().inner_text()

        debug fmt"{word_header_text=}"

        if word_header_text.contains("phrasal"):
            word_class = parse_word_class(word_header.get())
        elif word_header_text.contains("idiom"):
            let word_class_h =
                cherrypick_node(word_header.get(), WORD_CLASS_CONTAINERS["idiom"], true)
            debug fmt"{word_class_h=}"
            if word_class_h.is_some:
                word_class = parse_word_class(word_class_h.get(), false)
        else:
            let word_class_h = cherrypick_node(
                word_header.get(), WORD_CLASS_CONTAINERS["default"], true
            )
            debug fmt"{word_class_h=}"
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
