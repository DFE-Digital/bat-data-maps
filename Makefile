.PHONY : all clean view-all view-actors view-logical view-physical view-representations

OUTPUTS_SVG=out/key.svg out/actors_dbs.svg out/logical.svg out/physical.svg out/representations.svg
OUTPUTS_PNG=out/key.png out/actors_dbs.png out/logical.png out/physical.png out/representations.png
OUTPUTS_HTML=out/representations.html
OUTPUTS_STATIC_HTML=out/index.html
OUTPUTS_DOT=out/actors_dbs.dot out/logical.dot out/physical.dot out/representations.dot
OUTPUTS=$(OUTPUTS_SVG) $(OUTPUTS_PNG) $(OUTPUTS_HTML) $(OUTPUTS_STATIC_HTML)
SOURCES=src/model.rb src/engine.rb src/key.dot Makefile README.md src/index.html

all : $(OUTPUTS)

view-key : out/key.svg
	inkview out/key.svg

view-actors : out/actors_dbs.svg
	inkview out/actors_dbs.svg

view-logical : out/logical.svg
	inkview out/logical.svg

view-physical : out/physical.svg
	inkview out/physical.svg

view-representations : out/representations.svg
	inkview out/representations.svg

clean :
	-rm -rf out

out : src/resources/*
	-rm -rf out
	mkdir out
	cp -R src/resources out

$(OUTPUTS_DOT) $(OUTPUTS_HTML) : src/model.rb src/engine.rb out
	cd out ; ruby ../src/model.rb

NEATO_FLAGS=-Goverlap=voronoi -Gsplines=true -Gsep=.5

out/actors_dbs.png out/actors_dbs.svg : out/actors_dbs.dot
	neato $(NEATO_FLAGS) -Gsep=0.1 -Tsvg out/actors_dbs.dot > out/actors_dbs.svg
	neato $(NEATO_FLAGS) -Gsep=0.1 -Tpng out/actors_dbs.dot > out/actors_dbs.png

out/logical.png out/logical.svg : out/logical.dot
	neato $(NEATO_FLAGS) -Tsvg out/logical.dot > out/logical.svg
	neato $(NEATO_FLAGS) -Tpng out/logical.dot > out/logical.png

out/physical.png out/physical.svg : out/physical.dot
	neato $(NEATO_FLAGS) -Tsvg out/physical.dot > out/physical.svg
	neato $(NEATO_FLAGS) -Tpng out/physical.dot > out/physical.png

out/representations.png out/representations.svg : out/representations.dot
	neato $(NEATO_FLAGS) -Tsvg out/representations.dot > out/representations.svg
	neato $(NEATO_FLAGS) -Tpng out/representations.dot > out/representations.png

out/key.png out/key.svg : src/key.dot out
	dot -Tsvg src/key.dot > out/key.svg
	dot -Tpng src/key.dot > out/key.png

out/index.html : src/index.html
	cp src/index.html out/index.html

out/outputs.zip : $(OUTPUTS)
	-rm outputs.zip
	cd out ; zip -9 outputs.zip `echo $(OUTPUTS) | sed s_out/__g`

out/all.zip : $(OUTPUTS) $(OUTPUTS_DOT) $(SOURCES)
	zip -9 out/all.zip $(OUTPUTS) $(OUTPUTS_DOT) $(SOURCES)
