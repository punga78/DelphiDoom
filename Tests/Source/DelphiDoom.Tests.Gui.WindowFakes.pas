{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - fakes of the windows of Doom 3       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowFakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.UserInterface, DelphiDoom.Gui.Window.Factory,
  DelphiDoom.Tests.Gui.Fakes;

type
  /// <summary>The log as lines "P: text" and "W: text", as the harness of the C++ writes them</summary>
  TGuiWindowFakeLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  /// <summary>The game side of the scripts: every call is a line "host ..."</summary>
  TGuiWindowFakeHost = class(TInterfacedObject, IGuiGameHost)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure LocalSound(const AName: AnsiString);
    procedure EndGame;
    procedure ResetCinematic(const ABackground: AnsiString; const ATime: Integer);
  end;

  /// <summary>One table: the value is the entry of the index (the integer part), clamped</summary>
  TGuiWindowFakeTables = class(TInterfacedObject, IGuiTables)
  strict private
    FName: AnsiString;
    FValues: TArray<Single>;
  public
    constructor Create(const AName: AnsiString; const AValues: TArray<Single>);
    function FindTable(const AName: AnsiString; out AIndex: Integer): Boolean;
    function Lookup(const AIndex: Integer; const AValue: Single): Single;
  end;

  /// <summary>A language dictionary with one entry</summary>
  TGuiWindowFakeLanguage = class(TInterfacedObject, IGuiLanguage)
  strict private
    FKey: AnsiString;
    FValue: AnsiString;
  public
    constructor Create(const AKey, AValue: AnsiString);
    function GetString(const AText: AnsiString): AnsiString;
  end;

  /// <summary>Fonts by order of the first request, from 1</summary>
  TGuiWindowFakeFonts = class(TInterfacedObject, IGuiFontLookup)
  strict private
    FNames: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function FindFont(const AName: AnsiString): Integer;
  end;

  /// <summary>A gui over files in memory with a log and a host that write to the same lines</summary>
  TGuiWindowWorld = class
  strict private
    FLines: TStringList;
    FFiles: IGuiFakeFiles;
    FInterface: TGuiUserInterface;
  public
    constructor Create(const ATables: IGuiTables = nil; const ALanguage: IGuiLanguage = nil;
      const AFonts: IGuiFontLookup = nil);
    destructor Destroy; override;
    /// <summary>Puts the text in a file in memory and reads it</summary>
    function Load(const AText: AnsiString; const AName: AnsiString = 'test.gui'): Boolean;
    property Lines: TStringList read FLines;
    property Files: IGuiFakeFiles read FFiles;
    property UserInterface: TGuiUserInterface read FInterface;
  end;

implementation

{ TGuiWindowFakeLog }

constructor TGuiWindowFakeLog.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiWindowFakeLog.Printf(const AMessage: string);
begin
  FLines.Add('P: ' + AMessage);
end;

procedure TGuiWindowFakeLog.Warning(const AMessage: string);
begin
  FLines.Add('W: ' + AMessage);
end;

{ TGuiWindowFakeHost }

constructor TGuiWindowFakeHost.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiWindowFakeHost.LocalSound(const AName: AnsiString);
begin
  FLines.Add('host sound ' + string(AName));
end;

procedure TGuiWindowFakeHost.EndGame;
begin
  FLines.Add('host endgame');
end;

procedure TGuiWindowFakeHost.ResetCinematic(const ABackground: AnsiString; const ATime: Integer);
begin
  FLines.Add(Format('host cinematic %s %d', [string(ABackground), ATime]));
end;

{ TGuiWindowFakeTables }

constructor TGuiWindowFakeTables.Create(const AName: AnsiString; const AValues: TArray<Single>);
begin
  inherited Create;
  FName := AName;
  FValues := AValues;
end;

function TGuiWindowFakeTables.FindTable(const AName: AnsiString; out AIndex: Integer): Boolean;
begin
  Result := SameText(string(AName), string(FName));
  AIndex := 7;
end;

function TGuiWindowFakeTables.Lookup(const AIndex: Integer; const AValue: Single): Single;
var
  LIndex: Integer;
begin
  LIndex := Trunc(AValue);
  if LIndex < 0 then
    LIndex := 0;
  if LIndex > High(FValues) then
    LIndex := High(FValues);
  Result := FValues[LIndex];
end;

{ TGuiWindowFakeLanguage }

constructor TGuiWindowFakeLanguage.Create(const AKey, AValue: AnsiString);
begin
  inherited Create;
  FKey := AKey;
  FValue := AValue;
end;

function TGuiWindowFakeLanguage.GetString(const AText: AnsiString): AnsiString;
begin
  if AText = FKey then
    Result := FValue
  else
    Result := AText;
end;

{ TGuiWindowFakeFonts }

constructor TGuiWindowFakeFonts.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
end;

destructor TGuiWindowFakeFonts.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TGuiWindowFakeFonts.FindFont(const AName: AnsiString): Integer;
begin
  Result := FNames.IndexOf(string(AName));
  if Result < 0 then
    Result := FNames.Add(string(AName));
  Inc(Result);
end;

{ TGuiWindowWorld }

constructor TGuiWindowWorld.Create(const ATables: IGuiTables; const ALanguage: IGuiLanguage;
  const AFonts: IGuiFontLookup);
begin
  inherited Create;
  FLines := TStringList.Create;
  FFiles := TGuiFakeFileSystem.Create;
  FInterface := TGuiUserInterface.Create(FFiles, TGuiWindowFakeLog.Create(FLines), TGuiWindowFactory.Create,
    TGuiWindowFakeHost.Create(FLines), ALanguage, ATables, AFonts);
end;

destructor TGuiWindowWorld.Destroy;
begin
  FInterface.Free;
  FLines.Free;
  inherited Destroy;
end;

function TGuiWindowWorld.Load(const AText: AnsiString; const AName: AnsiString): Boolean;
begin
  FFiles.Add(AName, AText);
  Result := FInterface.InitFromFile(AName);
end;

end.
