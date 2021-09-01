MAIN := main
SUPP := supp
TEX := latexmk
TEX_OPT := -pdf 
MON_OPT := -pvc
CLN_OPT := -CA

.PHONY: all main-monitor supp-monitor wordcount clean

all: ${MAIN}.pdf ${SUPP}.pdf

${MAIN}.pdf:
	${TEX} ${TEX_OPT} ${MAIN}.tex

${SUPP}.pdf:
	${TEX} ${TEX_OPT} ${SUPP}.tex

main-monitor:
	${TEX} ${MON_OPT} ${MAIN}.tex

supp-monitor:
	${TEX} ${MON_OPT} ${SUPP}.tex

clean:
	${TEX} ${CLN_OPT} ${MAIN}.tex
	${TEX} ${CLN_OPT} ${SUPP}.tex

wordcount:
	detex -l -n -w ${MAIN}.tex | wc -w

