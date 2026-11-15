{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the sprite definitions          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.SpriteDefs;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.Tests.Renderer.Fakes;

type
  /// <summary>The sprite lumps of a WAD made of names: the first lump is FirstLump</summary>
  TFakeSpriteSource = class(TInterfacedObject, IRendererSpriteSource)
  public
    First: Integer;
    Names: TArray<TRendererLumpName>;
    Present: TArray<Boolean>;
    /// <summary>The lump that a modified game uses in place of the lump (-1 when the game is not modified)</summary>
    Patched: TArray<Integer>;
    Developer: Boolean;
    NameCalls: Integer;
    function FirstLump: Integer;
    function LastLump: Integer;
    function IsPresent(ALump: Integer): Boolean;
    function LumpName(ALump: Integer): TRendererLumpName;
    function PatchedLump(ALump: Integer): Integer;
    function DeveloperMode: Boolean;
    procedure Add(const AName: string; APresent: Boolean = True);
  end;

  [TestFixture]
  [Category('renderer')]
  TTestRendererSpriteDefs = class(TObject)
  private
    FSource: TFakeSpriteSource;
    FSourceIntf: IRendererSpriteSource;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FDefs: IRendererSpriteDefs;
    function PackName(const AName: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareUnaSpriteSenzaLump;
    [Test]
    procedure DovrebbeUsareUnSoloLumpPerTutteLeRotazioni;
    [Test]
    procedure DovrebbeInstallareOttoRotazioni;
    [Test]
    procedure DovrebbeInstallareLaVersioneSpecchiataDelLump;
    [Test]
    procedure DovrebbeSegnareSediciETrentaduRotazioni;
    [Test]
    procedure DovrebbeAvvisareSeUnaRotazioneHaDueLump;
    [Test]
    procedure DovrebbeAvvisareSeCiSonoRotazioniEUnLumpZero;
    [Test]
    procedure DovrebbeAvvisareSeUnFrameNonHaLump;
    [Test]
    procedure DovrebbeFallireSeMancaUnaRotazione;
    [Test]
    procedure DovrebbeIgnorareILumpNonPresenti;
    [Test]
    procedure DovrebbeUsareIlLumpDelGiocoModificato;
    [Test]
    procedure DovrebbeFallireSeIlFrameENonValido;
    [Test]
    procedure DovrebbeSaltareIlLumpNonValidoInModoSviluppo;
    [Test]
    procedure DovrebbeLeggereIlNomeDiOgniLumpUnaSolaVolta;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    /// <summary>
    ///   Parity: R_InstallSpriteLump and R_InitSpriteDefs of the old r_things.pas, copied here
    ///   as they were, and the library give the same frames, the same warnings in the same order
    ///   and the same error, on random WADs
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_InitSpriteDefs;
  end;

implementation

uses
  DelphiDoom.Renderer.Factory;

const
  MAXFRAMES = 29;

type
  TOldFrame = record
    rotate: Integer;
    lump: array[0..31] of Integer;
    flip: array[0..31] of Boolean;
  end;

  EOldFatal = class(Exception);

  /// <summary>The old code of r_things.pas, with the unit variables as fields</summary>
  TOldSpriteDefs = class
  public
    Source: TFakeSpriteSource;
    Messages: TList<string>;
    sprtemp: array[0..MAXFRAMES - 1] of TOldFrame;
    maxframe: Integer;
    spritename: string;
    firstspritelump: Integer;
    result_frames: TArray<TArray<TOldFrame>>;
    procedure I_DevWarning(const S: string);
    procedure I_Warning(const S: string);
    procedure I_DevError(const S: string);
    procedure R_InstallSpriteLump(lump: Integer; frame: LongWord; rotation: LongWord;
      flipped: Boolean);
    procedure R_InitSpriteDefs(const namelist: TArray<Integer>);
  end;

procedure TOldSpriteDefs.I_DevWarning(const S: string);
begin
  Messages.Add('dev:' + S);
end;

procedure TOldSpriteDefs.I_Warning(const S: string);
begin
  Messages.Add('warn:' + S);
end;

procedure TOldSpriteDefs.I_DevError(const S: string);
begin
  if Source.Developer then
    I_Warning(S)
  else
    raise EOldFatal.Create(S + #13#10#13#10'Specify -devparm from the command line if you want this error to be ignored');
end;

procedure TOldSpriteDefs.R_InstallSpriteLump(lump: Integer; frame: LongWord;
  rotation: LongWord; flipped: Boolean);
var
  r: Integer;
begin
  if (frame >= MAXFRAMES) or (rotation > 32) then
  begin
    I_DevError(Format('R_InstallSpriteLump(): Bad frame characters in lump %d (frame = %d, rotation = %d)'#13#10,
      [lump, Integer(frame), Integer(rotation)]));
    // the old code went on out of the table: the comparison is only for valid lumps
    raise EOldFatal.Create('unreachable');
  end;

  if Integer(frame) > maxframe then
    maxframe := frame;

  if rotation = 0 then
  begin
    if sprtemp[frame].rotate = 0 then
      I_DevWarning(Format('R_InitSprites(): Sprite %s frame %s has multip rot=0 lump'#13#10,
        [spritename, Chr(Ord('A') + frame)]));

    if sprtemp[frame].rotate in [1..3] then
      I_DevWarning(Format('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump'#13#10,
        [spritename, Chr(Ord('A') + frame)]));

    sprtemp[frame].rotate := 0;
    for r := 0 to 7 do
    begin
      sprtemp[frame].lump[r] := lump - firstspritelump;
      sprtemp[frame].flip[r] := flipped;
    end;
    Exit;
  end;

  if sprtemp[frame].rotate = 0 then
    I_DevWarning(Format('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump'#13#10,
      [spritename, Chr(Ord('A') + frame)]));

  if rotation in [1..8] then
    if sprtemp[frame].rotate = -1 then
      if sprtemp[frame].rotate < 1 then
        sprtemp[frame].rotate := 1;

  if rotation in [9..16] then
    if (sprtemp[frame].rotate = -1) or (sprtemp[frame].rotate = 1) then
      if sprtemp[frame].rotate < 2 then
        sprtemp[frame].rotate := 2;

  if rotation in [17..32] then
    if (sprtemp[frame].rotate = -1) or (sprtemp[frame].rotate = 1) or (sprtemp[frame].rotate = 2) then
      sprtemp[frame].rotate := 3;

  Dec(rotation);
  if sprtemp[frame].lump[rotation] <> -1 then
  begin
    if rotation > 9 then
      I_DevWarning(Format('R_InitSprites(): Sprite %s : %s : %s has two lumps mapped to it'#13#10,
        [spritename, Chr(Ord('A') + frame), Chr(Ord('A') + rotation - 10)]))
    else
      I_DevWarning(Format('R_InitSprites(): Sprite %s : %s : %s has two lumps mapped to it'#13#10,
        [spritename, Chr(Ord('A') + frame), Chr(Ord('1') + rotation)]));
  end;

  sprtemp[frame].lump[rotation] := lump - firstspritelump;
  sprtemp[frame].flip[rotation] := flipped;
end;

procedure TOldSpriteDefs.R_InitSpriteDefs(const namelist: TArray<Integer>);

  procedure sprtempreset;
  var
    i: Integer;
    j: Integer;
  begin
    for i := 0 to MAXFRAMES - 1 do
    begin
      sprtemp[i].rotate := -1;
      for j := 0 to 31 do
      begin
        sprtemp[i].lump[j] := -1;
        sprtemp[i].flip[j] := False;
      end;
    end;
  end;

  function rotationfromchar(const ch: AnsiChar): Integer;
  begin
    if ch in ['0'..'9'] then
    begin
      Result := Ord(ch) - Ord('0');
      Exit;
    end;
    if ch in ['A'..'W'] then
    begin
      Result := Ord(ch) - Ord('A') + 10;
      Exit;
    end;
    Result := 33;
  end;

var
  i: Integer;
  l: Integer;
  intname: Integer;
  lname: TRendererLumpName;
  frame: Integer;
  rotation: Integer;
  start: Integer;
  finish: Integer;
  patched: Integer;
begin
  SetLength(result_frames, Length(namelist));
  firstspritelump := Source.FirstLump;
  start := Source.FirstLump - 1;
  finish := Source.LastLump + 1;

  for i := 0 to High(namelist) do
  begin
    spritename := Chr(namelist[i] and $FF) + Chr((namelist[i] shr 8) and $FF) +
      Chr((namelist[i] shr 16) and $FF) + Chr((namelist[i] shr 24) and $FF);
    sprtempreset;
    maxframe := -1;
    intname := namelist[i];

    for l := start + 1 to finish - 1 do
    begin
      if Source.Present[l - firstspritelump] then
      begin
        lname := Source.Names[l - firstspritelump];
        if PInteger(@lname[0])^ = intname then
        begin
          frame := Ord(lname[4]) - Ord('A');
          rotation := rotationfromchar(lname[5]);
          patched := Source.PatchedLump(l);
          R_InstallSpriteLump(patched, frame, rotation, False);
          if lname[6] <> #0 then
          begin
            frame := Ord(lname[6]) - Ord('A');
            rotation := rotationfromchar(lname[7]);
            R_InstallSpriteLump(l, frame, rotation, True);
          end;
        end;
      end;
    end;

    if maxframe = -1 then
      Continue;

    Inc(maxframe);

    for frame := 0 to maxframe - 1 do
    begin
      case sprtemp[frame].rotate of
        -1:
          I_Warning(Format('R_InitSprites(): No patches found for %s frame %s'#13#10,
            [spritename, Chr(frame + Ord('A'))]));
        0:
          ;
        1:
          for rotation := 0 to 7 do
            if sprtemp[frame].lump[rotation] = -1 then
              raise EOldFatal.Create(Format('R_InitSprites(): Sprite %s frame %s is missing rotations',
                [spritename, Chr(frame + Ord('A'))]));
        2:
          for rotation := 0 to 15 do
            if sprtemp[frame].lump[rotation] = -1 then
              raise EOldFatal.Create(Format('R_InitSprites(): Sprite %s frame %s is missing rotations',
                [spritename, Chr(frame + Ord('A'))]));
        3:
          for rotation := 0 to 31 do
            if sprtemp[frame].lump[rotation] = -1 then
              raise EOldFatal.Create(Format('R_InitSprites(): Sprite %s frame %s is missing rotations',
                [spritename, Chr(frame + Ord('A'))]));
      end;
    end;

    SetLength(result_frames[i], maxframe);
    for frame := 0 to maxframe - 1 do
      result_frames[i][frame] := sprtemp[frame];
  end;
end;

{ TFakeSpriteSource }

procedure TFakeSpriteSource.Add(const AName: string; APresent: Boolean);
var
  LName: TRendererLumpName;
  LIndex: Integer;
begin
  FillChar(LName, SizeOf(LName), 0);
  for LIndex := 1 to Length(AName) do
    LName[LIndex - 1] := AnsiChar(AName[LIndex]);
  SetLength(Names, Length(Names) + 1);
  Names[High(Names)] := LName;
  SetLength(Present, Length(Present) + 1);
  Present[High(Present)] := APresent;
  SetLength(Patched, Length(Patched) + 1);
  Patched[High(Patched)] := -1;
end;

function TFakeSpriteSource.FirstLump: Integer;
begin
  Result := First;
end;

function TFakeSpriteSource.LastLump: Integer;
begin
  Result := First + Length(Names) - 1;
end;

function TFakeSpriteSource.IsPresent(ALump: Integer): Boolean;
begin
  Result := Present[ALump - First];
end;

function TFakeSpriteSource.LumpName(ALump: Integer): TRendererLumpName;
begin
  Inc(NameCalls);
  Result := Names[ALump - First];
end;

function TFakeSpriteSource.PatchedLump(ALump: Integer): Integer;
begin
  if Patched[ALump - First] >= 0 then
    Result := Patched[ALump - First]
  else
    Result := ALump;
end;

function TFakeSpriteSource.DeveloperMode: Boolean;
begin
  Result := Developer;
end;

{ TTestRendererSpriteDefs }

procedure TTestRendererSpriteDefs.Setup;
begin
  FSource := TFakeSpriteSource.Create;
  FSource.First := 100;
  FSourceIntf := FSource;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FDefs := TRendererFactory.CreateSpriteDefs(FSourceIntf, FLogIntf);
end;

procedure TTestRendererSpriteDefs.TearDown;
begin
  FDefs := nil;
  FLogIntf := nil;
  FSourceIntf := nil;
end;

function TTestRendererSpriteDefs.PackName(const AName: string): Integer;
begin
  Result := Ord(AName[1]) or (Ord(AName[2]) shl 8) or (Ord(AName[3]) shl 16) or
    (Ord(AName[4]) shl 24);
end;

procedure TTestRendererSpriteDefs.DovrebbeDareUnaSpriteSenzaLump;
var
  LDefs: TArray<TRendererSpriteDefinition>;
begin
  FSource.Add('TROOA1');
  LDefs := FDefs.Build([PackName('POSS')]);
  Assert.AreEqual<Integer>(1, Length(LDefs));
  Assert.AreEqual<Integer>(0, Length(LDefs[0].Frames));
  Assert.AreEqual<Integer>(0, FLog.Others.Count);
end;

procedure TTestRendererSpriteDefs.DovrebbeUsareUnSoloLumpPerTutteLeRotazioni;
var
  LDefs: TArray<TRendererSpriteDefinition>;
  LRotation: Integer;
begin
  FSource.Add('TROOA0');
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual<Integer>(1, Length(LDefs[0].Frames));
  Assert.AreEqual(0, LDefs[0].Frames[0].Rotate);
  for LRotation := 0 to 7 do
  begin
    Assert.AreEqual(0, LDefs[0].Frames[0].Lump[LRotation]);
    Assert.IsFalse(LDefs[0].Frames[0].Flip[LRotation]);
  end;
  Assert.AreEqual(-1, LDefs[0].Frames[0].Lump[8]);
end;

procedure TTestRendererSpriteDefs.DovrebbeInstallareOttoRotazioni;
var
  LDefs: TArray<TRendererSpriteDefinition>;
  LRotation: Integer;
begin
  for LRotation := 1 to 8 do
    FSource.Add('TROOB' + IntToStr(LRotation));
  LDefs := FDefs.Build([PackName('TROO')]);
  // the frame B is the second: the frame A has no lump
  Assert.AreEqual<Integer>(2, Length(LDefs[0].Frames));
  Assert.AreEqual(-1, LDefs[0].Frames[0].Rotate);
  Assert.AreEqual(1, LDefs[0].Frames[1].Rotate);
  for LRotation := 0 to 7 do
    Assert.AreEqual(LRotation, LDefs[0].Frames[1].Lump[LRotation]);
  Assert.AreEqual<Integer>(1, FLog.Others.Count, 'No patches found for the frame A');
end;

procedure TTestRendererSpriteDefs.DovrebbeInstallareLaVersioneSpecchiataDelLump;
var
  LDefs: TArray<TRendererSpriteDefinition>;
begin
  // A2 and its mirror A8: one lump for two rotations
  FSource.Add('TROOA2A8');
  FSource.Add('TROOA1');
  FSource.Add('TROOA3');
  FSource.Add('TROOA4');
  FSource.Add('TROOA5');
  FSource.Add('TROOA6');
  FSource.Add('TROOA7');
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual(1, LDefs[0].Frames[0].Rotate);
  Assert.AreEqual(0, LDefs[0].Frames[0].Lump[1]);
  Assert.IsFalse(LDefs[0].Frames[0].Flip[1]);
  Assert.AreEqual(0, LDefs[0].Frames[0].Lump[7]);
  Assert.IsTrue(LDefs[0].Frames[0].Flip[7]);
end;

procedure TTestRendererSpriteDefs.DovrebbeSegnareSediciETrentaduRotazioni;
var
  LDefs: TArray<TRendererSpriteDefinition>;
  LRotation: Integer;
begin
  for LRotation := 1 to 9 do
    FSource.Add('TROOA' + IntToStr(LRotation));
  for LRotation := 0 to 6 do
    FSource.Add('TROOA' + Chr(Ord('A') + LRotation));
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual(2, LDefs[0].Frames[0].Rotate);
  for LRotation := 0 to 15 do
    FSource.Add('TROOA' + Chr(Ord('H') + LRotation));
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual(3, LDefs[0].Frames[0].Rotate);
end;

procedure TTestRendererSpriteDefs.DovrebbeAvvisareSeUnaRotazioneHaDueLump;
begin
  FSource.Add('TROOA0');
  FSource.Add('TROOA0');
  FDefs.Build([PackName('TROO')]);
  Assert.AreEqual<Integer>(1, FLog.DevWarnings.Count);
  Assert.AreEqual('R_InitSprites(): Sprite TROO frame A has multip rot=0 lump'#13#10,
    FLog.DevWarnings[0]);
end;

procedure TTestRendererSpriteDefs.DovrebbeAvvisareSeCiSonoRotazioniEUnLumpZero;
begin
  FSource.Add('TROOA1');
  FSource.Add('TROOA0');
  try
    FDefs.Build([PackName('TROO')]);
  except
    on ERendererException do
      ; // the frame has the rotation 1 only: it is missing the others
  end;
  Assert.IsTrue(FLog.DevWarnings.Count >= 1);
  Assert.AreEqual('R_InitSprites(): Sprite TROO frame A has rotations and a rot=0 lump'#13#10,
    FLog.DevWarnings[0]);
end;

procedure TTestRendererSpriteDefs.DovrebbeAvvisareSeUnFrameNonHaLump;
begin
  FSource.Add('TROOC0');
  FDefs.Build([PackName('TROO')]);
  Assert.AreEqual<Integer>(2, FLog.Others.Count);
  Assert.AreEqual('R_InitSprites(): No patches found for TROO frame A'#13#10, FLog.Others[0]);
  Assert.AreEqual('R_InitSprites(): No patches found for TROO frame B'#13#10, FLog.Others[1]);
end;

procedure TTestRendererSpriteDefs.DovrebbeFallireSeMancaUnaRotazione;
begin
  FSource.Add('TROOA1');
  FSource.Add('TROOA2');
  try
    FDefs.Build([PackName('TROO')]);
    Assert.Fail('No error');
  except
    on E: ERendererException do
      Assert.AreEqual('R_InitSprites(): Sprite TROO frame A is missing rotations', E.Message);
  end;
end;

procedure TTestRendererSpriteDefs.DovrebbeIgnorareILumpNonPresenti;
var
  LDefs: TArray<TRendererSpriteDefinition>;
begin
  FSource.Add('TROOA0', False);
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual<Integer>(0, Length(LDefs[0].Frames));
end;

procedure TTestRendererSpriteDefs.DovrebbeUsareIlLumpDelGiocoModificato;
var
  LDefs: TArray<TRendererSpriteDefinition>;
begin
  FSource.Add('TROOA0A0');
  FSource.Patched[0] := 555;
  LDefs := FDefs.Build([PackName('TROO')]);
  // the patched lump for the direct use, the lump itself for the mirrored one (that wins: it is last)
  Assert.AreEqual(100 - 100, LDefs[0].Frames[0].Lump[0]);
  Assert.IsTrue(LDefs[0].Frames[0].Flip[0]);
  FLog.DevWarnings.Clear;
  FSource.Add('TROOB0');
  FSource.Patched[1] := 555;
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual(555 - 100, LDefs[0].Frames[1].Lump[0]);
end;

procedure TTestRendererSpriteDefs.DovrebbeFallireSeIlFrameENonValido;
begin
  FSource.Add('TROO#0');
  try
    FDefs.Build([PackName('TROO')]);
    Assert.Fail('No error');
  except
    on E: ERendererException do
      Assert.IsTrue(E.Message.EndsWith('Specify -devparm from the command line if you want this error to be ignored'));
  end;
end;

procedure TTestRendererSpriteDefs.DovrebbeSaltareIlLumpNonValidoInModoSviluppo;
var
  LDefs: TArray<TRendererSpriteDefinition>;
begin
  FSource.Developer := True;
  FSource.Add('TROO#0');
  FSource.Add('TROOA0');
  LDefs := FDefs.Build([PackName('TROO')]);
  Assert.AreEqual<Integer>(1, Length(LDefs[0].Frames));
  Assert.AreEqual<Integer>(1, FLog.Others.Count, 'the warning of the bad lump');
end;

procedure TTestRendererSpriteDefs.DovrebbeLeggereIlNomeDiOgniLumpUnaSolaVolta;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 9 do
    FSource.Add('TROOA0');
  FDefs.Build([PackName('TROO'), PackName('POSS'), PackName('SPOS')]);
  Assert.AreEqual(10, FSource.NameCalls);
end;

procedure TTestRendererSpriteDefs.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateSpriteDefs(nil, FLogIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateSpriteDefs(FSourceIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestRendererSpriteDefs.DovrebbeFareComeIlVecchioR_InitSpriteDefs;
const
  PREFIXES: array[0..3] of string = ('TROO', 'POSS', 'SPOS', 'IMPX');
  ROTATIONS = '012345678ABCDEFGHIJKLMNOPQRSTUVW';
var
  LScenario: Integer;
  LRandSeed: Integer;
  LSource: TFakeSpriteSource;
  LSourceIntf: IRendererSpriteSource;
  LLog: TFakeLog;
  LLogIntf: ILog;
  LOld: TOldSpriteDefs;
  LNew: TArray<TRendererSpriteDefinition>;
  LNames: TArray<Integer>;
  LCount: Integer;
  LIndex: Integer;
  LName: string;
  LOldError: string;
  LNewError: string;
  LOldMessages: TStringList;
  LNewMessages: TStringList;
  LOldOthers: TStringList;
  LFrame: Integer;
  LRotation: Integer;
  LTotal: Integer;
begin
  LRandSeed := 20261116;
  RandSeed := LRandSeed;
  LTotal := 0;
  for LScenario := 1 to 400 do
  begin
    LSource := TFakeSpriteSource.Create;
    LSourceIntf := LSource;
    LSource.First := Random(500);
    LSource.Developer := Random(2) = 0;
    LLog := TFakeLog.Create;
    LLogIntf := LLog;
    LCount := 1 + Random(60);
    for LIndex := 1 to LCount do
    begin
      LName := PREFIXES[Random(Length(PREFIXES))] + Chr(Ord('A') + Random(6));
      if Random(3) = 0 then
        LName := LName + '0'
      else
        LName := LName + ROTATIONS[1 + Random(9)];
      if Random(4) = 0 then
        LName := LName + Chr(Ord('A') + Random(6)) + ROTATIONS[1 + Random(9)];
      LSource.Add(LName, Random(10) > 0);
      if Random(8) = 0 then
        LSource.Patched[High(LSource.Patched)] := LSource.First + Random(LCount);
    end;
    SetLength(LNames, 1 + Random(5));
    for LIndex := 0 to High(LNames) do
      LNames[LIndex] := PackName(PREFIXES[Random(Length(PREFIXES))]);

    LOld := TOldSpriteDefs.Create;
    LOldMessages := TStringList.Create;
    LNewMessages := TStringList.Create;
    LOldOthers := TStringList.Create;
    try
      LOld.Source := LSource;
      LOld.Messages := TList<string>.Create;
      LOldError := '';
      try
        LOld.R_InitSpriteDefs(LNames);
      except
        on E: EOldFatal do
          LOldError := E.Message;
      end;

      LNewError := '';
      LNew := nil;
      try
        LNew := TRendererFactory.CreateSpriteDefs(LSourceIntf, LLogIntf).Build(LNames);
      except
        on E: ERendererException do
          LNewError := E.Message;
      end;

      Assert.AreEqual(LOldError, LNewError, 'error, scenario ' + IntToStr(LScenario));
      if LOldError = '' then
      begin
        for LIndex := 0 to High(LNames) do
        begin
          Assert.AreEqual<Integer>(Length(LOld.result_frames[LIndex]), Length(LNew[LIndex].Frames),
            'frames, scenario ' + IntToStr(LScenario));
          for LFrame := 0 to High(LNew[LIndex].Frames) do
          begin
            Assert.AreEqual(LOld.result_frames[LIndex][LFrame].rotate,
              LNew[LIndex].Frames[LFrame].Rotate);
            for LRotation := 0 to 31 do
            begin
              Assert.AreEqual(LOld.result_frames[LIndex][LFrame].lump[LRotation],
                LNew[LIndex].Frames[LFrame].Lump[LRotation]);
              Assert.AreEqual(LOld.result_frames[LIndex][LFrame].flip[LRotation],
                LNew[LIndex].Frames[LFrame].Flip[LRotation]);
            end;
          end;
        end;
        // the warnings, in order: the old code tagged the kind, the fake log keeps two lists
        for LIndex := 0 to LOld.Messages.Count - 1 do
          if LOld.Messages[LIndex].StartsWith('dev:') then
            LOldMessages.Add(Copy(LOld.Messages[LIndex], 5, MaxInt))
          else
            LOldOthers.Add(Copy(LOld.Messages[LIndex], 6, MaxInt));
        for LIndex := 0 to LLog.DevWarnings.Count - 1 do
          LNewMessages.Add(LLog.DevWarnings[LIndex]);
        Assert.AreEqual(LOldMessages.Text, LNewMessages.Text,
          'developer warnings, scenario ' + IntToStr(LScenario));
        Assert.AreEqual<Integer>(LOldOthers.Count, LLog.Others.Count,
          'warnings, scenario ' + IntToStr(LScenario));
        for LIndex := 0 to LOldOthers.Count - 1 do
          Assert.AreEqual(LOldOthers[LIndex], LLog.Others[LIndex]);        Inc(LTotal);
      end;
    finally
      LOld.Messages.Free;
      LOldOthers.Free;
      LNewMessages.Free;
      LOldMessages.Free;
      LOld.Free;
    end;
  end;
  Assert.IsTrue(LTotal > 20, 'enough scenarios without errors');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererSpriteDefs);

end.
