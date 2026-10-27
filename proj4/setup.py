from distutils.core import setup, Extension
import sysconfig

def main():
    # Mac (Apple Silicon) 版本的参数：clang 需要 -Xpreprocessor -fopenmp + Homebrew libomp
    CFLAGS = ['-g', '-Wall', '-std=c99', '-Xpreprocessor', '-fopenmp',
              '-I/opt/homebrew/opt/libomp/include', '-pthread', '-O3']
    LDFLAGS = ['-L/opt/homebrew/opt/libomp/lib', '-lomp']
    # Use the setup function we imported and set up the modules.
    # You may find this reference helpful: https://docs.python.org/3.6/extending/building.html
    module = Extension("numc",
                       sources=["numc.c", "matrix.c"],
                       extra_compile_args=CFLAGS,
                       extra_link_args=LDFLAGS)
    setup(name="numc",
          version="1.0",
          description="numc matrix module",
          ext_modules=[module])


if __name__ == "__main__":
    main()
