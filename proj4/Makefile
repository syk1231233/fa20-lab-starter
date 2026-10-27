# Mac (Apple Silicon) 版本：clang + Homebrew libomp，NEON 代替 AVX
CC = clang
OMP = /opt/homebrew/opt/libomp
CFLAGS = -g -Wall -std=c99 -Xpreprocessor -fopenmp -I$(OMP)/include -pthread -O3
LDFLAGS = -L$(OMP)/lib -lomp
CUNIT = -L/opt/homebrew/opt/cunit/lib -I/opt/homebrew/opt/cunit/include -lcunit
PYTHON = -I/opt/anaconda3/include/python3.13 -L/opt/anaconda3/lib -lpython3.13 -Wl,-rpath,/opt/anaconda3/lib

install:
	if [ ! -f files.txt ]; then touch files.txt; fi
	rm -rf build
	xargs rm -rf < files.txt
	python3 setup.py install --record files.txt

uninstall:
	if [ ! -f files.txt ]; then touch files.txt; fi
	rm -rf build
	xargs rm -rf < files.txt

clean:
	rm -f *.o
	rm -f test
	rm -rf build
	rm -rf __pycache__

test:
	rm -f test
	$(CC) $(CFLAGS) mat_test.c matrix.c -o test $(LDFLAGS) $(CUNIT) $(PYTHON)
	./test

.PHONY: test