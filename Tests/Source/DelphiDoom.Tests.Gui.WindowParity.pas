{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - parity with the C++ of Doom 3        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WindowParity;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Runs the scenarios of Tests\Data\Gui\window\window.input.txt with the classes of Libs\Gui and
  ///   compares the text with the answer of the real windows of Doom 3 (window.golden.txt, made by
  ///   the harness of Tools\Verifica\111 with the C++ of ui\Window.cpp, Winvar.h, RegExp.cpp, GuiScript.cpp...)
  /// </summary>
  [TestFixture]
  [Category('GuiWindow')]
  [Category('Parity')]
  TTestGuiWindowParity = class
  public
    [Test]
    procedure IScenariCoincidonoConIlCpp;
    [Test]
    procedure IlGoldenHaTuttiICasi;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Gui.UserInterface, DelphiDoom.Gui.Window.Factory,
  DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Tests.Gui.Fakes, DelphiDoom.Tests.Gui.WindowFakes, DelphiDoom.Tests.Gui.WindowDump;

type
  /// <summary>The operations of a scenario, as the driver of the C++ harness reads them</summary>
  TScenarioRunner = class
  strict private
    FLines: TStringList;
    FFiles: IGuiFakeFiles;
    FFonts: IInterface;
    FInterface: TGuiUserInterface;
    function NewInterface: TGuiUserInterface;
    function Unescape(const AText: string): string;
    procedure RunOperation(const AText: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run(const AInput: TStrings);
    property Lines: TStringList read FLines;
  end;

constructor TScenarioRunner.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FFiles := TGuiFakeFileSystem.Create;
  FFonts := TGuiWindowFakeFonts.Create;
end;

destructor TScenarioRunner.Destroy;
begin
  FInterface.Free;
  FLines.Free;
  inherited Destroy;
end;

function TScenarioRunner.NewInterface: TGuiUserInterface;
var
  LFonts: IGuiFontLookup;
begin
  Supports(FFonts, IGuiFontLookup, LFonts);
  Result := TGuiUserInterface.Create(FFiles, TGuiWindowFakeLog.Create(FLines), TGuiWindowFactory.Create,
    TGuiWindowFakeHost.Create(FLines), nil, nil, LFonts);
end;

function TScenarioRunner.Unescape(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) then
    begin
      Inc(LIndex);
      case AText[LIndex] of
        'n':
          Result := Result + #10;
        't':
          Result := Result + #9;
      else
        Result := Result + AText[LIndex];
      end;
    end
    else
      Result := Result + AText[LIndex];
    Inc(LIndex);
  end;
end;

procedure TScenarioRunner.RunOperation(const AText: string);
var
  LWords: TArray<string>;
  LKey: string;
  LActivation: AnsiString;
begin
  FLines.Add('> ' + AText);
  LWords := AText.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if LWords[0] = 'load' then
  begin
    FInterface.Free;
    FInterface := NewInterface;
    FInterface.InitFromFile(AnsiString(LWords[1]));
  end
  else if LWords[0] = 'frame' then
    FInterface.RunFrame(StrToInt(LWords[1]))
  else if LWords[0] = 'state' then
  begin
    LKey := LWords[1];
    if Length(AText) > 6 + Length(LKey) + 1 then
      FInterface.SetStateString(AnsiString(LKey), AnsiString(Unescape(Copy(AText, 6 + Length(LKey) + 2, MaxInt))))
    else
      FInterface.SetStateString(AnsiString(LKey), '');
  end
  else if LWords[0] = 'statechanged' then
    FInterface.StateChanged(StrToInt(LWords[1]), False)
  else if LWords[0] = 'named' then
    FInterface.HandleNamedEvent(AnsiString(LWords[1]))
  else if LWords[0] = 'activate' then
  begin
    LActivation := FInterface.Activate(StrToInt(LWords[1]) <> 0, StrToInt(LWords[2]));
    FLines.Add('act "' + string(LActivation) + '"');
  end
  else if LWords[0] = 'trigger' then
    FInterface.Trigger(StrToInt(LWords[1]))
  else if LWords[0] = 'dump' then
  begin
    FLines.Add(Format('I interactive=%d pending="%s"', [Ord(FInterface.Interactive),
      string(FInterface.PendingCommand)]));
    DumpWindow(FInterface.Desktop, FLines);
  end;
end;

procedure TScenarioRunner.Run(const AInput: TStrings);
var
  LLine: string;
  LFileName: string;
  LFileText: string;
  LInFile: Boolean;

  procedure CloseFile;
  begin
    if LInFile then
      FFiles.Add(AnsiString(LFileName), AnsiString(LFileText));
    LInFile := False;
  end;

begin
  LInFile := False;
  for LLine in AInput do
  begin
    if LLine.StartsWith('#') then
      Continue;
    if LLine.StartsWith('@case ') then
    begin
      CloseFile;
      FLines.Add('## ' + Copy(LLine, 7, MaxInt));
      FFiles := TGuiFakeFileSystem.Create;
      FreeAndNil(FInterface);
    end
    else if LLine = '@end' then
      CloseFile
    else if LLine.StartsWith('@file ') then
    begin
      CloseFile;
      LFileName := Copy(LLine, 7, MaxInt);
      LFileText := '';
      LInFile := True;
    end
    else if LLine.StartsWith('@op ') then
    begin
      CloseFile;
      RunOperation(Copy(LLine, 5, MaxInt));
    end
    else if LInFile then
      LFileText := LFileText + LLine + #10;
  end;
end;

{ TTestGuiWindowParity }

procedure TTestGuiWindowParity.IScenariCoincidonoConIlCpp;
var
  LInput: TStringList;
  LGolden: TStringList;
  LRunner: TScenarioRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TScenarioRunner.Create;
  try
    LInput.LoadFromFile(GuiDataFolder + 'window\window.input.txt');
    LGolden.LoadFromFile(GuiDataFolder + 'window\window.golden.txt');
    LRunner.Run(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LRunner.Lines.Count then
        Assert.Fail('The run ends at line ' + IntToStr(LIndex + 1) + ', the golden has ' + IntToStr(LGolden.Count));
      if LGolden[LIndex] <> LRunner.Lines[LIndex] then
      begin
        LRunner.Lines.SaveToFile(ChangeFileExt(ParamStr(0), '.window.actual.txt'));
        Assert.Fail(Format('Line %d: golden [%s] actual [%s]', [LIndex + 1, LGolden[LIndex], LRunner.Lines[LIndex]]));
      end;
    end;
    Assert.AreEqual(LGolden.Count, LRunner.Lines.Count);
  finally
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

procedure TTestGuiWindowParity.IlGoldenHaTuttiICasi;
var
  LGolden: TStringList;
  LCount: Integer;
  LLine: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(GuiDataFolder + 'window\window.golden.txt');
    LCount := 0;
    for LLine in LGolden do
      if LLine.StartsWith('## ') then
        Inc(LCount);
    Assert.AreEqual(13, LCount);
  finally
    LGolden.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWindowParity);

end.
