# Rbsiev

[![Build Status](https://github.com/mnbi/rbsiev/workflows/Build/badge.svg)](https://github.com/mnbi/rbsiev/actions?query=workflow%3A"Build")

SICP evaluator in Ruby.

Or, Ruby で書いた SICP の evaluator.

It is intended to be a part of Scheme implementation written in Ruby.

## Installation

Execute:

    $ gem install rbsiev

## Usage

Run the simple REPL as:

    $ rbsiev

Then, you can input Scheme program.

## Supported Syntax

In 0.1.0, the evaluator mostly corresponds to the one in SICP 4.1.1 -
4.1.6.

See the [wiki page](https://github.com/mnbi/rbsiev/wiki/実装の進捗)
for more information about the progress of implementing.

### Literals

- boolean value (`#f` and `#t`),
- an empty list (`()`),
- a string enclosing with double-quotations, such `"hoge"`
- numbers (integer, real, rational, and complex)

### Primitive procedures

- arithmetic operators (`+`, `-`, `*`, `/`, `%`),
- comparison operators (`=`, `<`, `>`, `<=`, `>=`)
- `cons`, `car`, `cdr`
- `null?`, `pair?`, `list?`, `number?`
- `list`, `append`
- `write`, `display`

### Syntax to be evaluated

- lambda expression
  - such `(lambda (n) (+ n 1))`
- procedure application
  - such `(foo 1)`
- conditional expression
  - `if`, `cond`, `when`, `unless`
- logical test
  - `and`, `or`
- assignment
  - `set!`
- definition
  - `define`
- sequence
  - `begin`
- local bindings
  - `let`, `let*`, `letrec`, `letrec*`
- loop
  - `do`

## Related projects

- Lexical Analyzer for Scheme - [mnbi/rbscmlex](https://github.com/mnbi/rbscmlex)
- Abstract Syntax Tree and Syntax Analyzer for Scheme - [mnbi/rubasteme](https://github.com/mnbi/rubasteme)
- Ruby wit Syntax Sugar of Scheme - [mnbi/rus3](https://github.com/mnbi/rus3)
- A small Scheme implementation in Ruby - [mnbi/rubeme](https://github.com/mnbi/rubeme)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/mnbi/rbsiev](https://github.com/mnbi/rbsiev).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
