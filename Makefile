## Build GOARCG and GOOS can be set externaly, otherwise the target
#  will match the build platform
#  Example GOARCH: amd64, GOOS: windows
#
GOARCH ?= $(shell go env GOARCH)
GOOS ?= $(shell go env GOOS)
GOOS ?= $(GOOS)
CGO_ENABLED = 0
GO111MODULE=on

RELEASE = 0.1.0

DISTDIR = .
FLAGS = -v 
EXTRA_FLAGS ?=
STATIC_BUILD ?= 1
GIT_COMMIT := $(shell git rev-list --abbrev-commit -1 HEAD 2>/dev/null)
GIT_COMMIT ?= unknown

## Add static build flags
ifeq ($(STATIC_BUILD),1)
	FLAGS += --tags "static" -ldflags '-s -w -X main.Version=$(RELEASE) -X main.GitCommit=$(GIT_COMMIT)'
else
	FLAGS += --tags "static" -ldflags '-X main.Version=$(RELEASE) -X main.GitCommit=$(GIT_COMMIT)'
endif

export GO111MODULE
export GOARCH
export GOOS
export CGO_ENABLED

build:
	@[ -d $(DISTDIR) ] || mkdir -p $(DISTDIR)
	go build $(FLAGS) $(EXTRA_FLAGS) -o $(DISTDIR)/gocd-$(GOOS)-$(GOARCH)

build-%: GOOS = $(shell _v=$*; echo $${_v%-*})
build-%: GOARCH = $(shell _v=$*; echo $${_v#*-})
build-%: build
	go build $(FLAGS) $(EXTRA_FLAGS) -o $(DISTDIR)/gocd-$(GOOS)-$(GOARCH)

dist-shasum: DISTDIR=./dist/
dist-shasum:
	cd $(DISTDIR) && sha256sum gocd-$(GOOS)-$(ARCH) | tee gocd-$(GOOS)-$(ARCH).sha256

dist: DISTDIR=./dist/
dist: build

dist-%: DISTDIR=./dist/
dist-%: build-%
	$(NOOP)

lint:
	[ -x ./bin/golangci-lint ] || wget -O - -q https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s
	./bin/golangci-lint run

test: lint
	go test
