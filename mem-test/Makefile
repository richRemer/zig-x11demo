bin = mem-test
sources = mem-test.c

default: $(bin)

clean:
	rm -fr $(bin)

$(bin): $(sources)
	gcc $< -o $@

.PHONY: default clean
