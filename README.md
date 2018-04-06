[![Gem Version](https://badge.fury.io/rb/timeasure.svg)](https://badge.fury.io/rb/timeasure)
[![Maintainability](https://api.codeclimate.com/v1/badges/0ceacd5b50b0cd45fb8f/maintainability)](https://codeclimate.com/github/Riskified/timeasure/maintainability)

# Timeasure

**What Is It?**

Timeasure is a transparent method-level wrapper for profiling purposes. See a live example [right here!](https://timeasure-demo.herokuapp.com/)

Timeasure is a Ruby gem that allows measuring the runtime of methods in production environments
without having to alter the code of the methods themselves.

Timeasure allows you to declare tracked methods to be measured transparently upon each call.
Measured calls are then reported to Timeasure's Profiler, which aggregates the measurements on the method level.
This part is configurable and if you wish you can report measurements to another profiler of your choice.

**Why Use It?**

Timeasure was created in order to serve as an easy-to-use, self-contained framework for method-level profiling
that is safe to use in production. Testing runtime in non-production environments is helpful, but there is
great value to the knowledge gained by measuring what really goes on at real time.

**What To Do With the Data?**

The imagined usage of measured methods timing is to aggregate it along a certain transaction and report it to a live
BI service such as [NewRelic Insights](https://newrelic.com/insights) or [Keen.io](https://keen.io/);
however, different usages might prove helpful as well, such as writing the data to a database or a file.

**General Notes**

Timeasure uses minimal intervention in the Ruby Object Model for tracked modules and classes.
It integrates well within Rails and non-Rails apps.

Timeasure is inspired by [Metaprogramming Ruby 2](https://pragprog.com/book/ppmetr2/metaprogramming-ruby-2)
by [Paolo Perrotta](https://twitter.com/nusco)
and by [this](https://hashrocket.com/blog/posts/module-prepend-a-super-story) blog post by Hashrocket.

Timeasure is developed and maintained by [Eliav Lavi](http://www.eliavlavi.com) & [Riskified](https://www.riskified.com/).

## Requirements

Ruby 2.1 or a later version is mandatory. (Timeasure uses `Module#prepend` introduced in Ruby 2.0 and `Process::CLOCK_MONOTONIC` introduced in Ruby 2.1.)

## Installation

Add this line to your application's Gemfile:

    gem 'timeasure'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timeasure

## Usage
#### 1. Include Timeasure in Modules and Classes
Simply include the Timeasure module in any class or module and declare the desired methods to track:

```ruby
class Foo
  include Timeasure
  tracked_class_methods :bar
  tracked_instance_methods :baz, :qux
  
  def self.bar
    # some class-level stuff that can benefit from measuring runtime...
  end
    
  def baz
    # some instance-level stuff that can benefit from measuring runtime...
  end
  
  def qux
    # some other instance-level stuff that can benefit from measuring runtime...
  end
end
```
**An Important Note Regarding Private Methods**

If you need to track any private methods - either class methods or instance methods - use the designated class macros for that:

```ruby
class Foo
  include Timeasure
  tracked_class_methods :a_class_method_that_calls_private_methods
  tracked_private_class_methods :a_scoped_private_class_method, :an_inline_private_class_method
  
  class << self
    def a_class_method_that_calls_private_methods
      a_scoped_private_class_method
      an_inline_private_class_method
    end
    
    def a_scoped_private_class_method
      # some private class-level stuff that can benefit from measuring runtime...
    end
  end
  
  def self.an_inline_private_class_method
    # some other private class-level stuff that can benefit from measuring runtime...
  end
end
```

And the instance-level equivalent:

```ruby
class Foo
  include Timeasure
  tracked_instance_methods :a_instance_method_that_calls_private_methods
  tracked_private_instance_methods :a_scoped_private_instance_method, :an_inline_private_instance_method
  
  class << self
    def a_instance_method_that_calls_private_methods
      a_scoped_private_instance_method
      an_inline_private_instance_method
    end
    
    def a_scoped_private_instance_method
      # some private instance-level stuff that can benefit from measuring runtime...
    end
  end
  
  def self.an_inline_private_instance_method
    # some other private instance-level stuff that can benefit from measuring runtime...
  end
end
```

**ATTENTION!**

**Declaring the tracking of private methods with `tracked_class_methods` or `tracked_instance_methods` will end up in `NoMethodError` upon calling their triggering method!**

Also, tracking your public methods with `tracked_private_class_methods` or `tracked_private_instance_methods` will make your class' interface inaccessible.
The reason for these two is that since Timeasure is declared at the top of the class,
it cannot know in advance which methods will be declared as private, so you need to specify this explicitly.

As a side note, it could be claimed that as a rule of thumb, if you find yourself measuring private methods,
this might be a good idea to invest in refactoring this area of code and [Extract Class](https://refactoring.guru/extract-class).
However, this is not always possible, of course, especially when working on legacy code.
Hence, this feature of Timeasure should be considered as somewhat of a last resort and be handled with care.   

#### 2. Define the Boundaries of the Tracked Transaction
**Preparing for Method Tracking**

The user is responsible for managing the final reporting and the clean-up of the aggregated data after each transation.
It is recommended to prepare the profiler at the beginning of a transaction in which tracked methods exist with

```ruby
Timeasure::Profiling::Manager.prepare
```
and to re-prepare it again at the end of it in order to ensure a "clean slate" -
after you have handled the aggregated data in some way.

**Getting Hold of the Data**

In order to get hold of the reported methods data, use 
```ruby
Timeasure::Profiling::Manager.export
````
This will return an array of `ReportedMethod`s. Each `ReportedMethod` object holds the aggregated timing data per
each tracked method call. This means that no matter how many times you call a tracked method, Timeasure's Profiler will
still hold a single `ReportedMethod` object to represent it.

`ReportedMethod` allows reading the following attributes:  
* `klass_name`: Name of the class in which the tracked method resides.
* `method_name`: Name of the tracked method.
* `segment`: See [Segmented Method Tracking](#segmented-method-tracking) below.
* `metadata`: See [Carrying Metadata](#carrying-metadata) below.
* `method_path`: `klass_name` and `method_name` concatenated.
* `full_path`: Same as `method_path` unless segmentation is declared,
in which case the segment will be concatenated to the string as well. See [Segmented Method Tracking](#segmented-method-tracking) below.
* `runtime_sum`: The aggregated time it took the reported method in question to run across all calls.
* `call_count`: The times the reported method in question was called across all calls.
 

## Advanced Usage
#### Segmented Method Tracking
Timeasure was designed to separate regular code from its time measurement declaration.
This is achieved by Timeasure's class macros `tracked_class_methods` and `tracked_instance_methods`.
Sometimes, however, the need for additional data might arise. Imagine this method:

```ruby
class Foo
  def bar(baz)
    # some stuff that can benefit from measuring runtime
    # yet its runtime is also highly affected by the value of baz...
  end
end
```

We've seen how Timeasure makes it easy to measure the `bar` method.
However, if we wish to segment each call by the value of `baz`,
we may use Timeasure's direct interface and send this value as a **segment**:

```ruby
class Foo
  def bar(baz)
    Timeasure.measure(klass_name: 'Foo', method_name: 'bar', segment: { baz: baz }) do
      # the code to be measured
    end
  end
end
```

For such calls, Timeasure's Profiler will aggregate the data in `ReportedMethod` objects grouped by
class, method and segment.

This approach obviously violates Timeasure's idea of separating code and measurement-declaration,
but it allows for much more detailed investigations, if needed.
This will result in different `ReportedMethod` object in Timeasure's Profiler for
each combination of class, method and segment. Accordingly, such `ReportedMethod` object will include
these three elements, concatenated, as the value for `ReportedMethod#full_path`. 

#### Carrying Metadata
This feature was developed in order to complement the segmented method tracking.

Sometimes carrying data with measurement that does not define a segment might be needed.
For example, assuming we save all our `ReportedMethod`s to some table called `reported_methods`,
we might want to supply a custom table name for specific measurements.
This might be achieved by using `metadata`:
 
```ruby
class Foo
  def bar
    Timeasure.measure(klass_name: 'Foo', method_name: 'bar', metadata: { table_name: 'my_custom_table' }) do
      # the code to be measured
    end
  end
end
```

Unlike Segments, Timeasure only carries the Metadata onwards.
It is up to the user to make use of this data, probably after calling `Timeasure::Profiling::Manager.export`.

## Notes
#### Compatibility with RSpec

If you run your test suite with Timeasure installed and modules, classes and methods tracked and all works fine - hurray!
However, due to the mechanics of Timeasure - namely, its usage of prepended modules - there exist a problem with
**stubbing** Timeasure-tracked method (RSpec does not support stubbing methods that appear in a prepended module).
To be accurate, that means that if you are tracking method `#foo`, you can not
declare something like `allow(bar).to receive(:foo).and_return(bar)`. Your specs will refuse to run in this case.
To solve that problem you can configure Timeasure's `enable_timeasure_proc` **not** to run under certain conditions.

If you are on Rails, add the following as a Rails initializer:

```ruby
require 'timeasure'

Timeasure.configure do |configuration|
  configuration.enable_timeasure_proc = lambda { !Rails.env.test? }
end
```  

Timeasure will not come into action if the expression in the block evaluates to `false`.
By default this block evaluates to `true`.

In case you are loading files manually (probably not on Rails), you can add this to *spec_helper.rb*:

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    Timeasure.configure do |configuration|
      configuration.enable_timeasure_proc = lambda { false }
    end
  end
end
``` 


## Feature Requests

Timeasure is open for changes and requests!
If you have an idea, a question or some need, feel free to contact me here or at eliavlavi@gmail.com.

## Contributing

1. Fork it ( https://github.com/riskified/timeasure/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
