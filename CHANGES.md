# 0.1.1
- Added support for `:as` in `attr_encodable` calls, allowing you to create custom default encoding groups. See README.md for more.

# 0.1.0
- Added support for `:only` to to_json, just like you'd expect. Now passing `:only` will exclude all other whitelisted attributes and, as always,
  includes inline-support for `:method` and `:include`.
- Removed accidental redis requirement from the Gemspec.