.PHONY : all view clean

all : out/model.svg out/model.png

view : out/model.svg
	inkview out/model.svg

clean :
	-rm -rf out

out/model.svg : src/model.dot
	-mkdir out
	dot -Tsvg src/model.dot > out/model.svg

out/model.png : src/model.dot
	-mkdir out
	dot -Tpng src/model.dot > out/model.png
