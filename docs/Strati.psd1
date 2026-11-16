# Issue #219: manifesto degli strati. Letto da Tools\Verifica\219\Controlla-Strati.ps1.
# Versione leggibile e motivata: docs\STRATI.md. Solo caratteri ASCII.
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
    'Framework\IdLib' = 'L0'
    'Framework\Geometry' = 'L0'
    'Framework\Logging' = 'L0'
    'Framework\Platform' = 'L0'
    'Framework\Bytes' = 'L0'
    'Framework\Clock' = 'L0'
    'Framework\Threading' = 'L0'
    'Framework\Zlib' = 'L0'
    'Framework\Yaml' = 'L0'
    'Framework\MathCore' = 'L0'
    'Framework\GameMath' = 'L0'
    'Framework\NetTransport' = 'L0'
    'Framework\Configuration' = 'L0'
    'Framework\CommandLine' = 'L0'
    # L1
    'Framework\Cinematic' = 'L1'
    'Framework\Compression' = 'L1'
    'Framework\Png' = 'L1'
    'Framework\Jpeg' = 'L1'
    'Framework\Ogg' = 'L1'
    'Framework\Mp3' = 'L1'
    'Framework\Sndfile' = 'L1'
    'Framework\Sound' = 'L1'
    'Framework\Mikmod' = 'L1'
    'Framework\Xmi' = 'L1'
    'Framework\M2m' = 'L1'
    'Framework\Midi' = 'L1'
    'Framework\Opl' = 'L1'
    'Framework\Imaging' = 'L1'
    'Framework\Palette' = 'L1'
    'Framework\Wad' = 'L1'
    'Framework\Texture' = 'L1'
    'Framework\Flic' = 'L1'
    # L2
    'Framework\Models' = 'L2'
    'Framework\Audio' = 'L2'
    'Framework\AudioMix' = 'L2'
    'Framework\Input' = 'L2'
    'Framework\Video' = 'L2'
    'Framework\Console' = 'L2'
    'Framework\Screenshot' = 'L2'
    'Framework\Scanner' = 'L2'
    'Framework\Serializer' = 'L2'
    # L3
    'Framework\GameHost' = 'L3'
    'Framework\OpenGlBinding' = 'L3'
    'Framework\OpenGlBinding\Recorder' = 'L3'
    'Framework\PascalScript' = 'L3'
    'Framework\Script' = 'L3'
    'Framework\ScriptHost' = 'L3'
    'Framework\Ddc' = 'L3'
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
    'Libs\GlContext' = 'IdTech1'
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
    'IdTech4\Collision' = 'IdTech4'
    'IdTech4\MapFile' = 'IdTech4'
    'IdTech4\Decl' = 'IdTech4'
    'IdTech4\Gui' = 'IdTech4'
    'IdTech4\BotAi' = 'IdTech4'
    'IdTech4\Aas' = 'IdTech4'
    'IdTech4\Qvm' = 'IdTech4'
    'IdTech4\Pmove' = 'IdTech4'
    'IdTech4\NetQ3' = 'IdTech4'
    'IdTech4\DoomScript' = 'IdTech4'
    # Giochi
    'Games\Keen' = 'Giochi'
    'Games\Greed' = 'Giochi'
    'Games\War' = 'Giochi'
    'Games\Racing' = 'Giochi'
    'Games\XcomAudio' = 'Giochi'
    'Games\XcomBasescape' = 'Giochi'
    'Games\XcomBattle' = 'Giochi'
    'Games\XcomBattleStates' = 'Giochi'
    'Games\XcomBattlescape' = 'Giochi'
    'Games\XcomDebriefing' = 'Giochi'
    'Games\XcomEngine' = 'Giochi'
    'Games\XcomFormats' = 'Giochi'
    'Games\XcomGeoscape' = 'Giochi'
    'Games\XcomMenu' = 'Giochi'
    'Games\XcomMod' = 'Giochi'
    'Games\XcomSave' = 'Giochi'
    'Games\XcomStrategy' = 'Giochi'
    'Games\XcomSurface' = 'Giochi'
    'Games\XcomUfopaedia' = 'Giochi'
    'Games\XcomUi' = 'Giochi'
    # Strumenti
    'Strumenti\Ide' = 'Strumenti'
    'Strumenti\ToolsCore' = 'Strumenti'
    'Strumenti\EndoomEditor' = 'Strumenti'
    'Strumenti\Font' = 'Strumenti'
    'Strumenti\FontEditor' = 'Strumenti'
    'Strumenti\VoxelEditor' = 'Strumenti'
    'Strumenti\Launcher' = 'Strumenti'
    # Cartelle dei prodotti
    'Base' = 'IdTech1'
    'Common' = 'IdTech1'
    'Doom' = 'IdTech1'
    'Heretic' = 'IdTech1'
    'Hexen' = 'IdTech1'
    'Strife' = 'IdTech1'
    'Radix' = 'IdTech1'
    'Speed' = 'IdTech1'
    'Games\OpenXcom' = 'Giochi'
    'Strumenti\DD_IDE' = 'Strumenti'
    'Strumenti\DD_Tools' = 'Strumenti'
  }

  # Difetti noti (censimento, docs\FRAMEWORK_CENSIMENTO.md). Ogni voce dice chi la toglie.
  # Massimo = numero di unit di arrivo distinte coperte: piu' unit e' una violazione nuova,
  # meno unit e' una eccezione da ridurre. Ciclo = insieme di aree che si usano a vicenda.
  Eccezioni = @(
    # --- #225: librerie miste (la parte generica va separata da quella di Doom) ---
    @{ Da = 'Libs\Speed'; A = 'Games\Racing'; Massimo = 2; Issue = 226
       Motivo = 'ActorDefinitions, CarSpriteBuilder e SkyTextures di SpeedHaste32 (motore id Tech 1) usano Racing.Types e Racing.CarData (auto e piste, strato Giochi): Speed32 e SpeedHaste32 stanno nella stessa area, da separare quando si spostano le cartelle' }
    # --- #226: cartella di prodotto mista ---
    @{ Da = 'Speed'; A = 'Games\Racing'; Massimo = 9; Issue = 226
       Motivo = 'la cartella Speed ha Speed32 (corse, usa Racing) e SpeedHaste32 (motore id): da separare quando si spostano le cartelle' }
  )
}



