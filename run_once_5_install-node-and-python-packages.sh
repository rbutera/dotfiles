#!/bin/bash
# install global node packages
nodenv install 16.13.1
nodenv global 16.13.1
npm install -g @nestjs/cli prettier eslint typescript xo markdownlint remark hicat ts-node

# install global python packages
pyenv install 3.10.4
pyenv global 3.10.4
pip install autopep8 flake8 black click
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
