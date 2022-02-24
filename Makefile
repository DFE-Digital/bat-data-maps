.PHONY : all clean view-all view-actors view-logical view-physical view-realisations

all : out/key.svg out/actors_dbs.svg out/logical.svg out/physical.svg out/realisations.svg out/realisations.html

view-key : out/key.svg
	inkview out/key.svg

view-actors : out/actors_dbs.svg
	inkview out/actors_dbs.svg

view-logical : out/logical.svg
	inkview out/logical.svg

view-physical : out/physical.svg
	inkview out/physical.svg

view-realisations : out/realisations.svg
	inkview out/realisations.svg

clean :
	-rm -rf out

out :
	mkdir out

out/actors_dbs.dot out/logical.dot out/physical.dot out/realisations.dot out/realisations.html : src/model.rb out
	cd out ; ruby ../src/model.rb

NEATO_FLAGS=-Goverlap=voronoi -Gsplines=true -Gsep=.5

out/actors_dbs.png out/actors_dbs.svg : out/actors_dbs.dot
	neato $(NEATO_FLAGS) -Tsvg out/actors_dbs.dot > out/actors_dbs.svg
	neato $(NEATO_FLAGS) -Tpng out/actors_dbs.dot > out/actors_dbs.png

out/logical.png out/logical.svg : out/logical.dot
	neato $(NEATO_FLAGS) -Tsvg out/logical.dot > out/logical.svg
	neato $(NEATO_FLAGS) -Tpng out/logical.dot > out/logical.png

out/physical.png out/physical.svg : out/physical.dot
	neato $(NEATO_FLAGS) -Tsvg out/physical.dot > out/physical.svg
	neato $(NEATO_FLAGS) -Tpng out/physical.dot > out/physical.png

out/realisations.png out/realisations.svg : out/realisations.dot
	neato $(NEATO_FLAGS) -Tsvg out/realisations.dot > out/realisations.svg
	neato $(NEATO_FLAGS) -Tpng out/realisations.dot > out/realisations.png

out/key.png out/key.svg : src/key.dot out
	dot -Tsvg src/key.dot > out/key.svg
	dot -Tpng src/key.dot > out/key.png
