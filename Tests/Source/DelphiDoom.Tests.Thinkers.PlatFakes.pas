{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the fake world of the platforms }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlatFakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>A sector for the tests: the heights and what is around it, which the platforms read</summary>
  TFakePlatSector = class
  public
    FloorHeight: Integer;
    CeilingHeight: Integer;
    FloorPicture: Integer;
    Special: Integer;
    LowestSurrounding: Integer;
    HighestSurrounding: Integer;
    NextHigher: Integer;
    constructor Create(AFloorHeight, ACeilingHeight: Integer);
  end;

  /// <summary>
  ///   The game as the platforms see it, written down: the host and the surroundings of the fake
  ///   sectors in one object. The floor moves for real (a small T_MovePlane: up to the destination,
  ///   crushed at the block) so that every branch of a platform happens; everything that is done is
  ///   written in Events, so that two runs can be compared line by line. It does not count its
  ///   references: the test owns it and frees it
  /// </summary>
  TFakePlatWorld = class(TObject, IPlatHost, IPlatSurroundings)
  strict private
    FSectors: TObjectList<TFakePlatSector>;
    FEvents: TStringList;
  public
    /// <summary>The level time that the host answers</summary>
    LevelTime: Integer;
    /// <summary>The host answer for the engine versions after 1.15</summary>
    ModernEngine: Boolean;
    /// <summary>A platform that goes up is crushed when the floor would pass this height</summary>
    BlockHeight: Integer;
    /// <summary>How many times a platform was removed</summary>
    RemoveCount: Integer;
    constructor Create;
    destructor Destroy; override;
    function AddSector(AFloorHeight, ACeilingHeight: Integer): TFakePlatSector;
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    // IPlatHost
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      ADirection: Integer): TPlatMoveResult;
    function GetFloorHeight(ASector: Pointer): Integer;
    procedure PlaySound(ASector: Pointer; ASound: TPlatSound);
    function GetLevelTime: Integer;
    function IsModernEngine: Boolean;
    procedure RemovePlat(APlat: Pointer);
    // IPlatSurroundings
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
    function GetCeilingHeight(ASector: Pointer): Integer;
    procedure SetFloorPicture(ASector: Pointer; APicture: Integer);
    procedure ClearSpecial(ASector: Pointer);
    /// <summary>What was done, one line each (moves, sounds, removals, changes of the sector)</summary>
    property Events: TStringList read FEvents;
  end;

implementation

{ TFakePlatSector }

constructor TFakePlatSector.Create(AFloorHeight, ACeilingHeight: Integer);
begin
  inherited Create;
  FloorHeight := AFloorHeight;
  CeilingHeight := ACeilingHeight;
  LowestSurrounding := AFloorHeight - 64 * 65536;
  HighestSurrounding := AFloorHeight + 96 * 65536;
  NextHigher := AFloorHeight + 24 * 65536;
end;

{ TFakePlatWorld }

constructor TFakePlatWorld.Create;
begin
  inherited Create;
  FSectors := TObjectList<TFakePlatSector>.Create(True);
  FEvents := TStringList.Create;
  ModernEngine := True;
  BlockHeight := MaxInt;
end;

destructor TFakePlatWorld.Destroy;
begin
  FEvents.Free;
  FSectors.Free;
  inherited Destroy;
end;

function TFakePlatWorld.AddSector(AFloorHeight, ACeilingHeight: Integer): TFakePlatSector;
begin
  Result := TFakePlatSector.Create(AFloorHeight, ACeilingHeight);
  FSectors.Add(Result);
end;

function TFakePlatWorld.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := HResult($80004002);
end;

function TFakePlatWorld._AddRef: Integer;
begin
  Result := -1;
end;

function TFakePlatWorld._Release: Integer;
begin
  Result := -1;
end;

function TFakePlatWorld.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
  ADirection: Integer): TPlatMoveResult;
var
  LSector: TFakePlatSector;
begin
  LSector := TFakePlatSector(ASector);
  FEvents.Add(Format('move %d %d %s %d', [ASpeed, ADestination, BoolToStr(ACrush, True), ADirection]));
  Result := TPlatMoveResult.Ok;
  if ADirection < 0 then
  begin
    if LSector.FloorHeight - ASpeed < ADestination then
    begin
      LSector.FloorHeight := ADestination;
      Result := TPlatMoveResult.PastDestination;
    end
    else
      LSector.FloorHeight := LSector.FloorHeight - ASpeed;
  end
  else
  begin
    if LSector.FloorHeight + ASpeed > BlockHeight then
      Result := TPlatMoveResult.Crushed
    else if LSector.FloorHeight + ASpeed > ADestination then
    begin
      LSector.FloorHeight := ADestination;
      Result := TPlatMoveResult.PastDestination;
    end
    else
      LSector.FloorHeight := LSector.FloorHeight + ASpeed;
  end;
end;

function TFakePlatWorld.GetFloorHeight(ASector: Pointer): Integer;
begin
  Result := TFakePlatSector(ASector).FloorHeight;
end;

procedure TFakePlatWorld.PlaySound(ASector: Pointer; ASound: TPlatSound);
const
  SOUND_NAMES: array[TPlatSound] of string = ('move', 'start', 'stop');
begin
  FEvents.Add('sound ' + SOUND_NAMES[ASound]);
end;

function TFakePlatWorld.GetLevelTime: Integer;
begin
  Result := LevelTime;
end;

function TFakePlatWorld.IsModernEngine: Boolean;
begin
  Result := ModernEngine;
end;

procedure TFakePlatWorld.RemovePlat(APlat: Pointer);
begin
  Inc(RemoveCount);
  FEvents.Add('remove');
end;

function TFakePlatWorld.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := TFakePlatSector(ASector).LowestSurrounding;
end;

function TFakePlatWorld.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := TFakePlatSector(ASector).HighestSurrounding;
end;

function TFakePlatWorld.NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
begin
  Result := TFakePlatSector(ASector).NextHigher;
end;

function TFakePlatWorld.GetCeilingHeight(ASector: Pointer): Integer;
begin
  Result := TFakePlatSector(ASector).CeilingHeight;
end;

procedure TFakePlatWorld.SetFloorPicture(ASector: Pointer; APicture: Integer);
begin
  TFakePlatSector(ASector).FloorPicture := APicture;
  FEvents.Add('picture ' + IntToStr(APicture));
end;

procedure TFakePlatWorld.ClearSpecial(ASector: Pointer);
begin
  TFakePlatSector(ASector).Special := 0;
  FEvents.Add('clear special');
end;

end.
