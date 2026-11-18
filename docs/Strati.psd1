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
    @{ Nome = 'Games'; Tipo = 'Modulo'; Ammessi = @(); Titolo = 'Giochi non id: Xcom, Keen, Greed, War, Racing' }
    @{ Nome = 'Strumenti'; Tipo = 'Modulo'; Ammessi = @('IdTech1'); Titolo = 'Strumenti: IDE, editor, Launcher' }
  )

  # Cartelle scartate nella ricerca dei .pas (a qualunque profondita').
  Escluse = @('Tests', 'Tools', 'Reference', 'bin', 'dcu', '__history', 'Win32', 'Win64')

  # Aree che per il grafo contano come una sola (stessi nomi di unit in piu' cartelle).
  Gruppi = @{
    'IdTech1\Doom' = 'GiochiId'
    'IdTech1\Heretic' = 'GiochiId'
    'IdTech1\Hexen' = 'GiochiId'
    'IdTech1\Strife' = 'GiochiId'
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
    'IdTech1\Zone' = 'IdTech1'
    'IdTech1\Acs' = 'IdTech1'
    'IdTech1\ScriptEngine' = 'IdTech1'
    'IdTech1\Actions' = 'IdTech1'
    'IdTech1\ActorDef' = 'IdTech1'
    'IdTech1\Automap' = 'IdTech1'
    'IdTech1\Blockmap' = 'IdTech1'
    'IdTech1\Definitions' = 'IdTech1'
    'IdTech1\Dehacked' = 'IdTech1'
    'IdTech1\DynLights' = 'IdTech1'
    'IdTech1\Demo' = 'IdTech1'
    'IdTech1\Endoom' = 'IdTech1'
    'IdTech1\Glbsp' = 'IdTech1'
    'IdTech1\Hud' = 'IdTech1'
    'IdTech1\Info' = 'IdTech1'
    'IdTech1\Iwad' = 'IdTech1'
    'IdTech1\MapInfo' = 'IdTech1'
    'IdTech1\MusInfo' = 'IdTech1'
    'IdTech1\Net' = 'IdTech1'
    'IdTech1\Nodes' = 'IdTech1'
    'IdTech1\Obituary' = 'IdTech1'
    'IdTech1\Renderer' = 'IdTech1'
    'IdTech1\Specials' = 'IdTech1'
    'IdTech1\TableExport' = 'IdTech1'
    'IdTech1\TextureDefs' = 'IdTech1'
    'IdTech1\Thinkers' = 'IdTech1'
    'IdTech1\Udmf' = 'IdTech1'
    'IdTech1\Voxel' = 'IdTech1'
    'IdTech1\GlAutomap' = 'IdTech1'
    'IdTech1\GlContext' = 'IdTech1'
    'IdTech1\GlLevel' = 'IdTech1'
    'IdTech1\GlMath' = 'IdTech1'
    'IdTech1\GlScene' = 'IdTech1'
    'IdTech1\GlTexture' = 'IdTech1'
    'IdTech1\OpenGl\Legacy' = 'IdTech1'
    'IdTech1\EngineSystem' = 'IdTech1'
    'IdTech1\GameState' = 'IdTech1'
    'IdTech1\GameData' = 'IdTech1'
    'IdTech1\IdTech' = 'IdTech1'
    'IdTech1\Parity' = 'IdTech1'
    'IdTech1\Radix' = 'IdTech1'
    'IdTech1\Speed' = 'IdTech1'
    # IdTech4
    'IdTech4\Collision' = 'IdTech4'
    'IdTech4\MapFile' = 'IdTech4'
    'IdTech4\Decl' = 'IdTech4'
    'IdTech4\Gui' = 'IdTech4'
    'IdTech4\BotAi' = 'IdTech4'
    'IdTech4\Aas' = 'IdTech4'
    'IdTech4\Qvm' = 'IdTech4'
    'IdTech4\Q3Host' = 'IdTech4'
    'IdTech4\Q3Render' = 'IdTech4'
    'IdTech4\D3Host' = 'IdTech4'
    'IdTech4\D3Game' = 'IdTech4'
    'IdTech4\Pmove' = 'IdTech4'
    'IdTech4\NetQ3' = 'IdTech4'
    'IdTech4\DoomScript' = 'IdTech4'
    # Giochi
    'Games\Keen' = 'Games'
    'Games\Greed' = 'Games'
    'Games\War' = 'Games'
    'Games\Racing' = 'Games'
    'Games\XcomAudio' = 'Games'
    'Games\XcomBasescape' = 'Games'
    'Games\XcomBattle' = 'Games'
    'Games\XcomBattleStates' = 'Games'
    'Games\XcomBattlescape' = 'Games'
    'Games\XcomDebriefing' = 'Games'
    'Games\XcomEngine' = 'Games'
    'Games\XcomFormats' = 'Games'
    'Games\XcomGeoscape' = 'Games'
    'Games\XcomMenu' = 'Games'
    'Games\XcomMod' = 'Games'
    'Games\XcomSave' = 'Games'
    'Games\XcomStrategy' = 'Games'
    'Games\XcomSurface' = 'Games'
    'Games\XcomUfopaedia' = 'Games'
    'Games\XcomUi' = 'Games'
    # Strumenti
    'Strumenti\Ide' = 'Strumenti'
    'Strumenti\ToolsCore' = 'Strumenti'
    'Strumenti\EndoomEditor' = 'Strumenti'
    'Strumenti\Font' = 'Strumenti'
    'Strumenti\FontEditor' = 'Strumenti'
    'Strumenti\VoxelEditor' = 'Strumenti'
    'Strumenti\Launcher' = 'Strumenti'
    # Cartelle dei prodotti
    'IdTech1\Base' = 'IdTech1'
    'IdTech1\Common' = 'IdTech1'
    'IdTech1\Doom' = 'IdTech1'
    'IdTech1\Heretic' = 'IdTech1'
    'IdTech1\Hexen' = 'IdTech1'
    'IdTech1\Strife' = 'IdTech1'
    'Games\OpenXcom' = 'Games'
    'Strumenti\DD_IDE' = 'Strumenti'
    'Strumenti\DD_Tools' = 'Strumenti'
  }

  # Difetti noti (censimento, docs\FRAMEWORK_CENSIMENTO.md). Ogni voce dice chi la toglie.
  # Massimo = numero di unit di arrivo distinte coperte: piu' unit e' una violazione nuova,
  # meno unit e' una eccezione da ridurre. Ciclo = insieme di aree che si usano a vicenda.
  Eccezioni = @(
    # --- #225: librerie miste (la parte generica va separata da quella di Doom) ---
    @{ Da = 'IdTech1\Speed'; A = 'Games\Racing'; Massimo = 9; Issue = 226
       Motivo = 'la cartella Speed ha Speed32 (corse, usa Racing) e SpeedHaste32 (motore id; ActorDefinitions, CarSpriteBuilder e SkyTextures usano Racing.Types e Racing.CarData): Speed32 usa anche le unit di IdTech1\Speed (modulo IdTech1), quindi spostarlo in Games cambierebbe questa eccezione in una Games -> IdTech1 senza toglierla'
    }
  )
}



