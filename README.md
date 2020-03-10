# ResoTransport

A Ruby gem for connecting to and interacting with RESO WebAPI services.  Learn more about what that is by checking out the [RESO WebAPI](https://www.reso.org/reso-web-api/) Documentation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reso_transport'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reso_transport

## Usage


### Compatability

This gem has been tested to work with:

* [Spark Platform](https://sparkplatform.com)
* [Trestle](https://trestle.corelogic.com)
* [Bridge Interactive](https://www.bridgeinteractive.com)


### Loggin

You can either set a global logger in an initializer file:

```ruby
ResoTransport.configure do |c|
  c.logger = Logger.new("some_log_file")
  # OR
  c.logger = Rails.logger
end

```
Or you can set a logger for each specific instance of a client which can be useful for debugging:

```ruby
@client = ResoTransport::Client.new(config.merge(logger: Logger.new("logfile")))
```


### Getting Connected

There are 2 strategies for authentication. 

**Bearer Token**

It's simple to use a static access token if your token never expires:

```ruby
  @client = ResoTransport::Client.new({
    md_file: METADATA_CACHE,
    endpoint: ENDPOINT_URL
    authentication: {
      access_token: TOKEN,
      token_type: "Bearer" # this is the default and can be ommitted
    }
  })
```


**Authorization Endpoint**

If the connection requires requesting a new token periodically, it's easy to provide that information:

```ruby
  @client = ResoTransport::Client.new({
    md_file: METADATA_CACHE,
    endpoint: ENDPOINT_URL
    authentication: {
      endpoint: AUTH_ENDPOINT,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: "client_credentials", # these are the default and can be ommitted
      scope: "api"                      # 
    }
  })
```

This will pre-fetch a token from the provided endpoint when the current token is either non-existent or has expired.


### Resources

Once you have a successful connection you can explore what resources are available from the API:


```ruby
  @client.resources
  #=> {"Property"=>#<ResoTransport::Resource entity_set="Property", schema="ODataService">, "Office"=>#<ResoTransport::Resource entity_set="Office", schema="ODataService">, "Member"=>#<ResoTransport::Resource entity_set="Member", schema="ODataService">}

  @client.resources["Property"]
  #=> #<ResoTransport::Resource entity_set="Property", schema="ODataService"> 

  @client.resources["Property"].query.limit(1).results
  #=> Results Array
```

#### Querying

ResoTransport provides powerful querying capabilities:

To get 10 listings in Los Angeles between 900K and 1M and at least 5 bedrooms:
```ruby
  @resource.query.
    eq(City: "Los Angeles").
    le(ListPrice: 1_000_000).
    ge(ListPrice: 900_000, Bedrooms: 5).
    limit(10).
    results
```

To get 10 listings in Los Angeles OR Hollywood between 900K and 1M and at least 5 bedrooms:
```ruby
  @resource.query.
  any {
    eq(City: "Los Angeles").eq(City: "Hollywood")
  }.
  le(ListPrice: 1_000_000).
  ge(ListPrice: 900_000, Bedrooms: 5).
  limit(10).
  results
```

#### Expanding Child Records

To see what child records can be expanded look at `expandable`:

```ruby
  @resource.expandable
  #=> [#<struct ResoTransport::Property name="Media", data_type="Collection(RESO.Media)", attrs={"Name"=>"Media", "Type"=>"Collection(RESO.Media)"}, multi=true, enum=nil, complex_type=nil, entity_type=#<struct ResoTransport::EntityType name="Media", base_type=nil, primary_key="MediaKey", schema="CoreLogic.DataStandard.RESO.DD">> ...] 
```

Use `expand` to expand child records with the top level results.

```ruby
  @resource.query.expand("Media").limit(10).results
  #=> Results Array
```

You have several options to expand multiple child record sets. Each of these will have the same result.

```ruby
  @resource.query.expand("Media", "Office").limit(10).results
  
  @resource.query.expand(["Media", "Office"]).limit(10).results

  @resource.query.expand("Media").expand("Office").limit(10).results
```

### Results Array

The results are parsed according to the metadata with some things worth mentioning:

* Date fields are parsed into ruby `DateTime` objects
* Enumeration fields are parsed into either the `Name` or `Annotation -> String` of the member that is represented.
* Collections or Enumerations with `is_flags=true` will also be parsed into an `Array`.

### Enumerations

Enumerations are essentially a mapping of system values and display values.  To see a mapping:

```ruby
  @resource.property("StandardStatus").enum.mapping

  => {
       "Active"=>"Active",
       "ActiveUnderContract"=>"Active Under Contract",
       "Canceled"=>"Canceled",
       "Closed"=>"Closed",
       "ComingSoon"=>"Coming Soon",
       "Delete"=>"Delete",
       "Expired"=>"Expired",
       "Hold"=>"Hold",
       "Incomplete"=>"Incomplete",
       "Pending"=>"Pending",
       "Withdrawn"=>"Withdrawn"
     }
```

Most Enumerations will ultimately be used to fill a dropdown with options to select from.  Like so:

```ruby
  @resource.property("StandardStatus").enum.mapping.values
  #=> ["Active", "Active Under Contract", "Canceled", "Closed", "Coming Soon", "Delete", "Expired", "Hold", "Incomplete", "Pending", "Withdrawn"]
```

When querying for an enumeration value, you can provide either the system name, or the display name and it will be converted to the correct value. This allows your programs to not worry too much about the system values.

```ruby
  @resource.query.eq(StandardStatus: "Active Under Contract").limit(1).compile_params
  #=> {"$top"=>1, "$filter"=>"StandardStatus eq 'ActiveUnderContract'"} 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reso_transport. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ResoTransport project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/reso_transport/blob/master/CODE_OF_CONDUCT.md).
