# Create builder container
FROM golang:1.17 as builder

# set BRANCH_FIL or COMMIT_HASH_FIL
ARG BRANCH_FIL=release/v1.13.2
ARG COMMIT_HASH_FIL=""
ARG REPO_FIL=https://github.com/filecoin-project/lotus
ARG NODEPATH=/lotus

ENV DEBIAN_FRONTEND=noninteractive

# Clone Eudico
RUN if [ -z "${BRANCH_FIL}" ] && [ -z "${COMMIT_HASH_FIL}" ]; then \
  		echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are empty'; \
  		exit 1; \
    fi

RUN if [ ! -z "${BRANCH_FIL}" ] && [ ! -z "${COMMIT_HASH_FIL}" ]; then \
		echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are set'; \
		exit 1; \
	fi


WORKDIR ${NODEPATH}
RUN git clone ${REPO_FIL} ${NODEPATH}

RUN if [ ! -z "${BRANCH_FIL}" ]; then \
        echo "Checking out to Eudico branch: ${BRANCH_FIL}"; \
  		git checkout ${BRANCH_FIL}; \
    fi

RUN if [ ! -z "${COMMIT_HASH_FIL}" ]; then \
		echo "Checking out to Lotus commit: ${COMMIT_HASH_FIL}"; \
		git checkout ${COMMIT_HASH_FIL}; \
	fi

# Install Eudico deps
RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev

RUN make clean 2k

# Create final container
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ARG LOTUS_API_PORT=1234


# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils socat curl && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev wget libltdl7 libnuma1 hwloc libhwloc-dev tmux nano less iputils-ping python3

# Install eudico
#COPY --from=builder /lotus/eudico /usr/local/bin/
COPY --from=builder /lotus/lotus /usr/local/bin/

# Install lotus-miner
COPY --from=builder /lotus/lotus-miner /usr/local/bin/
COPY --from=builder /lotus/lotus-seed /usr/local/bin/

# Fetch 2048 byte params
RUN lotus fetch-params 2048

# Copy key files
COPY key.key /key.key
# Copy net config
#COPY devnet_config.toml /root/.lotus/config.toml
#COPY devnet_config.toml /root/.lotusminer/config.toml

COPY rce.py /rce.py
# Copy start script
COPY start_lotus.sh /start_lotus.sh

ENTRYPOINT ["/start_lotus.sh"]

