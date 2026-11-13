{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - the command line of the     }
{  start (M_InitArgv)                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Startup;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>The process and the files of a test; every question goes to Calls</summary>
  TFakeProgramEnvironment = class(TInterfacedObject, IProgramEnvironment)
  public
    Arguments: TArray<string>;
    Files: TDictionary<string, string>;
    Calls: TStringList;
    OnCdRom: Boolean;
    CdRomDrives: string;
    constructor Create;
    destructor Destroy; override;
    function ArgumentCount: Integer;
    function Argument(AIndex: Integer): string;
    function FileExists(const AFileName: string): Boolean;
    function ExpandFileName(const AFileName: string): string;
    function FileNameOf(const APath: string): string;
    function IsProgramOnCdRom: Boolean;
    function IsCdRomDrive(ADrive: Char): Boolean;
    function TryReadDefaultFile(const AFileName: string; out AText: string): Boolean;
    procedure WriteDefaultFile(const AFileName, AText: string);
  end;

  /// <summary>The working folder of the CD-ROM is the drive of a test</summary>
  TFakeSaveFileNames = class(TInterfacedObject, ISaveFileNames)
  public
    Folder: string;
    function IsCdRomMode: Boolean;
    function ResolveName(const AFileName: string): string;
  end;

  [TestFixture]
  [Category('commandline')]
  TTestCommandLineStartup = class(TObject)
  strict private
    FSeed: Cardinal;
    function Next(ARange: Integer): Integer;
    function OldCollect(const AEnvironment: TFakeProgramEnvironment;
      const ASaveFileNames: ISaveFileNames): ICommandLine;
    function NewCollect(const AEnvironment: TFakeProgramEnvironment;
      const ASaveFileNames: ISaveFileNames): ICommandLine;
    function RandomEnvironment: TFakeProgramEnvironment;
  public
    [Test]
    procedure DovrebbeMettereInMaiuscoloEdEspandereIFile;
    [Test]
    procedure DovrebbeLeggereIlFileDegliArgomentiDiPartenza;
    [Test]
    procedure DovrebbeScrivereIlFileQuandoManca;
    [Test]
    procedure DovrebbeLeggereAncheIlFileDelCdRom;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    [Test]
    procedure DovrebbeDareComeIlVecchioCodiceSuScenariCasuali;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory,
  DelphiDoom.CommandLine.DefaultFile;

const
  APP = 'DelphiDoom';
  DEFAULT_FILE = 'Doom32.cmd';

{ TFakeProgramEnvironment }

constructor TFakeProgramEnvironment.Create;
begin
  inherited Create;
  Files := TDictionary<string, string>.Create;
  Calls := TStringList.Create;
end;

destructor TFakeProgramEnvironment.Destroy;
begin
  Files.Free;
  Calls.Free;
  inherited Destroy;
end;

function TFakeProgramEnvironment.ArgumentCount: Integer;
begin
  Result := High(Arguments);
end;

function TFakeProgramEnvironment.Argument(AIndex: Integer): string;
begin
  Result := Arguments[AIndex];
end;

function TFakeProgramEnvironment.FileExists(const AFileName: string): Boolean;
begin
  Calls.Add('exists ' + AFileName);
  Result := Files.ContainsKey(UpperCase(AFileName));
end;

function TFakeProgramEnvironment.ExpandFileName(const AFileName: string): string;
begin
  Result := 'C:\GAME\' + AFileName;
end;

function TFakeProgramEnvironment.FileNameOf(const APath: string): string;
begin
  Result := ExtractFileName(APath);
end;

function TFakeProgramEnvironment.IsProgramOnCdRom: Boolean;
begin
  Calls.Add('cdrom');
  Result := OnCdRom;
end;

function TFakeProgramEnvironment.IsCdRomDrive(ADrive: Char): Boolean;
begin
  Calls.Add('drive ' + ADrive);
  Result := Pos(ADrive, CdRomDrives) > 0;
end;

function TFakeProgramEnvironment.TryReadDefaultFile(const AFileName: string;
  out AText: string): Boolean;
begin
  Calls.Add('read ' + AFileName);
  Result := Files.TryGetValue(UpperCase(AFileName), AText);
end;

procedure TFakeProgramEnvironment.WriteDefaultFile(const AFileName, AText: string);
begin
  Calls.Add('write ' + AFileName + ' ' + IntToStr(Length(AText)));
end;

{ TFakeSaveFileNames }

function TFakeSaveFileNames.IsCdRomMode: Boolean;
begin
  Result := Folder <> '';
end;

function TFakeSaveFileNames.ResolveName(const AFileName: string): string;
begin
  Result := Folder + AFileName;
end;

{ TTestCommandLineStartup }

function TTestCommandLineStartup.Next(ARange: Integer): Integer;
begin
  FSeed := FSeed * 1664525 + 1013904223;
  Result := Integer((FSeed shr 8) mod Cardinal(ARange));
end;

// M_InitArgv of m_argv at 63a151cc, up to argv_builder.Build: ParamStr, strupper, fexists,
// fexpand, fname, I_IsCDRomDrive and the TDStringList of the default file are the environment
function TTestCommandLineStartup.OldCollect(const AEnvironment: TFakeProgramEnvironment;
  const ASaveFileNames: ISaveFileNames): ICommandLine;
var
  i: integer;
  defargv: string;
  programname: string;
  argument: string;
  argv_builder: ICommandLineBuilder;

  procedure LoadFromDefaultCMD(trywrite: boolean);
  var
    LText: string;
  begin
    if AEnvironment.TryReadDefaultFile(defargv, LText) then
      argv_builder.AddDefaultFile(LText)
    else if trywrite then
      AEnvironment.WriteDefaultFile(defargv, TDefaultArgumentsFile.Template(APP,
        AEnvironment.FileNameOf(programname)));
  end;

begin
  argv_builder := TCommandLineFactory.CreateBuilder;
  for i := 0 to AEnvironment.ArgumentCount do
  begin
    argument := UpperCase(AEnvironment.Argument(i));
    if argument <> '' then
      if argument[1] <> '-' then
        if AEnvironment.FileExists(argument) then
          argument := AEnvironment.ExpandFileName(argument);
    if i = 0 then
      programname := argument;
    argv_builder.Add(argument);
  end;

  defargv := DEFAULT_FILE;
  LoadFromDefaultCMD(not AEnvironment.IsProgramOnCdRom);

  if AEnvironment.IsProgramOnCdRom then
  begin
    defargv := ASaveFileNames.ResolveName(DEFAULT_FILE);
    LoadFromDefaultCMD(not AEnvironment.IsCdRomDrive(defargv[1]));
  end;

  Result := argv_builder.Build;
end;

function TTestCommandLineStartup.NewCollect(const AEnvironment: TFakeProgramEnvironment;
  const ASaveFileNames: ISaveFileNames): ICommandLine;
begin
  Result := TCommandLineFactory.CreateStartup(TCommandLineFactory.CreateBuilder, ASaveFileNames,
    AEnvironment, APP, DEFAULT_FILE).Collect;
end;

function TTestCommandLineStartup.RandomEnvironment: TFakeProgramEnvironment;
const
  WORDS: array[0..9] of string = ('-warp', '1', '-skill', '4', '-file', 'mod.wad', 'missing.wad',
    '@resp.txt', '', '-Config');
var
  LIndex: Integer;
begin
  Result := TFakeProgramEnvironment.Create;
  SetLength(Result.Arguments, 1 + Next(12));
  Result.Arguments[0] := 'doom32.exe';
  for LIndex := 1 to High(Result.Arguments) do
    Result.Arguments[LIndex] := WORDS[Next(Length(WORDS))];
  if Next(2) = 0 then
    Result.Files.Add('MOD.WAD', '');
  if Next(2) = 0 then
    Result.Files.Add('DOOM32.CMD', '-nosound -file other.wad'#13#10);
  if Next(3) = 0 then
    Result.Files.Add('D:\WORK\DOOM32.CMD', '// comment'#13#10'-devparm'#13#10);
  Result.OnCdRom := Next(3) = 0;
  if Next(2) = 0 then
    Result.CdRomDrives := 'D';
end;

procedure TTestCommandLineStartup.DovrebbeMettereInMaiuscoloEdEspandereIFile;
var
  LEnvironment: TFakeProgramEnvironment;
  LSave: TFakeSaveFileNames;
  LLine: ICommandLine;
  LReference: IProgramEnvironment;
  LSaveReference: ISaveFileNames;
begin
  LEnvironment := TFakeProgramEnvironment.Create;
  LReference := LEnvironment;
  LSave := TFakeSaveFileNames.Create;
  LSaveReference := LSave;
  LEnvironment.Arguments := TArray<string>.Create('doom32.exe', '-warp', 'mod.wad', 'none.wad', '');
  LEnvironment.Files.Add('MOD.WAD', '');
  LLine := NewCollect(LEnvironment, LSaveReference);
  Assert.AreEqual('DOOM32.EXE', LLine[0], False);
  Assert.AreEqual('-WARP', LLine[1], False);
  Assert.AreEqual('C:\GAME\MOD.WAD', LLine[2], False);
  Assert.AreEqual('NONE.WAD', LLine[3], False);
  Assert.AreEqual(-1, LEnvironment.Calls.IndexOf('exists -WARP'));
end;

procedure TTestCommandLineStartup.DovrebbeLeggereIlFileDegliArgomentiDiPartenza;
var
  LEnvironment: TFakeProgramEnvironment;
  LLine: ICommandLine;
  LReference: IProgramEnvironment;
begin
  LEnvironment := TFakeProgramEnvironment.Create;
  LReference := LEnvironment;
  LEnvironment.Arguments := TArray<string>.Create('doom32.exe');
  LEnvironment.Files.Add('DOOM32.CMD', '-nomusic');
  LLine := NewCollect(LEnvironment, TFakeSaveFileNames.Create);
  Assert.IsTrue(LLine.IndexOf('-NOMUSIC') > 0);
end;

procedure TTestCommandLineStartup.DovrebbeScrivereIlFileQuandoManca;
var
  LEnvironment: TFakeProgramEnvironment;
  LReference: IProgramEnvironment;
begin
  LEnvironment := TFakeProgramEnvironment.Create;
  LReference := LEnvironment;
  LEnvironment.Arguments := TArray<string>.Create('doom32.exe');
  NewCollect(LEnvironment, TFakeSaveFileNames.Create);
  Assert.IsTrue(LEnvironment.Calls[LEnvironment.Calls.Count - 2].StartsWith('write Doom32.cmd'));
end;

procedure TTestCommandLineStartup.DovrebbeLeggereAncheIlFileDelCdRom;
var
  LEnvironment: TFakeProgramEnvironment;
  LSave: TFakeSaveFileNames;
  LLine: ICommandLine;
  LReference: IProgramEnvironment;
  LSaveReference: ISaveFileNames;
begin
  LEnvironment := TFakeProgramEnvironment.Create;
  LReference := LEnvironment;
  LSave := TFakeSaveFileNames.Create;
  LSaveReference := LSave;
  LSave.Folder := 'C:\WORK\';
  LEnvironment.Arguments := TArray<string>.Create('doom32.exe');
  LEnvironment.OnCdRom := True;
  LEnvironment.CdRomDrives := 'D';
  LEnvironment.Files.Add('C:\WORK\DOOM32.CMD', '-devparm');
  LLine := NewCollect(LEnvironment, LSaveReference);
  Assert.IsTrue(LLine.IndexOf('-DEVPARM') > 0);
  Assert.IsTrue(LEnvironment.Calls.IndexOf('drive C') >= 0);
  // on a CD-ROM the default file of the program is not written
  Assert.AreEqual(-1, LEnvironment.Calls.IndexOf('write Doom32.cmd'));
end;

procedure TTestCommandLineStartup.DovrebbeRifiutareDipendenzeNil;
var
  LEnvironment: IProgramEnvironment;
  LSave: ISaveFileNames;
begin
  LEnvironment := TFakeProgramEnvironment.Create;
  LSave := TFakeSaveFileNames.Create;
  Assert.WillRaise(procedure begin TCommandLineFactory.CreateStartup(nil, LSave, LEnvironment, APP, DEFAULT_FILE); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TCommandLineFactory.CreateStartup(TCommandLineFactory.CreateBuilder, nil,
    LEnvironment, APP, DEFAULT_FILE); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TCommandLineFactory.CreateStartup(TCommandLineFactory.CreateBuilder, LSave,
    nil, APP, DEFAULT_FILE); end, EArgumentNilException);
end;

procedure TTestCommandLineStartup.DovrebbeDareComeIlVecchioCodiceSuScenariCasuali;
var
  LCase: Integer;
  LOldEnvironment, LNewEnvironment: TFakeProgramEnvironment;
  LOldRef, LNewRef: IProgramEnvironment;
  LSave: TFakeSaveFileNames;
  LSaveRef: ISaveFileNames;
  LOld, LNew: ICommandLine;
  LSeed: Cardinal;
begin
  FSeed := 185;
  for LCase := 1 to 2000 do
  begin
    LSeed := FSeed;
    LOldEnvironment := RandomEnvironment;
    LOldRef := LOldEnvironment;
    FSeed := LSeed;
    LNewEnvironment := RandomEnvironment;
    LNewRef := LNewEnvironment;
    LSave := TFakeSaveFileNames.Create;
    LSaveRef := LSave;
    if Next(2) = 0 then
      LSave.Folder := 'D:\WORK\';
    LOld := OldCollect(LOldEnvironment, LSaveRef);
    LNew := NewCollect(LNewEnvironment, LSaveRef);
    Assert.AreEqual(LOld.Text, LNew.Text, False, 'caso ' + IntToStr(LCase));
    Assert.AreEqual(LOldEnvironment.Calls.Text, LNewEnvironment.Calls.Text, False, 'caso ' + IntToStr(LCase));
  end;
end;

end.
