# Hamster::Record

Hamster::Record is a simple immutable data structure using
Hamster::Hash that attempts to have a interface similar to that of
Ruby's Struct. Though while similar to Structs the interface allows
for default values and value checking, which in part makes it more
similar to Elixir's Structs or vaguely similar to Clojure's Records.

Also aims to have better performance than Functional Ruby's Record type
and Hamsteram's Struct type. See `bench/records.rb`.

## Why?

* Hashes are very simple and easy to work with, but many Ruby libraries
  expect Objects w/ reader methods available. For instance
  ActiveRecord::Serializers expects that any defined attribute is
  available on the given object via a public method.
* OpenStruct has poor performance; mutable. Hashie can be considered
  harmful http://www.schneems.com/2014/12/15/hashie-considered-harmful.html
* Many times when defining Contracts it is nice to not only know the
  argument isn't just a Hash but a specific type without actually having
  to check it's shape.
* Since Records are immutable we can consider their instances to be
  value objects(?)
* Being able define a type with default values can help code DRY.
* Simple type and pattern checking helps catch bugs earlier.
* Plain ol' Ruby Structs are mutable. ¯\\_(ツ)_/¯

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hamster-record'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hamster-record

## Usage

```ruby
Person  = Hamster::Record.define(:name, :age)
Address = Hamster::Record.define do
  field :lines, C::ArrayOf[String]
  field :country, String, "Canada"
  field :current, default: true # alternative syntax
  field :state, String
  field :city, String
end

James = Person.new(name: "James", age: 101)

my_address = Address.new(state: "BC", city: "Victoria")
dream_address = Address.new(country: :LandOfChocolate) # Exception

James.put(:age, 28) # Person[name: "James", age: 28]
my_address.put(current: :woof) # Not boolean; raises Contract exception
```

## Perf

```bash
-----------------------------------
PORO
-----------------------------------
Total allocated: 121.307 MBs
Total objects: 1100000 objects
-----------------------------------
ConcurrentRuby Struct
-----------------------------------
Total allocated: 30.518 MBs
Total objects: 800000 objects
-----------------------------------
Hasmter Record
-----------------------------------
Total allocated: 121.307 MBs
Total objects: 1100000 objects
-----------------------------------
FunctionalRuby Record
-----------------------------------
Total allocated: 98.419 MBs
Total objects: 1200000 objects
-----------------------------------
Hamsterdam Struct
-----------------------------------
Total allocated: 402.832 MBs
Total objects: 4600000 objects
-----------------------------------
Instantiation
-----------------------------------
                                user     system      total        real
class:                      0.300000   0.490000   0.790000 (  0.795630)
struct:                     0.290000   0.380000   0.670000 (  0.662491)
concurrent-ruby struct:     2.040000   1.820000   3.860000 (  3.890427)
hamster record:             4.830000   0.020000   4.850000 (  4.870912)
hamster record w/ default:  5.670000   0.030000   5.700000 (  5.710613)
hamster record w/ types:   18.900000   0.080000  18.980000 ( 19.059628)
hamster:                    4.770000   0.020000   4.790000 (  4.814535)
functional-ruby record:     7.490000   0.040000   7.530000 (  7.577671)
^^ w/ types:                8.850000   0.050000   8.900000 (  8.951575)
openstruct:                16.080000   0.930000  17.010000 ( 17.076379)
hamsterdam:                42.240000   0.590000  42.830000 ( 43.004427)
```

## Caveats

* Any field you would like to be readable *must* be defined in the
  Record definition. Seemingly just adding `#method_missing` to a Ruby
  object add significant performance issues (~25% in my tests.)
* Concurrent Ruby's ImmutableStruct type has better
  performance and uses less memory, however doesn't have default values
  or type checking. Would be interesting to build a 'Hamster::Struct'
  type with an identical interface to Ruby's Struct but with optional
  typing and defaults. Potentially it could be implemented with a simple
  Hamster::Vector or a frozen Ruby Array, may be able to eek out better
  perf.
* Using types comes at a fairly significant cost, in my tests it was
  generally ~3X slower to instantiate a record. As a result typing can
  be disabled with DISABLE_TYPES env var, which should make it suitable
  for production environment.

## Contributing

1. Fork it ( https://github.com/jamesdphillips/hamster-record/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
