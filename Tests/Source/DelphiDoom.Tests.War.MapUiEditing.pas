{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - "Raise dead" of the cheats of        }
{  editing (the corpse that becomes a skeleton)                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiEditing;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Combat.Intf,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>An input with one left click that was just made, at a place of the screen</summary>
  TClickInput = class(TInterfacedObject, IWarUiInput)
  strict private
    FX: Single;
    FY: Single;
    FPressed: Boolean;
  public
    constructor Create(AX, AY: Single; APressed: Boolean);
    function IsButtonHeld(AButton: TWarMouseButton): Boolean;
    function IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
    function IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
    function IsKeyHeld(AKey: TWarKey): Boolean;
    function IsKeyJustPressed(AKey: TWarKey): Boolean;
    function IsKeyJustReleased(AKey: TWarKey): Boolean;
    function GetPositionX: Single;
    function GetPositionY: Single;
  end;

  /// <summary>The spells that were cast, as the model tells them</summary>
  TCountingSpellEvents = class(TInterfacedObject, IWarSpellEvents)
  public
    Casts: Integer;
    procedure SpellCast(const APosition: TWarVec2);
    procedure SummonExpired(const APosition: TWarVec2; AUnitType: Integer);
  end;

  [TestFixture]
  [Category('war')]
  TTestWarMapUiEditing = class
  public
    [Test]
    procedure DovrebbeFareDiUnCadavereVicinoUnoScheletro;
    [Test]
    procedure DovrebbeLasciareStareICadaveriLontani;
    [Test]
    procedure DovrebbeIgnorareUnClicFuoriDallaMappaOSenzaPulsante;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.EntityPool, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.Editing,
  DelphiDoom.Tests.War.CommandRig;

const
  // the camera starts at (300, 300): the tile (20, 20), centre (328, 328), is at the screen point (72 + 28, 12 + 28)
  CAMERA_START = 300;
  TILE_SCREEN_X = 100;
  TILE_SCREEN_Y = 40;

{ TClickInput }

constructor TClickInput.Create(AX, AY: Single; APressed: Boolean);
begin
  inherited Create;
  FX := AX;
  FY := AY;
  FPressed := APressed;
end;

function TClickInput.IsButtonHeld(AButton: TWarMouseButton): Boolean;
begin
  Result := False;
end;

function TClickInput.IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
begin
  Result := FPressed and (AButton = wmbLeft);
end;

function TClickInput.IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
begin
  Result := False;
end;

function TClickInput.IsKeyHeld(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TClickInput.IsKeyJustPressed(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TClickInput.IsKeyJustReleased(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TClickInput.GetPositionX: Single;
begin
  Result := FX;
end;

function TClickInput.GetPositionY: Single;
begin
  Result := FY;
end;

{ TCountingSpellEvents }

procedure TCountingSpellEvents.SpellCast(const APosition: TWarVec2);
begin
  Inc(Casts);
end;

procedure TCountingSpellEvents.SummonExpired(const APosition: TWarVec2; AUnitType: Integer);
begin
end;

{ TTestWarMapUiEditing }

procedure TTestWarMapUiEditing.DovrebbeFareDiUnCadavereVicinoUnoScheletro;
var
  LRig: TCommandRig;
  LEvents: TCountingSpellEvents;
  LEventsRef: IWarSpellEvents;
  LCamera: TWarMapCamera;
  LEditing: TWarMapEditing;
  LCorpse: Integer;
  LId: Word;
  LSlot: Integer;
  LSkeletons: Integer;
begin
  LRig := TCommandRig.Create;
  LEvents := TCountingSpellEvents.Create;
  LEventsRef := LEvents;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, CAMERA_START, CAMERA_START);
  LEditing := TWarMapEditing.Create(LRig.World, nil, LCamera);
  try
    LRig.Context.SpellEvents := LEventsRef;
    LCorpse := LRig.AddCorpse(20, 20);
    LId := LRig.Context.Pool.Slots[LCorpse]^.Id;
    LEditing.SetMode(wemRaiseDead, 0);
    LEditing.Update(TClickInput.Create(TILE_SCREEN_X, TILE_SCREEN_Y, True));
    Assert.AreEqual(1, LEvents.Casts, 'l''incantesimo e'' lanciato una volta');
    // il cadavere non c'e' piu' e al suo posto c'e' uno scheletro
    LSkeletons := 0;
    for LSlot := 1 to 1023 do
      if LRig.Context.Pool.Slots[LSlot]^.Id <> 0 then
        if LRig.Context.Pool.Slots[LSlot]^.HasUnit and TWarUnitClassifier.IsSkeleton(LRig.Context.Pool.Slots[LSlot]^.UnitData.UnitType) then
          Inc(LSkeletons);
    Assert.AreEqual(1, LSkeletons);
    Assert.AreNotEqual<Integer>(LId, LRig.Context.Pool.Slots[LCorpse]^.Id, 'lo slot del cadavere e'' stato liberato');
  finally
    LEditing.Free;
    LCamera.Free;
    LRig.Free;
  end;
end;

procedure TTestWarMapUiEditing.DovrebbeLasciareStareICadaveriLontani;
var
  LRig: TCommandRig;
  LEvents: TCountingSpellEvents;
  LEventsRef: IWarSpellEvents;
  LCamera: TWarMapCamera;
  LEditing: TWarMapEditing;
begin
  LRig := TCommandRig.Create;
  LEvents := TCountingSpellEvents.Create;
  LEventsRef := LEvents;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, CAMERA_START, CAMERA_START);
  LEditing := TWarMapEditing.Create(LRig.World, nil, LCamera);
  try
    LRig.Context.SpellEvents := LEventsRef;
    // lontano piu' di quattro tegole dal clic
    LRig.AddCorpse(30, 30);
    LEditing.SetMode(wemRaiseDead, 0);
    LEditing.Update(TClickInput.Create(TILE_SCREEN_X, TILE_SCREEN_Y, True));
    Assert.AreEqual(0, LEvents.Casts);
  finally
    LEditing.Free;
    LCamera.Free;
    LRig.Free;
  end;
end;

procedure TTestWarMapUiEditing.DovrebbeIgnorareUnClicFuoriDallaMappaOSenzaPulsante;
var
  LRig: TCommandRig;
  LEvents: TCountingSpellEvents;
  LEventsRef: IWarSpellEvents;
  LCamera: TWarMapCamera;
  LEditing: TWarMapEditing;
begin
  LRig := TCommandRig.Create;
  LEvents := TCountingSpellEvents.Create;
  LEventsRef := LEvents;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, CAMERA_START, CAMERA_START);
  LEditing := TWarMapEditing.Create(LRig.World, nil, LCamera);
  try
    LRig.Context.SpellEvents := LEventsRef;
    LRig.AddCorpse(20, 20);
    LEditing.SetMode(wemRaiseDead, 0);
    // senza il pulsante
    LEditing.Update(TClickInput.Create(TILE_SCREEN_X, TILE_SCREEN_Y, False));
    // sul pannello dei comandi e non sulla mappa
    LEditing.Update(TClickInput.Create(10, 100, True));
    // nessun modo
    LEditing.SetMode(wemNone, 0);
    LEditing.Update(TClickInput.Create(TILE_SCREEN_X, TILE_SCREEN_Y, True));
    Assert.AreEqual(0, LEvents.Casts);
  finally
    LEditing.Free;
    LCamera.Free;
    LRig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiEditing);

end.
