<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/j-trueman/MultiPlayer/assets/82833724/efa40489-11e3-41ca-bc73-731a4bb3007e" width='400px'>
    <img alt="Shows an illustrated sun in light color mode and a moon with stars in dark color mode." src="https://github.com/j-trueman/MultiplayerClient/assets/82833724/4d29ab28-9e70-49d6-8963-bcfc532ace9c" width='400px'>
  </picture>
</p>

---

# _WELCOME, HIGH ROLLER._

We know many of you have been anxiously awaiting the release of official multiplayer for Buckshot Roulette. Since there is no ETA, [MSLaFaver](https://github.com/MSLaFaver/) and I decided to take matters into our own hands. And now, a mere two months after the Steam release, we are proud to present to you _MultiPlayer_, a 1v1 mod for Buckshot Roulette.

<p align="center"><strong>LATEST VERSION: 0.2.1</strong><br>Please check your version before connecting online.</p>

Although based off of my (Josh's) [original](https://github.com/j-trueman/BuckshotRouletteMultiplayer) multiplayer mod for the itch.io version of the game, _MultiPlayer_ is better in almost every way. Let's take a look at a couple of things.

### Contents:
- [Setup](#setup)
- [Dedicated Servers](#dedicated-servers)
- [User accounts](#user-accounts)
  - [Authentication](#authentication)
  - [Creating an account](#creating-an-account)
- [Fancy menus](#fancy-menus)
- [Invite system](#invite-system)
- [Compatibility](#compatibility)
- [What's Next?](#future-plans)
- [Known Bugs](#known-bugs)

## Setup

* Download and install the [BRML](https://github.com/AGO061/BuckshotRouletteModLoader) using `BRML_setup.exe` from [this link](https://github.com/AGO061/BuckshotRouletteModLoader/releases/latest).
* Download `GlitchedData-MultiPlayer.zip` from [this repository's releases](https://github.com/j-trueman/MultiplayerClient/releases/latest).
* Place the .zip file inside your `mods` folder created when you installed the BRML. This folder is usually located at `Documents\Buckshot Roulette\mods`.
* Start the game! Pick a username when prompted.

## Dedicated Servers

First and foremost, we now have a dedicated server framework for managing all things MultiPlayer! No longer will you have to mess about with port forwarding and other such shenanigans, it's a much more streamlined system. (And it looks much nicer too!) And here's the best part, you can host your own instance! You can read more about how to do that over on the [MultiPlayer Server](https://www.github.com/j-trueman/MultiplayerServer) repo!

## User Accounts

We thought it would be helpful if you could actually tell who you're playing against. That's why we implemented user accounts! You'll need to create one before you can play online with your friends. (Don't worry, you don't need any personal information. And, you can do it in-game!)

### Authentication

User authentication is fairly simple process. When a new user account is created, an RSA private key file is generated. A copy of this is stored on the server in a database alongside their username and a copy is sent to the user themselves. Then, when a user tries to login the next time, the server checks if the user's key matches the one in the database for the specified username. If they do then the user is logged in (this process is entirely automated)

### Creating An Account

When you run the game for the first time with MultiPlayer installed you will be prompted (When you interact with the crt) to enter a username. After pressing the signup button the server will check if the user already exists and if not will automatically generate and send you a private key and log the user in. 

**NOTE: IF YOU DELETE OR MODIFY YOUR PRIVATE KEY YOU WILL NOT BE ABLE TO ACCESS YOUR ACCOUNT**

## Fancy Menus

Technically, no interactions a ever performed on the crt anymore, the crt menus and menu systms are all part of a menu UI scene with some very strategically placed elements that gets instantiated when the mod loads. This makes it easier for you to interact with and makes it easier to work with behind the scenes. And hey, it looks pretty darn cool too!

## Invite System

The invite system is my baby. When you open the crt menu you are greeted with a list of online players (provided you were successfully logged in). When you press the invite button located next to any of the usernames it will send a new inivite over the server to the player it is addressed to. On the receiving end, a popup will appear showing the new incoming invite and you can view all your incoming (and outoing) invites via the hamburger menu in the top right of the screen

## Compatibility

I released the original mod as a _patch_ meaning that it was standalone and not able to be used with [BRML](https://github.com/AGO061/BuckshotRouletteModLoader/) (which Michael also contributes to. He's so talented 😊). _MultiPlayer_, on the other hand, has been built from the ground up to be compatible with BRML, so there's no need to install a whole new version of the game just to use the mod! As for compatibility with other mods, _MultiPlayer_ is likely compatible with any mods that do not affect the gameplay (So, things like [EmK530's NativeResolution](https://github.com/EmK530/BRMods/tree/main/BRML/NativeResolution) should be okay. However, we haven't tested compatibility with _any_ mods as of yet.) As for mods like [Starpanda's ChallengePack](https://github.com/StarPandaBeg/ChallengePack), _MultiPlayer_ is not currently compatible with such mods but _may_ be in the future. This would, however, be a _very big_ and _very manual_ undertaking.

## Future Plans

We plan on continuing to update MultiPlayer, even after the official release of multiplayer as I'm sure there will be features that will not be implemented into official multiplayer but people will still want to see.

## Known Bugs
* MPB012: Unclear status of players currently in matches
* MPB017: Dealer face changes too quickly between rounds
* MPB018: Player can send messages when not in a match
* MPB019: Action validation for picking up shotgun not received by opponent after returning from handcuff check
