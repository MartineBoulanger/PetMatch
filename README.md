# <span style="color:#00f300">**PetMatch**</span>

<span style="color:#f8cac6">**A complete Battle Pet team-management companion, built directly into the World of Warcraft Pet Journal.**</span>

PetMatch expands the standard Pet Journal with powerful tools for creating, organizing, loading, and managing Battle Pet teams — without replacing the familiar World of Warcraft interface.

Whether you're building teams for trainers, achievements, family challenges, levelling strategies, PvP, or simply managing a large Battle Pet collection, PetMatch keeps your teams and pets organized in one place.

Instead of rebuilding teams manually or keeping track of them outside the game, you can manage your Battle Pet collection and strategies directly from the Pet Journal.

<span style="color:#f1c40f"><strong>PetMatch has no required Battle Pet addon dependencies.</strong></span>

Optional addons can be installed for breed information and battle-script support.

***

## ✨ <span style="color:#3598db">Key Features</span>

*   Create, save, update, load, and unload Battle Pet teams
*   Organize teams into folders
*   Assign teams to Battle Pet Target NPCs
*   Automatically detect teams for your current target
*   Get suggested counter teams for supported trainers
*   Use Random, family-specific Random, and Levelling Pet slots
*   Manage a dedicated Levelling Queue
*   Inspect pets using detailed Pet Cards
*   Search, filter, sort, and tag your pet collection
*   Import and export Rematch-compatible teams
*   Optional <span style="color:#f1c40f">BattlePetBreedID </span> integration
*   Optional <span style="color:#f1c40f">PetBattleScripts </span> integration
*   Extensive Pet Journal quality-of-life improvements

***

# <span style="color:#00f300">Team Management</span>

PetMatch adds full Battle Pet team management directly alongside the standard Pet Journal.

Create teams for the encounters and strategies you use regularly, organize them into folders, and load them directly into your active Battle Pet slots.

When a saved PetMatch team is loaded, its name is displayed above the Battle Pet slots so you can immediately see which team is currently active.

Teams can be updated directly from the Pet Journal after changing pets, abilities, special slots, or their assigned target.

A dedicated <span style="color:#f1c40f"><strong>Unload Team</strong></span> action completely clears the active Battle Pet loadout and returns the Pet Journal to its normal Battle Pet Slots state.

![image](https://media.forgecdn.net/attachments/description/1652922/description_e6a2b258-f613-43e7-85ec-e784ade48db3.png)

***

## <span style="color:#3598db">Team Setup Mode</span>

Teams don't have to consist of three permanently assigned pets.

PetMatch's <span style="color:#f1c40f"><strong>Team Setup Mode</strong></span> lets you configure how each individual Battle Pet slot should behave when the team is saved and loaded.

Each slot can be configured as:

*   <span style="color:#f1c40f"><strong>Current Pet</strong></span> — use the pet currently occupying the Battle Pet slot (or choose another pet that should be a steady pet in your team).
*   <span style="color:#f1c40f"><strong>Random Pet</strong></span> — choose a random battle-capable pet from your collection.
*   <span style="color:#f1c40f"><strong>Random Pet Family</strong></span> — choose a random pet belonging to a specific Battle Pet family.
*   <span style="color:#f1c40f"><strong>Levelling Pet</strong></span> — choose a suitable pet from your PetMatch Levelling Queue (PetMatch will always pick the first pet in the levelling queue, unless the pet slot has preferences set).

Special slots are displayed directly on the Battle Pet slots and on saved team cards, making their purpose easy to recognize.

Changes made in Team Setup Mode are not immediately written to your saved team. Configure your team first, then use <span style="color:#f1c40f"><strong>Update Team</strong></span> or <span style="color:#f1c40f"><strong>Save As</strong></span> when you're happy with the setup.

<span style="color:#f1c40f"><strong>Always make sure you toggle the team setup mode off again when you are done!</strong></span>

You can recognize the mode being enabled by the blue borders on the pet slots, the team setup toggle button in the toolbar and that the target NPC dropdown is showing.

![image](https://media.forgecdn.net/attachments/description/1652922/description_3810ec8a-4f1f-4e21-aa32-34272d02cda3.png)

***

## <span style="color:#3598db">Levelling Pet Preferences</span>

Levelling slots can be configured (in the team setup mode) with additional requirements, giving you more control over which queued pet PetMatch should select. To set these preferences, you will need to set the pet slot to a levelling pet and a dialog will appear.

Available preferences include:

*   <span style="color:#f1c40f"><strong>Minimum Level</strong></span>
*   <span style="color:#f1c40f"><strong>Minimum Health</strong></span>

This makes it possible to build reusable levelling strategies without having to manually replace the levelling pet every time one reaches level 25. It also gives you the freedom not to be dependent on websites if you do not wish to use those, or if you want to create teams that you later want to add to those websites as a strategy.

![image](https://media.forgecdn.net/attachments/description/1652922/description_88721d95-3572-4f2e-90cb-7e3381ba7bd6.png)

***

# <span style="color:#00f300">Battle Pet Target NPCs</span>

PetMatch teams can be associated with supported Pet Battle Target NPCs.

When you target an NPC, PetMatch can detect whether you already have a team saved for that encounter.

You can choose how PetMatch should respond:

*   <span style="color:#f1c40f"><strong>Disabled</strong></span> — do nothing when a matching NPC is targeted (this is the default option).
*   <span style="color:#f1c40f"><strong>Show Load Team Button</strong></span> — display a Load Team icon button left above to the Battle Pet slots.
*   <span style="color:#f1c40f"><strong>Load Team Automatically</strong></span> — immediately load the matching team.
*   <span style="color:#f1c40f"><strong>Ask Before Loading</strong></span> — ask for confirmation before loading the team via a dialog.

If several teams are associated with the same NPC, PetMatch displays a team selection dialog so you can choose which strategy you want to use.

Target associations imported from compatible Rematch teams are supported as well.

Load Team Button  
![image](https://media.forgecdn.net/attachments/description/1652922/description_1a9531b2-4dff-4ce8-a3b6-cec047f74387.png)

Confirmation Dialog  
![image](https://media.forgecdn.net/attachments/description/1652922/description_99c78be3-ff76-4e9d-886f-6428cd545222.png)

Multiple Teams Dialog  
![image](https://media.forgecdn.net/attachments/description/1652922/description_7aa68a52-e34e-4b24-a108-c62b7ef7dd9e.png)

***

## <span style="color:#3598db">Target Team Card</span>

When working with a supported Pet Battle Target NPC, PetMatch can display a <span style="color:#f1c40f"><strong>Target Team Card</strong></span> above your Battle Pet slots.

The card provides an at-a-glance overview of the encounter:

*   The enemy Battle Pets
*   The target's name
*   Your currently loaded pets
    *   Or, when appropriate, a suggested team from your collection

This makes it easy to compare the encounter with the team you're about to use without leaving the Pet Journal.

![image](https://media.forgecdn.net/attachments/description/1652922/description_1c771b39-0837-4dbf-b63b-d5622c8d6b91.png)

***

## <span style="color:#3598db">Suggested Teams</span>

<span style="color:#f1c40f"><strong>Don't have a saved team for a supported target NPC yet?</strong></span>

PetMatch can inspect the target's Battle Pets and suggest suitable pets from your own collection.

Suggestions take multiple factors into account, including:

*   Strong abilities against the enemy
*   Defensive matchup against enemy ability types
*   Pet quality
*   Current health
*   Power
*   Speed
*   Maximum health

PetMatch also chooses suitable abilities for the suggested pets.

Suggested pets appear directly in the Target Team Card. Click one of them to load the complete suggested team and its selected abilities into your Battle Pet slots.

<span style="color:#f1c40f"><strong>A suggested team is temporary — it does not automatically create or overwrite one of your saved teams.</strong></span>

You can use it as-is or turn it into your own saved strategy.

![image](https://media.forgecdn.net/attachments/description/1652922/description_ed046224-8ae9-4e2d-9c54-22ee37356c5d.png)

***

# <span style="color:#00f300">Organize Your Teams</span>

A large team collection quickly becomes difficult to manage as one long list.

PetMatch includes folders so you can organize teams in whatever way makes sense for your collection.

For example:

*   Battle Pet Trainers
*   Expansions
*   Family achievements
*   Dungeons and events
*   Levelling teams
*   Daily or weekly content
*   PvP teams
*   Your own custom categories

New teams are saved into the folder you currently have open (meaning if you want to have the team in a specific folder you either have to select the folder by clicking on it or choosing the folder from the dropdown when you save the team). <span style="color:#f1c40f">If no folder is selected, they are placed in <strong>Unsorted</strong>.</span> The Unsorted and Favorites folders are defaults folders from PetMatch, and cannot be changed or deleted.

Combined with team searching, and sorting, folders make even large team collections much easier to navigate.

![image](https://media.forgecdn.net/attachments/description/1652922/description_8b6ca1c8-885f-4008-93d7-319456471589.png)

***

# <span style="color:#00f300">Import &amp; Export</span>

PetMatch supports importing and exporting Battle Pet teams using Rematch-compatible team strings.

This makes it easier to:

*   Share teams with other players
*   Import strategies from compatible sources
*   Import teams from resources such as Xu-Fu's Pet Guides

Target NPC information and supported levelling preferences will also be preserved through compatible imports and exports, as well as notes, and scripts.

***

## <span style="color:#3598db">Moving from Rematch to PetMatch</span>

If you already have a large Rematch collection, you don't need to rebuild everything manually.

The <span style="color:#f1c40f"><strong>PetMatch Rematch Import Tool</strong></span> can convert your existing Rematch data into PetMatch-compatible data.

The tool can use your:

*   `Rematch.lua`
*   `tdBattlePetScript.lua`

SavedVariables files and generate:

*   Import strings for individual teams, or per folder, or all the folders and teams
*   An import string for your Levelling Queue
*   A generated `PetMatch.lua` SavedVariables file that you can download

### <span style="color:#eccafa">Rematch Import Tool</span>

[Import Tool Link](https://www.petmastersleague.com/rematch-import-tool)

<span style="color:#f1c40f"><strong>Please read the instructions on the import tool page before replacing or importing SavedVariables!</strong></span>

***

# <span style="color:#00f300">Levelling Queue</span>

Keep the Battle Pets you still want to level in one convenient queue.

Pets can be added directly from the Pet Journal and reordered using drag-and-drop.

When a queued pet reaches level 25, PetMatch will automatically remove it from the queue.

Pets currently in your Levelling Queue are also marked in the Pet Journal, making them easy to recognize while browsing your collection.

![image](https://media.forgecdn.net/attachments/description/1652922/description_25411011-747d-4031-95b2-e09e543f29d0.png)

The queue also provides quick access to relevant items in your bags, including Pet Treats and Battle-Training Stones.

Live item counts show what you currently have available, and supported training stones can be used directly on queued pets.

Automatic queueing can also be enabled if you want newly learned Battle Pets below level 25 to be added to the queue automatically.

Most importantly, the Levelling Queue integrates directly with <span style="color:#f1c40f"><strong>Levelling Pet team slots</strong></span>.

Instead of saving one specific levelling pet into a strategy, mark the slot as a Levelling Pet slot and PetMatch can choose an appropriate queued pet when the team is loaded.

![image](https://media.forgecdn.net/attachments/description/1652922/description_3230bfec-b5e9-479e-ba07-8839a3386cc1.png)

***

# <span style="color:#00f300">Pet Cards</span>

PetMatch includes a detailed <span style="color:#f1c40f"><strong>Pet Card</strong></span> for inspecting Battle Pets without leaving the interface you're currently using.

Depending on the pet and the information available, the card shows:

*   Pet name and family
*   Level and expansion
*   Health, Power, and Speed
*   3D pet model
*   Battle abilities
*   Ability families
*   Source information
*   Pet description
*   Breed information when available

Abilities are grouped by Battle Pet ability slot, making it easy to compare the two available ability choices.

![image](https://media.forgecdn.net/attachments/description/1652922/description_700be67b-c9cd-4c35-8859-413d4f3a6985.png)

Pet Cards are integrated throughout PetMatch and can be available for pets in areas such as:

*   The Pet Journal
*   Saved teams
*   The Levelling Queue
*   Target Team Cards

<span style="color:#f1c40f"><strong>You can independently choose where Pet Cards should be enabled.</strong></span>

***

## <span style="color:#3598db">Pet Card Interaction</span>

Choose how Pet Cards should behave:

*   <span style="color:#f1c40f"><strong>Hover</strong></span> — show the Pet Card while hovering over a pet.
*   <span style="color:#f1c40f"><strong>Click</strong></span> — click a pet to open and pin its Pet Card.
*   <span style="color:#f1c40f"><strong>Both</strong></span> — use hover for quick inspection while retaining click-to-pin functionality.

PetMatch uses Blizzard's existing Battle Pet information and tooltips where appropriate, keeping pet and ability information consistent with the standard Pet Journal.

***

# <span style="color:#00f300">Search, Filtering &amp; Sorting</span>

PetMatch adds additional tools for navigating large Battle Pet collections.

Search, filter, and sort your pets using additional criteria to quickly narrow the Pet Journal down to the pets you're looking for.

Active filters and sorting options are displayed in the filter bar, where they can also be removed without reopening the individual menus.

Filters added to the original filters  
![image](https://media.forgecdn.net/attachments/description/1652922/description_04e52805-8df3-4d1c-8189-b8b5a16e5fc5.png)

Sorting (add up to 3 sorting options)  
![image](https://media.forgecdn.net/attachments/description/1652922/description_8904bc15-ba85-4d47-b6bf-08b4767b8c63.png)

Search en filter bar  
![image](https://media.forgecdn.net/attachments/description/1652922/description_6ba9ad37-f8db-402d-9538-9cbfbffcfe1e.png)

***

# <span style="color:#00f300">Pet Tags</span>

Pets in your collection can be tagged to make important pets easier to recognize.

Tags appear directly in the Pet Journal pet list and on active Battle Pet slots.

They can be useful for identifying:

*   Frequently used pets
*   Pets reserved for particular strategies
*   PvP pets
*   Levelling pets
*   Favorites or personal categories

<span style="color:#f1c40f">You can filter on the specific pet tag via the <strong>Tag</strong> filter option in the Filters menu.</span>

![image](https://media.forgecdn.net/attachments/description/1652922/description_c9216e0b-c70b-4577-ab39-1390e9412fca.png)

***

# <span style="color:#00f300">Random Battle Pets</span>

Want to battle with something completely different?

Use the <span style="color:#f1c40f"><strong>Random Battle Pets</strong></span> dice button to instantly load three random battle-capable pets from your collection.

PetMatch also randomizes their abilities while respecting which abilities are currently available to each pet.

**<span style="color:#f1c40f">This does not create or modify a saved team!</span>**

It's simply a quick way to generate a random loadout and start battling, or when you want to have a challenge.

![image](https://media.forgecdn.net/attachments/description/1652922/description_92e6e7d5-bfdc-46f3-862d-621a68c431c5.png)

***

# <span style="color:#00f300">Pet Journal Enhancements</span>

PetMatch is designed to extend the existing World of Warcraft Pet Journal rather than replace it.

Alongside its larger features, it includes numerous smaller quality-of-life improvements for managing your Battle Pet collection.

These include features such as:

*   Additional pet information in the Pet Journal
*   Compact Pet Journal layouts
*   Pet tags and Levelling Queue indicators
*   Battle Pet slot overlays
*   Team names above the Battle Pet slots
*   Integrated Load and Unload Team controls
*   Additional contextual actions
*   Configurable Pet Card integration
*   Breed placement options
*   Search, filtering, and sorting improvements

Many interface features can be enabled, disabled, or customized through the PetMatch options.

![image](https://media.forgecdn.net/attachments/description/1652922/description_857d8a05-b369-43f9-87bb-00d423085ad0.png)

***

# <span style="color:#00f300">Duplicate Team Handling</span>

PetMatch can detect when a newly created team matches an existing team.

You can configure whether matching teams should:

*   Replace the existing matching team (default option)
*   Or be saved as another copy
*   Or just skip the existing teams

This gives you control over whether identical setups represent an update or a separate strategy.

![image](https://media.forgecdn.net/attachments/description/1652922/description_7b30e7b9-ee92-4faa-87e6-89c9c2f8b317.png)

***

# <span style="color:#00f300">Optional Breed Support</span>

<span style="color:#f1c40f"><strong>BattlePetBreedID is completely optional.</strong></span>

PetMatch works normally without it.

If <span style="color:#f1c40f"><strong>BattlePetBreedID</strong></span> is installed, PetMatch can use its data to display additional breed information, including possible breeds and detailed breed information in the Pet Card.

If you don't need breed information, you don't need to install it, or you can hide it in the options panel.

Breed Option  
![image](https://media.forgecdn.net/attachments/description/1652922/description_de4b2f2f-3a48-4e61-afdb-03788c23b981.png)

In pet list  
![image](https://media.forgecdn.net/attachments/description/1652922/description_69281172-f2c9-4e30-9e7e-355aa1e77c41.png)

On Pet Card  
![image](https://media.forgecdn.net/attachments/description/1652922/description_daee1a26-2d33-4cd6-bfe7-1262526a1a3f.png)

***

# <span style="color:#00f300">Optional Battle Script Support</span>

Battle Pet scripting is also optional.

To use Battle Pet scripts with PetMatch, install the following addons:

*   <span style="color:#f1c40f"><strong>PetBattleScripts</strong></span>
*   <span style="color:#f1c40f"><strong>PetMatch_PetBattleScripts</strong></span>

`PetBattleScripts` provides the Battle Pet scripting functionality itself.

`PetMatch_PetBattleScripts` connects those scripts with PetMatch teams.

<span style="color:#f1c40f">If you only want to create, organize, and load teams, neither addon above is required.</span>

***

# <span style="color:#00f300">PetMastersLeagueLogs Integration</span>

If <span style="color:#f1c40f"><strong>PetMastersLeagueLogs</strong></span> is installed, PetMatch automatically detects it.

This applies whether you're participating in the Pet Masters League or simply using PetMastersLeagueLogs to keep track of your PvP Pet Battle logs.

When detected, PetMatch adds quick access to PetMastersLeagueLogs from the Teams panel.

![image](https://media.forgecdn.net/attachments/description/1652922/description_6c1499c9-1a4a-44c0-9dd9-e9ae78b80e25.png)

***

# <span style="color:#00f300">Optional Dependencies</span>

PetMatch's core functionality has <span style="color:#f1c40f"><strong>no required Battle Pet addon dependencies.</strong></span>

Install these only if you want the corresponding additional functionality:

| Addon                     |Adds                                                    |
| ------------------------- |------------------------------------------------------- |
| <span style="color:#f1c40f"><strong>BattlePetBreedID</strong></span> |Detailed Battle Pet breed information                   |
| <span style="color:#f1c40f"><strong>PetBattleScripts</strong></span> |Battle Pet scripting functionality                      |
| <span style="color:#f1c40f"><strong>PetMatch_PetBattleScripts</strong></span> |Integration between PetMatch teams and PetBattleScripts |

***

# <span style="color:#00f300">Designed to Feel Like Part of World of Warcraft</span>

One of PetMatch's main design goals is integration.

Rather than placing Battle Pet management inside an entirely separate interface, PetMatch extends the Pet Journal you already use.

Blizzard-style frames, buttons, backgrounds, pet models, slots, and tooltips are used where appropriate so that the additional functionality feels at home alongside World of Warcraft's existing Battle Pet interface.

The goal is simple:

<span style="color:#f1c40f"><strong>Add powerful Battle Pet management tools without losing the familiar Pet Journal experience.</strong></span>

***

# <span style="color:#00f300">Development &amp; Feedback</span>

PetMatch is actively developed, and its features will continue to evolve.

Future updates may bring additional team-management tools, customization options, integrations, and Battle Pet quality-of-life improvements.

Feedback, suggestions, and bug reports are always welcome.

They help improve PetMatch and can help shape future versions of the addon.

***

## <span style="color:#3598db">Requirements</span>

<span style="color:#f1c40f"><strong>PetMatch itself has no required Battle Pet addon dependency.</strong></span>

Optional functionality:

<span style="color:#f1c40f"><strong>Breed information</strong></span>

*   BattlePetBreedID

<span style="color:#f1c40f"><strong>Battle Pet scripts</strong></span>

*   PetBattleScripts
*   PetMatch\_PetBattleScripts

***

<span style="color:#f8cac6"><strong>Build your teams. Organize your strategies. Find the right pets.</strong></span>  
<span style="color:#f8cac6"><strong>Battle Pet team management, directly inside the World of Warcraft Pet Journal.</strong></span>

# <span style="color:#00f300"><strong>PetMatch</strong></span>