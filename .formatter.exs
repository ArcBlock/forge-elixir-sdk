# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:typed_struct],
  locals_without_parens: [
    my_macro: 2,
    my_other_macro: 3,
    plug: :*,
    pipe_through: 1,
    forward: 2,
    forward: 3,
    get: 3,
    post: 3,
    delete: 3,
    patch: 3,
    socket: 2,
    socket: 3,
    field: 3,
    oneof: 2,
    field: 2,
    rpc: 2,
    rpc: 3,
    tx: 1,
    tx: 2,
    intercept: 1,
    intercept: 2,
    run: 1,
    run: 2
  ]
]
