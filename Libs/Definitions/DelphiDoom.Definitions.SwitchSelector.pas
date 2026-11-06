{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the choice of the switches of a game      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.SwitchSelector;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   The second half of P_InitSwitchList of Doom and Strife: from the table to the pairs
  ///   of texture numbers. (Heretic and Hexen did not filter by episode and did not warn)
  /// </summary>
  TSwitchSelector = class(TInterfacedObject, IDefSwitchSelector)
  private
    FTextures: IDefTextureLookup;
    FLog: ILog;
    function Resolve(const AName: string): Integer;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const ATextures: IDefTextureLookup; const ALog: ILog);
    function Select(const ATable: TArray<TDefSwitchPair>; AMaxEpisode: Integer): TArray<TDefResolvedSwitch>;
  end;

implementation

{ TSwitchSelector }

constructor TSwitchSelector.Create(const ATextures: IDefTextureLookup; const ALog: ILog);
begin
  inherited Create;
  FTextures := ATextures;
  FLog := ALog;
end;

function TSwitchSelector.Resolve(const AName: string): Integer;
begin
  Result := FTextures.CheckTextureNumForName(AName);
  if (Result < 0) and Assigned(FLog) then
    FLog.Warning(Format('P_InitSwitchList(): Unknown texture "%s"'#13#10, [AName]));
end;

function TSwitchSelector.Select(const ATable: TArray<TDefSwitchPair>;
  AMaxEpisode: Integer): TArray<TDefResolvedSwitch>;
var
  LIndex: Integer;
  LCount: Integer;
  LEntry: TDefResolvedSwitch;
begin
  LCount := 0;
  SetLength(Result, Length(ATable));
  for LIndex := 0 to High(ATable) do
  begin
    if (ATable[LIndex].Episode = -1) or (ATable[LIndex].Name1 = '') or (ATable[LIndex].Name2 = '') then
      Break;
    if ATable[LIndex].Episode <= AMaxEpisode then
    begin
      LEntry.Pair := ATable[LIndex];
      LEntry.Texture1 := Resolve(ATable[LIndex].Name1);
      LEntry.Texture2 := Resolve(ATable[LIndex].Name2);
      if (LEntry.Texture1 >= 0) and (LEntry.Texture2 >= 0) then
      begin
        Result[LCount] := LEntry;
        Inc(LCount);
      end;
    end;
  end;
  SetLength(Result, LCount);
end;

end.
