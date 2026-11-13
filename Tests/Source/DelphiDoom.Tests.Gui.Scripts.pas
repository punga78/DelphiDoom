{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - action scripts                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Scripts;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Gui.Types, DelphiDoom.Gui.ScriptCursor,
  DelphiDoom.Gui.Menu, DelphiDoom.Tests.Gui.Fakes;

type
  [TestFixture]
  [Category('gui')]
  TTestGuiScriptCursor = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereLeParoleSeparateDaBlanks;
    [Test]
    procedure DovrebbeLeggereUnaParolaTraVirgoletteConIBlanks;
    [Test]
    procedure DovrebbeSaltareICommenti;
    [Test]
    procedure DovrebbeDareVuotoAFineTesto;
    [Test]
    procedure DovrebbeFermarsiAUnACapo;
    [Test]
    procedure DovrebbeScartareUnaParolaDi1024Caratteri;
    [Test]
    procedure DovrebbeTrattareIByteDa128ComeBlanks;
    [Test]
    procedure DovrebbeTornareIndietroConLoStato;
    [Test]
    procedure DovrebbeLeggereFloatEInteriConAtofEAtoi;
    [Test]
    procedure DovrebbeDareFalsoPerUnaParolaVuota;
    [Test]
    procedure DovrebbeLeggereColoreERettangolo;
  end;

  [TestFixture]
  [Category('gui')]
  TTestGuiScriptRunner = class(TObject)
  private
    FWorld: TGuiWorld;
    function Item(const AName: AnsiString): TGuiItem;
    function Host: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMostrareENascondereUnGruppo;
    [Test]
    procedure DovrebbeFermareLaCinematicaNascondendo;
    [Test]
    procedure DovrebbeDissolvereUnItem;
    [Test]
    procedure DovrebbeColorareLItemStesso;
    [Test]
    procedure DovrebbeColorareUnGruppoConSetItemColor;
    [Test]
    procedure DovrebbeMandareOpenCloseEConditionalOpenAlGioco;
    [Test]
    procedure DovrebbeMandareICvarEIlTestoAlGioco;
    [Test]
    procedure DovrebbeSuonareEIlBrano;
    [Test]
    procedure DovrebbeMandareUnComandoSconosciutoAlGiocoConGliArgomenti;
    [Test]
    procedure DovrebbeSpostareUnItemConTransition;
    [Test]
    procedure DovrebbeTroncareLeDifferenzeDiUnaTransitionComeAbsDiInt;
    [Test]
    procedure DovrebbeDareInfinitoDividendoPerZeroInUnaTransition;
    [Test]
    procedure DovrebbeMettereUnItemInOrbita;
    [Test]
    procedure DovrebbeDareIlFuocoEFarGirareLeFunzioniDelFuoco;
    [Test]
    procedure DovrebbeLeggereIlRestoComeComandiSeUnComandoNonPrendeTutto;
    [Test]
    procedure DovrebbeTagliareLoScriptA1023Caratteri;
    [Test]
    procedure DovrebbeNonFareNullaPerUnItemSenzaMenuNeiComandiCheLoVogliono;
    [Test]
    procedure DovrebbeNonFareNullaSenzaGioco;
    [Test]
    procedure DovrebbeUsareIlColoreDellaSquadra;
    [Test]
    procedure DovrebbeRiconoscereICommandiSenzaMaiuscole;
    [Test]
    procedure DovrebbeTogliereIlFuocoDaTuttiRunnendoLeggereLeaveFocus;
  end;

implementation

uses
  DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.ScriptRunner;

{ TTestGuiScriptCursor }

procedure TTestGuiScriptCursor.DovrebbeLeggereLeParoleSeparateDaBlanks;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create('  show   a ;');
  try
    Assert.AreEqual('show', string(LCursor.ParseExt));
    Assert.AreEqual('a', string(LCursor.ParseExt));
    Assert.AreEqual(';', string(LCursor.ParseExt));
    Assert.AreEqual('', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeLeggereUnaParolaTraVirgoletteConIBlanks;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create('"a b  c" d');
  try
    Assert.AreEqual('a b  c', string(LCursor.ParseExt));
    Assert.AreEqual('d', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeSaltareICommenti;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create('a /* b c */ d // e' + #10 + ' f');
  try
    Assert.AreEqual('a', string(LCursor.ParseExt));
    Assert.AreEqual('d', string(LCursor.ParseExt));
    // the new line that ends the comment stops the word reading (allowLineBreaks is false)
    Assert.AreEqual('', string(LCursor.ParseExt));
    Assert.AreEqual('f', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeDareVuotoAFineTesto;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create('');
  try
    Assert.AreEqual('', string(LCursor.ParseExt));
    Assert.AreEqual('', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeFermarsiAUnACapo;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create('a' + #10 + 'b');
  try
    Assert.AreEqual('a', string(LCursor.ParseExt));
    Assert.AreEqual('', string(LCursor.ParseExt));
    Assert.AreEqual('b', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeScartareUnaParolaDi1024Caratteri;
var
  LCursor: TGuiScriptCursor;
begin
  LCursor := TGuiScriptCursor.Create(AnsiString(StringOfChar('x', 1024)) + ' ok');
  try
    Assert.AreEqual('', string(LCursor.ParseExt));
    Assert.AreEqual('ok', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeTrattareIByteDa128ComeBlanks;
var
  LCursor: TGuiScriptCursor;
begin
  // char is signed in the original: a byte of 128 or more is below the space
  LCursor := TGuiScriptCursor.Create(AnsiString('ab') + AnsiChar(200) + AnsiString('cd'));
  try
    Assert.AreEqual('ab', string(LCursor.ParseExt));
    Assert.AreEqual('cd', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeTornareIndietroConLoStato;
var
  LCursor: TGuiScriptCursor;
  LState: TGuiScriptCursorState;
begin
  LCursor := TGuiScriptCursor.Create('a b');
  try
    LState := LCursor.SaveState;
    LCursor.ParseExt;
    LCursor.RestoreState(LState);
    Assert.AreEqual('a', string(LCursor.ParseExt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeLeggereFloatEInteriConAtofEAtoi;
var
  LCursor: TGuiScriptCursor;
  LFloat: Single;
  LInt: Integer;
begin
  LCursor := TGuiScriptCursor.Create('2.5abc 7xyz');
  try
    Assert.IsTrue(LCursor.ParseFloat(LFloat));
    Assert.AreEqual(Single(2.5), LFloat);
    Assert.IsTrue(LCursor.ParseInt(LInt));
    Assert.AreEqual(7, LInt);
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeDareFalsoPerUnaParolaVuota;
var
  LCursor: TGuiScriptCursor;
  LText: AnsiString;
  LFloat: Single;
  LInt: Integer;
begin
  LCursor := TGuiScriptCursor.Create('');
  try
    Assert.IsFalse(LCursor.ParseString(LText));
    Assert.IsFalse(LCursor.ParseFloat(LFloat));
    Assert.IsFalse(LCursor.ParseInt(LInt));
  finally
    LCursor.Free;
  end;
end;

procedure TTestGuiScriptCursor.DovrebbeLeggereColoreERettangolo;
var
  LCursor: TGuiScriptCursor;
  LColor: TGuiColor;
  LRect: TGuiRect;
begin
  LColor := Default(TGuiColor);
  LRect := Default(TGuiRect);
  LCursor := TGuiScriptCursor.Create('1 2 3 4 5 6 7 8 9');
  try
    Assert.IsTrue(LCursor.ParseColor(LColor));
    Assert.AreEqual(Single(4), LColor[3]);
    Assert.IsTrue(LCursor.ParseRect(LRect));
    Assert.AreEqual(Single(7), LRect.W);
    Assert.IsFalse(LCursor.ParseRect(LRect));
  finally
    LCursor.Free;
  end;
end;

{ TTestGuiScriptRunner }

procedure TTestGuiScriptRunner.Setup;
begin
  FWorld := TGuiWorld.Create;
  FWorld.ParseMenuText(
    'menuDef { name "m" rect 10 20 100 100 border 1 borderSize 2' +
    ' itemDef { name "a" group "g" rect 1 2 3 4 visible 1 onFocus { setcolor backcolor 1 0 0 1 } leaveFocus { setcolor bordercolor 0 0 1 1 } }' +
    ' itemDef { name "b" group "g" rect 5 6 7 8 cinematic "c.roq" }' +
    ' itemDef { name "c" rect 9 10 11 12 decoration }' +
    ' }');
  FWorld.Transcript.Clear;
end;

procedure TTestGuiScriptRunner.TearDown;
begin
  FWorld.Free;
end;

function TTestGuiScriptRunner.Item(const AName: AnsiString): TGuiItem;
begin
  Result := FWorld.Menus[0].FindItemByName(AName);
end;

function TTestGuiScriptRunner.Host: string;
begin
  Result := Trim(FWorld.Transcript.Text);
end;

procedure TTestGuiScriptRunner.DovrebbeMostrareENascondereUnGruppo;
begin
  FWorld.Runner.Run(Item('c'), 'hide g');
  Assert.AreEqual(0, Item('a').Window.Flags and WINDOW_VISIBLE);
  FWorld.Runner.Run(Item('c'), 'show g');
  Assert.AreEqual(WINDOW_VISIBLE, Item('a').Window.Flags and WINDOW_VISIBLE);
  Assert.AreEqual(WINDOW_VISIBLE, Item('b').Window.Flags and WINDOW_VISIBLE);
end;

procedure TTestGuiScriptRunner.DovrebbeFermareLaCinematicaNascondendo;
begin
  Item('b').Window.Cinematic := 5;
  FWorld.Runner.Run(Item('c'), 'hide b');
  Assert.AreEqual('host stopcinematic 5', Host);
  Assert.AreEqual(-1, Item('b').Window.Cinematic);
end;

procedure TTestGuiScriptRunner.DovrebbeDissolvereUnItem;
begin
  FWorld.Runner.Run(Item('c'), 'fadeout a ; fadein b');
  Assert.AreEqual(WINDOW_FADINGOUT or WINDOW_VISIBLE, Item('a').Window.Flags and (WINDOW_FADINGOUT or WINDOW_FADINGIN or WINDOW_VISIBLE));
  Assert.AreEqual(WINDOW_FADINGIN or WINDOW_VISIBLE, Item('b').Window.Flags and (WINDOW_FADINGOUT or WINDOW_FADINGIN or WINDOW_VISIBLE));
end;

procedure TTestGuiScriptRunner.DovrebbeColorareLItemStesso;
begin
  FWorld.Runner.Run(Item('a'), 'setcolor forecolor 0.5 0.25 0.125 1');
  Assert.AreEqual(Single(0.25), Item('a').Window.ForeColor[1]);
  Assert.AreNotEqual(0, Item('a').Window.Flags and WINDOW_FORECOLORSET);
end;

procedure TTestGuiScriptRunner.DovrebbeColorareUnGruppoConSetItemColor;
begin
  FWorld.Runner.Run(Item('c'), 'setitemcolor g backcolor 1 2 3 4');
  Assert.AreEqual(Single(3), Item('a').Window.BackColor[2]);
  Assert.AreEqual(Single(4), Item('b').Window.BackColor[3]);
  Assert.AreEqual(0, Item('a').Window.Flags and WINDOW_BACKCOLORSET);
end;

procedure TTestGuiScriptRunner.DovrebbeMandareOpenCloseEConditionalOpenAlGioco;
begin
  FWorld.Runner.Run(Item('c'), 'open next ; close old ; conditionalopen zero one two ; conditionalopen other one two');
  Assert.AreEqual('host open "next"' + sLineBreak + 'host close "old"' + sLineBreak + 'host open "two"' + sLineBreak +
    'host open "one"', Host);
end;

procedure TTestGuiScriptRunner.DovrebbeMandareICvarEIlTestoAlGioco;
begin
  FWorld.Runner.Run(Item('c'), 'setcvar a b ; setplayermodel sarge ; setplayerhead visor ; exec "map x"');
  Assert.AreEqual('host setcvar "a" "b"' + sLineBreak + 'host setcvar "team_model" "sarge"' + sLineBreak +
    'host setcvar "team_headmodel" "visor"' + sLineBreak + 'host exec 2 "map x ; "', Host);
end;

procedure TTestGuiScriptRunner.DovrebbeSuonareEIlBrano;
begin
  FWorld.Runner.Run(Item('c'), 'play snd/a.wav ; playlooped snd/b.wav');
  Assert.AreEqual('reg sound 1 "snd/a.wav" 0' + sLineBreak + 'host sound 1 6' + sLineBreak + 'host stopbackground' +
    sLineBreak + 'host background "snd/b.wav" "snd/b.wav"', Host);
end;

procedure TTestGuiScriptRunner.DovrebbeMandareUnComandoSconosciutoAlGiocoConGliArgomenti;
begin
  FWorld.Runner.Run(Item('c'), 'uiScript Start "two words" ; hide b');
  Assert.AreEqual('host command "Start" "two words"', Host);
  Assert.AreEqual(0, Item('b').Window.Flags and WINDOW_VISIBLE);
end;

procedure TTestGuiScriptRunner.DovrebbeSpostareUnItemConTransition;
begin
  FWorld.Runner.Run(Item('c'), 'transition a 0 0 10 10 20 30 40 50 1000 4');
  Assert.AreEqual(Single(20), Item('a').Window.RectEffects.X);
  Assert.AreEqual(Single(5), Item('a').Window.RectEffects2.X);
  Assert.AreEqual(Single(7.5), Item('a').Window.RectEffects2.Y);
  Assert.AreEqual(1000, Item('a').Window.OffsetTime);
  Assert.AreNotEqual(0, Item('a').Window.Flags and WINDOW_INTRANSITION);
  // the item is placed from the menu: 10 + border 2 + 0 and 20 + border 2 + 0
  Assert.AreEqual(Single(12), Item('a').Window.Rect.X);
  Assert.AreEqual(Single(22), Item('a').Window.Rect.Y);
end;

procedure TTestGuiScriptRunner.DovrebbeTroncareLeDifferenzeDiUnaTransitionComeAbsDiInt;
begin
  // abs() of the original takes an int: 0.9 becomes 0, -2.9 becomes 2
  FWorld.Runner.Run(Item('c'), 'transition a 0 0 0 0 0.9 -2.9 0 0 0 1');
  Assert.AreEqual(Single(0), Item('a').Window.RectEffects2.X);
  Assert.AreEqual(Single(2), Item('a').Window.RectEffects2.Y);
end;

procedure TTestGuiScriptRunner.DovrebbeDareInfinitoDividendoPerZeroInUnaTransition;
begin
  FWorld.Runner.Run(Item('c'), 'transition a 0 0 0 0 4 0 0 0 0 0');
  Assert.IsTrue(Item('a').Window.RectEffects2.X = Single.PositiveInfinity);
  Assert.IsTrue(Item('a').Window.RectEffects2.Y <> Item('a').Window.RectEffects2.Y);
end;

procedure TTestGuiScriptRunner.DovrebbeMettereUnItemInOrbita;
begin
  FWorld.Runner.Run(Item('c'), 'orbit a 1 2 3 4 500');
  Assert.AreEqual(Single(3), Item('a').Window.RectEffects.X);
  Assert.AreEqual(Single(1), Item('a').Window.RectClient.X);
  Assert.AreEqual(500, Item('a').Window.OffsetTime);
  Assert.AreNotEqual(0, Item('a').Window.Flags and WINDOW_ORBITING);
end;

procedure TTestGuiScriptRunner.DovrebbeDareIlFuocoEFarGirareLeFunzioniDelFuoco;
begin
  FWorld.Runner.Run(Item('c'), 'setfocus a');
  Assert.AreNotEqual(0, Item('a').Window.Flags and WINDOW_HASFOCUS);
  // onFocus of the item ran: its back color
  Assert.AreEqual(Single(1), Item('a').Window.BackColor[0]);
  FWorld.Runner.Run(Item('c'), 'setfocus c');
  // a decoration takes no focus
  Assert.AreNotEqual(0, Item('a').Window.Flags and WINDOW_HASFOCUS);
end;

procedure TTestGuiScriptRunner.DovrebbeLeggereIlRestoComeComandiSeUnComandoNonPrendeTutto;
begin
  FWorld.Runner.Run(Item('c'), 'setcolor nope 9 8 ; show a');
  // "9 8" are commands for the game, up to the ";"
  Assert.AreEqual('host command "8"', Host);
end;

procedure TTestGuiScriptRunner.DovrebbeTagliareLoScriptA1023Caratteri;
var
  LScript: string;
begin
  LScript := StringOfChar(' ', 1023) + 'show a';
  Item('a').Window.Flags := 0;
  FWorld.Runner.Run(Item('c'), AnsiString(LScript));
  Assert.AreEqual(0, Item('a').Window.Flags and WINDOW_VISIBLE);
end;

procedure TTestGuiScriptRunner.DovrebbeNonFareNullaPerUnItemSenzaMenuNeiComandiCheLoVogliono;
var
  LLone: TGuiItem;
begin
  LLone := TGuiItem.Create;
  try
    FWorld.Runner.Run(LLone, 'show a ; hide a ; fadein a ; fadeout a ; setitemcolor a backcolor 1 2 3 4 ; ' +
      'transition a 0 0 0 0 0 0 0 0 0 1 ; orbit a 1 2 3 4 5 ; setfocus a');
    Assert.AreEqual(0, LLone.Window.Flags);
    Assert.AreEqual('', Host);
  finally
    LLone.Free;
  end;
end;

procedure TTestGuiScriptRunner.DovrebbeNonFareNullaSenzaGioco;
var
  LRunner: TGuiScriptRunner;
begin
  LRunner := TGuiScriptRunner.Create(FWorld.Menus.Assets, FWorld.Assets, FWorld.Menus.Strings, nil, nil);
  try
    LRunner.Run(Item('c'), 'open a ; close a ; conditionalopen a b c ; setcvar a b ; exec x ; play a ; playlooped a ; ' +
      'setteamcolor ; unknown arg ; hide b');
    Assert.AreEqual(0, Item('b').Window.Flags and WINDOW_VISIBLE);
  finally
    LRunner.Free;
  end;
end;

procedure TTestGuiScriptRunner.DovrebbeUsareIlColoreDellaSquadra;
begin
  FWorld.Runner.Run(Item('a'), 'setteamcolor');
  Assert.AreEqual(Single(0.5), Item('a').Window.BackColor[1]);
end;

procedure TTestGuiScriptRunner.DovrebbeRiconoscereICommandiSenzaMaiuscole;
begin
  FWorld.Runner.Run(Item('c'), 'HIDE G ; Show B');
  Assert.AreEqual(0, Item('a').Window.Flags and WINDOW_VISIBLE);
  Assert.AreNotEqual(0, Item('b').Window.Flags and WINDOW_VISIBLE);
end;

procedure TTestGuiScriptRunner.DovrebbeTogliereIlFuocoDaTuttiRunnendoLeggereLeaveFocus;
var
  LHad: TGuiItem;
begin
  Item('a').Window.Flags := Item('a').Window.Flags or WINDOW_HASFOCUS;
  LHad := FWorld.Runner.ClearFocus(FWorld.Menus[0]);
  Assert.IsTrue(LHad = Item('a'));
  Assert.AreEqual(0, Item('a').Window.Flags and WINDOW_HASFOCUS);
  Assert.AreEqual(Single(1), Item('a').Window.BorderColor[2]);
  Assert.IsNull(FWorld.Runner.ClearFocus(nil));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiScriptCursor);
  TDUnitX.RegisterTestFixture(TTestGuiScriptRunner);

end.
