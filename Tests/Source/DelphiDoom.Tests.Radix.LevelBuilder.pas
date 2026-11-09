{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - a level of Radix made in memory    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelBuilder;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Radix.Level.Types;

type
  /// <summary>Writes the bytes of a level (WorldData[i][j]) as Radix has them</summary>
  TRadixLevelBuilder = class
  strict private
    FSectors: TArray<TRadixLevelSector>;
    FWalls: TArray<TRadixLevelWall>;
    FThings: TArray<TRadixLevelThing>;
    FActionParams: TArray<TArray<SmallInt>>;
    FTriggerActions: TArray<Integer>;
    FPlayerStarts: packed array[0..RADIX_PLAYER_STARTS - 1] of TRadixLevelPlayerStart;
    FOrthogonal: Boolean;
    FTriggerGridValue: SmallInt;
    procedure WriteGrid(const AStream: TStream; AValue: SmallInt);
  public
    constructor Create;
    /// <summary>The sector has the heights and the textures given, no flags and no slope</summary>
    function AddSector(AFloorHeight, ACeilingHeight, AFloorTexture, ACeilingTexture, ALight,
      AFlags: Integer): Integer;
    /// <summary>A wall from (x1, y1) to (x2, y2) in the coordinates of Radix</summary>
    function AddWall(AX1, AY1, AX2, AY2, AFront, ABack: Integer; AFlags: Cardinal): Integer;
    function AddThing(AX, AY, AType, AKey, ASkill, AAngle: Integer): Integer;
    /// <summary>An action with these parameters (so many words as the array has)</summary>
    procedure AddAction(const AParams: TArray<SmallInt>);
    /// <summary>A trigger with this number of actions</summary>
    procedure AddTrigger(AActions: Integer);
    procedure SetPlayerStart(AIndex, AX, AY, AZ, AAngle: Integer);
    function ToBytes: TBytes;
    property Sectors: TArray<TRadixLevelSector> read FSectors;
    property Walls: TArray<TRadixLevelWall> read FWalls;
    property Orthogonal: Boolean read FOrthogonal write FOrthogonal;
    /// <summary>The value of every cell of the first row of the trigger grid</summary>
    property TriggerGridValue: SmallInt read FTriggerGridValue write FTriggerGridValue;
  end;

implementation

{ TRadixLevelBuilder }

constructor TRadixLevelBuilder.Create;
begin
  inherited Create;
  FOrthogonal := True;
  FillChar(FPlayerStarts, SizeOf(FPlayerStarts), 0);
end;

function TRadixLevelBuilder.AddSector(AFloorHeight, ACeilingHeight, AFloorTexture, ACeilingTexture, ALight,
  AFlags: Integer): Integer;
var
  LSector: TRadixLevelSector;
begin
  FillChar(LSector, SizeOf(LSector), 0);
  LSector.FloorHeight := AFloorHeight;
  LSector.CeilingHeight := ACeilingHeight;
  LSector.FloorTexture := AFloorTexture;
  LSector.CeilingTexture := ACeilingTexture;
  LSector.LightLevel := ALight;
  LSector.Flags := AFlags;
  Result := Length(FSectors);
  SetLength(FSectors, Result + 1);
  FSectors[Result] := LSector;
end;

function TRadixLevelBuilder.AddWall(AX1, AY1, AX2, AY2, AFront, ABack: Integer; AFlags: Cardinal): Integer;
var
  LWall: TRadixLevelWall;
begin
  FillChar(LWall, SizeOf(LWall), 0);
  LWall.V1X := AX1;
  LWall.V1Y := AY1;
  LWall.V2X := AX2;
  LWall.V2Y := AY2;
  LWall.FrontSector := AFront;
  LWall.BackSector := ABack;
  LWall.Flags := AFlags;
  LWall.HitPoints := 100;
  Result := Length(FWalls);
  SetLength(FWalls, Result + 1);
  FWalls[Result] := LWall;
end;

function TRadixLevelBuilder.AddThing(AX, AY, AType, AKey, ASkill, AAngle: Integer): Integer;
var
  LThing: TRadixLevelThing;
begin
  FillChar(LThing, SizeOf(LThing), 0);
  LThing.X := AX;
  LThing.Y := AY;
  LThing.RadixType := AType;
  LThing.ThingKey := AKey;
  LThing.Skill := ASkill;
  LThing.Angle := AAngle;
  Result := Length(FThings);
  SetLength(FThings, Result + 1);
  FThings[Result] := LThing;
end;

procedure TRadixLevelBuilder.AddAction(const AParams: TArray<SmallInt>);
begin
  SetLength(FActionParams, Length(FActionParams) + 1);
  FActionParams[High(FActionParams)] := AParams;
end;

procedure TRadixLevelBuilder.AddTrigger(AActions: Integer);
begin
  SetLength(FTriggerActions, Length(FTriggerActions) + 1);
  FTriggerActions[High(FTriggerActions)] := AActions;
end;

procedure TRadixLevelBuilder.SetPlayerStart(AIndex, AX, AY, AZ, AAngle: Integer);
begin
  FPlayerStarts[AIndex].X := AX;
  FPlayerStarts[AIndex].Y := AY;
  FPlayerStarts[AIndex].Z := AZ;
  FPlayerStarts[AIndex].Angle := AAngle;
end;

// Every row is a run: -32000, value, count (a row of the trigger grid starts with its value)
procedure TRadixLevelBuilder.WriteGrid(const AStream: TStream; AValue: SmallInt);
var
  LRow: Integer;
  LWidth: Integer;
  LRows: Integer;
  LMarker: SmallInt;
  LValue: SmallInt;
  LCount: SmallInt;
begin
  if FOrthogonal then
  begin
    LWidth := 320;
    LRows := 128;
  end
  else
  begin
    LWidth := 1280;
    LRows := 32;
  end;
  LMarker := -32000;
  LCount := LWidth;
  for LRow := 0 to LRows - 1 do
  begin
    if LRow = 0 then
      LValue := AValue
    else
      LValue := 0;
    AStream.WriteBuffer(LMarker, 2);
    AStream.WriteBuffer(LValue, 2);
    AStream.WriteBuffer(LCount, 2);
  end;
end;

function TRadixLevelBuilder.ToBytes: TBytes;
var
  LStream: TBytesStream;
  LHeader: TRadixLevelHeader;
  LIndex: Integer;
  LAction: TRadixLevelAction;
  LTrigger: TRadixLevelTrigger;
  LExtra: SmallInt;
  LParams: TArray<SmallInt>;
begin
  LStream := TBytesStream.Create;
  try
    FillChar(LHeader, SizeOf(LHeader), 0);
    LHeader.Id := RADIX_MAP_MAGIC;
    LHeader.NumTriggers := Length(FTriggerActions);
    LHeader.NumActions := Length(FActionParams);
    LHeader.NumWalls := Length(FWalls);
    LHeader.NumSectors := Length(FSectors);
    LHeader.NumThings := Length(FThings);
    LHeader.OrthogonalMap := Ord(FOrthogonal);
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    if Length(FSectors) > 0 then
      LStream.WriteBuffer(FSectors[0], Length(FSectors) * SizeOf(TRadixLevelSector));
    if Length(FWalls) > 0 then
      LStream.WriteBuffer(FWalls[0], Length(FWalls) * SizeOf(TRadixLevelWall));
    WriteGrid(LStream, 0);
    if Length(FThings) > 0 then
      LStream.WriteBuffer(FThings[0], Length(FThings) * SizeOf(TRadixLevelThing));
    WriteGrid(LStream, FTriggerGridValue);
    for LIndex := 0 to High(FActionParams) do
    begin
      FillChar(LAction, SizeOf(LAction), 0);
      LAction.Unknown1 := 1;
      LAction.Enabled := 1;
      LParams := FActionParams[LIndex];
      LExtra := Length(LParams) * 2;
      LAction.ExtraData := LExtra;
      LAction.ActionType := LIndex;
      LStream.WriteBuffer(LAction, RADIX_ACTION_HEADER_SIZE);
      if LExtra > 0 then
        LStream.WriteBuffer(LParams[0], LExtra);
    end;
    for LIndex := 0 to High(FTriggerActions) do
    begin
      FillChar(LTrigger, SizeOf(LTrigger), 0);
      LTrigger.Unknown1 := 1;
      LTrigger.NumActions := FTriggerActions[LIndex];
      LStream.WriteBuffer(LTrigger, RADIX_TRIGGER_HEADER_SIZE);
      for LExtra := 0 to FTriggerActions[LIndex] - 1 do
      begin
        LTrigger.Actions[LExtra].ActionId := LExtra + 1;
        LStream.WriteBuffer(LTrigger.Actions[LExtra], SizeOf(TRadixLevelTriggerAction));
      end;
    end;
    LIndex := Integer(LStream.Size);
    LStream.WriteBuffer(FPlayerStarts, SizeOf(FPlayerStarts));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
    // the position of the player starts is in the header
    Move(LIndex, Result[SizeOf(LHeader) - 4], 4);
  finally
    LStream.Free;
  end;
end;

end.
