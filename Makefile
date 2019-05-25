CC=gcc
CFLAGS=--std=gnu99 -Werror -Wall -g
LDFLAGS=--std=gnu99 -g
LDLIBS=-lm

LAT = latex -shell-escape
#TEX = pdflatex --shell-escape
TEXINPUTS=.:./sty:
TEX = TEXINPUTS=.:./sty: latexmk -pdf -xelatex -halt-on-error
BIB = bibtex8
TEXFILES = $(wildcard *.tex)
PDFFILES = $(TEXFILES:.tex=.pdf)
BIBFILES = $(wildcard *.bib)
DOT = dot -Tpdf
ifeq ($(shell uname -s), Darwin)
VIEW_PDF = open
else
VIEW_PDF = evince
endif

%.pdf: %.tex
	$(TEX) $<

%.pdf: %.dot
	$(DOT) < $< > $@

###### All the text and graphics files needed to make the ALIFE paper

GRAPHICS = \
	rzwavy-vfunc.png rzwavy-phfunc.png rzwavy-phrange.png rzwavy-graph.png \
	circle-phfunc.png circle-vfunc.png circle-phrange.png circle-graph.png \
	moats-phfunc.png moats-vfunc.png moats-phrange.png moats-graph.png \
	yxline1-vfunc.png ratio.pdf

# The ALIFE paper
acclivation.pdf: acclivation.tex acclivation.bib $(GRAPHICS)

# These programs are needed to generate the graphics files
progs: sa _sa.so

$(PDFFILES): $(BIBFILES)

###### ./sa : Spreading activation. This runs all the evolutionary simulations.

sa: sa.o sds.o coordset.o

# Default arguments to ./sa for runs for the ALIFE paper
DEFS = --bumps=1 --down_bump=1 \
	--knob_type=1 --knob_constant=0.02 --crossover_freq=0.02 --mutation_type_ub=16 \
	--input_accs=1 --activation_types=6 --sa_timesteps=10 --alpha=0.8 \
	--edge_from_phnode=0 --edge_inheritance=5 --multi_edges=0 --allow_move_edge=1 \
	--num_organisms=200 --num_candidates=10 --num_epochs=40 \

###### SWIG file for Python interface to ./sa, called by ./analyze.py

MACH := $(shell uname)
ifeq ($(MACH),Darwin)
  EXTRA_WARN=""
else
  EXTRA_WARN="-Wno-maybe-uninitialized"
endif

# The dynamic library file that lets Python talk to ./sa
_sa.so: sa.i sa.c
	swig -python sa.i
	CFLAGS="-std=gnu99 -g -Wno-strict-prototypes -Wno-return-type $(EXTRA_WARN) -Wno-unused-variable" LDFLAGS="-lm" python setup_sa.py build_ext --inplace

swig_test:
	python -c "import sa; sa.tom()"

###### Razorback

RZ_WAVY_SLOPE = $(DEFS) --bumps=1 --seed=4152195160 #--log=ancestors

rzwavy-vfunc.png rzwavy-phfunc.png rzwavy-phrange.png rzwavy-graph.png: rzwavy.done

rzwavy.done: progs
	./sa $(RZ_WAVY_SLOPE) --log=ancestors > rzwavy.out
	echo "\
plot phfitness show=False delta=0.01 azim=-66.0 elev=52 dpi=100 filename=rzwavy-phfunc.png\n\
plot vfitness show=False delta=0.005 azim=52.0 elev=15 dpi=100 filename=rzwavy-vfunc.png\n\
plot phrange show=False delta=0.01 azim=-66.0 elev=52 dpi=100 filename=rzwavy-phrange.png\n\
dot show=False filename=rzwavy-graph format=png\n\
exit\n" | ./analyze.py ancestors
	@touch rzwavy.done

###### Circle

CIRCLE = --ridge_type=1 --bumps=0 --ridge_radius=0.1 --peak_movement=1 \
	--c1_lb=-1 --c1_ub=1

REALLY_GOOD_CIRCLE1 = $(DEFS) $(CIRCLE) --ridge_radius=0.15 --bumps=0 \
	--num_organisms=200 --num_candidates=40 --num_epochs=40 \
  --dot=0 --log=ancestors --seed=1560864133

circle-vfunc.png circle-phfunc.png circle-phrange.png circle-graph.png: circle.done

circle.done: progs
	./sa $(REALLY_GOOD_CIRCLE1) > really-good-circle.out
	echo "\
plot phfitness show=False delta=0.005 azim=-56.0 elev=44 dpi=100 filename=circle-phfunc.png\n\
plot vfitness show=False delta=0.005 azim=20.0 elev=44 dpi=100 filename=circle-vfunc.png\n\
plot phrange show=False delta=0.01 azim=-56.0 elev=44 dpi=100 filename=circle-phrange.png\n\
dot show=False filename=circle-graph format=png\n\
exit\n\
" | ./analyze.py ancestors
	@touch circle.done

###### Moats

moats-phfunc.png moats-vfunc.png moats-phrange.png moats-graph.png: moats.done

moats.done: progs
	./sa $(TIGHT_FOLDING_FOR_LEAPING) > moats.out
	echo "\
plot phfitness show=False delta=0.005 azim=-29.0 elev=46 dpi=100 filename=moats-phfunc.png\n\
plot vfitness show=False delta=0.005 azim=66.0 elev=69 dpi=100 filename=moats-vfunc.png\n\
plot phrange show=False delta=0.01 azim=-29.0 elev=46 dpi=100 filename=moats-phrange.png\n\
dot show=False filename=moats-graph format=png\n\
exit\n\
" | ./analyze.py ancestors
	@touch moats.done

###### Like Moats, but consecutive islands touch at one point (easier)

CLOSE_BUMPS_ACCLIVATION = $(THINYX_WITH_BUMPS) \
	--moat_ub=0 --bump_freq=15.0 --flat=1 \
	--num_organisms=80 --edge_inheritance=5 --knob_type=0 \
	--num_candidates=8 --seed=3859373065 --log=ancestors

CLOSE_BUMPS_ACCLIVATION2 = $(THINYX_WITH_BUMPS) \
	--moat_ub=0 --bump_freq=15.0 --flat=1 \
	--num_organisms=80 --edge_inheritance=5 --knob_type=0 \
	--num_candidates=8 --viability_lb=0.0 --log=ancestors --seed=2722035180

close-bumps.done: progs
	./sa $(CLOSE_BUMPS_ACCLIVATION2) > close-bumps.out
	echo "\
plot phfitness show=False delta=0.005 azim=111.0 elev=44 dpi=100 filename=moats-phfunc.png\n\
plot vfitness show=False delta=0.005 azim=34.0 elev=64 dpi=100 filename=moats-vfunc.png\n\
plot phrange show=False delta=0.01 azim=111.0 elev=44 dpi=100 filename=moats-phrange.png\n\
dot show=False filename=moats-graph format=png\n\
exit\n\
" | ./analyze.py ancestors
	@touch close-bumps.done

###### The easy example near the end of the paper

#Thin ridge along y=x
YXLINE = --ridge_type=0 --c1_lb=-1 --c1_ub=1 

YX = $(YXLINE) --ridge_radius=0.1 --bumps=0 \
	--knob_type=1 --knob_constant=0.02 --crossover_freq=0.05 --mutation_type_ub=16 \
	--num_organisms=200 --num_candidates=7 \
	--input_accs=1 --activation_types=6 --sa_timesteps=10 --alpha=0.8 \
	--edge_from_phnode=1 --edge_inheritance=1 --multi_edges=0 \
	--num_epochs=40 --dot=1

GOOD_YXLINE1 = $(YX) --ridge_radius=0.2 --num_organisms=800 \
	--dot=1 --log=ancestors --seed=2848818913

yxline1-vfunc.png:
	./sa $(GOOD_YXLINE1) > yxline1.out
	echo "\
plot vfitness show=False delta=0.01 azim=80.0 elev=27 dpi=100 filename=yxline1-vfunc.png\n\
exit\n\
" | ./analyze.py ancestors

###### Makefile administration

swig_clean:
	rm -rf *.pyc *.so a.out* build sa_wrap.c* sa.py

graphics_clean:
	rm -f $(GRAPHICS)

prog_clean: swig_clean
	rm -f sa *.o

latex_clean:
	rm -f acclivation.pdf acclivation.log acclivation.out
	rm -f *.aux *.bbl *.blg *.fdb_latexmk *.fls

clean: prog_clean graphics_clean latex_clean
	rm -f ancestors out outs/* core

tags:
	ctags *.[ch]

.PHONY: tags run all dot clean plot fitness with_seed out tom swig_clean swig_test runs prog
