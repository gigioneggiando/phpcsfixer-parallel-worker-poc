# Self-contained repro for PHP-CS-Fixer#9854: a parallel worker killed by a
# non-exception fatal (memory_limit) silently drops its file chunk while the run
# still exits 0. php-cs-fixer is installed as a Composer dependency, pinned to the
# commit where this was reproduced. To test another ref, override VERSION (and
# REPOSITORY, if the ref lives in a fork), e.g.:
#   docker build -t worker-poc \
#     --build-arg REPOSITORY=https://github.com/Wirone/PHP-CS-Fixer.git \
#     --build-arg VERSION=dev-codito/9854-oom-in-parallel-worker .
FROM php:8.3-cli

# Composer version constraint of friendsofphp/php-cs-fixer to install.
ARG VERSION=dev-master#945e6d8adaf000994145ee2c06490f435609a06c
# Optional git URL of a repository (e.g. a fork) to install php-cs-fixer from instead of Packagist.
ARG REPOSITORY=

RUN apt-get update && apt-get install -y --no-install-recommends git unzip libzip-dev \
    && docker-php-ext-install zip && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /project
RUN composer init --no-interaction --name=poc/target \
    && composer config minimum-stability dev \
    && if [ -n "${REPOSITORY}" ]; then composer config repositories.php-cs-fixer git "${REPOSITORY}"; fi \
    && composer require --no-interaction --no-progress \
         "friendsofphp/php-cs-fixer:${VERSION}"

COPY poc.sh /poc.sh
RUN chmod +x /poc.sh
ENTRYPOINT ["/bin/sh", "/poc.sh"]
