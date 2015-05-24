# Espinita

[![Build Status](https://secure.travis-ci.org/continuum/espinita.png)](http://travis-ci.org/continuum/espinita) [![Dependency Status](https://gemnasium.com/continuum/espinita.png)](https://gemnasium.com/continuum/espinita) [![Coverage Status](https://coveralls.io/repos/continuum/espinita/badge.png?branch=master)](https://coveralls.io/r/continuum/espinita?branch=master) [![Code Climate](https://codeclimate.com/github/continuum/espinita.png)](https://codeclimate.com/github/continuum/espinita)
=======

## Audits activerecord models like a boss

![Alt text](./espinita.jpg)

Audit activerecord models like a boss. Tested in rails 4.0 / 4.1 and ruby 1.9.3 / 2.0.0.

This project is heavily based in audited gem.

## Installation

In your gemfile

```ruby
gem "espinita"
```

In console
```ruby
$ rake espinita:install:migrations
$ rake db:migrate
```

## Usage

```ruby
class Post < ActiveRecord::Base
  auditable
end

@post.create(title: "an awesome blog post" )
```

Espinita will create an audit by default on creation , edition and destroy:

```ruby
@post.audits.size #=> 1
```

Espinita provides options to include or exclude columns to trigger the creation of audit.

```ruby
class Post < ActiveRecord::Base
  auditable only: [:title] # except: [:some_column]
end
```

And lets you declare the callbacks you want for audit creation:

```ruby
class Post < ActiveRecord::Base
  auditable on: [:create]  # on: [:create, :update]
end
```

You can find the audits records easily:

```ruby
@post.audits.first #=>  #<Espinita::Audit id: 1, auditable_id: 1, auditable_type: "Post", user_id: 1, user_type: "User", audited_changes: {"title"=>[nil, "MyString"], "created_at"=>[nil, 2013-10-30 15:50:14 UTC], "updated_at"=>[nil, 2013-10-30 15:50:14 UTC], "id"=>[nil, 1]}
```

Espinita will save the model changes in a serialized column called audited_changes:

```ruby
@post.audits.first.audited_changes #=> {"title"=>[nil, "MyString"], "created_at"=>[nil, 2013-10-30 15:50:14 UTC], "updated_at"=>[nil, 2013-10-30 15:50:14 UTC], "id"=>[nil, 1]}
```

Espinita will detect the current user when records saved from rails controllers. By default Espinita uses current_user method but you can change it:

```ruby
Espinita.current_user_method = :authenticated_user
```

#### History and Restoration
If you just want a summary of changes for a particular attribute or attributes of a model, you can use the `history_from_audits_for` method.
```ruby
my_model.history_from_audits_for(:name)
=> [{changes: {name: "Arglebargle"}, changed_at: 2015-05-13 15:28:22 -0700},
{changes: {name: "Baz"}, changed_at: 2014-05-13 15:28:22 -0700},
{changes: {name: "Foo"}, changed_at: 2013-05-13 15:28:22 -0700}]

```

You can also provide an array of attributes to get a single history for all of them.
```ruby
my_model.history_from_audits_for([:name, :settings])
=> [{changes: {name: "Arglebargle", settings: "Waffles"}, changed_at: 2015-05-13 15:28:22 -0700},
{changes: {name: "Baz"}, changed_at: 2014-05-13 15:28:22 -0700}]

```

Sometimes it's useful to roll a record back to a particular point in time, such as if it was accidentally modified. For this, the `restore_attributes!` method is provided.

As with `history_from_audits_for`, this can be used with a single attribute or an array of attributes.
```ruby
model.name
=> "Baz"
model.settings
=> ""

model.history_from_audits_for([:name, :settings])
=> [{:changes=>{:name=>"Baz", :settings=>""}, :changed_at=>2015-05-03 15:33:58 -0700},
 {:changes=>{:name=>"Arglebargle", :settings=>"IHOP"}, :changed_at=>2015-03-24 15:33:58 -0700},
 {:changes=>{:name=>"Walrus"}, :changed_at=>2014-05-13 15:33:58 -0700}]

model.restore_attributes!([:name, :settings], DateTime.now - 57.days)
=> true

model.name
=> "Walrus"
model.settings
=> "MyText"
```

The `restore_attributes!` method returns `true` if it makes a change to the model, or `false` if there is no resulting change.

Note: this uses `update_attributes()` to do the rollback, so it will *skip* validations, but will trigger any callbacks that you may have in place.
