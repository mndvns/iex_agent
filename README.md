# IExAgent

Utility for persistent storage of modules to reload.

This is useful for development, especially when it involves many disparate modules.

## Quick examples

```elixir
# The "old" way of using `r/1` still works...

iex(1)> r MyApp.HTTP
# ... reloaded module warnings ...
{:reloaded, MyApp.HTTP, [MyApp.HTTP]}

# ...althought now it receives lists as well.

iex(2)> r [MyApp.HTTP, MyApp.Resource]
# ... reloaded module warnings ...
[
  {:reloaded, MyApp.HTTP, [MyApp.HTTP]},
  {:reloaded, MyApp.Resource, [MyApp.Resource]}
]

# Alternatively, use `z/1` instead of `r/1` to
# clear the screen of annoying reload warnings.

iex(3)> z [MyApp.HTTP, MyApp.Resource]
[
  {:reloaded, MyApp.HTTP, [MyApp.HTTP]},
  {:reloaded, MyApp.Resource, [MyApp.Resource]}
]

# You can also persist modules in a list.

iex(4)> iex_add MyApp.HTTP
[MyApp.HTTP]
iex(5)> iex_add [MyApp.Resource, MyApp.Supervisor]
[MyApp.HTTP, MyApp.Resource, MyApp.Supervisor]

# Now calling `r/0` or `z/0` will reload them all.

iex(5)> z
[
  {:reloaded, MyApp.HTTP, [MyApp.HTTP]},
  {:reloaded, MyApp.Resource, [MyApp.Resource]},
  {:reloaded, MyApp.Supervisor, [MyApp.Supervisor]}
]

# This list persists through application restarts,
# so you can easily pick up where you left off.

iex(1)> z
[
  {:reloaded, MyApp.HTTP, [MyApp.HTTP]},
  {:reloaded, MyApp.Resource, [MyApp.Resource]},
  {:reloaded, MyApp.Supervisor, [MyApp.Supervisor]}
]
```

## Installation

```elixir
def deps do
  [
    {:iex_agent, "~> 0.1.0"}
  ]
end
```
