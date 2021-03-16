FROM debian:buster-slim AS builder
LABEL maintainer "marcel.waldvogel@trifence.ch"

# Compile shallot
RUN apt update
RUN apt -y install build-essential libssl-dev
ADD ./shallot /shallot
WORKDIR /shallot
RUN ./configure && make


FROM debian:buster-slim
LABEL maintainer "marcel.waldvogel@trifence.ch"

# Base packages
RUN apt update && \
    apt -y --no-install-recommends install \
    nginx \
    tor torsocks && \
    apt clean && \
    rm -Rf /var/lib/apt/lists/*
COPY --from=builder /shallot/shallot /bin

# Security and permissions
RUN useradd --system --uid 666 -M --shell /usr/sbin/nologin hidden

# Configure nginx logs to go to Docker log collection (via stdout/stderr)
RUN ln --symbolic --force /dev/stdout /var/log/nginx/access.log
RUN ln --symbolic --force /dev/stderr /var/log/nginx/error.log

# Main script
ADD ./main.sh /main.sh

# Tor Config
ADD ./torrc /etc/tor/torrc

# Add nginx default configuration 
ADD ./nginx.conf /etc/nginx/nginx.conf

# Configuration files and data output folder
VOLUME /web
WORKDIR /web

ENTRYPOINT ["/main.sh"]
CMD ["serve"]

