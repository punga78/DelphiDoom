{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotWeightCache, the weight files the bots share     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_weight.c. Licensed under the GNU General Public License,  }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Intf;

interface

uses
  DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>
  ///   ReadWeightConfig, FreeWeightConfig and BotShutdownWeights: the library keeps the configurations
  ///   it reads (up to 128 files) and owns all of them, so the callers never free one.
  /// </summary>
  IBotWeightCache = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F76}']
    /// <summary>
    ///   ReadWeightConfig: a file already read is retained unless <c>bot_reloadcharacters</c> is set; nil
    ///   (with the message printed) if the file cannot be read or the cache is full.
    /// </summary>
    function ReadWeightConfig(const AFileName: AnsiString): TBotWeightConfig;
    /// <summary>FreeWeightConfig: does nothing unless <c>bot_reloadcharacters</c> is set; then the configuration is released</summary>
    procedure FreeWeightConfig(const AConfig: TBotWeightConfig);
    /// <summary>BotShutdownWeights: releases everything</summary>
    procedure Shutdown;
  end;

implementation

end.
