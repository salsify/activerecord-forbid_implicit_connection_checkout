# activerecord-forbid_implicit_checkout

## v4.0.0
- Also forbid checkout via `lease_connection` and `with_connection`, the paths Active Record has
  used for its own queries since Rails 7.2. Previously only `connection` was intercepted, so an
  ordinary query in a forbidding thread checked out a connection silently.
- Drop support for Ruby 3.1, 3.2
- Drop support for Rails 7.0, 7.1, 7.2
- Add support for Ruby 4.0
- Add support for Rails 8.1

## v3.0.0
- Drop support for Ruby 2.7, 3.0
- Drop support for Rails 6.0, 6.1
- Add support for Ruby 3.4
- Add support for Rails 7.1, 7.2, 8.0

## v2.0.0
- Drop support for Ruby < 2.7.
- Drop support for Rails < 6.0.
- Add support for Ruby 3.2.

## v1.1.0
- Add rails 6.1 support

## v1.0.0
- Add rails 6.0 support
- Drop support for ruby 2.4, 2.3 and 2.2.
- Drop support for rails 5.0 and 5.1

## v0.4.0
- Add rails 5.2 support

## v0.3.0
- Set required_ruby_version >= 2.2 in gemspec

## v0.2.0
- Support rails 5.1 in gemspec

## v0.1.0
- Initial version
