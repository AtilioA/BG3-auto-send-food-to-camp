[size=5][b]Overview[/b][/size]
[b]Auto Send Food To Camp is a mod designed to streamline inventory management by automatically sending food items to a supply sack inside the camp chest, [u]since they will still count towards your camp supplies[/u][/b]. Why edit their weight if you can play as Larian intended?
It supports configurable options via a JSON file but also works out of the box and in multiplayer.

Players can choose to enable or disable the automatic transfer of food and beverages separately, define ignore lists, etc. See the settings breakdown in the Configuration section below for more details.

[line][b][size=5][b]
Installation[/b][/size][/b]
[list=1]
[*]Download the .zip file and install using BG3MM.

[/list][b][size=4]Requirements
[/size][/b][size=2]-[b] [url=https://www.nexusmods.com/baldursgate3/mods/7676]Volition Cabinet[/url][/b][/size][size=2]
- [url=https://github.com/Norbyte/bg3se]BG3 Script Extender[/url] [size=2](you can easily install it with BG3MM through its [i]Tools[/i] tab or by pressing CTRL+SHIFT+ALT+T while its window is focused)
[line]
[/size][/size][size=5][b]Configuration[/b][/size][size=2][size=2]
When you load a save with the mod for the first time, it will automatically create an auto_send_food_to_camp_config.json file with default options.

You can easily navigate to it on Windows by pressing WIN+R and entering
[quote][code]explorer %LocalAppData%\Larian Studios\Baldur's Gate 3\Script Extender\AutoSendFoodToCamp[/code][/quote][/size][/size][size=2][size=2]
Open the JSON file with any text editor, even regular Notepad will work. Here's what each option inside does (order doesn't matter):

[size=2][size=2][font=Courier New]"GENERAL"[/font]: General settings for the mod.[font=Courier New]
   ﻿"enabled"[/font]: Set to [font=Courier New]true[/font] to activate the mod or [font=Courier New]false[/font] to disable it without uninstalling. [/size][/size]Enabled by default.

[font=Courier New]"FEATURES"[/font]: Controls various mod features.
[font=Courier New]   "move_food"[/font]: Set to [font=Courier New]true[/font] to automatically send food to chest camp. [size=2]Enabled by default.[/size]
[font=Courier New]   "move_beverages"[/font]: Set to [font=Courier New]true[/font] to [size=2]automatically send consumable beverages to chest camp[/size]. Enabled by default.
[font=Courier New]   "move_bought_food"[/font]: Set to [font=Courier New]true[/font] to [size=2]automatically send food items bought from vendors[/size] to chest camp. Enabled by default.
[font=Courier New]   "send_existing_food"[/font]:
    [font=Courier New]   - "enabled"[/font]: Set to [font=Courier New]true[/font] to [size=2]automatically send existing food items in the party's inventory to the camp chest when transitioning to camp[/size]. Enabled by default.
    [font=Courier New]   - "nested_containers"[/font]: Set to [font=Courier New]true[/font] to [size=2]also move food items inside nested containers (e.g., backpacks) to the camp chest[/size]. Enabled by default.
    [font=Courier New]   - "create_supply_sack"[/font]: Set to [font=Courier New]true[/font] to [size=2]automatically create a supply sack inside the camp chest if it doesn't exist[/size]. Enabled by default.
[font=Courier New]   "ignore"[/font]: Settings to ignore specific types of items.
    [font=Courier New]   - "healing"[/font]: Set to [font=Courier New]true[/font] to [size=2]ignore healing items in the [font=Courier New]healing_food_list.json[/font] file (e.g., Goodberry)[/size]. Enabled by default.
    [font=Courier New]   - "weapons"[/font]: Set to [font=Courier New]true[/font] to ignore [size=2]weapons listed in the [font=Courier New]weapons_food_list.json[/font] file (only Salami in the vanilla base game)[/size]. Disabled by default.
   ﻿   [/size][/size][size=2][size=2][font=Courier New]- "user_defined"[/font]: Set to [font=Courier New]true[/font] to ignore [size=2]items listed in the [font=Courier New]user_ignored_food_list.json[/font] file. [/size]Enabled by default.[/size][/size]
[size=2][size=2]
[size=2][font=Courier New]"DEBUG"[/font]: Adjusts the level of debugging information.
[font=Courier New]   "level"[/font]: Set this to 0 for no debug logs, 1 for basic logs, or 2 for detailed logs. Non-developers typically don't need to modify this setting. [size=2]0 by default.[/size]

[size=2][size=2][size=2][size=2][size=2][size=2]After making changes, load a save to reflect your changes, [/size][/size][/size][/size][/size][/size][/size][/size][/size][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2][size=2]or run [font=Courier New]!asftc_reload[/font] in the SE console.[/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][/size][size=2][size=2][size=2]
[/size][/size][line][size=4][b]
[/b][/size][/size][size=5][b]Compatibility[/b][/size]
- This mod should be compatible with most game versions and other mods, as it mostly just listens to game events and does not edit existing game data.
   ﻿- Mods that create regular food items will be affected as expected. I couldn't find a way to generalize the detection of food items that can heal.
   ﻿- Mods that affect the camp chest should be compatible.
   ﻿- Mods that auto loot/sort items may conflict with this mod's functionality. Since both types of mods manipulate inventory items, there could be unpredictable behavior when they try to move the same items, and I don't know if load order can dictate this. I can only guarantee that my mod by itself will not create duplicates of food items. Setting [size=2][size=2][font=Courier New]create_supply_sack[/font][/size][/size] to false might help.
[line][size=4][b]
Special Thanks[/b][/size]
Thanks to [url=https://www.nexusmods.com/users/64167336?tab=user+files]Fararagi[/url] for some pointers I used to start this mod; to [url=https://www.nexusmods.com/baldursgate3/users/21094599]Focus[/url] for some inventory helper functions and to [url=https://github.com/Norbyte/]Norbyte[/url], for the Script Extender.

[size=4][b]Source Code
[/b][/size]The source code is available on [url=https://github.com/AtilioA/BG3-auto-send-food-to-camp]GitHub[/url] or by unpacking the .pak file. Endorse on Nexus and give it a star on GitHub if you liked it!
[line][center][center][b][size=4]
My mods[/size][/b][size=2]
[url=https://www.nexusmods.com/baldursgate3/mods/6995]Waypoint Inside Emerald Grove[/url] - 'adds' a waypoint inside Emerald Grove
[b][size=4][url=https://www.nexusmods.com/baldursgate3/mods/7035][size=4][size=2]Auto Send Read Books To Camp[/size][/size][/url]﻿[size=4][size=2] [/size][/size][/size][/b][size=4][size=4][size=2]- [/size][/size][/size][size=2]send read books to camp chest automatically[/size]
[url=https://www.nexusmods.com/baldursgate3/mods/6880]Auto Use Soap[/url]﻿ - automatically use soap after combat/entering camp
[url=https://www.nexusmods.com/baldursgate3/mods/6540]Send Wares To Trader[/url]﻿[b] [/b]- automatically send all party members' wares to a character that initiates a trade[b]
[/b][b][url=https://www.nexusmods.com/baldursgate3/mods/6313]Preemptively Label Containers[/url]﻿[/b] - automatically tag nearby containers with 'Empty' or their item count[b]
[/b][url=https://www.nexusmods.com/baldursgate3/mods/5899]Smart Autosaving[/url] - create conditional autosaves at set intervals
[url=https://www.nexusmods.com/baldursgate3/mods/6086]Auto Send Food To Camp[/url] - send food to camp chest automatically
[url=https://www.nexusmods.com/baldursgate3/mods/6188]Auto Lockpicking[/url] - initiate lockpicking automatically
[size=2]
[/size][url=https://ko-fi.com/volitio][img]https://raw.githubusercontent.com/doodlum/nexusmods-widgets/main/Ko-fi_40px_60fps.png[/img][/url]﻿﻿[/size][/center][/center][center][url=https://www.nexusmods.com/baldursgate3/mods/7294][size=2][/size][/url][url=https://www.nexusmods.com/baldursgate3/mods/7294] [img]https://i.imgur.com/hOoJ9Yl.png[/img][/url][/center]
