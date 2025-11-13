(TeX-add-style-hook
 "guideref"
 (lambda ()
   (LaTeX-add-bibitems
    "riscv-asm-manual"
    "rv8-asm"
    "oracle-vrtualbox-faq"
    "chen-makefile"
    "ruan-makefile"
    "chen-makefile-debug"
    "palmer-all-aboard"))
 :bibtex)

