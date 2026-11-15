{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotItemConfig, the item configuration (items.c)       }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): itemconfig_t of     }
{  code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.ItemConfig;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Goal.Types;

type
  /// <summary>itemconfig_t: the item infos that the file items.c defines</summary>
  TBotItemConfig = class
  strict private
    FItems: TArray<TBotItemInfo>;
    function GetCount: Integer;
  public
    /// <summary>Adds an item info; its <c>number</c> is the index it gets</summary>
    procedure Add(var AInfo: TBotItemInfo);
    /// <summary>numiteminfo</summary>
    property Count: Integer read GetCount;
    /// <summary>iteminfo: an index outside the table is an <c>EBotAiException</c> (the original reads outside)</summary>
    function Info(const AIndex: Integer): TBotItemInfo;
  end;

implementation

uses
  DelphiDoom.BotAi.Exceptions;

resourcestring
  SItemOutOfRange = 'The item config has no item info %d';

{ TBotItemConfig }

function TBotItemConfig.GetCount: Integer;
begin
  Result := Length(FItems);
end;

procedure TBotItemConfig.Add(var AInfo: TBotItemInfo);
begin
  AInfo.Number := Length(FItems);
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := AInfo;
end;

function TBotItemConfig.Info(const AIndex: Integer): TBotItemInfo;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise EBotAiException.CreateFmt(SItemOutOfRange, [AIndex]);
  Result := FItems[AIndex];
end;

end.
