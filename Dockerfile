### Prepare the dependencies
FROM melopt/alpine-perl-devel AS builder

RUN apk --no-cache add mariadb-dev postgresql-dev

COPY cpanfile cpanfile.snapshot /minion/
RUN  cd /minion && carton install --deployment && rm -rf local/cache ~/.cpanm*

COPY bin /minion/bin/
RUN set -e && cd /minion && for script in bin/* ; do perl -wc -Ilocal/lib/perl5 $script ; done


### Runtime image
FROM melopt/alpine-perl-runtime

WORKDIR /app

RUN apk --no-cache add mariadb-dev postgresql-dev

COPY --from=builder /minion /minion

ENTRYPOINT [ "/minion/bin/entrypoint" ]
