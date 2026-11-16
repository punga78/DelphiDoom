{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightFactory, the composition of the fuzzy weights}
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_weight.c. Licensed under the GNU General Public License,  }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Weight.Intf;

type
  /// <summary>The only place that knows the classes of the weight library</summary>
  TBotWeightFactory = class
  public
    /// <summary>The library of weight files (ReadWeightConfig and its cache)</summary>
    class function CreateWeightCache(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVars): IBotWeightCache; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Weight.Cache;

{ TBotWeightFactory }

class function TBotWeightFactory.CreateWeightCache(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars): IBotWeightCache;
begin
  Result := TBotWeightCache.Create(AImport, AFiles, ALibVars);
end;

end.
