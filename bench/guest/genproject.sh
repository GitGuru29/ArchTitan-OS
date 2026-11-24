#!/bin/bash
# =============================================================================
# genproject.sh — generate the benchmark compile project
#
# A synthetic C++ template-heavy project calibrated to behave like real
# compiler workloads: deep recursive template instantiation forces large
# cc1plus RSS (~hundreds of MB) and multi-second compile times per TU.
#
# usage: genproject.sh <target-dir> [ntus] [chains_per_tu] [depth]
# =============================================================================
set -eu

DIR="${1:?target dir}"
NTUS="${2:-16}"
CHAINS="${3:-12}"
DEPTH="${4:-512}"

mkdir -p "$DIR"

# ── heavy translation units ──────────────────────────────────────────────────
for ((i = 0; i < NTUS; i++)); do
    {
        echo '#include <cstdint>'
        echo 'extern "C" unsigned long long bench_sink(unsigned long long);'
        for ((c = 0; c < CHAINS; c++)); do
            # vary the depth per chain so instantiations differ
            d=$((DEPTH - c))
            cat <<EOF
template<int N> struct H${c} {
    H${c}<N - 1> ch;
    unsigned long long p[16];
    static constexpr unsigned long long f(int x) {
        return H${c}<N - 1>::f(x) ^ (N * 2654435761ULL * (unsigned)x);
    }
};
template<> struct H${c}<0> {
    unsigned long long p[16];
    static constexpr unsigned long long f(int) { return 88172645463325252ULL; }
};
static const unsigned long long v${c}_${i} = H${c}<${d}>::f(${c} + ${i} + 1);
EOF
        done
        echo 'unsigned long long bench_sink(unsigned long long s) {'
        for ((c = 0; c < CHAINS; c++)); do
            echo "    s += v${c}_${i};"
        done
        echo '    return s;'
        echo '}'
    } > "$DIR/tu$i.cpp"
done

# ── Makefile ─────────────────────────────────────────────────────────────────
cat > "$DIR/Makefile" <<'EOF'
CXX      ?= g++
CXXFLAGS ?= -O1 -c -std=c++20 -w
SRCS     := $(wildcard tu*.cpp)
OBJS     := $(patsubst %.cpp,build/%.o,$(SRCS))

all: build/libbench.a

build/libbench.a: $(OBJS)
	ar rcs $@ $^

build/%.o: %.cpp
	@mkdir -p build
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -rf build

.PHONY: all clean
EOF

# ── CMakeLists.txt ───────────────────────────────────────────────────────────
# Not used to build (the Makefile is), but every real C++ project of this shape
# carries one. It also gives THM's CWD classifier a recognised project marker:
# without it the compile/hog processes are classified NEUTRAL and never tracked.
cat > "$DIR/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(bench CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB BENCH_SOURCES CONFIGURE_DEPENDS tu*.cpp)
add_library(bench STATIC ${BENCH_SOURCES})
EOF

echo "GENERATED_PROJECT dir=$DIR tus=$NTUS chains=$CHAINS depth=$DEPTH"
