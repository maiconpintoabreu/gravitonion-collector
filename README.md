# space-researcher
[![CD](https://github.com/maiconpintoabreu/space-researcher/actions/workflows/cd.yml/badge.svg)](https://github.com/maiconpintoabreu/space-researcher/actions/workflows/cd.yml)

[![Itch.io](https://static.itch.io/images/badge-color.svg)](https://maiconspas.itch.io/space-researcher?password=1gam)


Player needs to protect the BlackHole from the asteroids so it does not go too big and stay close from it so the scientists are able to collect information of it.


## TODO:
* UI to show the power (with power mechanics)
* Add power ups (gun modifier and temp shield dropped by the asteroids) 

### Maybes:
* local multiplayer (half score and increase in difficult)

## Entity map

Game - Blackhole

Game - Asteroids

Game - Player - Bullets

## Physics

Blackhole and Phaser collides to everyone

Player collides to everyone

Asteroids collide to everyone

Bullets collide to everyone but player

## Ownership

PhysicsBody is lives inside the entities, the PhysicsSystem only contains a list of pointers

Entities can read the PhysicsBody but cannot edit (not blocked just a rule)

PhysiscsSystem cam edit PhysicsBody

## Config

To activate Debug mode and tweak some values: [config.zig](src/config.zig)
