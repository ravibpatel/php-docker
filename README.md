# PHP Docker Image

This repository contains a Dockerfile to build a PHP CLI environment with additional tools for development and deployment.

## Features

- Alpine Linux
- PHP 8.4, 8.3, 8.2 or 8.1 CLI with GD, Exif, intl, and Zip extensions
- Composer
- Bash
- Git
- Rsync
- cURL with SFTP support
- Node.js and npm
- git-ftp
- LFTP
- OpenSSH Client
- ZIP

## Usage

This is an example of a .gitlab-ci.yml file that installs composer dependencies, runs tests, and deploys to a server using git-ftp and SSH.

```
stages:
  - build
  - test
  - deploy

default:
  image: rbsoftravi/php:8.4

build:
  stage: build
  only:
    refs:
      - merge_requests
      - push
  cache:
    key:
      files:
        - composer.lock
    paths:
      - vendor
    policy: pull-push
  script:
    - composer install --no-interaction --prefer-dist --optimize-autoloader

tests:
  stage: test
  only:
    refs:
      - merge_requests
      - push
  cache:
    key:
      files:
        - composer.lock
    paths:
      - vendor
    policy: pull
  script:
    - ./vendor/bin/pest --ci

deploy:
  stage: deploy
  only:
    refs:
      - main
  before_script:
    # https://docs.gitlab.com/ee/ci/jobs/ssh_keys.html
    - eval $(ssh-agent -s)
    - chmod 400 "$SSH_PRIVATE_KEY"
    - ssh-add "$SSH_PRIVATE_KEY"
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan $HOST >> ~/.ssh/known_hosts
    - chmod 644 ~/.ssh/known_hosts
  script:
    - git ftp push --auto-init --syncroot . --user "$USERNAME" --key "$SSH_PRIVATE_KEY" "sftp://${HOST}${REMOTE_DIR}"
    - ssh $USERNAME@$HOST "cd $REMOTE_DIR && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader && npm install && npm run build && exit"
```
