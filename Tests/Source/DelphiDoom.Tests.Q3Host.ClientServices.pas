{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the renderer that records, }
{  the sound, cinematic and parser calls of cgame and ui, written on cl_cgame.c }
{  and cl_ui.c, and which calls are left without a handler when every client    }
{  service is given (Tests\Data\Q3Host\unhandled-client.golden.txt)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientServices;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Q3Host.ClientSupport;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ClientServices = class
  strict private
    FRig: TQ3ClientRig;
    function Float(AValue: Single): Integer;
    procedure Put(AModule: Integer; AAddress: Integer; const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlRendererDovrebbeDareNumeriProgressiviEdUgualiPerLoStessoNome;
    [Test]
    procedure RegisterFontDiCgameDovrebbeCancellareAncheLaScena;
    [Test]
    procedure LeChiamateDiDisegnoDovrebberoArrivareAlRenderer;
    [Test]
    procedure LeRisposteSenzaDatiDovrebberoEssereQuelleNeutre;
    [Test]
    procedure IlGlConfigDovrebbeEssereScrittoComeIlC;
    [Test]
    procedure LeChiamateDelSuonoDiCgameDovrebberoArrivareAlSuono;
    [Test]
    procedure LeChiamateDelSuonoDiUiDovrebberoArrivareAlSuono;
    [Test]
    procedure LeChiamateDeiFilmatiDovrebberoArrivareAlServizio;
    [Test]
    procedure IlParserDovrebbeLeggereIFileEiTokenCosiCheIlC;
    [Test]
    procedure IlParserDovrebbeUsareLaStessaTabellaPerCgameEUi;
    [Test]
    procedure CgAcosDovrebbeDareLeRisposteDelC;
    [Test]
    procedure LeTrappeSenzaGestoreDovrebberoEssereQuelleDelGolden;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Host.OpcodeCatalog, DelphiDoom.Q3Host.ClientRecordingRenderer, DelphiDoom.Scanner.Q3.Types, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Q3Host.Services;

const
  BUFFER = 4096;
  OTHER = 4400;
  SCENE = 5000;

procedure TTestQ3ClientServices.Setup;
begin
  FRig := TQ3ClientRig.Create;
end;

procedure TTestQ3ClientServices.TearDown;
begin
  FRig.Free;
end;

function TTestQ3ClientServices.Float(AValue: Single): Integer;
begin
  Result := TQ3TestCalls.Bits(AValue);
end;

procedure TTestQ3ClientServices.Put(AModule: Integer; AAddress: Integer; const AText: AnsiString);
begin
  FRig.Memory(TQ3Module(AModule)).WriteString(AAddress, AText, Length(AText) + 1);
end;

procedure TTestQ3ClientServices.IlRendererDovrebbeDareNumeriProgressiviEdUgualiPerLoStessoNome;
begin
  Put(1, BUFFER, 'gfx/misc/Tracer');
  Put(1, OTHER, 'gfx/2d/bigchars');
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERSHADER, BUFFER]));
  Assert.AreEqual(2, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERSHADERNOMIP, OTHER]));
  // the same name, in any case: the same number; the no-mip call shares the table
  Put(1, BUFFER, 'GFX/MISC/TRACER');
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERSHADER, BUFFER]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERSHADERNOMIP, BUFFER]));
  // models and skins have their own numbers
  Put(1, BUFFER, 'models/weapons2/rocketl/rocketl.md3');
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERMODEL, BUFFER]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERSKIN, BUFFER]));
  Put(1, OTHER, 'models/players/sarge/default');
  Assert.AreEqual(2, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERMODEL, OTHER]));
  // ui shares the renderer
  Put(2, BUFFER, 'menu/art/back_0');
  Assert.AreEqual(3, FRig.Call(TQ3Module.Ui, [UI_R_REGISTERSHADERNOMIP, BUFFER]));
  Put(2, BUFFER, 'models/players/sarge/default');
  Assert.AreEqual(2, FRig.Call(TQ3Module.Ui, [UI_R_REGISTERMODEL, BUFFER]));
  // the skin of the player was not registered before
  Assert.AreEqual(2, FRig.Call(TQ3Module.Ui, [UI_R_REGISTERSKIN, BUFFER]));
  Assert.AreEqual(2, FRig.Renderer.CallCount('RegisterShader'));
  Assert.AreEqual(3, FRig.Renderer.CallCount('RegisterShaderNoMip'));
  Assert.AreEqual('gfx/misc/tracer', FRig.Renderer.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER)[0]);
  Assert.AreEqual<Integer>(3, Length(FRig.Renderer.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER)));
end;

procedure TTestQ3ClientServices.RegisterFontDiCgameDovrebbeCancellareAncheLaScena;
begin
  Put(1, BUFFER, 'fonts/smallfont');
  // the fall through of cl_cgame.c: re.RegisterFont and then re.ClearScene, and 0
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_REGISTERFONT, BUFFER, 12, OTHER]));
  Assert.AreEqual(1, FRig.Renderer.CallCount('RegisterFont'));
  Assert.AreEqual(1, FRig.Renderer.CallCount('ClearScene'));
  // the ui version returns after the font
  Put(2, BUFFER, 'fonts/smallfont');
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_REGISTERFONT, BUFFER, 12, OTHER]));
  Assert.AreEqual(2, FRig.Renderer.CallCount('RegisterFont'));
  Assert.AreEqual(1, FRig.Renderer.CallCount('ClearScene'));
end;

procedure TTestQ3ClientServices.LeChiamateDiDisegnoDovrebberoArrivareAlRenderer;
begin
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_CLEARSCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDREFENTITYTOSCENE, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDREFENTITYTOSCENE, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDPOLYTOSCENE, 4, 3, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDPOLYSTOSCENE, 4, 3, SCENE, 2]));
  FRig.Memory(TQ3Module.CGame).WriteInt32(SCENE, Float(10));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDLIGHTTOSCENE, SCENE, Float(200), Float(1), Float(0.5), Float(0)]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_ADDADDITIVELIGHTTOSCENE, SCENE, Float(100), Float(1), Float(1),
    Float(1)]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_RENDERSCENE, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_SETCOLOR, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_DRAWSTRETCHPIC, Float(1), Float(2), Float(30), Float(40), Float(0),
    Float(0), Float(1), Float(1), 6]));
  Assert.AreEqual(2, FRig.Renderer.CallCount('AddRefEntityToScene'));
  // AddPolyToScene(shader, verts, polys): one polygon for CG_R_ADDPOLYTOSCENE, the count of the call for the other
  Assert.AreEqual(2, FRig.Renderer.CallCount('AddPolyToScene'));
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('AddPolyToScene 4 3 1') >= 0);
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('AddPolyToScene 4 3 2') >= 0);
  Assert.AreEqual(1, FRig.Renderer.CallCount('AddLightToScene'));
  Assert.AreEqual(1, FRig.Renderer.CallCount('AddAdditiveLightToScene'));
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('RenderScene 2') >= 0);
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('DrawStretchPic 1 2 30 40 6') >= 0);
  Assert.AreEqual(1, FRig.Renderer.CallCount('SetColor'));
  // the ui scene has the same calls, with one polygon
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_CLEARSCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_ADDPOLYTOSCENE, 9, 4, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_RENDERSCENE, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_SETCOLOR, SCENE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_DRAWSTRETCHPIC, Float(0), Float(0), Float(640), Float(480), Float(0),
    Float(0), Float(1), Float(1), 7]));
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('AddPolyToScene 9 4 1') >= 0);
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('DrawStretchPic 0 0 640 480 7') >= 0);
  Put(1, BUFFER, 'maps/oa_dm1.bsp');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_LOADWORLDMAP, BUFFER]));
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('LoadWorld maps/oa_dm1.bsp') >= 0);
end;

procedure TTestQ3ClientServices.LeRisposteSenzaDatiDovrebberoEssereQuelleNeutre;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.CGame);
  // model bounds: a cube of 16 units
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_MODELBOUNDS, 3, BUFFER, OTHER]));
  Assert.AreEqual(Single(-8), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(BUFFER + 8)));
  Assert.AreEqual(Single(8), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(OTHER)));
  // a tag that is not there: false, the origin at zero and the axis clear
  Put(1, SCENE, 'tag_weapon');
  LMemory.Fill(BUFFER, $77, 48);
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_LERPTAG, BUFFER, 3, 0, 1, Float(0.5), SCENE]));
  Assert.AreEqual(0, LMemory.ReadInt32(BUFFER));
  Assert.AreEqual(Single(1), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(BUFFER + 12)));
  Assert.AreEqual(Single(1), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(BUFFER + 28)));
  Assert.AreEqual(Single(1), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(BUFFER + 44)));
  Assert.AreEqual(0, LMemory.ReadInt32(BUFFER + 16));
  // the ui call does the same work and returns 0 whatever the renderer says
  FRig.Memory(TQ3Module.Ui).WriteString(SCENE, 'tag_head', 9);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_CM_LERPTAG, BUFFER, 3, 0, 1, Float(0.5), SCENE]));
  Assert.AreEqual(2, FRig.Renderer.CallCount('LerpTag'));
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_R_INPVS, BUFFER, OTHER]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_LIGHTFORPOINT, BUFFER, 6000, 6100, 6200]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_CM_MARKFRAGMENTS, 3, BUFFER, OTHER, 100, 7000, 20, 8000]));
  // a NULL time offset is allowed
  Put(1, BUFFER, 'old');
  Put(1, OTHER, 'new');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_R_REMAP_SHADER, BUFFER, OTHER, 0]));
  Assert.IsTrue(FRig.Renderer.Log.IndexOf('RemapShader old new') >= 0);
  FRig.Memory(TQ3Module.Ui).WriteString(BUFFER, 'old', 4);
  FRig.Memory(TQ3Module.Ui).WriteString(OTHER, 'new', 4);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_R_REMAP_SHADER, BUFFER, OTHER, 0]));
  Assert.AreEqual(2, FRig.Renderer.CallCount('RemapShader'));
end;

procedure TTestQ3ClientServices.IlGlConfigDovrebbeEssereScrittoComeIlC;
var
  LMemory: IQvmMemory;
  LModule: TQ3Module;
  LNumber: Integer;
begin
  for LModule := TQ3Module.CGame to TQ3Module.Ui do
  begin
    if LModule = TQ3Module.CGame then
      LNumber := CG_GETGLCONFIG
    else
      LNumber := UI_GETGLCONFIG;
    LMemory := FRig.Memory(LModule);
    LMemory.Fill(BUFFER, $77, Q3_GLCONFIG_SIZE + 4);
    Assert.AreEqual(0, FRig.Call(LModule, [LNumber, BUFFER]));
    Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + Q3_GLCONFIG_SIZE)));
    Assert.AreEqual('DelphiDoom recording renderer', string(LMemory.ReadString(BUFFER)));
    Assert.AreEqual(2048, LMemory.ReadInt32(BUFFER + 11264));
    Assert.AreEqual(640, LMemory.ReadInt32(BUFFER + 11304));
    Assert.AreEqual(480, LMemory.ReadInt32(BUFFER + 11308));
    Assert.AreEqual(Single(1.3333334), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(BUFFER + 11312)));
  end;
end;

procedure TTestQ3ClientServices.LeChiamateDelSuonoDiCgameDovrebberoArrivareAlSuono;
var
  LMemory: IQvmMemory;
  LIndex: Integer;
begin
  LMemory := FRig.Memory(TQ3Module.CGame);
  Put(1, BUFFER, 'sound/weapons/rocket/rocklf1a.wav');
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_S_REGISTERSOUND, BUFFER, 0]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_S_REGISTERSOUND, BUFFER, 1]));
  // an origin: a point; no origin: follow the entity
  LMemory.WriteInt32(OTHER, Float(1));
  LMemory.WriteInt32(OTHER + 4, Float(2));
  LMemory.WriteInt32(OTHER + 8, Float(3));
  LMemory.WriteInt32(OTHER + 12, Float(0.5));
  LMemory.WriteInt32(OTHER + 16, Float(0.25));
  LMemory.WriteInt32(OTHER + 20, Float(0.125));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STARTSOUND, OTHER, 5, 2, 1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STARTSOUND, 0, 6, 3, 1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STARTLOCALSOUND, 1, 4]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_CLEARLOOPINGSOUNDS, 1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_ADDLOOPINGSOUND, 7, OTHER, OTHER + 12, 1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_ADDREALLOOPINGSOUND, 8, OTHER, OTHER + 12, 1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STOPLOOPINGSOUND, 7]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_UPDATEENTITYPOSITION, 9, OTHER]));
  for LIndex := 0 to 8 do
    LMemory.WriteInt32(6000 + 4 * LIndex, Float(LIndex + 1));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_RESPATIALIZE, 2, OTHER, 6000, 1]));
  Put(1, BUFFER, 'music/intro.wav');
  Put(1, 6100, 'music/loop.wav');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STARTBACKGROUNDTRACK, BUFFER, 6100]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STARTBACKGROUNDTRACK, BUFFER, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_S_STOPBACKGROUNDTRACK]));
  Assert.AreEqual('register sound/weapons/rocket/rocklf1a.wav 0', FRig.Sound.Calls[0]);
  Assert.AreEqual('register sound/weapons/rocket/rocklf1a.wav 1', FRig.Sound.Calls[1]);
  Assert.AreEqual('start 1 2 3 5 2 1', FRig.Sound.Calls[2]);
  Assert.AreEqual('start follow 6 3 1', FRig.Sound.Calls[3]);
  Assert.AreEqual('local 1 4', FRig.Sound.Calls[4]);
  Assert.AreEqual('clearloops 1', FRig.Sound.Calls[5]);
  Assert.AreEqual('loop 7 1 2 3 0.5 0.25 0.125 1', FRig.Sound.Calls[6]);
  Assert.AreEqual('realloop 8 1 2 3 1', FRig.Sound.Calls[7]);
  Assert.AreEqual('stoploop 7', FRig.Sound.Calls[8]);
  Assert.AreEqual('position 9 1 2 3', FRig.Sound.Calls[9]);
  Assert.AreEqual('respatialize 2 1 2 3 axis 1 2 3 4 5 6 7 8 9 water 1', FRig.Sound.Calls[10]);
  Assert.AreEqual('music music/intro.wav|music/loop.wav', FRig.Sound.Calls[11]);
  Assert.AreEqual('music music/intro.wav|', FRig.Sound.Calls[12]);
  Assert.AreEqual('stopmusic', FRig.Sound.Calls[13]);
end;

procedure TTestQ3ClientServices.LeChiamateDelSuonoDiUiDovrebberoArrivareAlSuono;
begin
  Put(2, BUFFER, 'sound/misc/menu1.wav');
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_S_REGISTERSOUND, BUFFER, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_S_STARTLOCALSOUND, 1, 0]));
  Put(2, 6100, 'music/menu.wav');
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_S_STARTBACKGROUNDTRACK, 6100, 6100]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_S_STOPBACKGROUNDTRACK]));
  Assert.AreEqual('register sound/misc/menu1.wav 0', FRig.Sound.Calls[0]);
  Assert.AreEqual('local 1 0', FRig.Sound.Calls[1]);
  Assert.AreEqual('music music/menu.wav|music/menu.wav', FRig.Sound.Calls[2]);
  Assert.AreEqual('stopmusic', FRig.Sound.Calls[3]);
end;

procedure TTestQ3ClientServices.LeChiamateDeiFilmatiDovrebberoArrivareAlServizio;
var
  LHandle: Integer;
begin
  Put(1, BUFFER, 'idlogo.roq');
  LHandle := FRig.Call(TQ3Module.CGame, [CG_CIN_PLAYCINEMATIC, BUFFER, 1, 2, 3, 4, 5]);
  Assert.AreEqual(0, LHandle);
  FRig.Cinematics.Status := Q3_FMV_PLAY;
  Assert.AreEqual(Q3_FMV_PLAY, FRig.Call(TQ3Module.CGame, [CG_CIN_RUNCINEMATIC, LHandle]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_CIN_DRAWCINEMATIC, LHandle]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_CIN_SETEXTENTS, LHandle, 10, 20, 30, 40]));
  Assert.AreEqual(Q3_FMV_EOF, FRig.Call(TQ3Module.CGame, [CG_CIN_STOPCINEMATIC, LHandle]));
  Put(2, BUFFER, 'video/q3intro.roq');
  // the fake hands out the number of its calls so far as the handle
  LHandle := FRig.Call(TQ3Module.Ui, [UI_CIN_PLAYCINEMATIC, BUFFER, 0, 0, 640, 480, 8]);
  Assert.AreEqual(5, LHandle);
  Assert.AreEqual(Q3_FMV_PLAY, FRig.Call(TQ3Module.Ui, [UI_CIN_RUNCINEMATIC, LHandle]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_CIN_DRAWCINEMATIC, LHandle]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_CIN_SETEXTENTS, LHandle, 1, 1, 2, 2]));
  Assert.AreEqual(Q3_FMV_EOF, FRig.Call(TQ3Module.Ui, [UI_CIN_STOPCINEMATIC, LHandle]));
  Assert.AreEqual('play idlogo.roq 1 2 3 4 5', FRig.Cinematics.Calls[0]);
  Assert.AreEqual('extents 0 10 20 30 40', FRig.Cinematics.Calls[3]);
  Assert.AreEqual('play video/q3intro.roq 0 0 640 480 8', FRig.Cinematics.Calls[5]);
end;

procedure TTestQ3ClientServices.IlParserDovrebbeLeggereIFileEiTokenCosiCheIlC;
var
  LMemory: IQvmMemory;
  LHandle, LKind, LCount: Integer;
  LText: string;
begin
  FRig.AddScriptFile('ui/test.menu', 'menuDef { name "main" rect 640 480 1.5 } // done');
  LMemory := FRig.Memory(TQ3Module.CGame);
  Put(1, BUFFER, 'ui/test.menu');
  LHandle := FRig.Call(TQ3Module.CGame, [CG_PC_LOAD_SOURCE, BUFFER]);
  Assert.IsTrue(LHandle > 0);
  // a file that is not there: handle 0
  Put(1, OTHER, 'ui/missing.menu');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_LOAD_SOURCE, OTHER]));

  LCount := 0;
  LText := '';
  LMemory.Fill(6000, $77, Q3_PCTOKEN_SIZE);
  while FRig.Call(TQ3Module.CGame, [CG_PC_READ_TOKEN, LHandle, 6000]) <> 0 do
  begin
    Inc(LCount);
    LKind := LMemory.ReadInt32(6000);
    LText := LText + string(LMemory.ReadString(6000 + Q3_PCTOKEN_STRING)) + '|';
    if LCount = 1 then
    begin
      Assert.AreEqual(TT_NAME, LKind);
      // strcpy: the seven letters and their zero, and the rest of the field is not touched
      Assert.AreEqual(0, Integer(LMemory.ReadByte(6000 + Q3_PCTOKEN_STRING + 7)));
      Assert.AreEqual($77, Integer(LMemory.ReadByte(6000 + Q3_PCTOKEN_STRING + 8)));
    end;
    if LCount = 2 then
      Assert.AreEqual(TT_PUNCTUATION, LKind);
    if LCount = 4 then
    begin
      // a string comes without its quotes
      Assert.AreEqual(TT_STRING, LKind);
      Assert.AreEqual('main', string(LMemory.ReadString(6000 + Q3_PCTOKEN_STRING)));
    end;
    if LCount = 6 then
    begin
      Assert.AreEqual(TT_NUMBER, LKind);
      Assert.AreEqual(640, LMemory.ReadInt32(6000 + 8));
      Assert.AreEqual(Single(640), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(6000 + 12)));
    end;
    if LCount = 8 then
      Assert.AreEqual(Single(1.5), TQ3SyscallArguments.ToSingle(LMemory.ReadInt32(6000 + 12)));
  end;
  // the comment is skipped
  Assert.AreEqual('menuDef|{|name|main|rect|640|480|1.5|}|', LText);

  // the file name and the line
  LMemory.Fill(6200, $77, 64);
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_PC_SOURCE_FILE_AND_LINE, LHandle, 6200, 6300]));
  Assert.AreEqual('ui/test.menu', string(LMemory.ReadString(6200)));
  Assert.IsTrue(LMemory.ReadInt32(6300) >= 1);
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_PC_FREE_SOURCE, LHandle]));
  // a handle that is not open: 0, and the token is left alone
  LMemory.Fill(6000, $55, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_FREE_SOURCE, LHandle]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_READ_TOKEN, LHandle, 6000]));
  Assert.AreEqual($55, Integer(LMemory.ReadByte(6000)));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_SOURCE_FILE_AND_LINE, LHandle, 6200, 6300]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_READ_TOKEN, 0, 6000]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_PC_READ_TOKEN, 64, 6000]));
end;

procedure TTestQ3ClientServices.IlParserDovrebbeUsareLaStessaTabellaPerCgameEUi;
var
  LHandle: Integer;
begin
  FRig.AddScriptFile('ui/shared.txt', 'one two');
  Put(1, BUFFER, 'ui/shared.txt');
  LHandle := FRig.Call(TQ3Module.CGame, [CG_PC_LOAD_SOURCE, BUFFER]);
  Assert.IsTrue(LHandle > 0);
  // the table of the sources is the one of botlib: a handle of one module is a handle of the other
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_PC_READ_TOKEN, LHandle, 6000]));
  Assert.AreEqual('one', string(FRig.Memory(TQ3Module.Ui).ReadString(6000 + Q3_PCTOKEN_STRING)));
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_PC_FREE_SOURCE, LHandle]));
  Put(2, BUFFER, 'ui/shared.txt');
  Assert.AreEqual(LHandle, FRig.Call(TQ3Module.Ui, [UI_PC_LOAD_SOURCE, BUFFER]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_PC_SOURCE_FILE_AND_LINE, LHandle, 6200, 6300]));
end;

procedure TTestQ3ClientServices.CgAcosDovrebbeDareLeRisposteDelC;
var
  LLines: TStringList;
  LLine: string;
  LInput, LExpected, LActual: Cardinal;
  LCount: Integer;
begin
  // Q_acos of the real common.c on gcc: the float in, the bits of the answer out
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'acos.golden.txt'));
  try
    LCount := 0;
    for LLine in LLines do
    begin
      if Trim(LLine) = '' then
        Continue;
      LInput := Cardinal(StrToInt64('$' + Copy(LLine, 1, 8)));
      LExpected := Cardinal(StrToInt64('$' + Copy(LLine, 10, 8)));
      LActual := Cardinal(FRig.Call(TQ3Module.CGame, [CG_ACOS, Integer(LInput)]));
      Assert.AreEqual(IntToHex(LExpected, 8), IntToHex(LActual, 8), 'acos of ' + IntToHex(LInput, 8));
      Inc(LCount);
    end;
    Assert.IsTrue(LCount > 4000);
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3ClientServices.LeTrappeSenzaGestoreDovrebberoEssereQuelleDelGolden;
var
  LActual, LGolden: TStringList;
  LModule: TQ3Module;
  LEntry: TQ3OpcodeEntry;
  LEntries: TArray<TQ3OpcodeEntry>;
  LOut: string;
begin
  LActual := TStringList.Create;
  try
    for LModule := TQ3Module.CGame to TQ3Module.Ui do
    begin
      LEntries := TQ3OpcodeCatalog.ImportEntries(LModule);
      LActual.Add(Format('%s registered=%d of %d', [TQ3OpcodeCatalog.ModuleName(LModule),
        FRig.Host(LModule).Registry.RegisteredCount, Length(LEntries)]));
      for LEntry in LEntries do
        if not FRig.Host(LModule).Registry.IsRegistered(LEntry.Value) then
          LActual.Add(Format('%s %s', [TQ3OpcodeCatalog.ModuleName(LModule), LEntry.Name]));
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_UNHANDLED_CLIENT_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'unhandled-client.golden.txt'));
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LActual.Free;
  end;
end;

end.
