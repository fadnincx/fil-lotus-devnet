# Create builder container
FROM golang:1.17 as builder

# set BRANCH_FIL or COMMIT_HASH_FIL
ARG BRANCH_FIL=fil-benchmark
ARG COMMIT_HASH_FIL=""
ARG REPO_FIL=https://github.com/fadnincx/lotus
ARG NODEPATH=/lotus
ENV DEBIAN_FRONTEND=noninteractive

# Clone Lotus

# Err if neither branch nor hash defined
RUN if [ -z "${BRANCH_FIL}" ] && [ -z "${COMMIT_HASH_FIL}" ]; then \
    echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are empty'; \
    exit 1; \
  fi

# Err if both branch and hash defined
RUN if [ ! -z "${BRANCH_FIL}" ] && [ ! -z "${COMMIT_HASH_FIL}" ]; then \
    echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are set'; \
    exit 1; \
  fi


# clone
WORKDIR ${NODEPATH}
RUN git clone ${REPO_FIL} ${NODEPATH}

# checkout branch
RUN if [ ! -z "${BRANCH_FIL}" ]; then \
    echo "Checking out to Lotus branch: ${BRANCH_FIL}"; \
    git checkout ${BRANCH_FIL}; \
    echo "Git tag: $(git log --format="%H" -n 1)"; \
  fi

# checkout hash
RUN if [ ! -z "${COMMIT_HASH_FIL}" ]; then \
		echo "Checking out to Lotus commit: ${COMMIT_HASH_FIL}"; \
		git checkout ${COMMIT_HASH_FIL}; \
	fi

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev

RUN make clean fil

# Create final container
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ARG LOTUS_API_PORT=1234


# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils socat curl && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev wget libltdl7 libnuma1 hwloc libhwloc-dev tmux nano less iputils-ping python3 iproute2 bc

# Install all lotus bins
COPY --from=builder /lotus/lotus /usr/local/bin/
COPY --from=builder /lotus/lotus-miner /usr/local/bin/
COPY --from=builder /lotus/lotus-seed /usr/local/bin/
COPY --from=builder /lotus/lotus-gateway /usr/local/bin/
COPY --from=builder /lotus/lotus-shed /usr/local/bin/
COPY --from=builder /lotus/lotus-wallet /usr/local/bin/
COPY --from=builder /lotus/lotus-worker /usr/local/bin/

# Fetch 2048 byte params
RUN lotus-shed fetch-params --proving-params 0
RUN lotus-shed fetch-params --proving-params 2048


# Copy RCE and rediscli
COPY rce/rce /usr/local/bin/
COPY redis-cli/rediscli /usr/local/bin

ENV LOTUS_REDIS_ADDR lotus-redis:6379

# Copy start script
COPY start_lotus.sh /start_lotus.sh

ENTRYPOINT ["/start_lotus.sh"]
