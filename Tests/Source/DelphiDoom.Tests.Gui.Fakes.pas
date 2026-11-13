{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - fakes of the services                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DelphiDoom.Gui.Types,
  DelphiDoom.Gui.Intf, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>Files from memory first, then from a folder (the root of the menu files); nothing is written</summary>
  TGuiFakeFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FRoot: string;
    FFiles: TDictionary<AnsiString, TBytes>;
  public
    constructor Create(const ARoot: string = '');
    destructor Destroy; override;
    procedure Add(const AName, AContent: AnsiString); overload;
    procedure Add(const AName: AnsiString; const ABytes: TBytes); overload;
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

  /// <summary>The transcript lines "log ..." of the messages, as the C driver prints them</summary>
  TGuiFakeLog = class(TInterfacedObject, IGuiLog)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure Error(const AFileName: AnsiString; const ALine: Integer; const AText: string);
    procedure Warning(const AFileName: AnsiString; const ALine: Integer; const AText: string);
    procedure Info(const AText: string);
  end;

  /// <summary>Handles by name, one table per kind, from 1; every call is a transcript line "reg ..."</summary>
  TGuiFakeAssets = class(TInterfacedObject, IGuiAssetRegistry)
  strict private
    FLines: TStrings;
    FShaders: TList<AnsiString>;
    FModels: TList<AnsiString>;
    FSounds: TList<AnsiString>;
    function Handle(const AList: TList<AnsiString>; const AName: AnsiString): Integer;
  public
    constructor Create(const ALines: TStrings);
    destructor Destroy; override;
    function RegisterShader(const AName: AnsiString): Integer;
    function RegisterModel(const AName: AnsiString): Integer;
    function RegisterSound(const AName: AnsiString; const ACompressed: Boolean): Integer;
  end;

  /// <summary>The game side of the scripts: every call is a transcript line "host ..."</summary>
  TGuiFakeHost = class(TInterfacedObject, IGuiScriptHost, IGuiMediaHost)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure RunCommand(const AItem: TObject; const ACommand: AnsiString; const AArguments: TArray<AnsiString>);
    procedure OpenMenu(const AName: AnsiString);
    procedure CloseMenu(const AName: AnsiString);
    function GetCvarValue(const AName: AnsiString): Single;
    procedure SetCvar(const AName, AValue: AnsiString);
    procedure ExecuteText(const AWhen: Integer; const AText: AnsiString);
    function GetTeamColor(out AColor: TGuiColor): Boolean;
    procedure StartLocalSound(const ASound, AChannel: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
    procedure StopCinematic(const AHandle: Integer);
  end;

  /// <summary>A fixed answer</summary>
  TGuiFakeRandom = class(TInterfacedObject, IGuiRandom)
  strict private
    FValue: Integer;
  public
    constructor Create(const AValue: Integer);
    function Next(const ARange: Integer): Integer;
  end;

/// <summary>A token source over a text in memory (the file "test.menu"), the messages of the parser to the log if given</summary>
function OpenGuiSource(const AText: AnsiString; const ALog: IGuiLog = nil): IGuiTokenSource;

/// <summary>The folder of the data of the tests of this library, with a closing separator</summary>
function GuiDataFolder: string;

implementation

uses
  DelphiDoom.Gui.Factory;

function OpenGuiSource(const AText: AnsiString; const ALog: IGuiLog): IGuiTokenSource;
var
  LFiles: TGuiFakeFileSystem;
  LSystem: IIdLibFileSystem;
begin
  LFiles := TGuiFakeFileSystem.Create;
  LSystem := LFiles;
  LFiles.Add('test.menu', AText);
  Result := TGuiFactory.CreateSourceLoader(LSystem, ALog).Load('test.menu');
end;

function GuiDataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Gui\');
end;

{ TGuiFakeFileSystem }

constructor TGuiFakeFileSystem.Create(const ARoot: string);
begin
  inherited Create;
  FRoot := ARoot;
  FFiles := TDictionary<AnsiString, TBytes>.Create;
end;

destructor TGuiFakeFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TGuiFakeFileSystem.Add(const AName, AContent: AnsiString);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AContent));
  if Length(AContent) > 0 then
    Move(AContent[1], LBytes[0], Length(AContent));
  FFiles.AddOrSetValue(AName, LBytes);
end;

procedure TGuiFakeFileSystem.Add(const AName: AnsiString; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(AName, ABytes);
end;

function TGuiFakeFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LPath: string;
begin
  AFile := Default(TIdLibFileData);
  AFile.FullPath := AName;
  if FFiles.TryGetValue(AName, AFile.Data) then
    Exit(True);
  if FRoot = '' then
    Exit(False);
  LPath := FRoot + StringReplace(string(AName), '/', '\', [rfReplaceAll]);
  if not FileExists(LPath) then
    Exit(False);
  AFile.Data := TFile.ReadAllBytes(LPath);
  Result := True;
end;

function TGuiFakeFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

{ TGuiFakeLog }

constructor TGuiFakeLog.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiFakeLog.Error(const AFileName: AnsiString; const ALine: Integer; const AText: string);
begin
  FLines.Add('log ^1ERROR: ' + string(AFileName) + ', line ' + IntToStr(ALine) + ': ' + TrimRight(AText));
end;

procedure TGuiFakeLog.Warning(const AFileName: AnsiString; const ALine: Integer; const AText: string);
begin
  FLines.Add('log ^3WARNING: ' + string(AFileName) + ', line ' + IntToStr(ALine) + ': ' + TrimRight(AText));
end;

procedure TGuiFakeLog.Info(const AText: string);
begin
  FLines.Add('log ' + TrimRight(AText));
end;

{ TGuiFakeAssets }

constructor TGuiFakeAssets.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FShaders := TList<AnsiString>.Create;
  FModels := TList<AnsiString>.Create;
  FSounds := TList<AnsiString>.Create;
end;

destructor TGuiFakeAssets.Destroy;
begin
  FSounds.Free;
  FModels.Free;
  FShaders.Free;
  inherited Destroy;
end;

function TGuiFakeAssets.Handle(const AList: TList<AnsiString>; const AName: AnsiString): Integer;
begin
  Result := AList.IndexOf(AName);
  if Result < 0 then
    Result := AList.Add(AName);
  Inc(Result);
end;

function TGuiFakeAssets.RegisterShader(const AName: AnsiString): Integer;
begin
  Result := Handle(FShaders, AName);
  FLines.Add(Format('reg shader %d "%s"', [Result, string(AName)]));
end;

function TGuiFakeAssets.RegisterModel(const AName: AnsiString): Integer;
begin
  Result := Handle(FModels, AName);
  FLines.Add(Format('reg model %d "%s"', [Result, string(AName)]));
end;

function TGuiFakeAssets.RegisterSound(const AName: AnsiString; const ACompressed: Boolean): Integer;
begin
  Result := Handle(FSounds, AName);
  FLines.Add(Format('reg sound %d "%s" %d', [Result, string(AName), Ord(ACompressed)]));
end;

{ TGuiFakeHost }

constructor TGuiFakeHost.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiFakeHost.RunCommand(const AItem: TObject; const ACommand: AnsiString;
  const AArguments: TArray<AnsiString>);
var
  LLine: string;
  LArgument: AnsiString;
begin
  LLine := 'host command';
  for LArgument in AArguments do
    LLine := LLine + ' "' + string(LArgument) + '"';
  FLines.Add(LLine);
end;

procedure TGuiFakeHost.OpenMenu(const AName: AnsiString);
begin
  FLines.Add('host open "' + string(AName) + '"');
end;

procedure TGuiFakeHost.CloseMenu(const AName: AnsiString);
begin
  FLines.Add('host close "' + string(AName) + '"');
end;

function TGuiFakeHost.GetCvarValue(const AName: AnsiString): Single;
begin
  if AName = 'zero' then
    Result := 0
  else
    Result := 1;
end;

procedure TGuiFakeHost.SetCvar(const AName, AValue: AnsiString);
begin
  FLines.Add('host setcvar "' + string(AName) + '" "' + string(AValue) + '"');
end;

procedure TGuiFakeHost.ExecuteText(const AWhen: Integer; const AText: AnsiString);
begin
  FLines.Add('host exec ' + IntToStr(AWhen) + ' "' + string(AText) + '"');
end;

function TGuiFakeHost.GetTeamColor(out AColor: TGuiColor): Boolean;
begin
  AColor[0] := 0.25;
  AColor[1] := 0.5;
  AColor[2] := 0.75;
  AColor[3] := 1.0;
  Result := True;
end;

procedure TGuiFakeHost.StartLocalSound(const ASound, AChannel: Integer);
begin
  FLines.Add(Format('host sound %d %d', [ASound, AChannel]));
end;

procedure TGuiFakeHost.StartBackgroundTrack(const AIntro, ALoop: AnsiString);
begin
  FLines.Add('host background "' + string(AIntro) + '" "' + string(ALoop) + '"');
end;

procedure TGuiFakeHost.StopBackgroundTrack;
begin
  FLines.Add('host stopbackground');
end;

procedure TGuiFakeHost.StopCinematic(const AHandle: Integer);
begin
  FLines.Add('host stopcinematic ' + IntToStr(AHandle));
end;

{ TGuiFakeRandom }

constructor TGuiFakeRandom.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TGuiFakeRandom.Next(const ARange: Integer): Integer;
begin
  Result := FValue mod ARange;
end;

end.
