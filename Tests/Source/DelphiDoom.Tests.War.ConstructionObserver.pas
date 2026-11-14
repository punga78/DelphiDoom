{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the host of building and training     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionObserver;

interface

uses
  DelphiDoom.War.Model.Construction.Intf, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>
  ///   The observer of the model that also is the host of building and training: the images of the buildings under
  ///   construction have 1 + resource mod 4 frames (what the stub of war_model_ref.c gives), the sounds are counted and
  ///   their ids mixed in (the stubs of the C do the same: audioId, or from * 1000 + to for a random one, or 9000 + player
  ///   for the acknowledgement), the whole map is known. A test can close a tile to the builders with KnownTiles
  /// </summary>
  TConstructionObserver = class(TModelObserver, IWarConstructionHost)
  strict private
    FUnknownX: Integer;
    FUnknownY: Integer;
    FLastSound: Integer;
    FAcknowledged: Integer;
  public
    constructor Create(ASeed: Cardinal);
    function UnitFrames(AUnitType: Integer): Integer;
    function ConstructionFrames(AUnitType: Integer): Integer;
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    function IsTileKnown(ATileX, ATileY: Integer): Boolean;
    /// <summary>The tile that the fog of war hides (a test of the order of a building); -1 for none</summary>
    procedure HideTile(ATileX, ATileY: Integer);
    /// <summary>The last id given to PlaySound (0 if none), the last range of a random sound is from * 1000 + to</summary>
    property LastSound: Integer read FLastSound;
    /// <summary>How many times the units answered to an order</summary>
    property Acknowledged: Integer read FAcknowledged;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Model.ActionStepData;

{$Q-}
{$R-}

{ TConstructionObserver }

constructor TConstructionObserver.Create(ASeed: Cardinal);
begin
  inherited Create(ASeed);
  FUnknownX := -1;
  FUnknownY := -1;
end;

function TConstructionObserver.UnitFrames(AUnitType: Integer): Integer;
begin
  Result := 0;
end;

function TConstructionObserver.ConstructionFrames(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  LIndex := AUnitType - WAR_BUILDING_FIRST_TYPE;
  if (LIndex < 0) or (LIndex > High(WAR_BUILDING_CONSTRUCTION_RESOURCES)) then
    Exit(0);
  Result := 1 + WAR_BUILDING_CONSTRUCTION_RESOURCES[LIndex] mod 4;
end;

procedure TConstructionObserver.PlaySound(AAudioId: Integer);
begin
  FLastSound := AAudioId;
  AddAudio(Cardinal(AAudioId));
end;

procedure TConstructionObserver.PlayRandomSound(AFromId, AToId: Integer);
begin
  FLastSound := AFromId * 1000 + AToId;
  AddAudio(Cardinal(AFromId) * 1000 + Cardinal(AToId));
end;

procedure TConstructionObserver.Acknowledge(APlayer: Integer);
begin
  Inc(FAcknowledged);
  AddAudio(9000 + Cardinal(APlayer));
end;

function TConstructionObserver.IsTileKnown(ATileX, ATileY: Integer): Boolean;
begin
  Result := not ((ATileX = FUnknownX) and (ATileY = FUnknownY));
end;

procedure TConstructionObserver.HideTile(ATileX, ATileY: Integer);
begin
  FUnknownX := ATileX;
  FUnknownY := ATileY;
end;

end.
