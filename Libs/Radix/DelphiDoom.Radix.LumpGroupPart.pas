{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLumpGroupPart                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateMusic, GenerateMissionText, GenerateMissionBriefing and     }
{  GenerateEndText of radix_xlat_wad.pas: lumps that are copied as they are    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.LumpGroupPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context;

type
  /// <summary>A lump of the DAT that is copied to a lump of the WAD with another name</summary>
  TRadixLumpMapping = record
    RadixName: string;
    WadName: string;
    /// <summary>True: a line of the PK3 entry says which lump it is</summary>
    WithAlias: Boolean;
  end;

  /// <summary>
  ///   A group of lumps that need no conversion (the modules of the music, the texts of the
  ///   missions, the briefings and the end of the episodes). A lump that is not in the DAT is
  ///   skipped
  /// </summary>
  TRadixLumpGroupPart = class(TInterfacedObject, IRadixPart)
  strict private
    FMappings: TArray<TRadixLumpMapping>;
    FFirstRequired: Boolean;
  public
    /// <param name="AMappings">The lumps, in order</param>
    /// <param name="AFirstRequired">True: nothing is copied when the first lump is missing</param>
    constructor Create(const AMappings: TArray<TRadixLumpMapping>; AFirstRequired: Boolean);
    procedure Build(const AContext: TRadixTranslationContext);
    /// <summary>D_INTRO and D_EiMj from "IntroMusic" and "MusicModule[i][j]"; none without the intro</summary>
    class function Music: IRadixPart; static;
    /// <summary>MNTEXTij from "MissionText[i][j]"</summary>
    class function MissionText: IRadixPart; static;
    /// <summary>BRIEF_ij from "MissionBrief[i][j]"</summary>
    class function MissionBriefing: IRadixPart; static;
    /// <summary>CiTEXT from "EndEpisodeiText"</summary>
    class function EndText: IRadixPart; static;
  end;

implementation

function Mapping(const ARadixName, AWadName: string; AWithAlias: Boolean): TRadixLumpMapping;
begin
  Result.RadixName := ARadixName;
  Result.WadName := AWadName;
  Result.WithAlias := AWithAlias;
end;

function Missions(const ARadixFormat, AWadFormat: string; AWithAlias: Boolean): TArray<TRadixLumpMapping>;
var
  LEpisode: Integer;
  LMission: Integer;
begin
  SetLength(Result, 0);
  for LEpisode := 1 to 3 do
    for LMission := 1 to 9 do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Mapping(
        Format(ARadixFormat, [LEpisode, LMission]), Format(AWadFormat, [LEpisode, LMission]), AWithAlias);
    end;
end;

{ TRadixLumpGroupPart }

constructor TRadixLumpGroupPart.Create(const AMappings: TArray<TRadixLumpMapping>;
  AFirstRequired: Boolean);
begin
  inherited Create;
  FMappings := AMappings;
  FFirstRequired := AFirstRequired;
end;

procedure TRadixLumpGroupPart.Build(const AContext: TRadixTranslationContext);
var
  LIndex: Integer;
  LBytes: TBytes;
begin
  for LIndex := 0 to High(FMappings) do
    if AContext.Container.TryRead(FMappings[LIndex].RadixName, LBytes) then
    begin
      AContext.Wad.AddLump(FMappings[LIndex].WadName, LBytes);
      if FMappings[LIndex].WithAlias then
        AContext.AddAlias(FMappings[LIndex].WadName, FMappings[LIndex].RadixName);
    end
    else if (LIndex = 0) and FFirstRequired then
      Exit;
end;

class function TRadixLumpGroupPart.Music: IRadixPart;
var
  LMappings: TArray<TRadixLumpMapping>;
begin
  LMappings := [Mapping('IntroMusic', 'D_INTRO', False)] +
    Missions('MusicModule[%d][%d]', 'D_E%dM%d', False);
  Result := TRadixLumpGroupPart.Create(LMappings, True);
end;

class function TRadixLumpGroupPart.MissionText: IRadixPart;
begin
  Result := TRadixLumpGroupPart.Create(Missions('MissionText[%d][%d]', 'MNTEXT%d%d', True), False);
end;

class function TRadixLumpGroupPart.MissionBriefing: IRadixPart;
begin
  Result := TRadixLumpGroupPart.Create(Missions('MissionBrief[%d][%d]', 'BRIEF_%d%d', True), False);
end;

class function TRadixLumpGroupPart.EndText: IRadixPart;
begin
  Result := TRadixLumpGroupPart.Create([
    Mapping('EndEpisode1Text', 'C1TEXT', True), Mapping('EndEpisode2Text', 'C2TEXT', True),
    Mapping('EndEpisode3Text', 'C3TEXT', True)], False);
end;

end.
