bin = x11-poc
sources = x11-poc.c

default: $(bin)

clean:
	rm -fr $(bin)

$(bin): $(sources)
	gcc $< -o $@

.PHONY: default clean
