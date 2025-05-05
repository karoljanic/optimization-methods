# Makefile for cleaning LaTeX project

# Files to clean
LATEX_FILES = *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.fls *.fdb_latexmk *.synctex.gz

# Target to clean up LaTeX files
clean:
	rm -f $(LATEX_FILES)
	echo "Cleaned LaTeX auxiliary files."

veryclean: clean
	rm -f *.pdf *.dvi *.ps
	echo "Cleaned all build files including PDFs, DVI, and PS."

.PHONY: clean veryclean
