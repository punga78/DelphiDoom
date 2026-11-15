# Writes Tests\Data\BotAi\goal\goalmove.txt, the scenario of the parity test of the goals, the movement, the
# elementary actions and the genetic selection of the bots (the commands of aigen.c and of
# Tests\Source\DelphiDoom.Tests.BotAi.GoalMoveScenario.pas). The recipe is here so that the scenario can be made again;
# the answers of the C are made by build.sh + aigen.exe (LEGGIMI.md).
#   powershell -File Make-Scenario.ps1 <output file>
param([string]$Output = (Join-Path $PSScriptRoot '..\..\..\..\Tests\Data\BotAi\goal\goalmove.txt'))

$L = New-Object System.Collections.Generic.List[string]
function A([string]$Line) { $L.Add($Line) }
function Rem([string]$Text) { $L.Add('# ' + $Text) }

# the flags: the default ones (TFL_DEFAULT: walk, crouch, barrier jump, jump, ladder, walk off ledge, swim, water jump,
# teleport, elevator, air, water, jump pad, func bobbing) plus the rocket jump, the BFG jump, the grapple hook, lava and areas the bots should not enter
$FLAGS = 33324990
$NOTELEPORT = $FLAGS -band (-bnot 1024)
$ONLYWALK = 2 + 524288 + 1048576          # walk, air, water
$NOFLAGS = 0
$CLIENT = 3

function Ent([hashtable[]]$Entities) {
    $s = ''
    foreach ($e in $Entities) {
        $s += '{\n'
        foreach ($k in $e.Keys) { $s += '"' + $k + '" "' + $e[$k] + '"\n' }
        $s += '}\n'
    }
    return $s
}
function O([double]$x, [double]$y, [double]$z) { return "$x $y $z" }

# ------------------------------------------------------------ the map: entities of the BSP
$entities = @(
    [ordered]@{ classname = 'worldspawn'; message = 'goal and move test' },
    [ordered]@{ classname = 'func_plat'; model = '*1' },
    [ordered]@{ classname = 'func_bobbing'; model = '*2' },
    [ordered]@{ classname = 'func_door'; model = '*3' },
    [ordered]@{ classname = 'func_static'; model = '*4' },
    [ordered]@{ classname = 'func_plat'; model = '*256' },
    [ordered]@{ classname = 'func_door'; model = '*-5' },
    [ordered]@{ classname = 'func_static' },
    [ordered]@{ classname = 'func_train'; model = '*5' },
    [ordered]@{ classname = 'item_armor_body'; origin = (O 170 32 5) },
    [ordered]@{ classname = 'item_health'; origin = (O 230 32 5) },
    [ordered]@{ classname = 'item_quad'; origin = (O 350 32 5) },
    [ordered]@{ classname = 'weapon_rocketlauncher'; origin = (O 40 32 5) },
    [ordered]@{ classname = 'ammo_rockets'; origin = (O 100 32 5) },
    [ordered]@{ classname = 'item_botroam'; origin = (O 60 32 5); weight = '2.5' },
    [ordered]@{ classname = 'item_flag_red'; origin = (O 10 32 5) },
    [ordered]@{ classname = 'item_armor_body' },
    [ordered]@{ classname = 'item_health'; origin = (O 200 32 50); spawnflags = '1' },
    [ordered]@{ classname = 'item_health'; origin = (O 30 32 5); spawnflags = '1' },
    [ordered]@{ classname = 'item_health'; origin = (O 220 40 5); notfree = '1' },
    [ordered]@{ classname = 'item_health'; origin = (O 225 40 5); notteam = '1' },
    [ordered]@{ classname = 'item_health'; origin = (O 215 40 5); notsingle = '1' },
    [ordered]@{ classname = 'item_health'; origin = (O 210 40 5); notbot = '1' },
    [ordered]@{ classname = 'item_unweighted'; origin = (O 340 40 5) },
    [ordered]@{ classname = 'target_location'; origin = (O 40 20 5); message = 'Red Base' },
    [ordered]@{ classname = 'target_location'; origin = (O 330 20 5); message = 'Blue Base' },
    [ordered]@{ classname = 'info_camp'; origin = (O 170 20 5); message = 'camp a'; range = '300'; weight = '1.5'; wait = '10'; random = '3' },
    [ordered]@{ classname = 'info_camp'; origin = (O 235 20 5); message = 'camp b'; range = '100'; weight = '0.5'; wait = '5'; random = '1' },
    [ordered]@{ classname = 'info_camp'; origin = (O -100 32 5); message = 'camp in solid' }
)
$entdata = Ent $entities

# ------------------------------------------------------------ genetics
Rem 'genetic selection'
A 'srand|1'
A 'gen|10|20|30|40|50'
A 'gen|5|-1|-1|7|-1|9|2'
A 'gen|1|2'
A 'gen|0|0|0|0'
A 'gen|3|3|3|3|3|3'
A 'gen|-1|-1|-1|-1'
A ('gen|' + ((1..257 | ForEach-Object { $_ }) -join '|'))
A ('gen|' + ((1..256 | ForEach-Object { $_ % 7 }) -join '|'))
A 'gensel|3|0|0|5'
A 'gensel|0|0|0'
A 'gensel|-1|-1|-1'
A 'gensel|1'
A 'gensel'
A 'gensel|-1|4|-1'
A 'gensel|0.5|0.25|0|0'

# ------------------------------------------------------------ setup of the actions, the map and the models
Rem 'setup'
A 'easetup|64'
A 'developer|1'
A 'libvar|sv_mapChecksum|305419896'
A 'srand|7'
A 'time|0'
A 'loadaas|botworld.aas'
A 'loadaas|missing.aas'
A "ttable|$FLAGS"
A 'ttable|2'
A "ttable|$ONLYWALK"
A "entdata|$entdata"
A 'model|1|-32|-32|-4|32|32|4|0|0|0'
A 'model|2|-16|-16|-2|16|16|2|0|0|0'
A 'model|3|-8|-8|-8|8|8|8|0|0|0'
A 'model|31|-1|-1|-1|1|1|1|0|0|0'

Rem 'the world'
foreach ($p in @('32 32 5', '32 32 0', '32 32 8', '32 32 40', '100 32 5', '100 32 40', '160 32 5', '224 32 5', '224 32 30', '288 32 5', '352 32 5', '352 32 8', '500 32 5', '-20 32 5', '32 90 5')) {
    A "world|$($p -replace ' ', '|')"
}

# ------------------------------------------------------------ the goals
function Items([string]$Label) {
    Rem $Label
    A 'goalsetup'
    A 'time|10'
    A 'goalinit'
    A 'golist'
}

Rem 'the goals: free for all'
A 'libvar|g_gametype|0'
A 'goalsetup'
A 'libvar|max_iteminfo|1'
A 'goalsetup'
A 'libvar|max_iteminfo|256'
A 'goalsetup'
A 'time|10'
A 'goalinit'
A 'golist'
A 'gsalloc|11'
A 'gsalloc|12'
A 'gsalloc|13'
A 'gsweights|1|bots/goal_i.c'
A 'gsweights|2|bots/goal2_i.c'
A 'gsweights|3|bots/missing_i.c'
A 'gsweights|9|bots/goal_i.c'
A "gsltg|1|40|32|5|$FLAGS|0|50|100|60|1|0|20"
A "gsltg|3|40|32|5|$FLAGS|0|50"
Rem 'entities link the items to the game'
A 'entity|1|1|2|11|170|32|0.25|170|32|0.25|0|0'
A 'entity|2|1|2|12|230|32|0.25|230|32|0.25|0|0'
A 'entity|3|1|2|14|350|32|0.25|350|32|0.25|0|0'
A 'entity|4|1|2|13|40|32|0.25|40|32|0.25|0|0'
A 'entity|5|1|2|15|60|32|0.25|60|32|0.25|0|0'
A 'entity|6|1|2|12|30|32|0.25|30|32|0.25|0|0'
A 'entity|7|1|3|13|10|10|10|10|10|10|0|0'
A 'entity|8|1|2|12|500|500|0|500|500|1|0|0'
A 'entity|9|0|2|12|230|32|0.25|230|32|0.25|0|0'
A 'entity|10|1|2|0|230|32|0.25|230|32|0.25|0|0'
A 'goalupdate'
A 'golist'
foreach ($inv in @('0|50|100|60|1|0|20', '0|75|100|60|1|0|20', '0|100|100|100|1|0|20', '0|0|0|0|0|0|0', '0|200|0|0|0|0|20', '0|50|100|60|0|0|0')) {
    A "gsltg|1|40|32|5|$FLAGS|$inv"
    A 'gstop|1'
    A 'gsdumpstack|1'
    A 'gsdumpavoid|1'
    A 'gspop|1'
}
A "gsltg|1|300|32|5|$FLAGS|0|50|100|60"
A "gsltg|2|300|32|5|$FLAGS|0|50|100|60"
A "gsltg|2|300|32|5|$FLAGS|0|50|100|60"
A "gsltg|1|0|0|0|$FLAGS|0|50|100|60"
A "gsltg|1|40|32|5|$ONLYWALK|0|50|100|60"
A "gsltg|1|40|32|5|$NOFLAGS|0|50|100|60"
A "gsltg|1|40|32|5|$FLAGS|0|50|100|60"
A "gsltg|1|40|32|5|$FLAGS|0|50|100|60"
A "gsnbg|1|40|32|5|$FLAGS|500|0|0|50|100|60"
A "gsnbg|1|40|32|5|$FLAGS|500|1|0|50|100|60"
A "gsnbg|1|40|32|5|$FLAGS|5|1|0|50|100|60"
A "gsnbg|2|40|32|5|$FLAGS|500|1|0|50|100|60"
A "gsnbg|2|200|32|5|$FLAGS|500|0|0|50|100|60"
A "gsnbg|3|200|32|5|$FLAGS|500|0|0|50|100|60"
A "gsnbg|2|0|0|0|$FLAGS|500|0|0|50|100|60"
A 'gstop|1'
A 'gssecond|1'
A 'gsdumpstack|1'
A 'gsavoid|1|1'
A 'gsavoid|1|2'
A 'gsavoid|1|3'
A 'gsavoid|1|99'
A 'gssetavoid|1|3|20'
A 'gssetavoid|1|4|-1'
A 'gssetavoid|1|99|-1'
A 'gssetavoid|1|2|-1'
A 'gsavoid|1|3'
A 'gsavoid|1|4'
A 'gsdumpavoid|1'
A 'time|12'
A 'gsavoid|1|3'
A 'gsremoveavoid|1|3'
A 'gsavoid|1|3'
A 'gsresetavoid|1'
A 'gsdumpavoid|1'
A 'gsname|1|40'
A 'gsname|2|5'
A 'gsname|3|1'
A 'gsname|999|40'
A 'gsname|4|40'
Rem 'stack: overflow and the goals'
A 'gsempty|1'
foreach ($n in 1..9) { A "gspush|1|$($n * 10)|32|5|3|1|$n|1|0" }
A 'gsdumpstack|1'
A 'gstop|1'
A 'gssecond|1'
A 'gstouch|1|90|32|5'
A 'gstouch|1|200|32|5'
A 'gsvis|1|1|10|32|5'
A 'gsvis|1|1|-10|32|5'
A 'gsvis|1|1|10|32|50'
A 'gspop|1'
A 'gspop|1'
A 'gsempty|1'
A 'gspop|1'
A 'gstop|1'
A 'gssecond|1'
A "gsnbg|1|0|0|0|$FLAGS|500|0|0"
A 'gstouch|1|90|32|5'
A 'gsvis|1|1|10|32|5'
A 'gsreset|1'
A 'gsreset|0'
A 'gsreset|99'
A 'gsfree|0'
A 'gsfree|99'
A 'gsfree|3'
A 'gsfree|3'
A 'gstop|3'
Rem 'the level item goals, the locations and the camp spots'
foreach ($name in @('Health', 'health', 'Rockets', 'Unweighted', 'Roam', 'Nothing')) {
    A "gslevelgoal|-1|$name"
}
A 'gslevelgoal|2|health'
A 'gslevelgoal|3|health'
A 'gslevelgoal|99|health'
A 'gslevelgoal|1|Quad Damage'
A 'gsloc|Red Base'
A 'gsloc|blue base'
A 'gsloc|none'
foreach ($n in -1..3) { A "gscamp|$n" }
Rem 'time out of dropped items, items that move, entities that are used again'
A 'entity|20|1|2|13|200|32|0.5|200|32|0.5|0|0'
A 'time|14'
A 'goalupdate'
A 'golist'
A 'entity|21|1|2|13|130|32|0.5|130|32|0.5|0|0'
A 'goalupdate'
A 'golist'
A "gsltg|2|130|32|0.5|$FLAGS|0|0|0|0|0"
A 'entity|20|1|2|11|200|32|0.5|200|32|0.5|0|0'
A 'entity|1|1|2|11|172|32|0.25|172|32|0.25|0|0'
A 'goalupdate'
A 'golist'
A 'entity|4|1|2|13|41|32|0.25|40|32|0.25|0|0'
A 'goalupdate'
A 'time|50'
A 'goalupdate'
A 'golist'
A 'entityclear'
A 'goalupdate'
A 'golist'
Rem 'the weights of the bots: breeding and evolving'
A 'gsalloc|14'
A 'gsweights|3|bots/goal_i.c'
A 'gsbreed|1|2|3'
A 'gsbreed|2|1|3'
A 'gsmutate|1'
A 'gsmutate|3'
A 'gsfreeweights|1'
A 'gsfreeweights|1'
A 'gsweights|1|bots/goal_i.c'
A 'gsmutate|1'
A 'gsfree|1'
A 'gsfree|2'
A 'gsfree|3'
Rem 'the other game types'
foreach ($gt in @(2, 3, 4)) {
    A "libvar|g_gametype|$gt"
    A 'gsshutdown'
    A 'goalsetup'
    A 'time|10'
    A 'goalinit'
    A 'golist'
    A 'gsalloc|21'
    A 'gsweights|1|bots/goal_i.c'
    A 'entity|1|1|2|11|170|32|0.25|170|32|0.25|0|0'
    A 'entity|2|1|2|12|230|32|0.25|230|32|0.25|0|0'
    A 'entity|3|1|2|14|350|32|0.25|350|32|0.25|0|0'
    A 'entity|31|1|2|12|220|40|0.25|220|40|0.25|0|0'
    A 'entity|32|1|2|12|225|40|0.25|225|40|0.25|0|0'
    A 'entity|33|1|2|12|215|40|0.25|215|40|0.25|0|0'
    A 'entity|34|1|2|12|210|40|0.25|210|40|0.25|0|0'
    A 'entity|35|1|2|12|340|40|0.25|340|40|0.25|0|0'
    A 'goalupdate'
    A "gsltg|1|40|32|5|$FLAGS|0|50|100|60"
    A 'gslevelgoal|-1|Health'
    A 'gsfree|1'
    A 'entityclear'
}
A 'libvar|g_gametype|0'
A 'gsshutdown'
A 'libvar|max_levelitems|2'
A 'goalsetup'
A 'goalinit'
A 'golist'
A 'libvar|max_levelitems|256'
A 'libvar|itemconfig|nothere.c'
A 'goalsetup'
A 'libvar|itemconfig|items.c'
A 'goalsetup'
A 'goalinit'
A 'golist'

# ------------------------------------------------------------ the movement
Rem 'the movement'
A 'mvsetup'
A 'mvalloc'
A 'mvalloc'
A 'mvfree|2'
A 'mvfree|2'
A 'mvfree|0'
A 'mvreset|7'
A 'mvarea|32|32|5|3'
A 'mvarea|32|32|50|3'
A 'mvarea|500|32|5|3'
A 'mvarea|0|0|0|3'
A 'mvfuzzy|32|32|5'
A 'mvfuzzy|32|32|200'
A 'mvfuzzy|-20|32|5'
A 'mvfuzzy|64|32|5'
A 'mvfuzzy|96|32|2'

function Init([double[]]$Origin, [double[]]$Velocity, [int]$Flags = 0, [double]$Think = 0.1, [int]$Presence = 2) {
    A "mvinit|1|$($Origin -join '|')|$($Velocity -join '|')|0|0|24|1|$CLIENT|$Think|$Presence|0|0|0|$Flags"
}
function Goal([double[]]$Origin, [int]$Area, [int]$Ent = 0, [int]$Number = 0, [int]$Flags = 0) {
    return "$($Origin -join '|')|$Area|$Ent|$Number|$Flags"
}
function MoveTo([double[]]$Origin, [double[]]$Velocity, [int]$TravelFlags, [string]$Goal, [int]$MoveFlags = 0) {
    Init $Origin $Velocity $MoveFlags
    A "mvgoal|1|$CLIENT|$TravelFlags|$Goal"
    A "eareset|$CLIENT"
}

Rem 'every travel type, on the ground and in the air'
# type, start area position, goal (area, origin), the travel flags, a position in the air
$types = @(
    @{ n = 'walk'; o = @(40, 32, 5); g = (Goal @(100, 32, 5) 2); f = $FLAGS; a = @(60, 32, 40) },
    @{ n = 'jumppad'; o = @(32, 32, 5); g = (Goal @(160, 32, 5) 3); f = $FLAGS; a = @(70, 32, 50) },
    @{ n = 'rocketjump'; o = @(30, 32, 5); g = (Goal @(288, 32, 5) 5); f = $FLAGS; a = @(60, 32, 30) },
    @{ n = 'waterjump'; o = @(90, 32, 5); g = (Goal @(32, 32, 5) 1); f = $FLAGS; a = @(90, 32, 20) },
    @{ n = 'swim'; o = @(100, 32, 5); g = (Goal @(160, 32, 5) 3); f = $FLAGS; a = @(100, 32, 20) },
    @{ n = 'grapple'; o = @(110, 32, 5); g = (Goal @(352, 32, 5) 6); f = $FLAGS; a = @(110, 32, 30) },
    @{ n = 'barrierjump'; o = @(150, 32, 5); g = (Goal @(100, 32, 5) 2); f = $FLAGS; a = @(150, 32, 40) },
    @{ n = 'jump'; o = @(170, 32, 5); g = (Goal @(224, 32, 5) 4); f = $FLAGS; a = @(180, 32, 30) },
    @{ n = 'bfgjump'; o = @(160, 32, 5); g = (Goal @(352, 32, 5) 6); f = $FLAGS; a = @(180, 32, 40) },
    @{ n = 'crouch'; o = @(200, 32, 5); g = (Goal @(160, 32, 5) 3); f = $FLAGS; a = @(200, 32, 30) },
    @{ n = 'ladder'; o = @(240, 32, 5); g = (Goal @(288, 32, 5) 5); f = $FLAGS; a = @(240, 32, 30) },
    @{ n = 'walkoffledge'; o = @(270, 32, 5); g = (Goal @(224, 32, 5) 4); f = $FLAGS; a = @(270, 32, 25) },
    @{ n = 'elevator'; o = @(262, 32, 5); g = (Goal @(352, 32, 5) 6); f = $FLAGS; a = @(262, 32, 30) },
    @{ n = 'funcbob'; o = @(380, 32, 5); g = (Goal @(288, 32, 5) 5); f = $NOTELEPORT; a = @(380, 32, 30) },
    @{ n = 'teleport'; o = @(350, 32, 5); g = (Goal @(32, 32, 5) 1); f = $FLAGS; a = @(350, 32, 30) }
)
# the movers of the map (models 1 and 2): where they are (down and at the start of their way)
A 'entity|30|1|4|1|300|32|-12|300|32|-12|0|0'
A 'entity|31|1|4|2|345|32|-12|345|32|-12|0|0'
A 'mvreset|1'
foreach ($t in $types) {
    Rem "travel type $($t.n)"
    A 'mvreset|1'
    MoveTo $t.o @(0, 0, 0) $t.f $t.g
    MoveTo $t.o @(0, 0, 0) $t.f $t.g
    MoveTo $t.a @(80, 0, 20) $t.f $t.g
    MoveTo $t.a @(-60, 20, -30) $t.f $t.g
    MoveTo $t.a @(0, 0, 0) $t.f $t.g 4
    A "mvsim|1|$CLIENT|8|0.1|$($t.o -join '|')|$($t.f)|$($t.g)"
}
Rem 'the same with the movers away from their start (the plat up, the func_bobbing far from its start)'
A 'entity|30|1|4|1|300|32|30|300|32|30|0|0'
A 'entity|31|1|4|2|420|32|-12|420|32|-12|0|0'
foreach ($n in @('elevator', 'funcbob')) {
    $t = $types | Where-Object { $_.n -eq $n }
    A 'mvreset|1'
    MoveTo $t.o @(0, 0, 0) $t.f $t.g
    MoveTo $t.a @(0, 0, 0) $t.f $t.g
    A "mvsim|1|$CLIENT|8|0.1|$($t.o -join '|')|$($t.f)|$($t.g)"
}
Rem 'the bot on the movers: the plat down, the func_bobbing at the start and at the end'
A 'entity|30|1|4|1|300|32|-12|300|32|-12|0|0'
A 'solid|30|280|10|-40|320|50|-20'
A 'solid|31|325|10|-40|375|50|-20'
foreach ($bobx in @(350, 345, 372, 400)) {
    A "entity|31|1|4|2|$bobx|32|-12|$bobx|32|-12|0|0"
    A 'mvreset|1'
    MoveTo @(350, 32, 5) @(0, 0, 0) $NOTELEPORT (Goal @(288, 32, 5) 5)
    MoveTo @(350, 32, 5) @(0, 0, 0) $NOTELEPORT (Goal @(288, 32, 5) 5)
    A "mvsim|1|$CLIENT|8|0.1|350|32|5|$NOTELEPORT|$(Goal @(288, 32, 5) 5)"
    Init @(350, 32, 40) @(0, 0, 10)
    A "mvgoal|1|$CLIENT|$NOTELEPORT|$(Goal @(288, 32, 5) 5)"
}
foreach ($pos in @(@(300, 32, 5), @(285, 32, 5), @(300, 32, 25), @(300, 32, 40))) {
    A 'mvreset|1'
    MoveTo $pos @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6)
    MoveTo $pos @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6)
    A "mvsim|1|$CLIENT|8|0.1|$($pos -join '|')|$FLAGS|$(Goal @(352, 32, 5) 6)"
}
Init @(300, 32, 40) @(0, 0, 10)
A "mvgoal|1|$CLIENT|$FLAGS|$(Goal @(352, 32, 5) 6)"
A 'clearsolids'
A 'entity|31|1|4|2|345|32|-12|345|32|-12|0|0'
Rem 'a bot on top of things'
A 'solid|30|280|10|-40|320|50|-20'
A 'solid|60|0|10|-40|60|50|-20'
A 'entity|60|1|1|3|30|32|-10|30|32|-10|0|0'
A 'entity|61|1|1|4|130|32|-10|130|32|-10|0|0'
A 'entity|62|1|1|2|230|32|-10|230|32|-10|0|0'
A 'entity|63|1|1|9|330|32|-10|330|32|-10|0|0'
A 'solid|61|90|10|-40|170|50|-20'
A 'solid|62|190|10|-40|270|50|-20'
A 'solid|63|290|10|-40|370|50|-20'
A 'mvreset|1'
foreach ($x in @(30, 130, 230, 330, 60, 300)) {
    MoveTo @($x, 32, 5) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6)
}
A 'mvarea|30|32|5|3'
A 'mvarea|130|32|5|3'
A 'mvarea|230|32|5|3'
A 'mvarea|300|32|5|3'
A 'clearsolids'
A 'entityclear'
Rem 'blocked by an entity'
A 'solid|50|100|20|-10|120|45|60'
A 'entity|50|1|1|0|100|32|0|100|32|0|0|0'
A 'mvreset|1'
MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2)
MoveTo @(100, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2)
A 'clearsolids'
Rem 'goals: the goal area, no goal, no area, no reachability, a handle that is not there'
A 'mvreset|1'
A "mvgoal|1|$CLIENT|$FLAGS|0|0|0|0|0|0|0"
MoveTo @(100, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2)
MoveTo @(100, 32, 5) @(0, 0, 0) $FLAGS (Goal @(120, 32, 5) 2)
MoveTo @(100, 32, 5) @(0, 0, 0) $FLAGS (Goal @(120, 32, 5) 2) 0
MoveTo @(500, 32, 5) @(0, 0, 0) $FLAGS (Goal @(120, 32, 5) 2)
MoveTo @(-20, 32, 5) @(0, 0, 0) $FLAGS (Goal @(120, 32, 5) 2)
MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(120, 32, 5) 7)
MoveTo @(40, 32, 5) @(0, 0, 0) $NOFLAGS (Goal @(120, 32, 5) 2)
A "mvgoal|1|$CLIENT|$FLAGS|null"
A "mvgoal|99|$CLIENT|$FLAGS|100|32|5|2|0|0|0"
A 'mvinit|99|40|32|5|0|0|0|0|0|24|1|3|0.1|2|0|0|0|0'
A 'mvdir|99|3|1|0|0|200|1'
Rem 'avoid spots and reachabilities that are avoided'
A 'mvreset|1'
A 'mvavoidspot|1|72|32|5|20|1'
A 'mvavoidspot|1|60|32|5|20|2'
A 'mvavoidspot|1|0|0|0|0|1'
MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2)
A 'mvresetavoid|1'
A 'mvresetlast|1'
MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2)
A 'mvavoidspot|1|0|0|0|0|0'
A 'mvresetlast|1'
foreach ($i in 1..4) { MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(100, 32, 5) 2) 0 }
A 'mvresetavoid|1'
A 'mvresetlast|1'
foreach ($i in 1..34) { A "mvavoidspot|1|$($i * 10)|32|5|15|1" }
A 'mvavoidspot|1|0|0|0|0|0'
Rem 'movement in a direction'
foreach ($d in @('mvdir|1|3|1|0|0|200|1', 'mvdir|1|3|0|1|0|300|2', 'mvdir|1|3|1|0|0|200|4', 'mvdir|1|3|1|0|0|100|0')) {
    foreach ($o in @(@(40, 32, 5), @(100, 32, 5), @(40, 32, 50))) {
        Init $o @(0, 0, 0)
        A $d
        A "eareset|$CLIENT"
    }
}
Init @(40, 32, 50) @(0, 0, 0) 0 0.1
A 'mvdir|1|3|1|0|0|100|0'
Rem 'view target and predicted position'
A 'mvreset|1'
MoveTo @(40, 32, 5) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6)
foreach ($look in @(5, 50, 200, 800)) {
    A "mvview|1|$FLAGS|$look|352|32|5|6|0|0|0"
}
A "mvview|7|$FLAGS|50|352|32|5|6|0|0|0"
A 'mvreset|1'
A "mvview|1|$FLAGS|50|352|32|5|6|0|0|0"
foreach ($p in @(@(40, 32, 5, 1), @(100, 32, 5, 2), @(224, 32, 5, 4), @(500, 32, 5, 0))) {
    A "mvpredict|$($p[0])|$($p[1])|$($p[2])|$($p[3])|$FLAGS|352|32|5|6|0|0|0"
}
A "mvpredict|40|32|5|1|$FLAGS|352|32|5|0|0|0|0"
A "mvpredict|40|32|5|1|$FLAGS|352|32|5|6|0|0|0"
A "mvpredict|352|32|5|6|$FLAGS|352|32|5|6|0|0|0"
A "mvpredict|40|32|5|1|$NOFLAGS|352|32|5|6|0|0|0"
Rem 'the walk of a bot'
A 'mvreset|1'
A "mvsim|1|$CLIENT|30|0.1|40|32|5|$FLAGS|352|32|5|6|0|0|0"
A "mvsim|1|$CLIENT|30|0.1|352|32|5|$FLAGS|40|32|5|1|0|0|0"
A "mvsim|1|$CLIENT|20|0.05|130|32|5|$FLAGS|32|32|5|1|0|0|0"
A 'mvreset|1'
A 'libvar|offhandgrapple|1'
foreach ($i in 1..3) { MoveTo @(110, 32, 5) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6) }
A 'entity|40|1|3|0|200|32|30|200|32|30|10|0'
MoveTo @(110, 32, 20) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6) 64
A 'mvsim|1|3|12|0.1|110|32|5|33324990|352|32|5|6|0|0|0'
A 'libvar|offhandgrapple|0'
A 'mvsim|1|3|12|0.1|110|32|5|33324990|352|32|5|6|0|0|0'
A 'entity|40|1|3|0|200|32|30|200|32|30|10|0'
MoveTo @(110, 32, 20) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6) 64
A 'mvsim|1|3|12|0.1|110|32|5|33324990|352|32|5|6|0|0|0'
Rem 'the grapple hook: look at the end, fire, let it pull, lose it'
$GOAL6 = (Goal @(352, 32, 5) 6)
$GOAL1 = (Goal @(32, 32, 5) 1)
foreach ($offhand in @(0, 1)) {
    A "libvar|offhandgrapple|$offhand"
    A 'entity|40|1|3|0|200|32|30|200|32|30|10|0'
    A 'mvreset|1'
    A "mvinit|1|110|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|0"
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'mvinit|1|140|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|64'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'time|60'
    A 'entityclear'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'time|61'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'mvinit|1|330|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|64'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'entity|40|1|3|0|200|32|30|200|32|30|10|0'
    A 'mvinit|1|110|32|4|0|0|0|0|0|24|1|3|0.1|2|0|0|0|0'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'mvinit|1|110|32|20|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|0'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'solid|55|150|20|-10|160|45|60'
    A 'mvinit|1|110|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|0'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A "eareset|$CLIENT"
    A 'clearsolids'
    A 'mvreset|1'
    A 'mvinit|1|110|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|0'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL6"
    A 'mvinit|1|90|32|4|0|0|0|0|0|24|1|3|0.1|2|-354.29|0|0|0'
    A "mvgoal|1|$CLIENT|$FLAGS|$GOAL1"
    A "eareset|$CLIENT"
}
A 'libvar|offhandgrapple|0'
A 'entityclear'Rem 'jump pads found without knowing'
A 'mvreset|1'
MoveTo @(60, 32, 5) @(0, 0, 0) $FLAGS (Goal @(352, 32, 5) 6)
Init @(150, 32, 40) @(200, 0, 100)
A "mvgoal|1|$CLIENT|$FLAGS|352|32|5|6|0|0|0"
Init @(120, 32, 40) @(100, 0, 50)
A "mvgoal|1|$CLIENT|$FLAGS|352|32|5|6|0|0|0"
A 'mvreset|1'
Init @(150, 32, 40) @(100, 0, 100)
A "mvgoal|1|$CLIENT|$FLAGS|352|32|5|6|0|0|0"
A 'mvreset|1'
Init @(150, 32, 40) @(100, 0, 100)
A "mvgoal|1|$CLIENT|$FLAGS|352|32|5|6|0|0|0"
Rem 'the elementary actions'
A 'eainput|3|0.5'
A 'eareset|3'
A 'eareset|3'
A 'mvfree|1'

$parent = Split-Path $Output -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
[System.IO.File]::WriteAllText($Output, (($L -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
"$($L.Count) lines in $Output"
