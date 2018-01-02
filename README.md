# Timeasure

Timeasure is a transparent method-level wrapper for profiling purposes developed by Riskified, Inc ([https://www.riskified.com](https://www.riskified.com/)).

Timeasure allows you to declare tracked methods to be measured transparently upon each call.
Measured calls are then reported according to a configurable proc of your liking.

Timeasure was created in order to serve as an easy-to-use, self-contained framework for method-level profiling.

The imagined usage of measured methods timing is to aggregate it along a certain transaction and report it to a live
BI service such as NewRelic insights; however, different usages might prove helpful as well,
such as writing the data to a database or a file.

Timeasure uses minimal intervention in the Ruby Object Model for tracked modules and classes.
Hence, the degradation in performance is minimal to nonexistent, assuming your post_measuring_proc is optimized.
It is eligible for use in production environment and for inclusion in Rails apps.

Timeasure is inspired by [Metaprogramming Ruby 2](https://pragprog.com/book/ppmetr2/metaprogramming-ruby-2) and [Hashrocket's](https://hashrocket.com/blog/posts/module-prepend-a-super-story) blog.

## Requirements

Ruby 2.0 or a later version is mandatory since Timeasure uses `Module#prepend` introduced in Ruby 2.0.

## Installation

Add this line to your application's Gemfile:

    gem 'timeasure'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timeasure

## Usage

#### 1. Configure Timeasure

For any tracked method, Timeasure will call its `configuration.post_measuring_proc` with 4 arguments:
* **base_class_name**: the name of the module or class in which the tracked method is defined.
* **method_name** : the tracked method name.
* **t0**: `Time.now.utc` before the execution of the method
* **t1**: `Time.now.utc` after the execution of the method

In case the call to `configuration.post_measuring_proc` raised an error of any kind,
`configuration.rescue_proc` will be called with 2 arguments:
* **e**: the rescued error.
* **base_class**: the name of the module or class in which the tracked method is defined.

Since Timeasure is a general purpose gem, it is up to the user to define the desired behaviour upon measurement.
The way to do so is by calling `Timeasure.configure` with a configuration code block (see example in the following part).
Normally you should do this part just once and forget about it.

**In a Rails App**

If you are using Rails, the easiest way to configure Timeasure is by adding an initializer to
*config/initializers* under your Rails app root directory.
Create a new *timeasure.rb* file in that directory. This file will execute upon Rails' initialization.

A possible content for this initializer:
```ruby
require 'timeasure'
 
Timeasure.configure do |configuration|
  configuration.post_measuring_proc = lambda do |base_class_name, method_name, t0, t1|
    SomeMonitoringClass.report_method_timing(base_class_name, method_name, t0, t1)
  end
 
  configuration.rescue_proc = lambda do |e, base_class|
    Rails.logger.error "Timeasure failed upon calling configuration.post_measuring_proc for class #{base_class}.
    Error: #{e}"
  end
end
``` 

The above assumes the existence of a service class named `SomeMonitoringClass`
which responds to `report_method_timing`.
It is advised to employ very light code as post_measuring_proc since this code will run
after each call to a tracked method.

The best practice would be to have a simple class that simply registers measurements during the course of a certain transaction;
when possible (i.e. once the transaction is finished), process this data in any desired way
(such as sending it to NewRelic Insights as events).  

**In a Non-Rails App**

If you are incorporating Timeasure in a non-Rails app, you need to find the equivalent of Rails' initializers
and follow the same ideas as in the former section. 

#### 2. Include Timeasure in Modules and Classes

Once configured, Timeasure is ready to be used in modules and classes.
This part is easy as a pie. Simply include the Timeasure module in the class and declare the desired methods to track:

```ruby
class Foo
  include Timeasure
  tracked_class_methods :bar
  tracked_instance_methods :baz, :another_baz
  
  def self.bar
    # some class-level stuff that can benefit from measuring runtime...
  end
    
  def baz
    # some instance-level stuff that can benefit from measuring runtime...
  end
  
  def another_baz
    # some other instance-level stuff that can benefit from measuring runtime...
  end
end
```

#### 3. Notes

**Compatiblity with RSpec**

If you run your test suite with Timeasure installed and modules, classes and methods tracked and all works fine - hurray!
However, due to the mechanics of Timeasure - namely, its usage of prepended modules - there exist a problem with
**stubbing** Timeasure-tracked method (RSpec does not support stubbing methods that appear in a prepended module). To be accurate, that means that if you are tracking method `#foo`, you can not
declare something like `allow(bar).to receive(:foo).and_return(bar)`.
To solve that problem you can configure Timeasure's `enable_timeasure_proc` **not** to run under certain conditions.
If you are on Rails, add the following to the initializer:

```ruby
Timeasure.configure do |configuration|
  configuration.post_measuring_proc = lambda { !Rails.env.test? }
end
```  

Timeasure will not come into action if the expression in the block is falsey. By default this block is truthy.


## Contributing

1. Fork it ( https://github.com/riskified/timeasure/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
