{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the sector functions of PS_GAME                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  TSector and the Get/Set functions of heights, flats, light, tag, texture    }
{  offsets (Doom and Strife only), rotation, flags, gravity, wind, slopes,     }
{  the things and the lines of a sector, its count, the search by tag, the     }
{  sound and MoveZ (the PS_*Sector* of psi_game.pas).                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.World.Sectors;

interface

uses
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>The sector functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptSectors = class(TInterfacedObject, IScriptSectors, IScriptFunctionSection)
  strict private
    FWorld: IScriptWorld;
    FGame: TScriptGame;
  public
    /// <exception cref="EArgumentNilException">If the world is nil</exception>
    constructor Create(const AWorld: IScriptWorld; const AGame: TScriptGame);
    procedure Describe(const ATable: IScriptFunctionTable);
    function TSector(const AId: Integer): Integer;
    function GetSectorFloorHeight(const ASector: Integer): Integer;
    procedure SetSectorFloorHeight(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingHeight(const ASector: Integer): Integer;
    procedure SetSectorCeilingHeight(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorPicture(const ASector: Integer): string;
    procedure SetSectorFloorPicture(const ASector: Integer; const AName: string);
    function GetSectorCeilingPicture(const ASector: Integer): string;
    procedure SetSectorCeilingPicture(const ASector: Integer; const AName: string);
    function GetSectorLightLevel(const ASector: Integer): Integer;
    /// <summary>Takes 0 to 255, and 256 as 255; any other value changes nothing</summary>
    procedure SetSectorLightLevel(const ASector: Integer; const AValue: Integer);
    function GetSectorSpecial(const ASector: Integer): Integer;
    function GetSectorTag(const ASector: Integer): Integer;
    procedure SetSectorTag(const ASector: Integer; const AValue: Integer);
    function GetSectorActors(const ASector: Integer): TArray<Cardinal>;
    function GetSectorNumActors(const ASector: Integer): Integer;
    function GetSectorLines(const ASector: Integer): TArray<Integer>;
    function GetSectorNumLines(const ASector: Integer): Integer;
    function GetSectorFloorXOffset(const ASector: Integer): Integer;
    procedure SetSectorFloorXOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorYOffset(const ASector: Integer): Integer;
    procedure SetSectorFloorYOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingXOffset(const ASector: Integer): Integer;
    procedure SetSectorCeilingXOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingYOffset(const ASector: Integer): Integer;
    procedure SetSectorCeilingYOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorAngle(const ASector: Integer): Cardinal;
    procedure SetSectorFloorAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorFloorAngleX(const ASector: Integer): Integer;
    procedure SetSectorFloorAngleX(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorAngleY(const ASector: Integer): Integer;
    procedure SetSectorFloorAngleY(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingAngle(const ASector: Integer): Cardinal;
    procedure SetSectorCeilingAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorCeilingAngleX(const ASector: Integer): Integer;
    procedure SetSectorCeilingAngleX(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingAngleY(const ASector: Integer): Integer;
    procedure SetSectorCeilingAngleY(const ASector: Integer; const AValue: Integer);
    function GetSectorRippleFloor(const ASector: Integer): Boolean;
    procedure SetSectorRippleFloor(const ASector: Integer; const AValue: Boolean);
    function GetSectorRippleCeiling(const ASector: Integer): Boolean;
    procedure SetSectorRippleCeiling(const ASector: Integer; const AValue: Boolean);
    function GetSectorInterpolate(const ASector: Integer): Boolean;
    procedure SetSectorInterpolate(const ASector: Integer; const AValue: Boolean);
    function GetSectorFog(const ASector: Integer): Boolean;
    procedure SetSectorFog(const ASector: Integer; const AValue: Boolean);
    /// <summary>The gravity of the sector; a sector that is not there gives the normal gravity (FRACUNIT)</summary>
    function GetSectorGravity(const ASector: Integer): Integer;
    procedure SetSectorGravity(const ASector: Integer; const AValue: Integer);
    /// <summary>The old code gave the normal gravity (not 0) for a sector that is not there, and it is kept</summary>
    function GetSectorWindThrust(const ASector: Integer): Integer;
    procedure SetSectorWindThrust(const ASector: Integer; const AValue: Integer);
    /// <summary>The old code gave the normal gravity (not 0) for a sector that is not there, and it is kept</summary>
    function GetSectorWindAngle(const ASector: Integer): Cardinal;
    procedure SetSectorWindAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorMidSector(const ASector: Integer): Integer;
    function GetSectorSlopeSector(const ASector: Integer): Integer;
    function SkyPicture: string;
    function IsValidSector(const ASector: Integer): Boolean;
    function GetSectorCount: Integer;
    /// <summary>The numbers of the sectors that have the tag, in the order of the level</summary>
    function FindSectorsFromTag(const ATag: Integer): TArray<Integer>;
    procedure SectorPlaySound(const ASector: Integer; const AName: string);
    procedure SectorMoveZ(const ASector: Integer; const ADelta: Integer);
    procedure SetSectorFloorSlope(const ASector: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
    procedure SetSectorCeilingSlope(const ASector: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
  end;

implementation

uses
  System.SysUtils;

const
  /// <summary>The normal gravity (FRACUNIT), that the old code also gave for the wind of a sector that is not there</summary>
  SECTOR_NORMAL_GRAVITY = 65536;

{ TScriptSectors }

constructor TScriptSectors.Create(const AWorld: IScriptWorld; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
  FGame := AGame;
end;

procedure TScriptSectors.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethodWithCustomResult('procedure TSector(const id: Integer);', '!TSector',
    'function TSector(const id: Integer): !TSector;', Self, @TScriptSectors.TSector);
  ATable.AddMethod('function GetSectorFloorHeight(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorFloorHeight);
  ATable.AddMethod('procedure SetSectorFloorHeight(const sec: Integer; const x: fixed_t);', Self,
    @TScriptSectors.SetSectorFloorHeight);
  ATable.AddMethod('function GetSectorCeilingHeight(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorCeilingHeight);
  ATable.AddMethod('procedure SetSectorCeilingHeight(const sec: Integer; const x: fixed_t);', Self,
    @TScriptSectors.SetSectorCeilingHeight);
  ATable.AddMethod('function GetSectorFloorPicture(const sec: Integer): string;', Self,
    @TScriptSectors.GetSectorFloorPicture);
  ATable.AddMethod('procedure SetSectorFloorPicture(const sec: Integer; const pic: string);', Self,
    @TScriptSectors.SetSectorFloorPicture);
  ATable.AddMethod('function GetSectorCeilingPicture(const sec: Integer): string;', Self,
    @TScriptSectors.GetSectorCeilingPicture);
  ATable.AddMethod('procedure SetSectorCeilingPicture(const sec: Integer; const pic: string);', Self,
    @TScriptSectors.SetSectorCeilingPicture);
  ATable.AddMethod('function GetSectorLightLevel(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorLightLevel);
  ATable.AddMethod('procedure SetSectorLightLevel(const sec: Integer; const x: Integer);', Self,
    @TScriptSectors.SetSectorLightLevel);
  ATable.AddMethod('function GetSectorSpecial(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorSpecial);
  ATable.AddMethod('function GetSectorTag(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorTag);
  ATable.AddMethod('procedure SetSectorTag(const sec: Integer; const x: Integer);', Self,
    @TScriptSectors.SetSectorTag);
  ATable.AddMethod('function GetSectorActors(const sec: Integer): TActorArray;', Self,
    @TScriptSectors.GetSectorActors);
  ATable.AddMethod('function GetSectorNumActors(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorNumActors);
  ATable.AddMethod('function GetSectorLines(const sec: Integer): TIntegerArray;', Self,
    @TScriptSectors.GetSectorLines);
  ATable.AddMethod('function GetSectorNumLines(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorNumLines);
  // the offsets of the textures exist in Doom and Strife only
  if FGame in [sgDoom, sgStrife] then
  begin
    ATable.AddMethod('function GetSectorFloorXOffset(const sec: Integer): fixed_t;', Self,
      @TScriptSectors.GetSectorFloorXOffset);
    ATable.AddMethod('procedure SetSectorFloorXOffset(const sec: Integer; const offs: fixed_t);', Self,
      @TScriptSectors.SetSectorFloorXOffset);
    ATable.AddMethod('function GetSectorFloorYOffset(const sec: Integer): fixed_t;', Self,
      @TScriptSectors.GetSectorFloorYOffset);
    ATable.AddMethod('procedure SetSectorFloorYOffset(const sec: Integer; const offs: fixed_t);', Self,
      @TScriptSectors.SetSectorFloorYOffset);
    ATable.AddMethod('function GetSectorCeilingXOffset(const sec: Integer): fixed_t;', Self,
      @TScriptSectors.GetSectorCeilingXOffset);
    ATable.AddMethod('procedure SetSectorCeilingXOffset(const sec: Integer; const offs: fixed_t);', Self,
      @TScriptSectors.SetSectorCeilingXOffset);
    ATable.AddMethod('function GetSectorCeilingYOffset(const sec: Integer): fixed_t;', Self,
      @TScriptSectors.GetSectorCeilingYOffset);
    ATable.AddMethod('procedure SetSectorCeilingYOffset(const sec: Integer; const offs: fixed_t);', Self,
      @TScriptSectors.SetSectorCeilingYOffset);
  end;
  ATable.AddMethod('function GetSectorFloorAngle(const sec: Integer): angle_t;', Self,
    @TScriptSectors.GetSectorFloorAngle);
  ATable.AddMethod('procedure SetSectorFloorAngle(const sec: Integer; const ang: angle_t);', Self,
    @TScriptSectors.SetSectorFloorAngle);
  ATable.AddMethod('function GetSectorFloorAngleX(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorFloorAngleX);
  ATable.AddMethod('procedure SetSectorFloorAngleX(const sec: Integer; const angx: fixed_t);', Self,
    @TScriptSectors.SetSectorFloorAngleX);
  ATable.AddMethod('function GetSectorFloorAngleY(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorFloorAngleY);
  ATable.AddMethod('procedure SetSectorFloorAngleY(const sec: Integer; const angy: fixed_t);', Self,
    @TScriptSectors.SetSectorFloorAngleY);
  ATable.AddMethod('function GetSectorCeilingAngle(const sec: Integer): angle_t;', Self,
    @TScriptSectors.GetSectorCeilingAngle);
  ATable.AddMethod('procedure SetSectorCeilingAngle(const sec: Integer; const ang: angle_t);', Self,
    @TScriptSectors.SetSectorCeilingAngle);
  ATable.AddMethod('function GetSectorCeilingAngleX(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorCeilingAngleX);
  ATable.AddMethod('procedure SetSectorCeilingAngleX(const sec: Integer; const angx: fixed_t);', Self,
    @TScriptSectors.SetSectorCeilingAngleX);
  ATable.AddMethod('function GetSectorCeilingAngleY(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorCeilingAngleY);
  ATable.AddMethod('procedure SetSectorCeilingAngleY(const sec: Integer; const angy: fixed_t);', Self,
    @TScriptSectors.SetSectorCeilingAngleY);
  ATable.AddMethod('function GetSectorRippleFloor(const sec: Integer): Boolean;', Self,
    @TScriptSectors.GetSectorRippleFloor);
  ATable.AddMethod('procedure SetSectorRippleFloor(const sec: Integer; const rpl: Boolean);', Self,
    @TScriptSectors.SetSectorRippleFloor);
  ATable.AddMethod('function GetSectorRippleCeiling(const sec: Integer): Boolean;', Self,
    @TScriptSectors.GetSectorRippleCeiling);
  ATable.AddMethod('procedure SetSectorRippleCeiling(const sec: Integer; const rpl: Boolean);', Self,
    @TScriptSectors.SetSectorRippleCeiling);
  ATable.AddMethod('function GetSectorInterpolate(const sec: Integer): Boolean;', Self,
    @TScriptSectors.GetSectorInterpolate);
  ATable.AddMethod('procedure SetSectorInterpolate(const sec: Integer; const intpl: Boolean);', Self,
    @TScriptSectors.SetSectorInterpolate);
  ATable.AddMethod('function GetSectorFog(const sec: Integer): Boolean;', Self,
    @TScriptSectors.GetSectorFog);
  ATable.AddMethod('procedure SetSectorFog(const sec: Integer; const fog: Boolean);', Self,
    @TScriptSectors.SetSectorFog);
  ATable.AddMethod('function GetSectorGravity(const sec: Integer): fixed_t;', Self,
    @TScriptSectors.GetSectorGravity);
  ATable.AddMethod('procedure SetSectorGravity(const sec: Integer; const grav: fixed_t);', Self,
    @TScriptSectors.SetSectorGravity);
  ATable.AddMethod('function GetSectorWindThrust(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorWindThrust);
  ATable.AddMethod('procedure SetSectorWindThrust(const sec: Integer; const wthrust: Integer);', Self,
    @TScriptSectors.SetSectorWindThrust);
  ATable.AddMethod('function GetSectorWindAngle(const sec: Integer): LongWord;', Self,
    @TScriptSectors.GetSectorWindAngle);
  ATable.AddMethod('procedure SetSectorWindAngle(const sec: Integer; const wangle: LongWord);', Self,
    @TScriptSectors.SetSectorWindAngle);
  ATable.AddMethod('function GetSectorMidSector(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorMidSector);
  ATable.AddMethod('function GetSectorSlopeSector(const sec: Integer): Integer;', Self,
    @TScriptSectors.GetSectorSlopeSector);
  ATable.AddMethod('function SkyPicture: string;', Self, @TScriptSectors.SkyPicture);
  ATable.AddMethod('function IsValidSector(const sec: Integer): boolean;', Self,
    @TScriptSectors.IsValidSector);
  ATable.AddMethod('function GetSectorCount: Integer;', Self, @TScriptSectors.GetSectorCount);
  ATable.AddMethod('function FindSectorsFromTag(const tag: integer): TIntegerArray;', Self,
    @TScriptSectors.FindSectorsFromTag);
  ATable.AddMethod('procedure SectorPlaySound(const secid: integer; const snd: string);', Self,
    @TScriptSectors.SectorPlaySound);
  ATable.AddMethod('procedure SectorMoveZ(const secid: integer; const dz: fixed_t);', Self,
    @TScriptSectors.SectorMoveZ);
  ATable.AddMethod('procedure SetSectorFloorSlope(const secid: integer; const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);',
    Self, @TScriptSectors.SetSectorFloorSlope);
  ATable.AddMethod('procedure SetSectorCeilingSlope(const secid: integer; const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);',
    Self, @TScriptSectors.SetSectorCeilingSlope);
end;

function TScriptSectors.TSector(const AId: Integer): Integer;
begin
  if IsValidSector(AId) then
    Result := AId + 1
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptSectors.GetSectorFloorHeight(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorHeight(ASector, splFloor)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorHeight(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorHeight(ASector, splFloor, AValue);
end;

function TScriptSectors.GetSectorCeilingHeight(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorHeight(ASector, splCeiling)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingHeight(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorHeight(ASector, splCeiling, AValue);
end;

function TScriptSectors.GetSectorFloorPicture(const ASector: Integer): string;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorPicture(ASector, splFloor)
  else
    Result := '';
end;

procedure TScriptSectors.SetSectorFloorPicture(const ASector: Integer; const AName: string);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorPicture(ASector, splFloor, AName);
end;

function TScriptSectors.GetSectorCeilingPicture(const ASector: Integer): string;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorPicture(ASector, splCeiling)
  else
    Result := '';
end;

procedure TScriptSectors.SetSectorCeilingPicture(const ASector: Integer; const AName: string);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorPicture(ASector, splCeiling, AName);
end;

function TScriptSectors.GetSectorLightLevel(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorLightLevel(ASector)
  else
    Result := SCRIPT_INVALID_ID;
end;

procedure TScriptSectors.SetSectorLightLevel(const ASector: Integer; const AValue: Integer);
begin
  if not IsValidSector(ASector) then
    Exit;
  if (AValue >= 0) and (AValue < 256) then
    FWorld.SetSectorLightLevel(ASector, AValue)
  else if AValue = 256 then
    FWorld.SetSectorLightLevel(ASector, 255);
end;

function TScriptSectors.GetSectorSpecial(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorSpecial(ASector)
  else
    Result := 0;
end;

function TScriptSectors.GetSectorTag(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorTag(ASector)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorTag(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorTag(ASector, AValue);
end;

function TScriptSectors.GetSectorActors(const ASector: Integer): TArray<Cardinal>;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorActorKeys(ASector)
  else
    SetLength(Result, 0);
end;

function TScriptSectors.GetSectorNumActors(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorActorCount(ASector)
  else
    Result := 0;
end;

function TScriptSectors.GetSectorLines(const ASector: Integer): TArray<Integer>;
var
  LOrder: Integer;
begin
  if IsValidSector(ASector) then
  begin
    SetLength(Result, FWorld.SectorLineCount(ASector));
    for LOrder := 0 to High(Result) do
      Result[LOrder] := FWorld.SectorLineNumber(ASector, LOrder);
  end
  else
    SetLength(Result, 0);
end;

function TScriptSectors.GetSectorNumLines(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorLineCount(ASector)
  else
    Result := 0;
end;

function TScriptSectors.GetSectorFloorXOffset(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorOffset(ASector, ssoFloorX)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorXOffset(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorOffset(ASector, ssoFloorX, AValue);
end;

function TScriptSectors.GetSectorFloorYOffset(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorOffset(ASector, ssoFloorY)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorYOffset(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorOffset(ASector, ssoFloorY, AValue);
end;

function TScriptSectors.GetSectorCeilingXOffset(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorOffset(ASector, ssoCeilingX)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingXOffset(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorOffset(ASector, ssoCeilingX, AValue);
end;

function TScriptSectors.GetSectorCeilingYOffset(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorOffset(ASector, ssoCeilingY)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingYOffset(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorOffset(ASector, ssoCeilingY, AValue);
end;

function TScriptSectors.GetSectorFloorAngle(const ASector: Integer): Cardinal;
begin
  if IsValidSector(ASector) then
    Result := Cardinal(FWorld.SectorAngle(ASector, ssaFloor))
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorAngle(const ASector: Integer; const AValue: Cardinal);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaFloor, Integer(AValue));
end;

function TScriptSectors.GetSectorFloorAngleX(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorAngle(ASector, ssaFloorX)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorAngleX(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaFloorX, AValue);
end;

function TScriptSectors.GetSectorFloorAngleY(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorAngle(ASector, ssaFloorY)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorFloorAngleY(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaFloorY, AValue);
end;

function TScriptSectors.GetSectorCeilingAngle(const ASector: Integer): Cardinal;
begin
  if IsValidSector(ASector) then
    Result := Cardinal(FWorld.SectorAngle(ASector, ssaCeiling))
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingAngle(const ASector: Integer; const AValue: Cardinal);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaCeiling, Integer(AValue));
end;

function TScriptSectors.GetSectorCeilingAngleX(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorAngle(ASector, ssaCeilingX)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingAngleX(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaCeilingX, AValue);
end;

function TScriptSectors.GetSectorCeilingAngleY(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorAngle(ASector, ssaCeilingY)
  else
    Result := 0;
end;

procedure TScriptSectors.SetSectorCeilingAngleY(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorAngle(ASector, ssaCeilingY, AValue);
end;

function TScriptSectors.GetSectorRippleFloor(const ASector: Integer): Boolean;
begin
  Result := IsValidSector(ASector) and FWorld.SectorFlag(ASector, ssfRippleFloor);
end;

procedure TScriptSectors.SetSectorRippleFloor(const ASector: Integer; const AValue: Boolean);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorFlag(ASector, ssfRippleFloor, AValue);
end;

function TScriptSectors.GetSectorRippleCeiling(const ASector: Integer): Boolean;
begin
  Result := IsValidSector(ASector) and FWorld.SectorFlag(ASector, ssfRippleCeiling);
end;

procedure TScriptSectors.SetSectorRippleCeiling(const ASector: Integer; const AValue: Boolean);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorFlag(ASector, ssfRippleCeiling, AValue);
end;

function TScriptSectors.GetSectorInterpolate(const ASector: Integer): Boolean;
begin
  Result := IsValidSector(ASector) and FWorld.SectorFlag(ASector, ssfInterpolate);
end;

procedure TScriptSectors.SetSectorInterpolate(const ASector: Integer; const AValue: Boolean);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorFlag(ASector, ssfInterpolate, AValue);
end;

function TScriptSectors.GetSectorFog(const ASector: Integer): Boolean;
begin
  Result := IsValidSector(ASector) and FWorld.SectorFlag(ASector, ssfFog);
end;

procedure TScriptSectors.SetSectorFog(const ASector: Integer; const AValue: Boolean);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorFlag(ASector, ssfFog, AValue);
end;

function TScriptSectors.GetSectorGravity(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorValue(ASector, ssvGravity)
  else
    Result := SECTOR_NORMAL_GRAVITY;
end;

procedure TScriptSectors.SetSectorGravity(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorValue(ASector, ssvGravity, AValue);
end;

function TScriptSectors.GetSectorWindThrust(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
    Result := FWorld.SectorValue(ASector, ssvWindThrust)
  else
    Result := SECTOR_NORMAL_GRAVITY;
end;

procedure TScriptSectors.SetSectorWindThrust(const ASector: Integer; const AValue: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorValue(ASector, ssvWindThrust, AValue);
end;

function TScriptSectors.GetSectorWindAngle(const ASector: Integer): Cardinal;
begin
  if IsValidSector(ASector) then
    Result := Cardinal(FWorld.SectorValue(ASector, ssvWindAngle))
  else
    Result := SECTOR_NORMAL_GRAVITY;
end;

procedure TScriptSectors.SetSectorWindAngle(const ASector: Integer; const AValue: Cardinal);
begin
  if IsValidSector(ASector) then
    FWorld.SetSectorValue(ASector, ssvWindAngle, Integer(AValue));
end;

function TScriptSectors.GetSectorMidSector(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
  begin
    Result := FWorld.SectorMidSector(ASector);
    if (Result < 0) or (Result >= FWorld.SectorCount) then
      Result := SCRIPT_INVALID_ID;
  end
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptSectors.GetSectorSlopeSector(const ASector: Integer): Integer;
begin
  if IsValidSector(ASector) then
  begin
    Result := FWorld.SectorSlopeSectorId(ASector);
    if Result = SCRIPT_WORLD_NO_SECTOR then
      Result := SCRIPT_INVALID_ID;
  end
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptSectors.SkyPicture: string;
begin
  Result := FWorld.SkyPicture;
end;

function TScriptSectors.IsValidSector(const ASector: Integer): Boolean;
begin
  Result := (ASector >= 0) and (ASector < FWorld.SectorCount);
end;

function TScriptSectors.GetSectorCount: Integer;
begin
  Result := FWorld.SectorCount;
end;

function TScriptSectors.FindSectorsFromTag(const ATag: Integer): TArray<Integer>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, FWorld.SectorCount);
  LCount := 0;
  for LIndex := 0 to FWorld.SectorCount - 1 do
    if FWorld.SectorTag(LIndex) = ATag then
    begin
      Result[LCount] := LIndex;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

procedure TScriptSectors.SectorPlaySound(const ASector: Integer; const AName: string);
begin
  if IsValidSector(ASector) and (AName <> '') then
    FWorld.PlaySectorSound(ASector, AName);
end;

procedure TScriptSectors.SectorMoveZ(const ASector: Integer; const ADelta: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.MoveSectorZ(ASector, ADelta);
end;

procedure TScriptSectors.SetSectorFloorSlope(const ASector: Integer;
  const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetFloorSlope(ASector, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
end;

procedure TScriptSectors.SetSectorCeilingSlope(const ASector: Integer;
  const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
begin
  if IsValidSector(ASector) then
    FWorld.SetCeilingSlope(ASector, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
end;

end.
