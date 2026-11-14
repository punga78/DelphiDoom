{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the scenarios of the C++ harness     }
{                                                                              }
{  Reads the scenarios of Tools\Verifica\111 (the files Tests\Data\Gui\window\ }
{  and \draw\ ...input.txt) and runs them with the classes of Libs\Gui: the    }
{  text it writes is what the driver of the C++ harness writes for the real    }
{  code of Doom 3.                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Harness;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Cvars, DelphiDoom.Gui.DrawContext,
  DelphiDoom.Gui.UserInterface, DelphiDoom.Tests.Gui.DrawFakes;

type
  /// <summary>
  ///   The operations of a scenario: "load", "frame", "dump"... on a gui and "dc ..." on the device context.
  ///   Each case starts with the fonts for fonts/english, a table of console variables and an initialized
  ///   device context, as the driver does.
  /// </summary>
  TGuiHarnessRunner = class
  strict private
    FLines: TStringList;
    FFiles: TGuiHarnessFiles;
    FFilesRef: IInterface;
    FMaterials: TGuiHarnessMaterials;
    FMaterialsRef: IInterface;
    FCvars: TGuiCvarSet;
    FCvarsRef: IInterface;
    FSurfaceRef: IInterface;
    FLogRef: IInterface;
    FDrawContext: TGuiDrawContext;
    FInterface: TGuiUserInterface;
    function Unescape(const AText: string; const AWithReturn: Boolean): string;
    function Number(const AText: string): Single;
    function Color(const AWords: TArray<string>; const AIndex: Integer): TIdVec4;
    function RestFrom(const AText: string; const AWords: Integer): string;
    procedure StartCase;
    procedure NewInterface;
    procedure RunDeviceContext(const AText: string; const AWords: TArray<string>);
    procedure RunOperation(const AText: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run(const AInput: TStrings);
    property Lines: TStringList read FLines;
    property DrawContext: TGuiDrawContext read FDrawContext;
  end;

  /// <summary>Runs a scenario file and compares the text with the golden, line by line and without tolerance</summary>
  TGuiHarnessCompare = class
  public
    /// <summary>The names are relative to Tests\Data\Gui; a difference writes the actual text next to the executable</summary>
    class procedure Check(const AInputName, AGoldenName: string; const AUlpCases: string = ''; const AUlps: Integer = 0); static;
    /// <summary>Two lines of floats as bits (hex words) that differ by at most AUlps in each word</summary>
    class function SameWithinUlps(const AGolden, AActual: string; const AUlps: Integer): Boolean; static;
    /// <summary>The number of cases ("## " lines) of a golden</summary>
    class function CountCases(const AGoldenName: string): Integer; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Scanner.IdCNumbers,
  DelphiDoom.Gui.DeviceContext.Intf, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Factory,
  DUnitX.TestFramework, DelphiDoom.Tests.Gui.Fakes, DelphiDoom.Tests.Gui.WindowFakes, DelphiDoom.Tests.Gui.WindowDump;

constructor TGuiHarnessRunner.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FFiles := TGuiHarnessFiles.Create;
  FFilesRef := FFiles;
  FMaterials := TGuiHarnessMaterials.Create(FLines);
  FMaterialsRef := FMaterials;
  FCvars := TGuiCvarSet.Create;
  FCvarsRef := FCvars;
  FSurfaceRef := TGuiHarnessSurface.Create(FLines);
  FLogRef := TGuiWindowFakeLog.Create(FLines);
end;

destructor TGuiHarnessRunner.Destroy;
begin
  FreeAndNil(FInterface);
  FreeAndNil(FDrawContext);
  FLines.Free;
  inherited Destroy;
end;

function TGuiHarnessRunner.Unescape(const AText: string; const AWithReturn: Boolean): string;
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
        'r':
          if AWithReturn then
            Result := Result + #13
          else
            Result := Result + 'r';
      else
        Result := Result + AText[LIndex];
      end;
    end
    else
      Result := Result + AText[LIndex];
    Inc(LIndex);
  end;
end;

// (float)atof(text)
function TGuiHarnessRunner.Number(const AText: string): Single;
begin
  Result := TIdCNumbers.Atof(AnsiString(AText));
end;

function TGuiHarnessRunner.Color(const AWords: TArray<string>; const AIndex: Integer): TIdVec4;
begin
  Result := TIdVec4.Create(Number(AWords[AIndex]), Number(AWords[AIndex + 1]), Number(AWords[AIndex + 2]),
    Number(AWords[AIndex + 3]));
end;

// the text after a number of words and the blank that follows them
function TGuiHarnessRunner.RestFrom(const AText: string; const AWords: Integer): string;
var
  LPosition: Integer;
  LIndex: Integer;
begin
  LPosition := 1;
  for LIndex := 1 to AWords do
  begin
    while (LPosition <= Length(AText)) and (AText[LPosition] = ' ') do
      Inc(LPosition);
    while (LPosition <= Length(AText)) and (AText[LPosition] <> ' ') do
      Inc(LPosition);
  end;
  if LPosition <= Length(AText) then
    Inc(LPosition);
  Result := Copy(AText, LPosition, MaxInt);
end;

procedure TGuiHarnessRunner.StartCase;
var
  LLog: IIdLibLog;
begin
  FreeAndNil(FInterface);
  FreeAndNil(FDrawContext);
  FFiles.Clear;
  FMaterials.Clear;
  FCvarsRef := nil;
  FCvars := TGuiCvarSet.Create;
  FCvarsRef := FCvars;
  TGuiHarnessFonts.AddSet(FFiles, 'fonts/english');
  Supports(FLogRef, IIdLibLog, LLog);
  FDrawContext := TGuiDrawContext.Create(FSurfaceRef as IGuiDeviceContext, FMaterials, FFiles, LLog, FCvars);
  FDrawContext.Initialize;
end;

procedure TGuiHarnessRunner.NewInterface;
var
  LLog: IIdLibLog;
begin
  Supports(FLogRef, IIdLibLog, LLog);
  FInterface := TGuiUserInterface.Create(FFiles, LLog, TGuiWindowFactory.Create,
    TGuiWindowFakeHost.Create(FLines), nil, nil, FDrawContext);
  FInterface.Context.DrawContext := FDrawContext;
  FInterface.Context.Materials := FMaterials;
  FInterface.Context.Cvars := FCvars;
end;

procedure TGuiHarnessRunner.RunDeviceContext(const AText: string; const AWords: TArray<string>);
var
  LOp: string;
  LX, LY, LW, LH, LS1, LT1, LS2, LT2: Single;
  LRect: TGuiRectangle;
  LBreaks: TList<Integer>;
  LCount, LIndex: Integer;
  LLine: string;
  LOrigin: TIdVec3;
  LMat: TIdMat3;
  LTextWords: Integer;
begin
  LOp := AWords[1];
  if LOp = 'size' then
    FDrawContext.SetSize(Number(AWords[2]), Number(AWords[3]))
  else if LOp = 'font' then
    FDrawContext.SetFont(StrToInt(AWords[2]))
  else if LOp = 'findfont' then
    FLines.Add('F ' + IntToStr(FDrawContext.FindFont(AnsiString(AWords[2]))))
  else if LOp = 'fontset' then
    TGuiHarnessFonts.AddSet(FFiles, AnsiString(AWords[2]))
  else if LOp = 'clip' then
    FDrawContext.PushClipRect(Number(AWords[2]), Number(AWords[3]), Number(AWords[4]), Number(AWords[5]))
  else if LOp = 'popclip' then
    FDrawContext.PopClipRect
  else if LOp = 'clipping' then
    FDrawContext.EnableClipping(StrToInt(AWords[2]) <> 0)
  else if LOp = 'overstrike' then
    FDrawContext.OverStrike := StrToInt(AWords[2]) <> 0
  else if LOp = 'tick' then
    FDrawContext.TickNumber := StrToInt(AWords[2])
  else if LOp = 'setcursor' then
    FDrawContext.SetCursor(StrToInt(AWords[2]))
  else if LOp = 'transform' then
  begin
    LOrigin := TIdVec3.Create(Number(AWords[2]), Number(AWords[3]), Number(AWords[4]));
    LMat := TIdMat3.Create(Number(AWords[5]), Number(AWords[6]), Number(AWords[7]), Number(AWords[8]),
      Number(AWords[9]), Number(AWords[10]), Number(AWords[11]), Number(AWords[12]), Number(AWords[13]));
    FDrawContext.SetTransformInfo(LOrigin, LMat);
  end
  else if LOp = 'filled' then
    FDrawContext.DrawFilledRect(Number(AWords[2]), Number(AWords[3]), Number(AWords[4]), Number(AWords[5]),
      Color(AWords, 6))
  else if LOp = 'rect' then
    FDrawContext.DrawRect(Number(AWords[2]), Number(AWords[3]), Number(AWords[4]), Number(AWords[5]),
      Number(AWords[6]), Color(AWords, 7))
  else if LOp = 'material' then
    FDrawContext.DrawMaterial(Number(AWords[3]), Number(AWords[4]), Number(AWords[5]), Number(AWords[6]),
      FMaterials.FindMaterial(AnsiString(AWords[2])), Color(AWords, 7), Number(AWords[11]), Number(AWords[12]))
  else if LOp = 'matrot' then
    FDrawContext.DrawMaterialRotated(Number(AWords[3]), Number(AWords[4]), Number(AWords[5]), Number(AWords[6]),
      FMaterials.FindMaterial(AnsiString(AWords[2])), Color(AWords, 7), Number(AWords[11]), Number(AWords[12]),
      Number(AWords[13]))
  else if LOp = 'matrect' then
    FDrawContext.DrawMaterialRect(Number(AWords[3]), Number(AWords[4]), Number(AWords[5]), Number(AWords[6]),
      Number(AWords[7]), FMaterials.FindMaterial(AnsiString(AWords[2])), Color(AWords, 8))
  else if LOp = 'cursor' then
  begin
    LX := Number(AWords[2]);
    LY := Number(AWords[3]);
    FDrawContext.DrawCursor(LX, LY, Number(AWords[4]));
    FLines.Add('K ' + TGuiBits.Float(LX) + ' ' + TGuiBits.Float(LY));
  end
  else if LOp = 'coords' then
  begin
    LX := Number(AWords[2]);
    LY := Number(AWords[3]);
    LW := Number(AWords[4]);
    LH := Number(AWords[5]);
    FLines.Add(Format('O %d %s %s %s %s', [Ord(FDrawContext.ClippedCoords(LX, LY, LW, LH)), TGuiBits.Float(LX),
      TGuiBits.Float(LY), TGuiBits.Float(LW), TGuiBits.Float(LH)]));
  end
  else if LOp = 'coordst' then
  begin
    LX := Number(AWords[2]);
    LY := Number(AWords[3]);
    LW := Number(AWords[4]);
    LH := Number(AWords[5]);
    LS1 := Number(AWords[6]);
    LT1 := Number(AWords[7]);
    LS2 := Number(AWords[8]);
    LT2 := Number(AWords[9]);
    LCount := Ord(FDrawContext.ClippedCoords(LX, LY, LW, LH, LS1, LT1, LS2, LT2));
    FLines.Add(Format('O %d %s %s %s %s %s %s %s %s', [LCount, TGuiBits.Float(LX), TGuiBits.Float(LY),
      TGuiBits.Float(LW), TGuiBits.Float(LH), TGuiBits.Float(LS1), TGuiBits.Float(LT1), TGuiBits.Float(LS2),
      TGuiBits.Float(LT2)]));
  end
  else if LOp = 'text' then
  begin
    LRect := TGuiRectangle.Create(Number(AWords[8]), Number(AWords[9]), Number(AWords[10]), Number(AWords[11]));
    LBreaks := TList<Integer>.Create;
    try
      LCount := FDrawContext.DrawText(AnsiString(Unescape(RestFrom(AText, 16), True)), Number(AWords[2]),
        StrToInt(AWords[3]), Color(AWords, 4), LRect, StrToInt(AWords[12]) <> 0, StrToInt(AWords[13]),
        StrToInt(AWords[14]) <> 0, LBreaks, StrToInt(AWords[15]));
      LLine := 'T ' + IntToStr(LCount) + ' breaks';
      for LIndex := 0 to LBreaks.Count - 1 do
        LLine := LLine + ' ' + IntToStr(LBreaks[LIndex]);
      FLines.Add(LLine);
    finally
      LBreaks.Free;
    end;
  end
  else if LOp = 'textwidth' then
  begin
    LTextWords := 4;
    FLines.Add('W ' + IntToStr(FDrawContext.TextWidth(AnsiString(Unescape(RestFrom(AText, LTextWords), True)),
      Number(AWords[2]), StrToInt(AWords[3]))));
  end
  else if LOp = 'textheight' then
    FLines.Add('H ' + IntToStr(FDrawContext.TextHeight(AnsiString(Unescape(RestFrom(AText, 4), True)),
      Number(AWords[2]), StrToInt(AWords[3]))))
  else if LOp = 'charwidth' then
    FLines.Add('CW ' + IntToStr(FDrawContext.CharWidth(AnsiChar(StrToInt(AWords[3])), Number(AWords[2]))))
  else if LOp = 'maxchar' then
    FLines.Add(Format('MC %d %d', [FDrawContext.MaxCharWidth(Number(AWords[2])),
      FDrawContext.MaxCharHeight(Number(AWords[2]))]))
  else if LOp = 'scrollbar' then
  begin
    if Assigned(FDrawContext.GetScrollBarImage(StrToInt(AWords[2]))) then
      FLines.Add('SB ok')
    else
      FLines.Add('SB none');
  end;
end;

procedure TGuiHarnessRunner.RunOperation(const AText: string);
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
    NewInterface;
    FInterface.InitFromFile(AnsiString(LWords[1]));
  end
  else if LWords[0] = 'frame' then
    FInterface.RunFrame(StrToInt(LWords[1]))
  else if LWords[0] = 'state' then
  begin
    LKey := LWords[1];
    if Length(AText) > 6 + Length(LKey) + 1 then
      FInterface.SetStateString(AnsiString(LKey), AnsiString(Unescape(Copy(AText, 6 + Length(LKey) + 2, MaxInt), False)))
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
  else if LWords[0] = 'redraw' then
    FInterface.Redraw(StrToInt(LWords[1]))
  else if LWords[0] = 'guicursor' then
  begin
    FInterface.Context.CursorX := Number(LWords[1]);
    FInterface.Context.CursorY := Number(LWords[2]);
  end
  else if LWords[0] = 'dc' then
    RunDeviceContext(AText, LWords)
  else if LWords[0] = 'cvar' then
  begin
    if Length(LWords) > 2 then
      FCvars.SetString(AnsiString(LWords[1]), AnsiString(LWords[2]))
    else
      FCvars.SetString(AnsiString(LWords[1]), '');
  end
  else if LWords[0] = 'mat' then
    FMaterials.SetInfo(AnsiString(LWords[1]), StrToInt(LWords[2]), StrToInt(LWords[3]), StrToInt(LWords[4]),
      StrToInt(LWords[5]) <> 0)
  else if LWords[0] = 'dump' then
  begin
    FLines.Add(Format('I interactive=%d pending="%s"', [Ord(FInterface.Interactive),
      string(FInterface.PendingCommand)]));
    DumpWindow(FInterface.Desktop, FLines);
  end;
end;

procedure TGuiHarnessRunner.Run(const AInput: TStrings);
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
      StartCase;
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

{ TGuiHarnessCompare }

class procedure TGuiHarnessCompare.Check(const AInputName, AGoldenName: string; const AUlpCases: string;
  const AUlps: Integer);
var
  LInput: TStringList;
  LGolden: TStringList;
  LRunner: TGuiHarnessRunner;
  LIndex: Integer;
  LCase: string;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TGuiHarnessRunner.Create;
  try
    LInput.LoadFromFile(GuiDataFolder + AInputName);
    LGolden.LoadFromFile(GuiDataFolder + AGoldenName);
    LRunner.Run(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LRunner.Lines.Count then
      begin
        LRunner.Lines.SaveToFile(ChangeFileExt(ParamStr(0), '.actual.txt'));
        Assert.Fail('The run ends at line ' + IntToStr(LIndex + 1) + ', the golden has ' + IntToStr(LGolden.Count));
      end;
      if LGolden[LIndex].StartsWith('## ') then
        LCase := Copy(LGolden[LIndex], 4, MaxInt);
      if (LGolden[LIndex] <> LRunner.Lines[LIndex]) and
        not ((AUlps > 0) and (Pos(',' + LCase + ',', ',' + AUlpCases + ',') > 0) and
        SameWithinUlps(LGolden[LIndex], LRunner.Lines[LIndex], AUlps)) then
      begin
        LRunner.Lines.SaveToFile(ChangeFileExt(ParamStr(0), '.actual.txt'));
        Assert.Fail(Format('Line %d: golden [%s] actual [%s]', [LIndex + 1, LGolden[LIndex], LRunner.Lines[LIndex]]));
      end;
    end;
    if LGolden.Count <> LRunner.Lines.Count then
      LRunner.Lines.SaveToFile(ChangeFileExt(ParamStr(0), '.actual.txt'));
    Assert.AreEqual(LGolden.Count, LRunner.Lines.Count);
  finally
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

class function TGuiHarnessCompare.SameWithinUlps(const AGolden, AActual: string; const AUlps: Integer): Boolean;
var
  LGolden, LActual: TArray<string>;
  LIndex: Integer;
  LA, LB: Int64;
begin
  LGolden := AGolden.Split([' ']);
  LActual := AActual.Split([' ']);
  Result := (Length(LGolden) = Length(LActual)) and (Length(LGolden) > 1);
  if not Result then
    Exit;
  for LIndex := 0 to High(LGolden) do
  begin
    if LGolden[LIndex] = LActual[LIndex] then
      Continue;
    if (Length(LGolden[LIndex]) <> 8) or (Length(LActual[LIndex]) <> 8) or
      not TryStrToInt64('$' + LGolden[LIndex], LA) or not TryStrToInt64('$' + LActual[LIndex], LB) then
      Exit(False);
    if Abs(LA - LB) > AUlps then
      Exit(False);
  end;
end;

class function TGuiHarnessCompare.CountCases(const AGoldenName: string): Integer;
var
  LGolden: TStringList;
  LLine: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(GuiDataFolder + AGoldenName);
    Result := 0;
    for LLine in LGolden do
      if LLine.StartsWith('## ') then
        Inc(Result);
  finally
    LGolden.Free;
  end;
end;

end.
