# PetMatch

**PetMatch is a World of Warcraft addon designed to make managing Battle Pet teams faster, clearer, and more convenient — directly from the Pet Journal.**

If you regularly do Pet Battles, collect teams for trainers, achievements, events, or simply maintain a large collection of pets, you probably know how quickly managing all those different teams can become cumbersome.

PetMatch was created to make that process easier.

Instead of keeping track of teams outside the game or rebuilding them manually, PetMatch lets you create, organize, search, and load your Battle Pet teams directly alongside the standard World of Warcraft Pet Journal.

PetMatch is designed to extend the existing Pet Journal rather than replace it, keeping the experience familiar while adding more powerful team-management and quality-of-life features.

## Team Management

At the heart of PetMatch is its Battle Pet team management system.

You can create and save teams for the encounters and strategies you use regularly, then load them directly into your active Battle Pet slots whenever you need them.

PetMatch supports regular collected pets as well as special pet slots, giving you more flexibility when building reusable teams.

When a PetMatch team is loaded, its name is displayed above the Battle Pet slots in the Pet Journal, making it easy to see which team is currently active.

## Organize Your Teams

As your collection of teams grows, keeping everything in one long list quickly becomes impractical.

PetMatch includes folder support so you can organize teams in whatever way makes sense for you.

For example, you could create folders for:

- Battle Pet trainers
- Expansions
- Family achievements
- Dungeons and events
- Leveling teams
- Daily or weekly content
- Your own custom categories

Together with searching and sorting, this makes managing a large collection of Battle Pet teams much easier.

## Pet Card

PetMatch includes a detailed **Pet Card** that lets you inspect pets without leaving the interface you're currently working in.

Depending on the pet and the information available, the Pet Card can display details such as:

- Pet name and family
- Level and expansion
- Health, Power and Speed
- A 3D model of the pet
- Battle abilities
- Ability families
- Pet source information
- Pet description
- Breed information when supported

The abilities are presented by slot, making it easy to compare the two possible abilities available for each Battle Pet ability slot.

The Pet Card also makes use of Blizzard's existing Battle Pet information and tooltips where possible, so ability and pet-family information remains consistent with the standard Pet Journal.

## Pet Card Interaction

PetMatch lets you decide how you want to interact with Pet Cards.

You can choose between:

- **Hover** — display the Pet Card when hovering over a pet.
- **Click** — click a pet to open and pin its Pet Card.
- **Both** — use hover for quick inspection while still being able to pin cards with a click.

You can separately choose where Pet Cards should be available:

- **Pet Journal** — only for pets in the Pet Journal.
- **Teams** — only for pets shown in your PetMatch teams.
- **Both** — enable Pet Cards in both locations.

This means the Pet Card can be configured around the way you personally use the Pet Journal rather than forcing one interaction style.

## Optional Breed Support with BattlePetBreedID

**BattlePetBreedID is optional and is not required to use PetMatch.**

PetMatch can be used normally without BattlePetBreedID installed.

However, if you want to see detailed **Battle Pet breed information**, you will need to install **BattlePetBreedID**.

When BattlePetBreedID is available, PetMatch integrates its breed information into the interface, including features such as possible breeds and detailed breed information in the Pet Card.

This integration is completely optional. Players who are not interested in breeds do not need BattlePetBreedID to use PetMatch.

## Optional Battle Script Support

PetMatch can also be extended with support for automated Battle Pet scripts.

This functionality is **optional** and is not required for normal PetMatch team management.

To use Battle Pet scripts with PetMatch, you need both:

- **PetBattleScripts**
- **PetMatch_PetBattleScripts**

`PetBattleScripts` provides the actual Battle Pet scripting functionality, while `PetMatch_PetBattleScripts` provides the integration between PetMatch teams and PetBattleScripts.

If you only want to use PetMatch for creating, organizing, and loading teams, neither of these addons is required.

## Automatic Addon Detection for the PML

If you have my other addon `PetMastersLeagueLogs` installed, because you are either a player in the PML tournament or you want to use it to keep track on your PvP Pet Battle logs, then you are in for a nice little thing.

PetMatch will detect if you have the addon installed, and will then add a button to the teams list panel (at the bottom right) that you can click on to open the PML Logs addon.

## Pet Journal Enhancements

PetMatch doesn't just add teams — it also adds several quality-of-life improvements to the Pet Journal itself.

Additional pet information can be integrated into the Pet Journal list, and you can configure how some of this information is displayed.

Options include features such as breed placement and a more compact Pet Journal row layout, allowing you to choose between a more detailed or more compact view of your collection.

## Duplicate Team Handling

PetMatch can detect when you're creating a team that matches an existing team.

You can configure how duplicate teams should be handled, allowing PetMatch to either replace an existing matching team or create another copy.

This gives you control over whether identical setups should be treated as updates or as separate strategies.

## Optional Dependencies

PetMatch has been designed so that its core team-management functionality does not require additional Battle Pet addons.

Optional addons unlock additional functionality:

**BattlePetBreedID**
Adds breed information and allows PetMatch to display detailed breed data and possible breeds.

**PetBattleScripts + PetMatch_PetBattleScripts**
Adds Battle Pet script support and integration with PetMatch teams.

You only need to install the addons for the additional features you actually want to use.

## Designed to Feel Like Part of World of Warcraft

One of the main design goals of PetMatch is integration.

Rather than creating a completely separate interface, PetMatch is designed to feel like an extension of World of Warcraft's existing Pet Journal.

It integrates directly with the Pet Journal and uses Blizzard-style frames, backgrounds, icons, slots, models, and tooltips where appropriate.

The intention is for PetMatch to complement the existing Battle Pet UI while providing the team-management functionality and additional information that the standard interface doesn't offer.

## More Features Are Coming

PetMatch is actively being developed.

The first releases focus on building a solid foundation for:

- Battle Pet team management
- Team organization
- Pet Journal integration
- Pet Cards
- Optional breed information
- Optional Battle Pet scripting integration
- Quality-of-life improvements

But development does not stop there.

**More features, customization options, integrations, and improvements are planned for future versions of PetMatch.**

The goal is to continue expanding PetMatch into a comprehensive Battle Pet team-management companion while keeping it easy to use and closely integrated with World of Warcraft's existing Battle Pet interface.

Feedback, suggestions, and bug reports are always welcome and may help shape future versions of the addon.

---

### Requirements

**PetMatch itself has no required Battle Pet addon dependency.**

For optional functionality:

**Breed information**

- BattlePetBreedID

**Battle Pet scripts / automated battles**

- PetBattleScripts
- PetMatch_PetBattleScripts

---

**Build your teams. Organize your strategies. Find the right pets.**

**PetMatch — Battle Pet team management, directly inside the Pet Journal.**
