FROM ruby:3.1.0-slim-bullseye AS assets

WORKDIR /app

ARG UID=1000
ARG GID=1000
ENV NVM_DIR /usr/local/nvm
ARG NODE_VERSION=18.18.0
ENV NODE_VERSION="${NODE_VERSION}"

RUN bash -c "set -o pipefail && apt-get update \
  && apt-get install -y --no-install-recommends build-essential curl git libpq-dev python3-pip \
  && mkdir -p /usr/local/nvm \
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
  && source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default \
  && npm install --global yarn \
  && yarn global add node-gyp \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && groupadd -g \"${GID}\" ruby \
  && useradd --create-home --no-log-init -u \"${UID}\" -g \"${GID}\" ruby \
  && mkdir /node_modules && chown ruby:ruby -R /node_modules /app"
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

USER ruby

COPY --chown=ruby:ruby Gemfile* ./
RUN bundle config --global frozen 1 && bundle config set --local without 'development test' && bundle install

COPY --chown=ruby:ruby package.json *yarn* ./
RUN yarn install

ARG RAILS_ENV="production"
ARG NODE_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    NODE_ENV="${NODE_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin:/node_modules/.bin" \
    USER="ruby"

COPY --chown=ruby:ruby . .

RUN if [ "${RAILS_ENV}" != "development" ]; then \
  SECRET_KEY_BASE=1 rails assets:precompile; fi

CMD ["bash"]

###############################################################################

FROM ruby:3.1.0-slim-bullseye AS app

WORKDIR /app

ARG UID=1000
ARG GID=1000
ENV NVM_DIR /usr/local/nvm
ARG NODE_VERSION=18.18.0
ENV NODE_VERSION="${NODE_VERSION}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential python3-pip curl libpq-dev \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && groupadd -g "${GID}" ruby \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" ruby \
  && chown ruby:ruby -R /app
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
# We have to install NodeJS in the app until we don't have execjs for the
# bootstrap gem.
RUN bash -c "set -o pipefail && \
  mkdir -p /usr/local/nvm \
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
  && source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default"

USER ruby

COPY --chown=ruby:ruby bin/ ./bin
RUN chmod 0755 bin/*

ARG RAILS_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin" \
    USER="ruby"

COPY --chown=ruby:ruby --from=assets /usr/local/bundle /usr/local/bundle
COPY --chown=ruby:ruby --from=assets /app/public /public
COPY --chown=ruby:ruby . .
RUN bundle config --global frozen 1
RUN bundle config set --local without 'development test'
RUN bundle install

ENTRYPOINT ["/app/bin/docker-entrypoint-web"]

EXPOSE 8000

CMD ["rails", "s", "-p", "8000"]
