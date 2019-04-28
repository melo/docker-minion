### Prepare the dependencies
FROM melopt/perl-alt:latest-build AS builder

RUN apk --no-cache add mariadb-dev postgresql-dev

COPY cpanfile* /stack/
RUN  cd /stack && pdi-build-deps

COPY bin /stack/bin/
RUN set -e && cd /stack && for script in bin/* ; do perl -wc $script ; done


### Runtime image
FROM melopt/perl-alt:latest-runtime

RUN apk --no-cache add mariadb-client postgresql-libs

COPY --from=builder /stack /stack

ENTRYPOINT [ "/stack/bin/minion-entrypoint" ]
