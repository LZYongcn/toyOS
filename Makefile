GN=/Users/lizhengyong/google/depot_tools/gn

install: 
	ninja -C out install -v

build: 
	ninja -C out build -v

gen:
	${GN} gen ./out --ide=xcode --xcode-project=toyOS --xcode-build-system=new

run: install
	ninja -C out run -v

clean:
	${GN} clean out

.PHONY: build install run clean gen
