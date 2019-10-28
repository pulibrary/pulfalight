# Plantain
[![Coverage Status](https://coveralls.io/repos/github/pulibrary/plantain/badge.svg?branch=master)](https://coveralls.io/github/pulibrary/plantain?branch=master)

This is an implementation of ArcLight being implemented as a replacement for the
 Princeton University Finding Aids (PULFA) service.

### Initial setup
```sh
git clone https://github.com/pulibrary/plantain.git
cd plantain
yarn install
bundle install
bundle exec rake db:setup db:migrate
```

#### Node.js Support
Remember you'll need to run `bundle install` and `yarn install` (or `npm 
install`) on an ongoing basis as dependencies are updated.  Please note that the
oldest version of Node.js supported is 10.16.0.

#### Setup server
1. For development:
   - `bundle exec rake plantain:development`
   - In a separate terminal, please run: `bundle exec foreman start`
   - _Or, should you need to debug the Webpack build, please run `bundle exec webpack-dev-server` instead, and then run `bundle exec rails server` in another terminal_
   - Now, please visit the new installation at
     [http://localhost:3000](http://localhost:3000)
2. For testing:
   - `bundle exec rake plantain:test`
   - In a separate terminal, please run: `bundle exec rspec`

### Configuration
By default, Plantain uses Solr over the port 8983 (deployed using
`solr_wrapper`) for the index.

Please see [the ArcLight 
documentation](https://github.com/projectblacklight/arclight/wiki/Indexing-EAD-in-ArcLight#repository-configuration)
for information regarding the configuration of repositories in ArcLight.

### Indexing documents into Plantain

#### Retrieving the EAD-XML Documents
Documents are available from Princeton University Library staff, and should be
populated into the `eads/pulfa` directory, yielding a structure similar to the
following:

```bash
% ll eads/pulfa
[...] cotsen
[...] eng
[...] ga
[...] lae
[...] mss
[...] mudd
[...] rarebooks
```
