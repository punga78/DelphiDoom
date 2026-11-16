{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - what an area says about itself                    }
{                                                                              }
{  Port of AAS_AreaCluster, AAS_AreaPresenceType, AAS_AreaInfo (be_aas_sample.c)}
{  and AAS_AreaReachability, AAS_AreaGrounded ... AAS_AreaDoNotEnter           }
{  (be_aas_reach.c). Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.AreaQuery;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   The settings of an area by its number. The original checks the number only where it
  ///   prints an error (AAS_AreaCluster, AAS_AreaPresenceType, AAS_AreaInfo,
  ///   AAS_AreaReachability) and reads outside the array in AAS_AreaGrounded and the other
  ///   ones; here a number out of range gives 0 (False) everywhere.
  /// </summary>
  TAasAreaQuery = class(TInterfacedObject, IAasAreaQuery)
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    function Valid(const AAreaNum: Integer): Boolean;
    function HasContents(const AAreaNum, AMask: Integer): Boolean;
    function HasFlags(const AAreaNum, AMask: Integer): Boolean;
  public
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    function AreaCluster(const AAreaNum: Integer): Integer;
    function AreaPresenceType(const AAreaNum: Integer): Integer;
    function AreaInfo(const AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
    function AreaReachability(const AAreaNum: Integer): Integer;
    function AreaContents(const AAreaNum: Integer): Integer;
    function AreaFlags(const AAreaNum: Integer): Integer;
    function AreaGrounded(const AAreaNum: Integer): Boolean;
    function AreaLadder(const AAreaNum: Integer): Boolean;
    function AreaLiquid(const AAreaNum: Integer): Boolean;
    function AreaLava(const AAreaNum: Integer): Boolean;
    function AreaSlime(const AAreaNum: Integer): Boolean;
    function AreaJumpPad(const AAreaNum: Integer): Boolean;
    function AreaTeleporter(const AAreaNum: Integer): Boolean;
    function AreaClusterPortal(const AAreaNum: Integer): Boolean;
    function AreaDoNotEnter(const AAreaNum: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer;

resourcestring
  SInvalidAreaCluster = 'AAS_AreaCluster: invalid area number'#10;
  SInvalidAreaPresence = 'AAS_AreaPresenceType: invalid area number'#10;
  SAreaInfoOutOfRange = 'AAS_AreaInfo: areanum %d out of range'#10;
  SReachabilityOutOfRange = 'AAS_AreaReachability: areanum %d out of range';

{ TAasAreaQuery }

constructor TAasAreaQuery.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
end;

function TAasAreaQuery.Valid(const AAreaNum: Integer): Boolean;
begin
  Result := (AAreaNum >= 0) and (AAreaNum < Length(FFile.AreaSettings));
end;

function TAasAreaQuery.HasContents(const AAreaNum, AMask: Integer): Boolean;
begin
  Result := Valid(AAreaNum) and ((FFile.AreaSettings[AAreaNum].Contents and AMask) <> 0);
end;

function TAasAreaQuery.HasFlags(const AAreaNum, AMask: Integer): Boolean;
begin
  Result := Valid(AAreaNum) and ((FFile.AreaSettings[AAreaNum].AreaFlags and AMask) <> 0);
end;

function TAasAreaQuery.AreaCluster(const AAreaNum: Integer): Integer;
begin
  if (AAreaNum <= 0) or (AAreaNum >= Length(FFile.Areas)) or not Valid(AAreaNum) then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, SInvalidAreaCluster);
    Exit(0);
  end;
  Result := FFile.AreaSettings[AAreaNum].Cluster;
end;

function TAasAreaQuery.AreaPresenceType(const AAreaNum: Integer): Integer;
begin
  if (AAreaNum <= 0) or (AAreaNum >= Length(FFile.Areas)) or not Valid(AAreaNum) then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, SInvalidAreaPresence);
    Exit(0);
  end;
  Result := FFile.AreaSettings[AAreaNum].PresenceType;
end;

function TAasAreaQuery.AreaInfo(const AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
var
  LSettings: TAasAreaSettings;
  LArea: TAasArea;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if (AAreaNum <= 0) or (AAreaNum >= Length(FFile.Areas)) or not Valid(AAreaNum) then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SAreaInfoOutOfRange, [AAreaNum]));
    Exit(0);
  end;
  LSettings := FFile.AreaSettings[AAreaNum];
  LArea := FFile.Areas[AAreaNum];
  AInfo.Cluster := LSettings.Cluster;
  AInfo.Contents := LSettings.Contents;
  AInfo.Flags := LSettings.AreaFlags;
  AInfo.PresenceType := LSettings.PresenceType;
  AInfo.Mins := LArea.Mins;
  AInfo.Maxs := LArea.Maxs;
  AInfo.Center := LArea.Center;
  Result := SizeOf(TAasAreaInfo);
end;

function TAasAreaQuery.AreaReachability(const AAreaNum: Integer): Integer;
begin
  if not Valid(AAreaNum) then
  begin
    // AAS_Error: level PRT_FATAL, no line feed in the original message
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SReachabilityOutOfRange, [AAreaNum]));
    Exit(0);
  end;
  Result := FFile.AreaSettings[AAreaNum].NumReachableAreas;
end;

function TAasAreaQuery.AreaContents(const AAreaNum: Integer): Integer;
begin
  if Valid(AAreaNum) then
    Result := FFile.AreaSettings[AAreaNum].Contents
  else
    Result := 0;
end;

function TAasAreaQuery.AreaFlags(const AAreaNum: Integer): Integer;
begin
  if Valid(AAreaNum) then
    Result := FFile.AreaSettings[AAreaNum].AreaFlags
  else
    Result := 0;
end;

function TAasAreaQuery.AreaGrounded(const AAreaNum: Integer): Boolean;
begin
  Result := HasFlags(AAreaNum, AREA_GROUNDED);
end;

function TAasAreaQuery.AreaLadder(const AAreaNum: Integer): Boolean;
begin
  Result := HasFlags(AAreaNum, AREA_LADDER);
end;

function TAasAreaQuery.AreaLiquid(const AAreaNum: Integer): Boolean;
begin
  Result := HasFlags(AAreaNum, AREA_LIQUID);
end;

function TAasAreaQuery.AreaLava(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_LAVA);
end;

function TAasAreaQuery.AreaSlime(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_SLIME);
end;

function TAasAreaQuery.AreaJumpPad(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_JUMPPAD);
end;

function TAasAreaQuery.AreaTeleporter(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_TELEPORTER);
end;

function TAasAreaQuery.AreaClusterPortal(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_CLUSTERPORTAL);
end;

function TAasAreaQuery.AreaDoNotEnter(const AAreaNum: Integer): Boolean;
begin
  Result := HasContents(AAreaNum, AREACONTENTS_DONOTENTER);
end;

end.
