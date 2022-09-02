# About

## Docker build

```bash
export MY_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
sudo -E docker build \
    --build-arg PKG_NAME=openssl/1.1.1-stable \
    --build-arg PKG_CHANNEL=conan/stable \
    --build-arg PKG_UPLOAD_NAME=openssl/1.1.1-stable@conan/stable \
    --build-arg CONAN_EXTRA_REPOS="conan-local http://$MY_IP:8081/artifactory/api/conan/conan False" \
    --build-arg CONAN_EXTRA_REPOS_USER="user -p password1 -r conan-local admin" \
    --build-arg CONAN_INSTALL="conan install --profile gcc --build missing" \
    --build-arg CONAN_CREATE="conan create --profile gcc --build missing" \
    --build-arg CONAN_UPLOAD="conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force" \
    --build-arg BUILD_TYPE=Debug \
    -f conan_openssl.Dockerfile --tag conan_openssl . --no-cache
```

## Local build

```bash
export VERBOSE=1
export CONAN_REVISIONS_ENABLED=1
export CONAN_VERBOSE_TRACEBACK=1
export CONAN_PRINT_RUN_COMMANDS=1
export CONAN_LOGGING_LEVEL=10

export PKG_NAME=openssl/1.1.1-stable@conan/stable
(CONAN_REVISIONS_ENABLED=1 \
    conan remove --force $PKG_NAME || true)
conan create . conan/stable -s build_type=Debug --profile gcc --build missing -o openssl:shared=True
conan upload $PKG_NAME --all -r=conan-local -c --retry 3 --retry-wait 10 --force

# clean build cache
conan remove "*" --build --force
```

## HOW TO BUILD WITH SANITIZERS ENABLED

Use `enable_asan` or `enable_ubsan`, etc.

```bash
export CC=$(find ~/.conan/data/llvm_tools/master/conan/stable/package/ -path "*bin/clang" | head -n 1)

export CXX=$(find ~/.conan/data/llvm_tools/master/conan/stable/package/ -path "*bin/clang++" | head -n 1)

export CFLAGS="-fsanitize=thread -fuse-ld=lld -stdlib=libc++ -lc++ -lc++abi -lunwind"

export CXXFLAGS="-fsanitize=thread -fuse-ld=lld -stdlib=libc++ -lc++ -lc++abi -lunwind"

export LDFLAGS="-stdlib=libc++ -lc++ -lc++abi -lunwind"

export VERBOSE=1
export CONAN_REVISIONS_ENABLED=1
export CONAN_VERBOSE_TRACEBACK=1
export CONAN_PRINT_RUN_COMMANDS=1
export CONAN_LOGGING_LEVEL=10

# must exist
file $(dirname $CXX)/../lib/clang/10.0.1/lib/linux/libclang_rt.tsan_cxx-x86_64.a

# NOTE: NO `--profile` argument cause we use `CXX` env. var
# NOTE: change `build_type=Debug` to `build_type=Release` in production
conan create . \
    conan/stable \
    -s build_type=Debug \
    -s llvm_tools:build_type=Release \
    -o llvm_tools:enable_tsan=True \
    -o llvm_tools:include_what_you_use=False \
    -s llvm_tools:compiler=clang \
    -s llvm_tools:compiler.version=10 \
    -s llvm_tools:compiler.libcxx=libstdc++11 \
    -o openssl:enable_tsan=True \
    -e openssl:enable_llvm_tools=True \
    -e openssl:compile_with_llvm_tools=True \
    -s compiler=clang \
    -s compiler.version=10 \
    -s compiler.libcxx=libc++ \
    -o openssl:shared=True

# reset changed LDFLAGS
unset LDFLAGS

# reset changed CFLAGS
unset CFLAGS

# reset changed CXXFLAGS
unset CXXFLAGS

NOTE: during compilation conan will print `llvm_tools_ROOT =`. Make sure its path matches `$CC` and `$CXX`.

# clean build cache
conan remove "*" --build --force
```

## How to diagnose errors in conanfile (CONAN_PRINT_RUN_COMMANDS)

```bash
export VERBOSE=1
export CONAN_REVISIONS_ENABLED=1
export CONAN_VERBOSE_TRACEBACK=1
export CONAN_PRINT_RUN_COMMANDS=1
export CONAN_LOGGING_LEVEL=10

# NOTE: about `--keep-source` see https://bincrafters.github.io/2018/02/27/Updated-Conan-Package-Flow-1.1/
conan create . conan/stable -s build_type=Debug --profile gcc --build missing --keep-source

# clean build cache
conan remove "*" --build --force
```
