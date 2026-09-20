# Self-contained repro for PHP-CS-Fixer#9854: a parallel worker killed by a
# non-exception fatal (memory_limit) silently drops its file chunk while the run
# still exits 0. php-cs-fixer is installed as a Composer dependency, pinned to the
# commit where this was reproduced (bump COMMIT to test another ref).
FROM php:8.3-cli

ARG COMMIT=945e6d8adaf000994145ee2c06490f435609a06c

RUN apt-get update && apt-get install -y --no-install-recommends git unzip libzip-dev \
    && docker-php-ext-install zip && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /project
RUN composer init --no-interaction --name=poc/target \
    && composer config minimum-stability dev \
    && composer require --no-interaction --no-progress \
         "friendsofphp/php-cs-fixer:dev-master#${COMMIT}"

COPY poc.sh /poc.sh
RUN chmod +x /poc.sh
ENTRYPOINT ["/bin/sh", "/poc.sh"]
