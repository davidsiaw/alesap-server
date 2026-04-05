FROM ruby:3.4-alpine

ARG PUID=1000
ARG PGID=1000

RUN apk --update add build-base git file less postgresql-dev nodejs tzdata curl rust cargo postgresql postgresql-contrib redis yaml-dev linux-headers && \
  gem install foreman && \
  addgroup -g ${PGID} srv && \
    adduser -D -u ${PUID} -G srv srv && \
    # mkdir -p /tmp/ && \ # Uncomment these if you want rbspy
    # cd /tmp/ && \
    # export PATH=/root/.cargo/bin:$PATH && \
    # git clone https://github.com/rbspy/rbspy && \
    # cd rbspy && \
    # cargo install && \
    mkdir -p /srv/tmp

ENV MECAB_VERSION 0.996
ENV IPADIC_VERSION 2.7.0-20070610

# the file ids can be obtained from the google drive links from
# http://taku910.github.io/mecab/#download
ENV mecab_url https://drive.google.com/uc?export=download&id=1SJjk4IylQaO2yGc0vMtx5MHhZcjaeMLZ

ENV ipadic_url https://drive.google.com/uc?export=download&id=1aQCOnE4aGPz-3tXpt6Mok2fcPgbnnouh

ARG _ARCH="--build=x86_64-unknown-linux-gnu"

RUN curl -SL -o mecab-${MECAB_VERSION}.tar.gz ${mecab_url} \
  && tar zxf mecab-${MECAB_VERSION}.tar.gz \
  && cd mecab-${MECAB_VERSION} \
  && ./configure --enable-utf8-only --with-charset=utf8 ${_ARCH} \
  && make \
  && make install

RUN curl -SL -o mecab-ipadic-${IPADIC_VERSION}.tar.gz ${ipadic_url} \
  && tar zxf mecab-ipadic-${IPADIC_VERSION}.tar.gz \
  && cd mecab-ipadic-${IPADIC_VERSION} \
  && ./configure --with-charset=utf8 ${_ARCH} \
  && make \
  && make install \
  && cd

ADD Gemfile Gemfile.lock Rakefile package.json .rspec .rubocop.yml .rubocop_todo.yml config.ru /srv/

WORKDIR /srv

RUN bundle

ADD --chown=srv:srv log /srv/log
ADD --chown=srv:srv public /srv/public
ADD --chown=srv:srv vendor /srv/vendor
ADD --chown=srv:srv bin /srv/bin
ADD --chown=srv:srv lib /srv/lib
ADD --chown=srv:srv db /srv/db
ADD --chown=srv:srv config /srv/config
ADD --chown=srv:srv spec /srv/spec
ADD --chown=srv:srv app /srv/app

ADD --chown=srv:srv docker/unit/start.sh docker/unit/waitpg.sh docker/unit/waitredis.sh docker/unit/Procfile /srv/

RUN mkdir -p /run/redis && \
    mkdir -p /run/postgresql && \
    chown -R srv:srv /run && \
    chown -R srv /srv && \
    chgrp -R srv /srv

USER srv

RUN mkdir postgres && \
    chmod -R 700 postgres && \
    initdb -D postgres

VOLUME /srv/postgres

EXPOSE 3000

ENV RAILS_ENV=development
ENV DATABASE_URL=postgres://srv:@localhost
ENV REDIS_URL=redis://localhost:6379/0

ENV MECAB_PATH=/mecab-ipadic-${IPADIC_VERSION}

HEALTHCHECK --interval=1m \
            --timeout=3s \
            --start-period=20s \
  CMD curl -f http://localhost:3000/api/v1/health || exit 1

CMD ["sh", "-c", "sh /srv/start.sh"]
