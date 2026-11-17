{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keys of the automap (AM_Responder)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.KeyCommands;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Automap.KeyCommands;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapKeyCommands = class
  strict private
    function DefaultBindings: TAutomapKeyBindings;
    function OldClassify(const ABindings: TAutomapKeyBindings; const AKey: Integer): TAutomapKeyCommand;
  public
    [Test]
    procedure DovrebbeRiconoscereITastiDiDefault;
    [Test]
    procedure DovrebbeDareNessunComandoPerUnTastoSconosciuto;
    [Test]
    procedure DovrebbeDareIlPrimoComandoSeDueTastiCoincidono;
    [Test]
    procedure DovrebbeDareIlComandoFissoSeUnTastoModificabileCoincide;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
  end;

implementation

const
  // the fixed keys of am_map.pas (KEY_RIGHTARROW, KEY_LEFTARROW, KEY_UPARROW, KEY_DOWNARROW, KEY_TAB)
  KEY_RIGHT = $AE;
  KEY_LEFT = $AC;
  KEY_UP = $AD;
  KEY_DOWN = $AF;
  KEY_TAB_CODE = 9;

{ TTestAutomapKeyCommands }

function TTestAutomapKeyCommands.DefaultBindings: TAutomapKeyBindings;
begin
  Result.PanRight := KEY_RIGHT;
  Result.PanLeft := KEY_LEFT;
  Result.PanUp := KEY_UP;
  Result.PanDown := KEY_DOWN;
  Result.ZoomOut := Ord('-');
  Result.ZoomIn := Ord('=');
  Result.ZoomInAlternative := Ord('+');
  Result.Toggle := KEY_TAB_CODE;
  Result.GoBig := Ord('o');
  Result.Follow := Ord('f');
  Result.Grid := Ord('g');
  Result.Rotate := Ord('r');
  Result.Textured := Ord('t');
  Result.Mark := Ord('m');
  Result.ClearMarks := Ord('c');
end;

function TTestAutomapKeyCommands.OldClassify(const ABindings: TAutomapKeyBindings;
  const AKey: Integer): TAutomapKeyCommand;
begin
  // the case and the chain of AM_Responder (keys down), copied; the fixed keys are constants there
  Result := akcNone;
  case AKey of
    KEY_RIGHT: Result := akcPanRight;
    KEY_LEFT: Result := akcPanLeft;
    KEY_UP: Result := akcPanUp;
    KEY_DOWN: Result := akcPanDown;
    Ord('-'): Result := akcZoomOut;
    Ord('='), Ord('+'): Result := akcZoomIn;
    KEY_TAB_CODE: Result := akcToggle;
  else
    if AKey = ABindings.GoBig then
      Result := akcGoBig
    else if AKey = ABindings.Follow then
      Result := akcFollow
    else if AKey = ABindings.Grid then
      Result := akcGrid
    else if AKey = ABindings.Rotate then
      Result := akcRotate
    else if AKey = ABindings.Textured then
      Result := akcTextured
    else if AKey = ABindings.Mark then
      Result := akcMark
    else if AKey = ABindings.ClearMarks then
      Result := akcClearMarks;
  end;
end;

procedure TTestAutomapKeyCommands.DovrebbeRiconoscereITastiDiDefault;
var
  LBindings: TAutomapKeyBindings;
begin
  LBindings := DefaultBindings;
  Assert.AreEqual(Ord(akcPanRight), Ord(TAutomapKeys.Classify(LBindings, KEY_RIGHT)));
  Assert.AreEqual(Ord(akcPanLeft), Ord(TAutomapKeys.Classify(LBindings, KEY_LEFT)));
  Assert.AreEqual(Ord(akcPanUp), Ord(TAutomapKeys.Classify(LBindings, KEY_UP)));
  Assert.AreEqual(Ord(akcPanDown), Ord(TAutomapKeys.Classify(LBindings, KEY_DOWN)));
  Assert.AreEqual(Ord(akcZoomOut), Ord(TAutomapKeys.Classify(LBindings, Ord('-'))));
  Assert.AreEqual(Ord(akcZoomIn), Ord(TAutomapKeys.Classify(LBindings, Ord('='))));
  Assert.AreEqual(Ord(akcZoomIn), Ord(TAutomapKeys.Classify(LBindings, Ord('+'))));
  Assert.AreEqual(Ord(akcToggle), Ord(TAutomapKeys.Classify(LBindings, KEY_TAB_CODE)));
  Assert.AreEqual(Ord(akcGoBig), Ord(TAutomapKeys.Classify(LBindings, Ord('o'))));
  Assert.AreEqual(Ord(akcFollow), Ord(TAutomapKeys.Classify(LBindings, Ord('f'))));
  Assert.AreEqual(Ord(akcGrid), Ord(TAutomapKeys.Classify(LBindings, Ord('g'))));
  Assert.AreEqual(Ord(akcRotate), Ord(TAutomapKeys.Classify(LBindings, Ord('r'))));
  Assert.AreEqual(Ord(akcTextured), Ord(TAutomapKeys.Classify(LBindings, Ord('t'))));
  Assert.AreEqual(Ord(akcMark), Ord(TAutomapKeys.Classify(LBindings, Ord('m'))));
  Assert.AreEqual(Ord(akcClearMarks), Ord(TAutomapKeys.Classify(LBindings, Ord('c'))));
end;

procedure TTestAutomapKeyCommands.DovrebbeDareNessunComandoPerUnTastoSconosciuto;
begin
  Assert.AreEqual(Ord(akcNone), Ord(TAutomapKeys.Classify(DefaultBindings, Ord('z'))));
end;

procedure TTestAutomapKeyCommands.DovrebbeDareIlPrimoComandoSeDueTastiCoincidono;
var
  LBindings: TAutomapKeyBindings;
begin
  LBindings := DefaultBindings;
  LBindings.Grid := Ord('f');
  Assert.AreEqual(Ord(akcFollow), Ord(TAutomapKeys.Classify(LBindings, Ord('f'))));
end;

procedure TTestAutomapKeyCommands.DovrebbeDareIlComandoFissoSeUnTastoModificabileCoincide;
var
  LBindings: TAutomapKeyBindings;
begin
  LBindings := DefaultBindings;
  LBindings.Mark := Ord('-');
  Assert.AreEqual(Ord(akcZoomOut), Ord(TAutomapKeys.Classify(LBindings, Ord('-'))));
end;

procedure TTestAutomapKeyCommands.DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
const
  KEYS: array[0..11] of Integer = (KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN, 45, 61, 43, 9, 111, 102, 103, 99);
var
  LBindings: TAutomapKeyBindings;
  LSeed: Cardinal;
  LRound: Integer;
  LKey: Integer;
  LCount: Integer;

  function Next: Integer;
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    Result := KEYS[(LSeed shr 16) mod Length(KEYS)];
  end;

begin
  LSeed := 12345;
  LCount := 0;
  for LRound := 1 to 3000 do
  begin
    // the fixed keys stay, the keys of the player draw from a small set so that they often coincide
    LBindings := DefaultBindings;
    LBindings.GoBig := Next;
    LBindings.Follow := Next;
    LBindings.Grid := Next;
    LBindings.Rotate := Next;
    LBindings.Textured := Next;
    LBindings.Mark := Next;
    LBindings.ClearMarks := Next;
    for LKey := 0 to 255 do
    begin
      Assert.AreEqual(Ord(OldClassify(LBindings, LKey)), Ord(TAutomapKeys.Classify(LBindings, LKey)),
        Format('round %d key %d', [LRound, LKey]));
      Inc(LCount);
    end;
  end;
  Assert.IsTrue(LCount > 700000);
end;

end.
