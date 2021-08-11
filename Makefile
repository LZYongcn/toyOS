install: 
	ninja -C out install -v

build: 
	ninja -C out build -v

gen:
	gn gen ./out

run: install
	bash -ic 'cdbox;bochs -q'

clean:
	find ./out -type file | xargs rm

.PHONY: build install run clean gen
