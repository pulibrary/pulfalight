# Pulfalight
[![CircleCI](https://circleci.com/gh/pulibrary/pulfalight.svg?style=svg)](https://circleci.com/gh/pulibrary/pulfalight)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=plastic)](./LICENSE)

This is an implementation of ArcLight being implemented as a replacement for the
 Princeton University Finding Aids (PULFA) service. Accessible at https://findingaids.princeton.edu/.

### Development

#### Setup
* Install Lando from https://github.com/lando/lando/releases (at least 3.0.0-rrc.2)
* See .tool-versions for language version requirements (ruby, nodejs)

```sh
bundle install
yarn install
```
(Remember you'll need to run the above commands on an ongoing basis as dependencies are updated.)

#### Starting / stopping services
We use lando to run services required for both test and development
environments.

Start and initialize solr and database services with `rake servers:start`

To stop solr and database services: `rake servers:stop` or `lando stop`

#### Run tests
`bundle exec rspec`
To watch feature tests run in a browser, make sure chrome is installed and run: `RUN_IN_BROWSER=true rspec spec`

#### Start development server
- `rails s`
- Access Pulfalight at http://localhost:3000/

### Configuration
Please see [the ArcLight
documentation](https://github.com/projectblacklight/arclight/wiki/Indexing-EAD-in-ArcLight#repository-configuration)
for information regarding the configuration of repositories in ArcLight.

### Indexing documents into Pulfalight

#### Configuring ASpace


1. `brew install lastpass-cli`
2. `lpass login emailhere`
3. `bundle exec rake setup_keys`

#### Index "Interesting" EADs
A sub-section of all our collections have been identified and can be queued up
  for ingest via:

  `bundle exec rake pulfalight:aspace:index_test_eads`

#### Full/Partial Reindex

In a Rails console, `Aspace::Indexer.index_new` can be run to either perform a
full reindex, or if that's happened before, index any changes.

This will move to a rake task when our production system is implemented.

Sidekiq must be running in a separate window to process the resulting jobs (see below.)

Make sure Redis is running (`redis-server`), and then run:

`$ bundle exec sidekiq`

Once the jobs are finished processing by sidekiq you'll need to either wait 5 minutes for the soft commit to occur or manually issue a solr commit:

`$ bin/rails c`

`> Blacklight.default_index.connection.commit`

#### Indexing into a Development environment

A subset of collections (the same that are run in specs) can be indexed into
  development via `bundle exec rake pulfalight:seed`

#### Adding new EADs to test suite.

1. Open up `app/services/aspace_fixture_generator.rb`
1. Add EAD ID to the `AspaceFixtureGenerator::EAD_IDS` constant.
   1. comment out the other entries unless you want to regenerate them. it takes
      a while to run all of them.
1. If you're only interested in a subset of components, add them to the `AspaceFixtureGenerator::COMPONENT_MAP` constant.
1. Ensure you're on VPN
1. `bundle exec rake pulfalight:fixtures:refresh_aspace_fixtures`

##### Troubleshooting Aspace API Connections

If you get an error that the login failed, the most likely explanation is that one or more VPN machines changed IPs and we need to regenerate the list of VPN IPs and send it to Lyrasis support.

You can validate this by running `Aspace::Client.new` on a staging box rails console. If that doesn't error then it's not an issue with the credentials.

[Instructions](https://github.com/pulibrary/pul-the-hard-way/blob/main/services/vpn.md) and [a ruby script for generating the list of ips](https://github.com/pulibrary/pul-the-hard-way/tree/main/services/vpn) are in the pul-the-hard-way repo. Once you have the list of IPs, send it in an email to support@lyrasis.zendesk.com. You can say something like, "I’m having trouble accessing the archivesspace API and I suspect it’s because our VPN changed their backend endpoint IPs again. Can you please make sure the following IPs are allowed to access the API endpoint for aspace.princeton.edu?" If they follow up with more questions, it may be helpful to mention that this list of VPN IPs is in addition to the subnet of IPs for our "on campus" machines, which don't change.


### Citation Formatting

Citations are generated for collections and components, and rendered on the
show page for either of these resources. The default formatted repository
sources may be found and updated within the appropriate [configuration
file](./config/citations.yml).
