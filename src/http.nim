import std/[httpclient, uri, options, streams, logging, strformat]
import constants

proc make_http_client*(): HttpClient =
    return httpclient.new_http_client(max_redirects = 0)

proc get_word_file*(client: HttpClient, word: string): string =
    let base_url = constants.BASE_URL / "dictionary" / $constants.LANGUAGE
    var resp = client.get(base_url / word)

    debug(&"{base_url=}")
    debug(&"{resp.version=}")
    debug(&"{resp.headers=}")
    debug(&"{resp.code=}")

    if resp.code == HttpCode(302):
        let match_url = $base_url & "/"
        debug(&"{match_url=}")
        if resp.headers["location"] == match_url:
            debug("Returning \"\" because `location` header matched match_url.")
            return ""
        resp = client.get(resp.headers["location"])

    resp.body_stream.read_all()
