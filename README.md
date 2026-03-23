# The "Rocks!" game

A spaceship shooter game for 2 simultaneous players.
Built with [Atmos][atmos] and [atmos-env-pico][env-pico].

[atmos]:    https://github.com/lua-atmos/atmos/
[env-pico]: https://github.com/lua-atmos/env-pico/

# Install

```
sudo luarocks --lua-version=5.4 install atmos 0.6
sudo luarocks --lua-version=5.4 install atmos-env-pico 0.1
```

# Run

```
git checkout v0.4
pico-lua main.lua
```

# Instructions

- Hit the other ship.
- Avoid the rocks!
- Controls:
    - Left Ship: `WASD` to move, `Shift Left` to shoot.
    - Right Ship: Arrow keys to move, `Shift Right` to shoot.
