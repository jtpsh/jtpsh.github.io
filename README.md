# readme

Static generator for https://jtp.sh


### Build status
[![CircleCI](https://circleci.com/gh/dyepriiii/dyepriiii.github.io/tree/static-generator.svg?style=svg)](https://circleci.com/gh/dyepriiii/dyepriiii.github.io/tree/static-generator)


### Building
```
git clone git@github.com:dyepriiii/dyepriiii.github.io.git
git fetch
git checkout static-generator
source local_setup.sh

make cssminify && make html && \
    make html5validator && \
    make serve
```

### Updating gh-pages
Every commits pushed to this branch are automatically fed on CirclCI.
See `.circleci/config.yml`

