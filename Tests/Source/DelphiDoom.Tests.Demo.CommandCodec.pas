{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands of a demo                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Demo.CommandCodec;

{$POINTERMATH ON}

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Demo.Types,
  DelphiDoom.Demo.CommandCodec;

type
  [TestFixture]
  [Category('demo')]
  TTestDemoCommandCodec = class
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiDoomPerOgniVersione;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiHereticPerOgniVersione;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiStrifePerOgniVersione;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeNonMuovereIlPuntatoreScrivendo;
    [Test]
    procedure DovrebbeToglierePerSempreIlBitDeiComandiSpeciali;
    [Test]
    procedure DovrebbeLeggereUnaDemoVecchiaDiDoomConAngoloAUnByte;
  end;

implementation

uses
  System.SysUtils;

const
  BT_SPECIAL = 128;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..65535] of Byte;

  // ticcmd_t of the three layouts with all the fields the old code touched
  TOldCmd = record
    forwardmove: ShortInt;
    sidemove: ShortInt;
    angleturn: SmallInt;
    buttons: Byte;
    buttons2: Byte;
    inventory: Integer;
    lookfly: Byte;
    arti: Byte;
    lookupdown: Byte;
    lookupdown16: Word;
    lookleftright: Byte;
    jump_crouch: Byte;
  end;

const
  VERSION203 = 203;

var
  demo_p: PByteArray;
  demoversion: Byte;
  olddemo: Boolean;

// ---------------------------------------------------------------------------
// The old code, copied as it was: the body of G_ReadDemoTiccmd and of
// G_WriteDemoTiccmd (what is between the end marker test and the end), per game
// ---------------------------------------------------------------------------

procedure OldDoom_Read(var cmd: TOldCmd);
begin
  cmd.forwardmove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.sidemove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  if olddemo then
  begin
    cmd.angleturn := shortint(demo_p[0]) * 256;
    demo_p := @demo_p[1];
  end
  else
  begin
    cmd.angleturn := PSmallInt(demo_p)^;
    demo_p := @demo_p[2];
  end;

  cmd.buttons := demo_p[0] and not BT_SPECIAL;
  demo_p := @demo_p[1];

  if olddemo then
  begin
    cmd.lookupdown := 0;
    cmd.lookupdown16 := 0; // JVAL Smooth Look Up/Down
    cmd.lookleftright := 0;
    cmd.jump_crouch := 0; // JVAL: 20211101 - Crouch
  end
  else
  begin
    cmd.lookupdown := demo_p[0];
    demo_p := @demo_p[1];

    // JVAL Smooth Look Up/Down
    if demoversion >= VERSION203 then
    begin
      cmd.lookupdown16 := PWord(demo_p)^;
      demo_p := @demo_p[2];
    end
    else
      cmd.lookupdown16 := 256 * cmd.lookupdown;

    cmd.lookleftright := demo_p[0];
    demo_p := @demo_p[1];
    cmd.jump_crouch := demo_p[0];
    demo_p := @demo_p[1];
  end;
end;

procedure OldHeretic_Read(var cmd: TOldCmd);
begin
  cmd.forwardmove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.sidemove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.angleturn := PSmallInt(demo_p)^;
  demo_p := @demo_p[2];

  cmd.buttons := demo_p[0] and not BT_SPECIAL;
  demo_p := @demo_p[1];

  cmd.lookfly := demo_p[0];
  demo_p := @demo_p[1];

  cmd.arti := demo_p[0];
  demo_p := @demo_p[1];

  cmd.lookleftright := demo_p[0];
  demo_p := @demo_p[1];

  cmd.jump_crouch := demo_p[0];
  demo_p := @demo_p[1];

  if demoversion < VERSION203 then
  begin
    cmd.lookupdown16 := (cmd.lookfly and 15) * 256; // JVAL Smooth Look Up/Down
  end
  else
  begin
    cmd.lookupdown16 := PWord(demo_p)^;
    demo_p := @demo_p[2];
  end;
  cmd.lookupdown := cmd.lookupdown16 div 256; // JVAL unused :)
end;

procedure OldStrife_Read(var cmd: TOldCmd);
begin
  cmd.forwardmove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.sidemove := shortint(demo_p[0]);
  demo_p := @demo_p[1];

  cmd.angleturn := PSmallInt(demo_p)^;
  demo_p := @demo_p[2];

  cmd.buttons := demo_p[0] and not BT_SPECIAL;
  demo_p := @demo_p[1];

  cmd.buttons2 := demo_p[0] and not BT_SPECIAL;
  demo_p := @demo_p[1];

  cmd.inventory := PInteger(demo_p)^;
  demo_p := @demo_p[4];

  cmd.lookupdown := demo_p[0];
  demo_p := @demo_p[1];
  cmd.lookleftright := demo_p[0];
  demo_p := @demo_p[1];
  cmd.jump_crouch := demo_p[0];
  demo_p := @demo_p[1];

  // JVAL Smooth Look Up/Down
  if demoversion >= VERSION203 then
  begin
    cmd.lookupdown16 := PWord(demo_p)^;
    demo_p := @demo_p[2];
  end
  else
    cmd.lookupdown16 := 256 * cmd.lookupdown;
end;

procedure OldDoom_Write(const cmd: TOldCmd);
begin
  demo_p[0] := Ord(cmd.forwardmove);
  demo_p := @demo_p[1];

  demo_p[0] := Ord(cmd.sidemove);
  demo_p := @demo_p[1];

  PSmallInt(demo_p)^ := cmd.angleturn;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.buttons and not BT_SPECIAL;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.lookupdown;
  demo_p := @demo_p[1];

  // JVAL Smooth Look Up/Down
  PWord(demo_p)^ := cmd.lookupdown16;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.lookleftright;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.jump_crouch;
  demo_p := @demo_p[1];
end;

procedure OldHeretic_Write(const cmd: TOldCmd);
begin
  demo_p[0] := Ord(cmd.forwardmove);
  demo_p := @demo_p[1];

  demo_p[0] := Ord(cmd.sidemove);
  demo_p := @demo_p[1];

  PSmallInt(demo_p)^ := cmd.angleturn;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.buttons and not BT_SPECIAL;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.lookfly;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.arti;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.lookleftright;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.jump_crouch;
  demo_p := @demo_p[1];

  // JVAL Smooth Look Up/Down
  PWord(demo_p)^ := cmd.lookupdown16;
  demo_p := @demo_p[2];
end;

procedure OldStrife_Write(const cmd: TOldCmd);
begin
  demo_p[0] := Ord(cmd.forwardmove);
  demo_p := @demo_p[1];

  demo_p[0] := Ord(cmd.sidemove);
  demo_p := @demo_p[1];

  PSmallInt(demo_p)^ := cmd.angleturn;
  demo_p := @demo_p[2];

  demo_p[0] := cmd.buttons and not BT_SPECIAL;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.buttons2;
  demo_p := @demo_p[1];

  PInteger(demo_p)^ := cmd.inventory;
  demo_p := @demo_p[4];

  demo_p[0] := cmd.lookupdown;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.lookleftright;
  demo_p := @demo_p[1];

  demo_p[0] := cmd.jump_crouch;
  demo_p := @demo_p[1];

  // JVAL Smooth Look Up/Down
  PWord(demo_p)^ := cmd.lookupdown16;
  demo_p := @demo_p[2];
end;

procedure FillRandom(var ABuffer: array of Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ABuffer) do
    ABuffer[LIndex] := Random(256);
end;

procedure ReadOld(const ALayout: TDemoLayout; var ACommand: TOldCmd);
begin
  case ALayout of
    dlDoom: OldDoom_Read(ACommand);
    dlHeretic: OldHeretic_Read(ACommand);
  else
    OldStrife_Read(ACommand);
  end;
end;

procedure CheckSameRead(const ALayout: TDemoLayout);
var
  LBuffer: array[0..31] of Byte;
  LVersion: Integer;
  LOld: Integer;
  LRepeat: Integer;
  LOldCmd: TOldCmd;
  LNewCmd: TDemoCommand;
  LPosition: PByte;
  LContext: string;
begin
  for LVersion := 0 to 255 do
    for LOld := 0 to Ord(ALayout = dlDoom) do
      for LRepeat := 1 to 20 do
      begin
        FillRandom(LBuffer);
        LContext := Format('layout %d version %d old %d', [Ord(ALayout), LVersion, LOld]);

        demo_p := @LBuffer[0];
        demoversion := LVersion;
        olddemo := LOld = 1;
        LOldCmd := Default(TOldCmd);
        ReadOld(ALayout, LOldCmd);

        LPosition := @LBuffer[0];
        TDemoCommandCodec.Read(LPosition, ALayout, LVersion, LOld = 1, LNewCmd);

        Assert.AreEqual<NativeInt>(NativeInt(demo_p) - NativeInt(@LBuffer[0]),
          NativeInt(LPosition) - NativeInt(@LBuffer[0]), 'bytes read, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.forwardmove, LNewCmd.ForwardMove, 'forwardmove, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.sidemove, LNewCmd.SideMove, 'sidemove, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.angleturn, LNewCmd.AngleTurn, 'angleturn, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.buttons, LNewCmd.Buttons, 'buttons, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.buttons2, LNewCmd.Buttons2, 'buttons2, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.inventory, LNewCmd.Inventory, 'inventory, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.lookfly, LNewCmd.LookFly, 'lookfly, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.arti, LNewCmd.Arti, 'arti, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.lookupdown, LNewCmd.LookUpDown, 'lookupdown, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.lookupdown16, LNewCmd.LookUpDown16, 'lookupdown16, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.lookleftright, LNewCmd.LookLeftRight, 'lookleftright, ' + LContext);
        Assert.AreEqual<Integer>(LOldCmd.jump_crouch, LNewCmd.JumpCrouch, 'jump_crouch, ' + LContext);
      end;
end;

procedure CheckSameWrite(const ALayout: TDemoLayout);
var
  LOldBytes: array[0..31] of Byte;
  LNewBytes: array[0..31] of Byte;
  LRepeat: Integer;
  LOldCmd: TOldCmd;
  LNewCmd: TDemoCommand;
  LStart: PByte;
begin
  for LRepeat := 1 to 2000 do
  begin
    LOldCmd := Default(TOldCmd);
    LOldCmd.forwardmove := Random(256) - 128;
    LOldCmd.sidemove := Random(256) - 128;
    LOldCmd.angleturn := Random(65536) - 32768;
    LOldCmd.buttons := Random(256);
    LOldCmd.buttons2 := Random(256);
    LOldCmd.inventory := Random(MaxInt) - 1000;
    LOldCmd.lookfly := Random(256);
    LOldCmd.arti := Random(256);
    LOldCmd.lookupdown := Random(256);
    LOldCmd.lookupdown16 := Random(65536);
    LOldCmd.lookleftright := Random(256);
    LOldCmd.jump_crouch := Random(256);

    LNewCmd := Default(TDemoCommand);
    LNewCmd.ForwardMove := LOldCmd.forwardmove;
    LNewCmd.SideMove := LOldCmd.sidemove;
    LNewCmd.AngleTurn := LOldCmd.angleturn;
    LNewCmd.Buttons := LOldCmd.buttons;
    LNewCmd.Buttons2 := LOldCmd.buttons2;
    LNewCmd.Inventory := LOldCmd.inventory;
    LNewCmd.LookFly := LOldCmd.lookfly;
    LNewCmd.Arti := LOldCmd.arti;
    LNewCmd.LookUpDown := LOldCmd.lookupdown;
    LNewCmd.LookUpDown16 := LOldCmd.lookupdown16;
    LNewCmd.LookLeftRight := LOldCmd.lookleftright;
    LNewCmd.JumpCrouch := LOldCmd.jump_crouch;

    FillChar(LOldBytes, SizeOf(LOldBytes), $EE);
    FillChar(LNewBytes, SizeOf(LNewBytes), $EE);

    demo_p := @LOldBytes[0];
    case ALayout of
      dlDoom: OldDoom_Write(LOldCmd);
      dlHeretic: OldHeretic_Write(LOldCmd);
    else
      OldStrife_Write(LOldCmd);
    end;

    LStart := @LNewBytes[0];
    TDemoCommandCodec.Write(LStart, ALayout, LNewCmd);

    Assert.IsTrue(CompareMem(@LOldBytes[0], @LNewBytes[0], SizeOf(LOldBytes)),
      'the bytes of the command, layout ' + IntToStr(Ord(ALayout)));
  end;
end;

{ TTestDemoCommandCodec }

procedure TTestDemoCommandCodec.Setup;
begin
  RandSeed := 245;
end;

procedure TTestDemoCommandCodec.DovrebbeLeggereComeIlVecchioCodiceDiDoomPerOgniVersione;
begin
  CheckSameRead(dlDoom);
end;

procedure TTestDemoCommandCodec.DovrebbeLeggereComeIlVecchioCodiceDiHereticPerOgniVersione;
begin
  CheckSameRead(dlHeretic);
end;

procedure TTestDemoCommandCodec.DovrebbeLeggereComeIlVecchioCodiceDiStrifePerOgniVersione;
begin
  CheckSameRead(dlStrife);
end;

procedure TTestDemoCommandCodec.DovrebbeScrivereComeIlVecchioCodiceDiDoom;
begin
  CheckSameWrite(dlDoom);
end;

procedure TTestDemoCommandCodec.DovrebbeScrivereComeIlVecchioCodiceDiHeretic;
begin
  CheckSameWrite(dlHeretic);
end;

procedure TTestDemoCommandCodec.DovrebbeScrivereComeIlVecchioCodiceDiStrife;
begin
  CheckSameWrite(dlStrife);
end;

procedure TTestDemoCommandCodec.DovrebbeNonMuovereIlPuntatoreScrivendo;
var
  LBytes: array[0..31] of Byte;
  LStart: PByte;
  LCommand: TDemoCommand;
begin
  LCommand := Default(TDemoCommand);
  LStart := @LBytes[0];
  TDemoCommandCodec.Write(LStart, dlDoom, LCommand);
  Assert.AreEqual<NativeInt>(0, NativeInt(LStart) - NativeInt(@LBytes[0]));
end;

procedure TTestDemoCommandCodec.DovrebbeToglierePerSempreIlBitDeiComandiSpeciali;
var
  LBytes: array[0..31] of Byte;
  LPosition: PByte;
  LCommand: TDemoCommand;
  LRead: TDemoCommand;
begin
  LCommand := Default(TDemoCommand);
  LCommand.Buttons := $FF;
  LPosition := @LBytes[0];
  TDemoCommandCodec.Write(LPosition, dlHeretic, LCommand);
  LPosition := @LBytes[0];
  TDemoCommandCodec.Read(LPosition, dlHeretic, 207, False, LRead);
  Assert.AreEqual<Integer>($7F, LRead.Buttons);
end;

procedure TTestDemoCommandCodec.DovrebbeLeggereUnaDemoVecchiaDiDoomConAngoloAUnByte;
var
  LBytes: array[0..7] of Byte;
  LPosition: PByte;
  LCommand: TDemoCommand;
begin
  LBytes[0] := 25;
  LBytes[1] := Byte(-3);
  LBytes[2] := Byte(-2);
  LBytes[3] := 5;
  LBytes[4] := 99;
  LPosition := @LBytes[0];
  TDemoCommandCodec.Read(LPosition, dlDoom, 109, True, LCommand);
  Assert.AreEqual<Integer>(25, LCommand.ForwardMove);
  Assert.AreEqual<Integer>(-3, LCommand.SideMove);
  Assert.AreEqual<Integer>(-512, LCommand.AngleTurn);
  Assert.AreEqual<Integer>(5, LCommand.Buttons);
  Assert.AreEqual<Integer>(0, LCommand.LookUpDown);
  Assert.AreEqual<NativeInt>(4, NativeInt(LPosition) - NativeInt(@LBytes[0]));
end;

end.
