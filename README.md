# Plantain
[![Coverage Status](https://coveralls.io/repos/github/pulibrary/plantain/badge.svg?branch=master)](https://coveralls.io/github/pulibrary/plantain?branch=master)

This is an implementation of ArcLight being implemented as a replacement for the
 Princeton University Finding Aids (PULFA) service.

### Initial setup
```sh
git clone https://github.com/pulibrary/plantain.git
cd plantain
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

##### Retrieving the Documents from SVN

One must ensure that SVN is installed locally:

*In a macOS Environment:*
```
brew install svn
```

###### Using `lpass` for authentication [LastPass](https://lastpass.com)

*In a macOS Environment:*
```
brew install lpass
```

Then please invoke the following:
```
lpass login username@domain.edu
bundle exec rake pulfa:checkout
```

###### Manually Retrieving the Documents (without `lpass`)
In order to download the EAD documents from Princeton University Library
servers, one will need to please retrieve the server name, as well as the
credentials for retrieving the documents from LastPass. Then, please download
the files with the following:

```
export PULFA_SERVER_URL=[the PULFA subversion URL]
export PULFA_USERNAME=[the PULFA subversion username]
svn checkout $PULFA_SERVER_URL --username $PULFA_USERNAME eads/pulfa/
```

One should now have access to the EAD files from within the local development
environment.

#### Indexing the PULFA Documents into the Plantain Server Environment
One may also index the Documents remotely on the staging server by invoking the
follow Capistrano task:

```bash
bundle exec cap staging plantain:index_pulfa
```
