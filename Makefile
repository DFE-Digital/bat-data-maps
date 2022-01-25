.PHONY : all view clean

all : out/model.svg

view : all
	inkview out/model.svg

clean :
	-rm -rf out

out/model.svg : src/model.dot
	-mkdir out
	dot -Tsvg src/model.dot > out/model.svg
