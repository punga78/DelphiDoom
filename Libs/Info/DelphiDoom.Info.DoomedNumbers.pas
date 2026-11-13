{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - things found by their editor number       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.DoomedNumbers;

interface

uses
  DelphiDoom.Info.Intf;

type
  /// <summary>
  ///   The thing of a number written in a map (doomednum). The answers are remembered in a
  ///   table of 65536 places, as the old Info_GetMobjNumForDoomNum did
  /// </summary>
  TInfoDoomedNumbers = class sealed
  strict private
    const
      TableSize = $10000;
    var
      FSource: IInfoMobjSource;
      FCache: TArray<Integer>;
  public
    constructor Create(const ASource: IInfoMobjSource);
    /// <summary>
    ///   The thing with the number; -1 if none. The things added by patches (from the end of
    ///   the table back to the last built-in one) come first, then the built-in ones from the
    ///   start. A number the table does not hold is not remembered
    /// </summary>
    function ThingForNumber(const ADoomedNum: Integer): Integer;
  end;

implementation

uses
  System.SysUtils;

{ TInfoDoomedNumbers }

constructor TInfoDoomedNumbers.Create(const ASource: IInfoMobjSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  SetLength(FCache, TableSize);
end;

function TInfoDoomedNumbers.ThingForNumber(const ADoomedNum: Integer): Integer;
var
  LPlace: Integer;
  LIndex: Integer;
  LCount: Integer;
  LBuiltIn: Integer;
begin
  LCount := FSource.Count;
  LBuiltIn := FSource.BuiltInCount;
  LPlace := ADoomedNum mod TableSize;
  if (LPlace >= 0) and (LPlace < TableSize) then
  begin
    LIndex := FCache[LPlace];
    if (LIndex >= 0) and (LIndex < LCount) then
      if FSource.DoomedNum(LIndex) = ADoomedNum then
        Exit(LIndex);
  end;

  for LIndex := LCount - 1 downto LBuiltIn do
    if FSource.DoomedNum(LIndex) = ADoomedNum then
    begin
      // Defect of the old code, not kept: it stored at table[number mod size] even for a negative
      // number, a write before the table; here a negative place is not remembered
      if LPlace >= 0 then
        FCache[LPlace] := LIndex;
      Exit(LIndex);
    end;

  for LIndex := 1 to LBuiltIn - 1 do
    if FSource.DoomedNum(LIndex) = ADoomedNum then
    begin
      if LPlace >= 0 then
        FCache[LPlace] := LIndex;
      Exit(LIndex);
    end;

  Result := -1;
end;

end.
