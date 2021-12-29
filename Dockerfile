FROM docker.io/library/ruby:slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends curl build-essential git-core libjemalloc2 && rm -rf /var/lib/apt/lists/*
RUN curl -O https://www.sqlite.org/2021/sqlite-autoconf-3370000.tar.gz && tar xvzf sqlite-autoconf-3370000.tar.gz
RUN cd sqlite-autoconf-3370000 && ./configure && make && make install

ENV LANG=C.UTF-8
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ARG USER=app
ARG GROUP=app
ARG UID=1101
ARG GID=1101

RUN groupadd --gid $GID $GROUP && useradd --uid $UID --gid $GID --groups $GROUP -ms /bin/bash $USER

RUN mkdir -p /var/app && chown -R $USER:$GROUP /var/app

USER $USER
WORKDIR /var/app

ENV BUNDLER_VERSION='2.2.27'
RUN gem install bundler --no-document -v '2.2.27'

COPY --chown=$USER Gemfile* /var/app/
COPY --chown=$USER *.gemspec /var/app/
RUN bundle install

COPY --chown=$USER . /var/app

CMD ["rake"]
