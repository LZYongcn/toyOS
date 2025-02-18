GN=/Users/lizhengyong/google/gn

install: 
	ninja -C out install -v

build: 
	ninja -C out build -v

gen:
	${GN} gen ./out --ide=xcode --xcode-project=toyOS --xcode-build-system=new --export-compile-commands

run: install
	ninja -C out run -v

clean:
	${GN} clean out

test:
	echo ${PATH}

.PHONY: build install run clean gen
