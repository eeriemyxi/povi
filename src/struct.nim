import std/options

type
    SupportedLanguage* = enum
        ENGLISH = "english"

    Emoji* = enum
        WARNING = "⚠"
        DIM_BUTTON = "🔅"
        HEARTS = "♥"
        SMALL_BLUE_DIAMOND = "🔹"
        SMALL_ORANGE_DIAMOND = "🔸"

    WordClass* = object
        cls*: Option[string]
        code*: Option[string]

    WordDefinition* = object
        text*: string
        examples*: seq[string]

    WordBody* = object
        word*: string
        word_class*: Option[WordClass]
        def_texts*: seq[WordDefinition]
