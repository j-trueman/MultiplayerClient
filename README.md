<p align="center">
  <img src="https://github.com/j-trueman/MultiPlayer/assets/82833724/efa40489-11e3-41ca-bc73-731a4bb3007e" width="400px" align="center">
</p>

---

# _WELCOME, HIGH ROLLER._

We know many of you have been anxiously awaiting the release of official multiplayer for Buckshot Roulette. Since there is no ETA, [MSLaFaver](https://github.com/MSLaFaver/) and I decided to take matters into our own hands. And now,teo months after the official Steam release, we are proud to present to you _MultiPlayer_, a 1v1 mod for Buckshot Roulette. 

Although based off of my (Josh's) [original](https://github.com/j-trueman/BuckshotRouletteMultiplayer) multiplayer mod for the itch.io version of the game, _MultiPlayer_ is better in almost every way. Let's take a look at a couple of things.

### Contents:
- [Dedicated Servers](#dedicated-servers)
- [User accounts](#user-accounts)
  - [Authentication](#authentication)
  - [Creating an account](#creating-an-account)
- [Fancy menus](#fancy-menus)
- [Invite system](#invite-system)

## Dedicated Servers

First and foremost, we now have a dedicated server framework for managing all things MultiPlayer! No longer will you have to mess about with port forwarding and other such shenanigans, it's a much more streamlined system (And it looks much nicer too!). And here's the best part, you can host your own instance! You can read more about how to do that over on the [MultiPlayer Server](https://www.github.com/j-trueman/MultiplayerServer) repo!

## User Accounts

We thought it would be a helpful if you could actually tell who you're playing against. That's why we implemented user accounts! You'll need to create one before you can play online with your friends (Don't worry, you don't need any personal information. And, you can do it in-game!)

### Authentication

User authentication is fairly simple process. When a new user account is created, an RSA private key file is generated. A copy of this is stored on the server in a database alongside their username and a copy is sent to the user themselves. Then, when a user tries to login the next time, the server checks if the user's key matches the one in the database for the specified username. If they do then the user is logged in (this process is entirely automated)

### Creating An Account

When you run the game for the first time with MultiPlayer installed you will be prompted (When you interact with the crt) to enter a username. After pressing the signup button the server will check if the user already exists and if not will automatically generate and send you a private key and log the user in. 

**NOTE: IF YOU DELETE YOUR PRIVATE KEYn YOU WILL NOT BE ABLE TO ACCESS YOUR ACCOUNT**

## Fancy Menus

Technically, no interacttions a ever performed on the crt anymore, the crt menus and menu systms are all part of a menu UI scene with some very strategically placed elements that gets instatnitated when the mod loads. This makes it easier for you to interact with and makes it easier to work with behind the scenes. And hey, it looks pretty darn cool too!

## Invite System

The invite system is my baby. When you open the crt menu you are greeted with a list of online players ( prvided you were successfully logged in). When you press the invite button located next to any of the usernames it will send a new inivite over the servver to the player it is for. On the receiving end a popup will appear showing the new incoming invite and you can view all your ingcoming (and outoing) invites via the hamburger menu in hte top right of the screen

## Compatibility

I released the original mod as a _patch_ meaning that it was standalone and not able to be used with [BRML](https://github.com/AGO061/BuckshotRouletteModLoader/) (which Michael also contributes to. He's so talented 😊). _MultiPlayer_, on the other hand, has been built from the ground up to be compatible with BRML, so there's no need to install a whole new version of the game just to use the mod! As for compatibility with other mods, _MultiPlayer_ is likely compatible with any mods that do not affect the gameplay (So, things like [EmK530's NativeResolution](https://github.com/EmK530/BRMods/tree/main/BRML/NativeResolution) should be okay. However, we haven't tested compatibility with _any_ mods as of yet.) As for mods like [Starpanda's ChallengePack](https://github.com/StarPandaBeg/ChallengePack), MultiPlayer_ is not currently compatible with such mods but _may_ be in the future. This would, however, be a _very big_ and _very manual_ undertaking.

## Future Plans

We plan on continuing to update MultiPlayer, even after the official release of multiplayer as I'm sure there will be features that will not be implemented into official multiplayer but people will still want to see.
