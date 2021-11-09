FROM docker.io/library/ruby:slim

RUN apt-get update -qq
RUN apt-get install -y build-essential libsqlite3-dev git-core

RUN apt-get install -y --no-install-recommends libjemalloc2
RUN rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ARG USER=app
ARG GROUP=app
ARG UID=1101
ARG GID=1101

RUN groupadd --gid $GID $GROUP
RUN useradd --uid $UID --gid $GID --groups $GROUP -ms /bin/bash $USER

RUN mkdir -p /var/app
RUN chown -R $USER:$GROUP /var/app

USER $USER
WORKDIR /var/app

ENV BUNDLER_VERSION='2.2.27'
RUN gem install bundler --no-document -v '2.2.27'

COPY --chown=$USER Gemfile* /var/app/
COPY --chown=$USER *.gemspec /var/app/
RUN bundle install

COPY --chown=$USER . /var/app

CMD ["rake"]
