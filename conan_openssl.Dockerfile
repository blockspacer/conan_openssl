# allows individual sections to be run by doing: docker build --target ...
FROM conan_build_env as conan_openssl
# NOTE: if not BUILD_GRPC_FROM_SOURCES, then script uses conan protobuf package
ARG BUILD_TYPE=Release
ARG CMAKE="cmake"
ARG GIT="git"
ARG GIT_EMAIL="you@example.com"
ARG GIT_USERNAME="Your Name"
ARG APT="apt-get -qq --no-install-recommends"
ARG LS_VERBOSE="ls -artl"
ARG CONAN="conan"
ARG PKG_NAME="openssl/OpenSSL_1_1_1-stable"
ARG PKG_CHANNEL="conan/stable"
ARG PKG_UPLOAD_NAME="openssl/OpenSSL_1_1_1-stable@conan/stable"
ARG CONAN_CREATE="conan create --profile gcc"
#ARG CODE_NAME="bionic"
# Example: conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force
ARG CONAN_UPLOAD=""
# Example: --build-arg CONAN_EXTRA_REPOS="conan-local http://localhost:8081/artifactory/api/conan/conan False"
ARG CONAN_EXTRA_REPOS=""
# Example: --build-arg CONAN_EXTRA_REPOS_USER="user -p password -r conan-local admin"
ARG CONAN_EXTRA_REPOS_USER=""
ENV LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    #TERM=screen \
    PATH=/usr/bin/:/usr/local/bin/:/go/bin:/usr/local/go/bin:/usr/local/include/:/usr/local/lib/:/usr/lib/clang/6.0/include:/usr/lib/llvm-6.0/include/:$PATH \
    LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH \
    GIT_AUTHOR_NAME=$GIT_USERNAME \
    GIT_AUTHOR_EMAIL=$GIT_EMAIL \
    GIT_COMMITTER_NAME=$GIT_USERNAME \
    GIT_COMMITTER_EMAIL=$GIT_EMAIL \
    WDIR=/opt \
    # NOTE: PROJ_DIR must be within WDIR
    PROJ_DIR=/opt/project_copy \
    GOPATH=/go \
    CONAN_REVISIONS_ENABLED=1 \
    CONAN_PRINT_RUN_COMMANDS=1 \
    CONAN_LOGGING_LEVEL=10 \
    CONAN_VERBOSE_TRACEBACK=1

# create all folders parent to $PROJ_DIR
RUN set -ex \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  mkdir -p $WDIR
# NOTE: ADD invalidates the cache, COPY does not
COPY "conanfile.py" $PROJ_DIR/conanfile.py
WORKDIR $PROJ_DIR

RUN set -ex \
  && \
  $APT update \
  && \
  cd $PROJ_DIR \
  && \
  $LS_VERBOSE $PROJ_DIR \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  ldconfig \
  && \
  export CC=gcc \
  && \
  export CXX=g++ \
  #&& \
  #git config --global http.sslVerify false \
  #&& \
  #git config --global https.sslVerify false \
  #&& \
  #git config --global http.postBuffer 1048576000 \
  #&& \
  #git config --global https.postBuffer 1048576000 \
  #&& \
  #echo $(git config --system --get http.proxy) \
  #&& \
  #echo $(git config --system --get https.proxy) \
  #&& \
  #git config --system --unset https.proxy \
  #&& \
  #git config --system --unset http.proxy \
  #&& \
  #git config --global --unset https.proxy \
  #&& \
  #git config --global --unset http.proxy \
  && \
  cd $PROJ_DIR \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS" ]; then \
    ($CONAN remote add $CONAN_EXTRA_REPOS || true) \
    ; \
  fi \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS_USER" ]; then \
    $CONAN $CONAN_EXTRA_REPOS_USER \
    ; \
  fi \
  && \
  $CONAN_CREATE -s build_type=$BUILD_TYPE . $PKG_CHANNEL \
  && \
  if [ ! -z "$CONAN_UPLOAD" ]; then \
    $CONAN_UPLOAD $PKG_UPLOAD_NAME \
    ; \
  fi \
  && \
  # remove unused project copy after install
  # NOTE: must remove copied files
  cd $WDIR && rm -rf $PROJ_DIR
  #
  # NOTE: no need to clean apt in dev env
