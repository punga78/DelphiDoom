{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the fake sectors                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   A sector for the tests: the light level and the special are 16 bit as in the engine, the
  ///   neighbors are other fake sectors (nil is a line with nothing on its other side). The
  ///   neighbors are plain references: the world below keeps every sector alive
  /// </summary>
  TFakeLightSector = class(TInterfacedObject, ILightSector)
  strict private
    FSpecial: SmallInt;
    FNeighbors: TArray<TFakeLightSector>;
  public
    /// <summary>The level as the 16 bit variable that the thinkers get (a field: it can be passed as var)</summary>
    Level: SmallInt;
    constructor Create(ALightLevel: Integer; ASpecial: Integer);
    procedure SetNeighbors(const ANeighbors: array of TFakeLightSector);
    function GetLightLevel: Integer;
    procedure SetLightLevel(AValue: Integer);
    function GetSpecial: Integer;
    procedure SetSpecial(AValue: Integer);
    function GetNeighborCount: Integer;
    function GetNeighbor(AIndex: Integer): ILightSector;
    function GetHandle: Pointer;
  end;

  /// <summary>Owns the fake sectors of a test</summary>
  TFakeLightWorld = class
  strict private
    FSectors: TList<ILightSector>;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(ALightLevel: Integer; ASpecial: Integer = 0): TFakeLightSector;
    /// <summary>
    ///   A sector with one neighbor for each level given; the level NO_NEIGHBOR is a line with
    ///   nothing on the other side
    /// </summary>
    function AddWithNeighbors(ALightLevel: Integer; const ANeighborLevels: array of Integer): TFakeLightSector;
  end;

  /// <summary>What the fake spawner saw</summary>
  TFakePhaseCall = record
    Sector: TFakeLightSector;
    Base: Integer;
    Index: Integer;
  end;

  /// <summary>A phase spawner that only writes down its calls</summary>
  TFakePhaseSpawner = class(TInterfacedObject, ILightPhaseSpawner)
  strict private
    FCalls: TList<TFakePhaseCall>;
    FPhaseMask: Integer;
  public
    /// <param name="APhaseMask">The bits of the special that the real spawner clears (it is what stops a sequence)</param>
    constructor Create(APhaseMask: Integer);
    destructor Destroy; override;
    procedure SpawnPhased(const ASector: ILightSector; ABase, AIndex: Integer);
    property Calls: TList<TFakePhaseCall> read FCalls;
  end;

const
  /// <summary>In the list of neighbors: a line with no sector on its other side</summary>
  NO_NEIGHBOR = -32768;

/// <summary>
///   A random of the game that starts at a given place of the table: two of them with the same
///   place give the same numbers, which is how the old and the new code are compared
/// </summary>
function CreateTestRandom(APlayIndex: Integer): IGameRandom;

implementation

uses
  DelphiDoom.MathCore.Factory;

{ TFakeLightSector }

constructor TFakeLightSector.Create(ALightLevel: Integer; ASpecial: Integer);
begin
  inherited Create;
  Level := SmallInt(ALightLevel);
  FSpecial := SmallInt(ASpecial);
end;

procedure TFakeLightSector.SetNeighbors(const ANeighbors: array of TFakeLightSector);
var
  LIndex: Integer;
begin
  SetLength(FNeighbors, Length(ANeighbors));
  for LIndex := 0 to High(ANeighbors) do
    FNeighbors[LIndex] := ANeighbors[LIndex];
end;

function TFakeLightSector.GetLightLevel: Integer;
begin
  Result := Level;
end;

procedure TFakeLightSector.SetLightLevel(AValue: Integer);
begin
  Level := SmallInt(AValue);
end;

function TFakeLightSector.GetSpecial: Integer;
begin
  Result := FSpecial;
end;

procedure TFakeLightSector.SetSpecial(AValue: Integer);
begin
  FSpecial := SmallInt(AValue);
end;

function TFakeLightSector.GetNeighborCount: Integer;
begin
  Result := Length(FNeighbors);
end;

function TFakeLightSector.GetNeighbor(AIndex: Integer): ILightSector;
begin
  if FNeighbors[AIndex] = nil then
    Result := nil
  else
    Result := FNeighbors[AIndex];
end;

function TFakeLightSector.GetHandle: Pointer;
begin
  Result := Pointer(Self);
end;

{ TFakeLightWorld }

constructor TFakeLightWorld.Create;
begin
  inherited Create;
  FSectors := TList<ILightSector>.Create;
end;

destructor TFakeLightWorld.Destroy;
begin
  FSectors.Free;
  inherited Destroy;
end;

function TFakeLightWorld.Add(ALightLevel: Integer; ASpecial: Integer): TFakeLightSector;
begin
  Result := TFakeLightSector.Create(ALightLevel, ASpecial);
  // the interface in the list keeps the object alive until the world is freed
  FSectors.Add(Result);
end;

function TFakeLightWorld.AddWithNeighbors(ALightLevel: Integer;
  const ANeighborLevels: array of Integer): TFakeLightSector;
var
  LNeighbors: TArray<TFakeLightSector>;
  LIndex: Integer;
begin
  Result := Add(ALightLevel);
  SetLength(LNeighbors, Length(ANeighborLevels));
  for LIndex := 0 to High(ANeighborLevels) do
    if ANeighborLevels[LIndex] = NO_NEIGHBOR then
      LNeighbors[LIndex] := nil
    else
      LNeighbors[LIndex] := Add(ANeighborLevels[LIndex]);
  Result.SetNeighbors(LNeighbors);
end;

function CreateTestRandom(APlayIndex: Integer): IGameRandom;
begin
  Result := TMathCoreFactory.CreateGameRandom;
  Result.PlayIndex := APlayIndex;
end;

{ TFakePhaseSpawner }

constructor TFakePhaseSpawner.Create(APhaseMask: Integer);
begin
  inherited Create;
  FPhaseMask := APhaseMask;
  FCalls := TList<TFakePhaseCall>.Create;
end;

destructor TFakePhaseSpawner.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

procedure TFakePhaseSpawner.SpawnPhased(const ASector: ILightSector; ABase, AIndex: Integer);
var
  LCall: TFakePhaseCall;
begin
  LCall.Sector := TFakeLightSector(ASector.Handle);
  LCall.Base := ABase;
  LCall.Index := AIndex;
  FCalls.Add(LCall);
  ASector.Special := ASector.Special and not FPhaseMask;
end;

end.
