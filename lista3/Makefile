JULIA = julia

.PHONY: install

install:
	$(JULIA) -e 'using Pkg; Pkg.add("JSON")'
	$(JULIA) -e 'using Pkg; Pkg.add("JuMP")'
	$(JULIA) -e 'using Pkg; Pkg.add("GLPK")'
	$(JULIA) -e 'using Pkg; Pkg.add("Plots")'
	$(JULIA) -e 'using Pkg; Pkg.add("JLD2")'