include src/includes/version

version = VERSION
author = "myxi"
description = "Novi, but written in Nim."
license = "MIT"
srcDir = "src"
bin = @["povi"]

requires "nim >= 2.2.0"
requires "htmlparser == 0.1.0"
