{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelPart                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateLevels and GenerateSimpleLevels of radix_xlat_wad.pas       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.LevelPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context, DelphiDoom.Radix.Level.Converter;

type
  /// <summary>E1M1 to E3M9 from the lumps "WorldData[i][j]"; the flats the sectors use are marked in the context</summary>
  TRadixLevelPart = class(TInterfacedObject, IRadixPart)
  strict private
    FConverter: TRadixLevelConverter;
    FExtraInfo: Boolean;
  public
    /// <param name="AConverter">Owned by the part</param>
    /// <param name="AExtraInfo">True for the game (GenerateLevels), false for GenerateSimpleLevels</param>
    constructor Create(const AConverter: TRadixLevelConverter; AExtraInfo: Boolean);
    destructor Destroy; override;
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Level.DoomMap;

{ TRadixLevelPart }

constructor TRadixLevelPart.Create(const AConverter: TRadixLevelConverter; AExtraInfo: Boolean);
begin
  inherited Create;
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  FConverter := AConverter;
  FExtraInfo := AExtraInfo;
end;

destructor TRadixLevelPart.Destroy;
begin
  FConverter.Free;
  inherited Destroy;
end;

procedure TRadixLevelPart.Build(const AContext: TRadixTranslationContext);
var
  LEpisode: Integer;
  LMission: Integer;
  LBytes: TBytes;
  LMarker: TRadixFlatMarker;
begin
  LMarker := procedure(AFlat: Integer)
    begin
      if (AFlat >= 0) and (AFlat < Length(AContext.MarkFlats)) then
        AContext.MarkFlats[AFlat] := True;
    end;
  for LEpisode := 1 to 3 do
    for LMission := 1 to 9 do
      if AContext.Container.TryRead(Format('WorldData[%d][%d]', [LEpisode, LMission]), LBytes) then
        FConverter.Convert(Format('E%dM%d', [LEpisode, LMission]), LBytes, AContext.Wad, FExtraInfo, LMarker);
end;

end.
