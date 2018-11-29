# Princeton University Finding Aids (PULFA)
## 3.0 Prototype with ArcLight

This is an experimental implementation of ArcLight being tested as a candidate for replacing the current PULFA 2.0 application.

### Installation
```bash
git clone
bundle install
bundle exec rake solr_wrapper
bundle exec rails s
```

Now, please visit the new installation at [http://localhost:3000]()

### Configuration
By default, PULFA 3.0 uses Solr over the port 8983 (deployed using `solr_wrapper`) for the index.  PULFA 3.0 also feature the following ArcLight repositories:

- mudd
- mss
- cotsen
- eng
- rarebooks
- ga
- lae

Please see [the ArcLight documentation](https://github.com/sul-dlss/arclight/wiki/Indexing-EAD-in-ArcLight#repository-configuration) for further information regarding repositories in ArcLight.

### Indexing documents into PULFA 3.0

#### Retrieving the EAD-XML Documents
Documents are available from Princeton University Library staff, and should be populated into the `eads/pulfa` directory, yielding a structure similar to the following:

```bash
% ll eads/pulfa/eads
[...] cotsen
[...] eng
[...] ga
[...] lae
[...] mss
[...] mudd
[...] rarebooks
```

#### Indexing Directories
One indexes directories of PULFA EAD Documents by passing the parent directory name to the Rake Task `pulfa:index:collection`:

```ruby
bundle exec rake pulfa:index:collection[cotsen]
```

#### Indexing Documents
One indexes single PULFA EAD Documents by passing the relative file path and repository name to the Rake Task `pulfa:index:document`:

```ruby
bundle exec rake pulfa:index:document[eads/pulfa/eads/mudd/univarchives/AC123.EAD.xml,mudd]
```
