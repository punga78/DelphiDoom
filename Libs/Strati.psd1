# Issue #219: manifesto degli strati. Letto da Tools\Verifica\219\Controlla-Strati.ps1.
# Versione leggibile e motivata: Libs\STRATI.md. Solo caratteri ASCII.
#
# Regola: uno STRATO puo' usare solo strati uguali o piu' bassi (Livello); un MODULO puo' usare
# tutti gli strati, se stesso e i moduli elencati in Ammessi (di solito nessuno).
@{
  Versione = 1

  Strati = @(
    @{ Nome = 'L0'; Tipo = 'Strato'; Livello = 0; Titolo = 'Fondazione' }
    @{ Nome = 'L1'; Tipo = 'Strato'; Livello = 1; Titolo = 'Formati e codec' }
    @{ Nome = 'L2'; Tipo = 'Strato'; Livello = 2; Titolo = 'Servizi di runtime' }
    @{ Nome = 'L3'; Tipo = 'Strato'; Livello = 3; Titolo = 'Piattaforma e scripting' }
    @{ Nome = 'IdTech1'; Tipo = 'Modulo'; Ammessi = @(); Titolo = 'id Tech 1: Base, giochi id, librerie id' }
    @{ Nome = 'IdTech4'; Tipo = 'Modulo'; Ammessi = @(); Titolo = 'Porte di id Tech 3 e 4' }
    @{ Nome = 'Giochi'; Tipo = 'Modulo'; Ammessi = @(); Titolo = 'Giochi non id: Xcom, Keen, Greed, War, Racing' }
    @{ Nome = 'Strumenti'; Tipo = 'Modulo'; Ammessi = @('IdTech1'); Titolo = 'Strumenti: IDE, editor, Launcher' }
  )

  # Cartelle scartate nella ricerca dei .pas (a qualunque profondita').
  Escluse = @('Tests', 'Tools', 'Reference', 'bin', 'dcu', '__history', 'Win32', 'Win64')

  # Aree che per il grafo contano come una sola (stessi nomi di unit in piu' cartelle).
  Gruppi = @{
    'Doom' = 'GiochiId'
    'Heretic' = 'GiochiId'
    'Hexen' = 'GiochiId'
    'Strife' = 'GiochiId'
  }

  Aree = @{
    # L0
    'Libs\IdLib' = 'L0'
    'Libs\Geometry' = 'L0'
    'Libs\Logging' = 'L0'
    'Libs\Platform' = 'L0'
    'Libs\Clock' = 'L0'
    'Libs\Threading' = 'L0'
    'Libs\Zlib' = 'L0'
    'Libs\Yaml' = 'L0'
    'Libs\MathCore' = 'L0'
    'Libs\GameMath' = 'L0'
    'Libs\Configuration' = 'L0'
    'Libs\CommandLine' = 'L0'
    # L1
    'Libs\Cinematic' = 'L1'
    'Libs\Compression' = 'L1'
    'Libs\Png' = 'L1'
    'Libs\Jpeg' = 'L1'
    'Libs\Ogg' = 'L1'
    'Libs\Mp3' = 'L1'
    'Libs\Sndfile' = 'L1'
    'Libs\Sound' = 'L1'
    'Libs\Mikmod' = 'L1'
    'Libs\Xmi' = 'L1'
    'Libs\M2m' = 'L1'
    'Libs\Midi' = 'L1'
    'Libs\Opl' = 'L1'
    'Libs\Imaging' = 'L1'
    'Libs\Palette' = 'L1'
    'Libs\Wad' = 'L1'
    'Libs\Texture' = 'L1'
    'Libs\Flic' = 'L1'
    # L2
    'Libs\Models' = 'L2'
    'Libs\Audio' = 'L2'
    'Libs\AudioMix' = 'L2'
    'Libs\Input' = 'L2'
    'Libs\Video' = 'L2'
    'Libs\Console' = 'L2'
    'Libs\Screenshot' = 'L2'
    'Libs\Scanner' = 'L2'
    'Libs\Serializer' = 'L2'
    # L3
    'Libs\GameHost' = 'L3'
    'Libs\OpenGlBinding' = 'L3'
    'Libs\OpenGlBinding\Recorder' = 'L3'
    'Libs\PascalScript' = 'L3'
    'Libs\Script' = 'L3'
    'Libs\ScriptHost' = 'L3'
    'Libs\Ddc' = 'L3'
    # IdTech1
    'Libs\Zone' = 'IdTech1'
    'Libs\Acs' = 'IdTech1'
    'Libs\ScriptEngine' = 'IdTech1'
    'Libs\Actions' = 'IdTech1'
    'Libs\ActorDef' = 'IdTech1'
    'Libs\Automap' = 'IdTech1'
    'Libs\Blockmap' = 'IdTech1'
    'Libs\Definitions' = 'IdTech1'
    'Libs\Dehacked' = 'IdTech1'
    'Libs\DynLights' = 'IdTech1'
    'Libs\Endoom' = 'IdTech1'
    'Libs\Glbsp' = 'IdTech1'
    'Libs\Hud' = 'IdTech1'
    'Libs\Info' = 'IdTech1'
    'Libs\Iwad' = 'IdTech1'
    'Libs\MapInfo' = 'IdTech1'
    'Libs\MusInfo' = 'IdTech1'
    'Libs\Net' = 'IdTech1'
    'Libs\Nodes' = 'IdTech1'
    'Libs\Obituary' = 'IdTech1'
    'Libs\Renderer' = 'IdTech1'
    'Libs\Specials' = 'IdTech1'
    'Libs\TableExport' = 'IdTech1'
    'Libs\TextureDefs' = 'IdTech1'
    'Libs\Thinkers' = 'IdTech1'
    'Libs\Udmf' = 'IdTech1'
    'Libs\Voxel' = 'IdTech1'
    'Libs\GlAutomap' = 'IdTech1'
    'Libs\GlLevel' = 'IdTech1'
    'Libs\GlMath' = 'IdTech1'
    'Libs\GlScene' = 'IdTech1'
    'Libs\GlTexture' = 'IdTech1'
    'Libs\OpenGl\Legacy' = 'IdTech1'
    'Libs\EngineSystem' = 'IdTech1'
    'Libs\GameState' = 'IdTech1'
    'Libs\GameData' = 'IdTech1'
    'Libs\IdTech' = 'IdTech1'
    'Libs\Parity' = 'IdTech1'
    'Libs\Radix' = 'IdTech1'
    'Libs\Speed' = 'IdTech1'
    # IdTech4
    'Libs\Collision' = 'IdTech4'
    'Libs\MapFile' = 'IdTech4'
    'Libs\Decl' = 'IdTech4'
    'Libs\Gui' = 'IdTech4'
    'Libs\BotAi' = 'IdTech4'
    'Libs\Aas' = 'IdTech4'
    'Libs\Qvm' = 'IdTech4'
    'Libs\Pmove' = 'IdTech4'
    'Libs\DoomScript' = 'IdTech4'
    # Giochi
    'Libs\Keen' = 'Giochi'
    'Libs\Greed' = 'Giochi'
    'Libs\War' = 'Giochi'
    'Libs\Racing' = 'Giochi'
    'Libs\XcomAudio' = 'Giochi'
    'Libs\XcomBasescape' = 'Giochi'
    'Libs\XcomBattle' = 'Giochi'
    'Libs\XcomBattleStates' = 'Giochi'
    'Libs\XcomBattlescape' = 'Giochi'
    'Libs\XcomDebriefing' = 'Giochi'
    'Libs\XcomEngine' = 'Giochi'
    'Libs\XcomFormats' = 'Giochi'
    'Libs\XcomGeoscape' = 'Giochi'
    'Libs\XcomMenu' = 'Giochi'
    'Libs\XcomMod' = 'Giochi'
    'Libs\XcomSave' = 'Giochi'
    'Libs\XcomStrategy' = 'Giochi'
    'Libs\XcomSurface' = 'Giochi'
    'Libs\XcomUfopaedia' = 'Giochi'
    'Libs\XcomUi' = 'Giochi'
    # Strumenti
    'Libs\Ide' = 'Strumenti'
    'Libs\ToolsCore' = 'Strumenti'
    'Libs\EndoomEditor' = 'Strumenti'
    'Libs\Font' = 'Strumenti'
    'Libs\FontEditor' = 'Strumenti'
    'Libs\VoxelEditor' = 'Strumenti'
    'Libs\Launcher' = 'Strumenti'
    # Cartelle dei prodotti
    'Base' = 'IdTech1'
    'Common' = 'IdTech1'
    'Doom' = 'IdTech1'
    'Heretic' = 'IdTech1'
    'Hexen' = 'IdTech1'
    'Strife' = 'IdTech1'
    'Radix' = 'IdTech1'
    'Speed' = 'IdTech1'
    'Keen' = 'Giochi'
    'Greed' = 'Giochi'
    'War' = 'Giochi'
    'OpenXcom' = 'Giochi'
    'DD_IDE' = 'Strumenti'
    'DD_Tools' = 'Strumenti'
    'Launcher' = 'Strumenti'
  }

  # Difetti noti (censimento, docs\FRAMEWORK_CENSIMENTO.md). Ogni voce dice chi la toglie.
  # Massimo = numero di unit di arrivo distinte coperte: piu' unit e' una violazione nuova,
  # meno unit e' una eccezione da ridurre. Ciclo = insieme di aree che si usano a vicenda.
  Eccezioni = @(
    # --- #225: librerie miste (la parte generica va separata da quella di Doom) ---
    @{ Da = 'Libs\Speed'; A = 'Libs\Racing'; Massimo = 2; Issue = 226
       Motivo = 'ActorDefinitions, CarSpriteBuilder e SkyTextures di SpeedHaste32 (motore id Tech 1) usano Racing.Types e Racing.CarData (auto e piste, strato Giochi): Speed32 e SpeedHaste32 stanno nella stessa area, da separare quando si spostano le cartelle' }
    @{ Da = 'Libs\Pmove'; A = 'Libs\Net'; Massimo = 1; Issue = 225
       Motivo = 'Pmove usa TQ3PlayerState e TQ3UserCmd di DelphiDoom.Net.Q3.Types: Net e'' mista (trasporto e protocollo di Doom e Quake III) e i tipi di Quake III vanno in un''area id Tech 3' }
    @{ Da = 'Libs\Console'; A = 'Libs\GameState'; Massimo = 1; Issue = 225
       Motivo = 'Console (registro dei comandi, generico) usa IGameContext (gioco in corso, di Doom) in Factory e VariableCommands' }
    @{ Da = 'Libs\Greed'; A = 'Libs\Net'; Massimo = 1; Issue = 225
       Motivo = 'Greed usa il trasporto UDP di Net, che e'' misto con il protocollo dei ticcmd di Doom (Net non e'' nell''elenco di #225: da aggiungere)' }
    @{ Da = 'Greed'; A = 'Libs\Net'; Massimo = 4; Issue = 225
       Motivo = 'DelphiDoom.Greed.Composition usa il trasporto UDP di Net (come sopra)' }
    # --- #229: unit comuni dei formati e dei lettori di byte ---
    @{ Da = 'Libs\Opl'; A = 'Libs\XcomFormats'; Massimo = 1; Issue = 229
       Motivo = 'CatSource e Factory dell''Adlib usano DelphiDoom.Xcom.Intf (lettura di archivi CAT): il contratto va in una libreria comune' }
    # --- #226: cartella di prodotto mista ---
    @{ Da = 'Speed'; A = 'Libs\Racing'; Massimo = 9; Issue = 226
       Motivo = 'la cartella Speed ha Speed32 (corse, usa Racing) e SpeedHaste32 (motore id): da separare quando si spostano le cartelle' }
  )
}



