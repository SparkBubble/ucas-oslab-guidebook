(TeX-add-style-hook
 "guide-book"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("book" "11pt" "a4paper" "oneside")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("ctex" "UTF8" "adobefonts") ("xcolor" "x11names") ("geometry" "top=1in" "bottom=1in" "left=1.25in" "right=1.25in") ("hyperref" "colorlinks" "linkcolor=black" "anchorcolor=black" "citecolor=black") ("mdframed" "framemethod=default")))
   (add-to-list 'LaTeX-verbatim-environments-local "minted")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (TeX-run-style-hooks
    "latex2e"
    "title-page"
    "chapters/0-basic"
    "chapters/1-start"
    "book"
    "bk11"
    "graphicx"
    "ctex"
    "array"
    "booktabs"
    "xcolor"
    "colortbl"
    "fontspec"
    "geometry"
    "titlesec"
    "fancyhdr"
    "color"
    "url"
    "hyperref"
    "amsmath"
    "amsfonts"
    "amssymb"
    "amsthm"
    "tabularx"
    "multirow"
    "bibunits"
    "subfigure"
    "mdframed"
    "minted"
    "caption"
    "enumitem")
   (TeX-add-symbols
    "foo"
    "headrule"
    "headrulewidth"
    "UrlAlphabet"
    "UrlDigits"
    "bibcite"
    "protect")
   (LaTeX-add-environments
    '("codeBoxWithCaption" 1)
    "exercise"
    "thinking"
    "note"
    "codeBox")
   (LaTeX-add-color-definecolors
    "ocre"
    "base0"
    "base1"
    "base2"
    "base3"
    "base4"
    "base5"
    "base6"
    "base7"
    "base8"
    "base9"
    "baseA"
    "baseB"
    "baseC"
    "baseD"
    "baseE"
    "baseF"
    "Gray"
    "linkcolor"
    "codecolorpink"
    "NoteColorFont"
    "NoteColorLine"
    "ExeColorFont"
    "ExeColorLine"
    "ExeColorBack"
    "ThinkColorFont"
    "ThinkColorLine"
    "ThinkColorBack")
   (LaTeX-add-amsthm-newtheorems
    "exerciseT"
    "thinkingT"
    "noteT")
   (LaTeX-add-amsthm-newtheoremstyles
    "ocrenumbox"
    "purplenumbox"
    "blackbox")
   (LaTeX-add-mdframed-newmdenvs
    "eBox"
    "tBox"
    "nBox"
    "pcodeBox"))
 :latex)

