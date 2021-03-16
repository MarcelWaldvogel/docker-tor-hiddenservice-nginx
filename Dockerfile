FROM debian:buster AS builder

# Compile shallot; use caching
RUN apt update
RUN apt -y --no-install-recommends install build-essential libssl-dev
ADD ./shallot /shallot
WORKDIR /shallot
RUN ./configure && make clean && make


FROM debian:buster-slim
LABEL maintainer "marcel.waldvogel@trifence.ch"

# Base packages
RUN apt update && \
    apt -y --no-install-recommends install nginx tor && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /shallot/shallot /bin

# Security and permissions
RUN useradd --system --uid 666 -M --shell /usr/sbin/nologin hidden

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
