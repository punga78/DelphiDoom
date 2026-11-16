# Issue #226: mappa vecchio -> nuovo delle cartelle. Letta da Sposta-Fetta.ps1. Solo caratteri ASCII.
# Dir = cartella intera (anche piu' vecchie cartelle nella stessa nuova: il programma di un gioco e la sua libreria),
# File = file singolo (ha la precedenza sulla cartella che lo contiene). Forma: 'vecchio>nuovo'.
@{
  Fette = @(
    @{ Nome = 'Framework'
      Dir = @(
      'Libs\IdLib>Framework\IdLib'
      'Libs\Geometry>Framework\Geometry'
      'Libs\Logging>Framework\Logging'
      'Libs\Platform>Framework\Platform'
      'Libs\Bytes>Framework\Bytes'
      'Libs\Clock>Framework\Clock'
      'Libs\Threading>Framework\Threading'
      'Libs\Zlib>Framework\Zlib'
      'Libs\Yaml>Framework\Yaml'
      'Libs\MathCore>Framework\MathCore'
      'Libs\GameMath>Framework\GameMath'
      'Libs\NetTransport>Framework\NetTransport'
      'Libs\Configuration>Framework\Configuration'
      'Libs\CommandLine>Framework\CommandLine'
      'Libs\Cinematic>Framework\Cinematic'
      'Libs\Compression>Framework\Compression'
      'Libs\Png>Framework\Png'
      'Libs\Jpeg>Framework\Jpeg'
      'Libs\Ogg>Framework\Ogg'
      'Libs\Mp3>Framework\Mp3'
      'Libs\Sndfile>Framework\Sndfile'
      'Libs\Sound>Framework\Sound'
      'Libs\Mikmod>Framework\Mikmod'
      'Libs\Xmi>Framework\Xmi'
      'Libs\M2m>Framework\M2m'
      'Libs\Midi>Framework\Midi'
      'Libs\Opl>Framework\Opl'
      'Libs\Imaging>Framework\Imaging'
      'Libs\Palette>Framework\Palette'
      'Libs\Wad>Framework\Wad'
      'Libs\Texture>Framework\Texture'
      'Libs\Flic>Framework\Flic'
      'Libs\Models>Framework\Models'
      'Libs\Audio>Framework\Audio'
      'Libs\AudioMix>Framework\AudioMix'
      'Libs\Input>Framework\Input'
      'Libs\Video>Framework\Video'
      'Libs\Console>Framework\Console'
      'Libs\Screenshot>Framework\Screenshot'
      'Libs\Scanner>Framework\Scanner'
      'Libs\Serializer>Framework\Serializer'
      'Libs\GameHost>Framework\GameHost'
      'Libs\OpenGlBinding>Framework\OpenGlBinding'
      'Libs\PascalScript>Framework\PascalScript'
      'Libs\Script>Framework\Script'
      'Libs\ScriptHost>Framework\ScriptHost'
      'Libs\Ddc>Framework\Ddc'
      )
      File = @(
      'Libs\STRATI.md>docs\STRATI.md'
      'Libs\Strati.psd1>docs\Strati.psd1'
      )
    }
    @{ Nome = 'IdTech4'
      Dir = @(
      'Libs\Collision>IdTech4\Collision'
      'Libs\MapFile>IdTech4\MapFile'
      'Libs\Decl>IdTech4\Decl'
      'Libs\Gui>IdTech4\Gui'
      'Libs\BotAi>IdTech4\BotAi'
      'Libs\Aas>IdTech4\Aas'
      'Libs\Qvm>IdTech4\Qvm'
      'Libs\Pmove>IdTech4\Pmove'
      'Libs\NetQ3>IdTech4\NetQ3'
      'Libs\DoomScript>IdTech4\DoomScript'
      )
      File = @(
      )
    }
    @{ Nome = 'Games'
      Dir = @(
      'Libs\Keen>Games\Keen'
      'Libs\Greed>Games\Greed'
      'Libs\War>Games\War'
      'Libs\Racing>Games\Racing'
      'Libs\XcomAudio>Games\XcomAudio'
      'Libs\XcomBasescape>Games\XcomBasescape'
      'Libs\XcomBattle>Games\XcomBattle'
      'Libs\XcomBattleStates>Games\XcomBattleStates'
      'Libs\XcomBattlescape>Games\XcomBattlescape'
      'Libs\XcomDebriefing>Games\XcomDebriefing'
      'Libs\XcomEngine>Games\XcomEngine'
      'Libs\XcomFormats>Games\XcomFormats'
      'Libs\XcomGeoscape>Games\XcomGeoscape'
      'Libs\XcomMenu>Games\XcomMenu'
      'Libs\XcomMod>Games\XcomMod'
      'Libs\XcomSave>Games\XcomSave'
      'Libs\XcomStrategy>Games\XcomStrategy'
      'Libs\XcomSurface>Games\XcomSurface'
      'Libs\XcomUfopaedia>Games\XcomUfopaedia'
      'Libs\XcomUi>Games\XcomUi'
      'OpenXcom>Games\OpenXcom'
      'Keen>Games\Keen'
      'Greed>Games\Greed'
      'War>Games\War'
      )
      File = @(
      'War\README.md>Games\War\README.Warcraft32.md'
      'War\CLAUDE.md>Games\War\CLAUDE.Warcraft32.md'
      )
    }
    @{ Nome = 'Strumenti'
      Dir = @(
      'Libs\Ide>Strumenti\Ide'
      'Libs\ToolsCore>Strumenti\ToolsCore'
      'Libs\EndoomEditor>Strumenti\EndoomEditor'
      'Libs\Font>Strumenti\Font'
      'Libs\FontEditor>Strumenti\FontEditor'
      'Libs\VoxelEditor>Strumenti\VoxelEditor'
      'Libs\Launcher>Strumenti\Launcher'
      'Launcher>Strumenti\Launcher'
      'DD_IDE>Strumenti\DD_IDE'
      'DD_Tools>Strumenti\DD_Tools'
      'DoomBuilder>Strumenti\DoomBuilder'
      )
      File = @(
      )
    }
    @{ Nome = 'IdTech1Libs'
      Dir = @(
      'Libs\Zone>IdTech1\Zone'
      'Libs\Acs>IdTech1\Acs'
      'Libs\ScriptEngine>IdTech1\ScriptEngine'
      'Libs\Actions>IdTech1\Actions'
      'Libs\ActorDef>IdTech1\ActorDef'
      'Libs\Automap>IdTech1\Automap'
      'Libs\Blockmap>IdTech1\Blockmap'
      'Libs\Definitions>IdTech1\Definitions'
      'Libs\Dehacked>IdTech1\Dehacked'
      'Libs\DynLights>IdTech1\DynLights'
      'Libs\Endoom>IdTech1\Endoom'
      'Libs\Glbsp>IdTech1\Glbsp'
      'Libs\Hud>IdTech1\Hud'
      'Libs\Info>IdTech1\Info'
      'Libs\Iwad>IdTech1\Iwad'
      'Libs\MapInfo>IdTech1\MapInfo'
      'Libs\MusInfo>IdTech1\MusInfo'
      'Libs\Net>IdTech1\Net'
      'Libs\Nodes>IdTech1\Nodes'
      'Libs\Obituary>IdTech1\Obituary'
      'Libs\Renderer>IdTech1\Renderer'
      'Libs\Specials>IdTech1\Specials'
      'Libs\TableExport>IdTech1\TableExport'
      'Libs\TextureDefs>IdTech1\TextureDefs'
      'Libs\Thinkers>IdTech1\Thinkers'
      'Libs\Udmf>IdTech1\Udmf'
      'Libs\Voxel>IdTech1\Voxel'
      'Libs\GlAutomap>IdTech1\GlAutomap'
      'Libs\GlContext>IdTech1\GlContext'
      'Libs\GlLevel>IdTech1\GlLevel'
      'Libs\GlMath>IdTech1\GlMath'
      'Libs\GlScene>IdTech1\GlScene'
      'Libs\GlTexture>IdTech1\GlTexture'
      'Libs\OpenGl>IdTech1\OpenGl'
      'Libs\EngineSystem>IdTech1\EngineSystem'
      'Libs\GameState>IdTech1\GameState'
      'Libs\GameData>IdTech1\GameData'
      'Libs\IdTech>IdTech1\IdTech'
      'Libs\Parity>IdTech1\Parity'
      'Libs\Radix>IdTech1\Radix'
      'Libs\Speed>IdTech1\Speed'
      'Radix>IdTech1\Radix'
      'Speed>IdTech1\Speed'
      )
      File = @(
      'Speed\README.md>IdTech1\Speed\README.Programmi.md'
      )
    }
    @{ Nome = 'IdTech1Motore'
      Dir = @(
      'Base>IdTech1\Base'
      'Common>IdTech1\Common'
      'Doom>IdTech1\Doom'
      'Heretic>IdTech1\Heretic'
      'Hexen>IdTech1\Hexen'
      'Strife>IdTech1\Strife'
      )
      File = @(
      )
    }
  )
}
