{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the list of the actors, the random   }
{  numbers and the table of the states                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameObjects;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Tests.Keen.VideoFakes;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenObjectList = class(TObject)
  strict private
    FClock: IKeenClock;
    FRefresh: IKeenRefresh;
    FList: IKeenObjectList;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIPrimiDuePostiAlGiocatoreEAlPunteggio;
    [Test]
    procedure DovrebbeLegareIlGiocatoreAlPunteggio;
    [Test]
    procedure DovrebbeMettereIlNuovoAttoreInFondoAllaLista;
    [Test]
    procedure DovrebbeDareUnAttoreAzzeratoEAttivo;
    [Test]
    procedure DovrebbeSegnareIlNuovoAttore;
    [Test]
    procedure DovrebbeScorrereLaListaConNextOf;
    [Test]
    procedure DovrebbeToglierUnAttoreInMezzo;
    [Test]
    procedure DovrebbeLasciareNextAlloAttoreTolto;
    [Test]
    procedure DovrebbeToglierelUltimoAttore;
    [Test]
    procedure DovrebbeRiusareIPostiLiberatiDall;
    [Test]
    procedure DovrebbeTogliereLoSpriteDalRefreshManager;
    [Test]
    procedure DovrebbeRifiutareDiTogliereIlGiocatore;
    [Test]
    procedure DovrebbeRifiutareUnAttoreChePiuNonE;
    [Test]
    procedure DovrebbeRifiutareQuandoLaListaEPiena;
    [Test]
    procedure DovrebbeDareLAttoreFittizioSeLaListaEPiena;
    [Test]
    procedure DovrebbeRicominciareConInit;
    [Test]
    procedure DovrebbeRifiutareUnPostoCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareIlRefreshNullo;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenRandom = class(TObject)
  public
    [Test]
    procedure DovrebbePartireDaZeroSenzaRandomizzare;
    [Test]
    procedure DovrebbePartireDalByteBassoDelTempo;
    [Test]
    procedure DovrebbeFareIlGiroDellaTabella;
    [Test]
    procedure DovrebbeDareSempreGliStessiNumeri;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenStateTable = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereITrediciEDuecentoStati;
    [Test]
    procedure DovrebbeDareLoStatoDiKeenFermo;
    [Test]
    procedure DovrebbeDareLoStatoDellaPortaCheSale;
    [Test]
    procedure DovrebbeAvereNomiDiversi;
    [Test]
    procedure DovrebbeAvereSoloStatiSeguentiCheEsistono;
    [Test]
    procedure DovrebbeAvereSoloFunzioniConosciute;
    [Test]
    procedure DovrebbeAvereLeFormeDentroLaTabellaDegliSprite;
    [Test]
    procedure DovrebbeDareIlNomeDiOgniFunzione;
    [Test]
    procedure DovrebbeCambiareLaCopiaENonLaTabella;
    [Test]
    procedure DovrebbeRifiutareUnoStatoCheNonEsiste;
    [Test]
    procedure DovrebbeDareICapitoliDelleGrafiche;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.ObjectList, DelphiDoom.Keen.Refresh, DelphiDoom.Keen.Video,
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.TileInfo, DelphiDoom.Keen.WorkingMap,
  DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.Random, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.StateTableCopy,
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.AudioIds;

{ TTestKeenObjectList }

procedure TTestKeenObjectList.Setup;
var
  LGraphics: IKeenGraphics;
  LSprites: IKeenSpriteCache;
begin
  LGraphics := TFakeKeenGraphics.Create(1);
  LSprites := TKeenSpriteCache.Create(LGraphics);
  FClock := TKeenManualClock.Create;
  FRefresh := TKeenRefresh.Create(TKeenVideo.Create(TKeenEgaMemory.Create, LGraphics, LSprites), LGraphics,
    TKeenTileInfo.Create(TFakeKeenTiles.EmptyTable), LSprites, FClock);
  FRefresh.NewMap(TKeenWorkingMap.Create(30, 30));
  FList := TKeenObjectList.Create(FRefresh);
end;

procedure TTestKeenObjectList.DovrebbeDareIPrimiDuePostiAlGiocatoreEAlPunteggio;
begin
  Assert.AreEqual(0, Integer(FList.Player^.Slot));
  Assert.AreEqual(1, Integer(FList.ScoreObj^.Slot));
  Assert.AreEqual(2, FList.Count);
  Assert.IsTrue(FList.First = FList.Player);
end;

procedure TTestKeenObjectList.DovrebbeLegareIlGiocatoreAlPunteggio;
begin
  Assert.AreEqual(1, Integer(FList.Player^.Next));
  Assert.AreEqual(-1, Integer(FList.Player^.Prev));
  Assert.AreEqual(0, Integer(FList.ScoreObj^.Prev));
  Assert.AreEqual(-1, Integer(FList.ScoreObj^.Next));
end;

procedure TTestKeenObjectList.DovrebbeMettereIlNuovoAttoreInFondoAllaLista;
var
  LNew: PKeenObject;
begin
  LNew := FList.GetNewObj(False);
  Assert.AreEqual(2, Integer(LNew^.Slot));
  Assert.AreEqual(1, Integer(LNew^.Prev));
  Assert.AreEqual(-1, Integer(LNew^.Next));
  Assert.AreEqual(2, Integer(FList.ScoreObj^.Next));
end;

procedure TTestKeenObjectList.DovrebbeDareUnAttoreAzzeratoEAttivo;
var
  LNew: PKeenObject;
begin
  LNew := FList.GetNewObj(False);
  LNew^.X := 123;
  LNew^.Temp3 := 9;
  FList.RemoveObj(LNew);
  LNew := FList.GetNewObj(False);
  Assert.AreEqual(0, Integer(LNew^.X));
  Assert.AreEqual(0, Integer(LNew^.Temp3));
  Assert.AreEqual(Ord(kaYes), Ord(LNew^.Active));
  Assert.IsTrue(LNew^.NeedToClip);
  Assert.IsFalse(LNew^.NeedToReact);
  Assert.AreEqual(Ord(kcNothing), Ord(LNew^.ObClass));
end;

procedure TTestKeenObjectList.DovrebbeSegnareIlNuovoAttore;
var
  LNew: PKeenObject;
begin
  LNew := FList.GetNewObj(False);
  Assert.IsTrue(FList.New = LNew);
end;

procedure TTestKeenObjectList.DovrebbeScorrereLaListaConNextOf;
var
  LObject: PKeenObject;
  LCount: Integer;
begin
  FList.GetNewObj(False);
  FList.GetNewObj(False);
  LObject := FList.First;
  LCount := 0;
  while Assigned(LObject) do
  begin
    Inc(LCount);
    LObject := FList.NextOf(LObject);
  end;
  Assert.AreEqual(4, LCount);
end;

procedure TTestKeenObjectList.DovrebbeToglierUnAttoreInMezzo;
var
  LFirst: PKeenObject;
  LMiddle: PKeenObject;
  LLast: PKeenObject;
begin
  LFirst := FList.GetNewObj(False);
  LMiddle := FList.GetNewObj(False);
  LLast := FList.GetNewObj(False);
  FList.RemoveObj(LMiddle);
  Assert.AreEqual(Integer(LLast^.Slot), Integer(LFirst^.Next));
  Assert.AreEqual(Integer(LFirst^.Slot), Integer(LLast^.Prev));
  Assert.AreEqual(4, FList.Count);
end;

procedure TTestKeenObjectList.DovrebbeLasciareNextAlloAttoreTolto;
var
  LMiddle: PKeenObject;
  LLast: PKeenObject;
begin
  FList.GetNewObj(False);
  LMiddle := FList.GetNewObj(False);
  LLast := FList.GetNewObj(False);
  FList.RemoveObj(LMiddle);
  // a loop that was on the removed actor can still go on
  Assert.AreEqual(Integer(LLast^.Slot), Integer(LMiddle^.Next));
  Assert.IsTrue(FList.NextOf(LMiddle) = LLast);
end;

procedure TTestKeenObjectList.DovrebbeToglierelUltimoAttore;
var
  LFirst: PKeenObject;
  LLast: PKeenObject;
  LAgain: PKeenObject;
begin
  LFirst := FList.GetNewObj(False);
  LLast := FList.GetNewObj(False);
  FList.RemoveObj(LLast);
  Assert.AreEqual(-1, Integer(LFirst^.Next));
  // the next one goes at the end after the first
  LAgain := FList.GetNewObj(False);
  Assert.AreEqual(Integer(LFirst^.Slot), Integer(LAgain^.Prev));
  Assert.AreEqual(Integer(LAgain^.Slot), Integer(LFirst^.Next));
end;

procedure TTestKeenObjectList.DovrebbeRiusareIPostiLiberatiDall;
var
  LFirst: PKeenObject;
  LSecond: PKeenObject;
  LSlot: Integer;
begin
  LFirst := FList.GetNewObj(False);
  LSecond := FList.GetNewObj(False);
  LSlot := LSecond^.Slot;
  FList.RemoveObj(LSecond);
  FList.RemoveObj(LFirst);
  // the free list goes backwards: the last one that was freed is the first to be used again
  Assert.AreEqual(Integer(LFirst^.Slot), Integer(FList.GetNewObj(False)^.Slot));
  Assert.AreEqual(LSlot, Integer(FList.GetNewObj(False)^.Slot));
end;

procedure TTestKeenObjectList.DovrebbeTogliereLoSpriteDalRefreshManager;
var
  LObject: PKeenObject;
begin
  LObject := FList.GetNewObj(False);
  FRefresh.NewPosition(1000, 1000);
  FRefresh.PlaceSprite(LObject^.Sprite, 1500, 1500, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  Assert.IsTrue(LObject^.Sprite > 0);
  FList.RemoveObj(LObject);
  Assert.AreEqual(0, Integer(LObject^.Sprite));
end;

procedure TTestKeenObjectList.DovrebbeRifiutareDiTogliereIlGiocatore;
begin
  Assert.WillRaise(
    procedure
    begin
      FList.RemoveObj(FList.Player);
    end, EKeenException);
end;

procedure TTestKeenObjectList.DovrebbeRifiutareUnAttoreChePiuNonE;
var
  LDummy: TKeenObject;
begin
  FillChar(LDummy, SizeOf(LDummy), 0);
  LDummy.Slot := 5;
  Assert.WillRaise(
    procedure
    begin
      FList.RemoveObj(@LDummy);
    end, EKeenException);
end;

procedure TTestKeenObjectList.DovrebbeRifiutareQuandoLaListaEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 1 to KEEN_MAXACTORS - 2 do
    FList.GetNewObj(False);
  Assert.AreEqual(KEEN_MAXACTORS, FList.Count);
  Assert.WillRaise(
    procedure
    begin
      FList.GetNewObj(False);
    end, EKeenException);
end;

procedure TTestKeenObjectList.DovrebbeDareLAttoreFittizioSeLaListaEPiena;
var
  LIndex: Integer;
  LDummy: PKeenObject;
  LLast: PKeenObject;
begin
  for LIndex := 1 to KEEN_MAXACTORS - 2 do
    LLast := FList.GetNewObj(False);
  LDummy := FList.GetNewObj(True);
  // an actor that nothing uses: it is not in the list and does not count
  Assert.AreEqual(KEEN_MAXACTORS, FList.Count);
  Assert.AreEqual(-1, Integer(LLast^.Next));
  Assert.IsTrue(FList.New = LDummy);
end;

procedure TTestKeenObjectList.DovrebbeRicominciareConInit;
begin
  FList.GetNewObj(False);
  FList.GetNewObj(False);
  FList.Init;
  Assert.AreEqual(2, FList.Count);
  Assert.AreEqual(0, Integer(FList.Player^.Slot));
  Assert.AreEqual(-1, Integer(FList.ScoreObj^.Next));
end;

procedure TTestKeenObjectList.DovrebbeRifiutareUnPostoCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FList.Objects[KEEN_MAXACTORS];
    end, EKeenException);
  Assert.AreEqual(1, Integer(FList.Objects[1]^.Slot));
end;

procedure TTestKeenObjectList.DovrebbeRifiutareIlRefreshNullo;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenObjectList.Create(nil);
    end, EArgumentNilException);
end;

{ TTestKeenRandom }

procedure TTestKeenRandom.DovrebbePartireDaZeroSenzaRandomizzare;
var
  LRandom: IKeenRandom;
begin
  LRandom := TKeenRandom.Create;
  LRandom.Initialize(False, 77);
  // the index goes up before the byte is read: the first is the one at 1
  Assert.AreEqual(8, Integer(LRandom.RndT));
  Assert.AreEqual(109, Integer(LRandom.RndT));
  Assert.AreEqual(220, Integer(LRandom.RndT));
end;

procedure TTestKeenRandom.DovrebbePartireDalByteBassoDelTempo;
var
  LRandom: IKeenRandom;
begin
  LRandom := TKeenRandom.Create;
  LRandom.Initialize(True, $1F7);
  // the index is $F7: the next byte is the one at $F8 (118)
  Assert.AreEqual(118, Integer(LRandom.RndT));
end;

procedure TTestKeenRandom.DovrebbeFareIlGiroDellaTabella;
var
  LRandom: IKeenRandom;
  LIndex: Integer;
begin
  LRandom := TKeenRandom.Create;
  LRandom.Initialize(True, 254);
  Assert.AreEqual(249, Integer(LRandom.RndT));
  // the index goes round to 0: the first byte of the table is 0
  Assert.AreEqual(0, Integer(LRandom.RndT));
  Assert.AreEqual(8, Integer(LRandom.RndT));
  for LIndex := 1 to 252 do
    LRandom.RndT;
  Assert.AreEqual(236, Integer(LRandom.RndT));
end;

procedure TTestKeenRandom.DovrebbeDareSempreGliStessiNumeri;
var
  LFirst: IKeenRandom;
  LSecond: IKeenRandom;
  LIndex: Integer;
begin
  LFirst := TKeenRandom.Create;
  LSecond := TKeenRandom.Create;
  LFirst.Initialize(False, 0);
  LSecond.Initialize(False, 999);
  for LIndex := 1 to 600 do
    Assert.AreEqual(Integer(LFirst.RndT), Integer(LSecond.RndT));
end;

{ TTestKeenStateTable }

procedure TTestKeenStateTable.DovrebbeAvereITrediciEDuecentoStati;
begin
  Assert.AreEqual(213, KEEN_STATE_COUNT);
  Assert.AreEqual(213, Length(KEEN_STATES));
  Assert.AreEqual(213, TKeenStateTableCopy.CreateGameStates.Count);
end;

procedure TTestKeenStateTable.DovrebbeDareLoStatoDiKeenFermo;
var
  LState: TKeenStateDef;
begin
  LState := KEEN_STATES[KEEN_STATE_S_KEENSTAND];
  Assert.AreEqual('s_keenstand', LState.Name);
  Assert.AreEqual(KEEN_GFX_KEENSTANDLSPR, LState.LeftShape);
  Assert.AreEqual(KEEN_GFX_KEENSTANDRSPR, LState.RightShape);
  Assert.AreEqual(Ord(kpStepThink), Ord(LState.Progress));
  Assert.IsFalse(LState.Skippable);
  Assert.IsTrue(LState.PushToFloor);
  Assert.AreEqual(4, LState.TicTime);
  Assert.AreEqual(0, LState.XMove);
  Assert.AreEqual(16, LState.YMove);
  Assert.AreEqual(KEEN_ACTION_KEENPAUSETHINK, Integer(LState.Think));
  Assert.AreEqual(KEEN_ACTION_KEENCONTACT, Integer(LState.Contact));
  Assert.AreEqual(KEEN_ACTION_KEENSTANDREACT, Integer(LState.React));
  Assert.AreEqual(KEEN_STATE_S_KEENSTAND, LState.NextState);
end;

procedure TTestKeenStateTable.DovrebbeDareLoStatoDellaPortaCheSale;
var
  LState: TKeenStateDef;
begin
  LState := KEEN_STATES[KEEN_STATE_S_DOORRAISE];
  Assert.AreEqual(Ord(kpSlide), Ord(LState.Progress));
  Assert.AreEqual(24, LState.TicTime);
  Assert.AreEqual(32, LState.YMove);
  Assert.AreEqual(KEEN_GFX_DOORSPR, LState.LeftShape);
  Assert.AreEqual(-1, LState.NextState);
  Assert.AreEqual(KEEN_ACTION_DRAWREACT, Integer(LState.React));
  Assert.AreEqual(KEEN_ACTION_NONE, Integer(LState.Think));
end;

procedure TTestKeenStateTable.DovrebbeAvereNomiDiversi;
var
  LNames: TDictionary<string, Boolean>;
  LIndex: Integer;
begin
  LNames := TDictionary<string, Boolean>.Create;
  try
    for LIndex := 0 to High(KEEN_STATES) do
    begin
      Assert.IsFalse(LNames.ContainsKey(KEEN_STATES[LIndex].Name), KEEN_STATES[LIndex].Name);
      LNames.Add(KEEN_STATES[LIndex].Name, True);
    end;
  finally
    LNames.Free;
  end;
end;

procedure TTestKeenStateTable.DovrebbeAvereSoloStatiSeguentiCheEsistono;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(KEEN_STATES) do
    Assert.IsTrue((KEEN_STATES[LIndex].NextState >= -1) and (KEEN_STATES[LIndex].NextState < KEEN_STATE_COUNT),
      KEEN_STATES[LIndex].Name);
end;

procedure TTestKeenStateTable.DovrebbeAvereSoloFunzioniConosciute;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(KEEN_STATES) do
  begin
    Assert.IsTrue(KEEN_STATES[LIndex].Think < KEEN_ACTION_COUNT, KEEN_STATES[LIndex].Name);
    Assert.IsTrue(KEEN_STATES[LIndex].Contact < KEEN_ACTION_COUNT, KEEN_STATES[LIndex].Name);
    Assert.IsTrue(KEEN_STATES[LIndex].React < KEEN_ACTION_COUNT, KEEN_STATES[LIndex].Name);
  end;
end;

procedure TTestKeenStateTable.DovrebbeAvereLeFormeDentroLaTabellaDegliSprite;
var
  LIndex: Integer;
  LShape: Integer;
begin
  for LIndex := 0 to High(KEEN_STATES) do
    for LShape in [KEEN_STATES[LIndex].LeftShape, KEEN_STATES[LIndex].RightShape] do
      // 0 = the think function chooses it, -1 = invisible, otherwise a sprite
      Assert.IsTrue((LShape <= 0) or ((LShape >= KEEN_STARTSPRITES) and (LShape < KEEN_STARTSPRITES + KEEN_NUMSPRITES)),
        KEEN_STATES[LIndex].Name);
end;

procedure TTestKeenStateTable.DovrebbeDareIlNomeDiOgniFunzione;
begin
  Assert.AreEqual('', KEEN_ACTION_NAMES[KEEN_ACTION_NONE]);
  Assert.AreEqual('KeenPauseThink', KEEN_ACTION_NAMES[KEEN_ACTION_KEENPAUSETHINK]);
  Assert.AreEqual('DrawReact', KEEN_ACTION_NAMES[KEEN_ACTION_DRAWREACT]);
  Assert.AreEqual(KEEN_ACTION_COUNT, Length(KEEN_ACTION_NAMES));
end;

procedure TTestKeenStateTable.DovrebbeCambiareLaCopiaENonLaTabella;
var
  LTable: IKeenStateTable;
begin
  LTable := TKeenStateTableCopy.CreateGameStates;
  LTable.SetPushToFloor(KEEN_STATE_S_KEENSTAND, False);
  Assert.IsFalse(LTable[KEEN_STATE_S_KEENSTAND].PushToFloor);
  Assert.IsTrue(KEEN_STATES[KEEN_STATE_S_KEENSTAND].PushToFloor);
  Assert.IsTrue(TKeenStateTableCopy.CreateGameStates[KEEN_STATE_S_KEENSTAND].PushToFloor);
end;

procedure TTestKeenStateTable.DovrebbeRifiutareUnoStatoCheNonEsiste;
var
  LTable: IKeenStateTable;
begin
  LTable := TKeenStateTableCopy.CreateGameStates;
  Assert.WillRaise(
    procedure
    var
      LState: TKeenStateDef;
    begin
      LState := LTable[213];
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      LTable.SetPushToFloor(-1, True);
    end, EKeenException);
end;

procedure TTestKeenStateTable.DovrebbeDareICapitoliDelleGrafiche;
begin
  // the constants of graphkdr.h and audiokdr.h that the table of the states and the engine use
  Assert.AreEqual(80, KEEN_GFX_KEENSTANDLSPR);
  Assert.AreEqual(211, KEEN_GFX_DOORSPR);
  Assert.AreEqual(297, KEEN_GFX_NUMSPRITES);
  Assert.AreEqual(28, KEEN_SND_NUMSOUNDS);
  Assert.AreEqual(0, KEEN_SND_KEENWALK1SND);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenObjectList);
  TDUnitX.RegisterTestFixture(TTestKeenRandom);
  TDUnitX.RegisterTestFixture(TTestKeenStateTable);

end.
