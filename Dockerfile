# Global Arguments
ARG PHP_VERSION=8.4

FROM curlimages/curl:latest AS builder

# Create base image
FROM php:${PHP_VERSION}-cli-alpine

# Copy artifacts from official curl image
# https://github.com/curl/curl-docker/blob/master/alpine/latest/Dockerfile#L96-L98
COPY --from=builder "/usr/lib/." "/usr/lib/"
COPY --from=builder "/usr/bin/curl" "/usr/bin/curl"
COPY --from=builder "/usr/include/curl" "/usr/include/curl"

RUN apk update && apk add --no-cache \
        freetype-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) exif gd intl zip

# Copy artifacts from official composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install dependencies
RUN apk add \
    --update \
    --no-cache \
    # Deployment
    bash \
    git \
    lftp \
    openssh-client \
    rsync \
    # Front-End tools
    nodejs \
    npm \
    # Additional tools
    zip \
    make

# Clone git-ftp and install
RUN git clone https://github.com/git-ftp/git-ftp.git \
    && cd git-ftp \
    && tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)" \
    && git checkout "$tag" \
    && make install

CMD ["bash"]
