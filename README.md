# The "Rocks!" game

A spaceship shooter game for 2 simultaneous players.

# Run

Requires [lua-atmos](https://github.com/lua-atmos/atmos):

```
sudo luarocks --lua-version=5.4 install pico-sdl 0.2
sudo luarocks --lua-version=5.4 install atmos 0.5
git checkout v0.4
pico-lua main.lua
```

# Instructions

- Hit the other ship.
- Avoid the rocks!
- Controls:
    - Left Ship: `WASD` to move, `Shift Left` to shoot.
    - Right Ship: Arrow keys to move, `Shift Right` to shoot.
