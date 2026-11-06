{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the dynamic lights library - the corpus of texts      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DynLights.Corpus;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Tests\Data\DynLights\cases.txt: the texts that were given to the old code to make the
  ///   golden files. A line "@@@ name" starts a case. "@@ lump NAME" and "@@ pak NAME" start
  ///   the text of a lump or of an entry of a PAK file; "@@ opt devparm|gldefs 0|1" sets an
  ///   option (gldefs is "GLDEFS lumps are read as LIGHTDEF", on by default); "@@ times t1 t2..."
  ///   asks for the animation of every light at those tics; "@@ find NAME" asks for the index
  ///   of a light. The dump has the format that the harness of the old code wrote
  /// </summary>
  TDynLightCorpus = class
  private
    FLines: TStringList;
  public
    constructor Create(const ACasesFileName: string);
    destructor Destroy; override;
    /// <summary>
    ///   Runs every case and dumps the result
    /// </summary>
    /// <param name="AMapCoefficient">128 for the OpenGL renderer, 1 for the software one</param>
    function Dump(AMapCoefficient: Double): TStringList;
    /// <summary>Lines of a file, whatever its line breaks are (the caller frees the list)</summary>
    class function LoadLines(const AFileName: string): TStringList; static;
  end;

implementation

uses
  System.IOUtils, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.DynLights.Types, DelphiDoom.DynLights.Intf, DelphiDoom.DynLights.Factory,
  DelphiDoom.Tests.DynLights.Fakes;

function Quote(const AText: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    if LChar = '\' then
      Result := Result + '\\'
    else if LChar = #13 then
      Result := Result + '\r'
    else if LChar = #10 then
      Result := Result + '\n'
    else if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
      Result := Result + '\x' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
  end;
end;

/// <summary>The bits of a single, as eight hexadecimal digits</summary>
function Bits(AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

type
  /// <summary>One case of the corpus: its own fakes, registry, parser and loader</summary>
  TCaseRun = class
  private
    FCoefficient: Double;
    FSource: TFakeTextSource;
    FSourceIntf: IDynLightTextSource;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FStates: TFakeStateTable;
    FStatesIntf: IDynLightStateTable;
    FRandom: IDynLightRandom;
    FRegistry: IDynLightRegistry;
    FDeveloperMode: Boolean;
    FGldefs: Boolean;
    FTimes: TArray<string>;
    FFinds: TStringList;
  public
    constructor Create(AMapCoefficient: Double);
    destructor Destroy; override;
    procedure AddText(const AKind, AName, AText: string);
    procedure SetOption(const AName, AValue: string);
    procedure SetTimes(const ATimes: TArray<string>);
    procedure AddFind(const AName: string);
    procedure Finish(AOutput: TStringList; const ACaseName: string);
  end;

{ TCaseRun }

constructor TCaseRun.Create(AMapCoefficient: Double);
begin
  inherited Create;
  FCoefficient := AMapCoefficient;
  FSource := TFakeTextSource.Create;
  FSourceIntf := FSource;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FStates := TFakeStateTable.Create;
  FStatesIntf := FStates;
  FRandom := TFakeRandom.Create;
  FRegistry := TDynLightFactory.CreateRegistry;
  FGldefs := True;
  FFinds := TStringList.Create;
end;

destructor TCaseRun.Destroy;
begin
  FFinds.Free;
  inherited Destroy;
end;

procedure TCaseRun.AddText(const AKind, AName, AText: string);
begin
  if AKind = 'lump' then
    FSource.AddLump(AName, AText)
  else
    FSource.AddPak(AName, AText);
end;

procedure TCaseRun.SetOption(const AName, AValue: string);
begin
  if AName = 'devparm' then
    FDeveloperMode := AValue = '1'
  else if AName = 'gldefs' then
    FGldefs := AValue = '1';
end;

procedure TCaseRun.SetTimes(const ATimes: TArray<string>);
begin
  FTimes := ATimes;
end;

procedure TCaseRun.AddFind(const AName: string);
begin
  FFinds.Add(AName);
end;

procedure TCaseRun.Finish(AOutput: TStringList; const ACaseName: string);
var
  LNames: TFakeNames;
  LNamesIntf: IInterface;
  LServices: TDynLightParserServices;
  LPresent: Boolean;
  LAnimator: IDynLightAnimator;
  LLight: TDynLightDefinition;
  LRender: TDynLightRender;
  LText: string;
  LIndex: Integer;
  LState: Integer;
  LTime: Integer;
begin
  LNames := TFakeNames.Create;
  LNamesIntf := LNames;
  LServices.Registry := FRegistry;
  LServices.Random := FRandom;
  LServices.Objects := LNames;
  LServices.Sprites := LNames;
  LServices.Binder := TDynLightFactory.CreateBinder(FStatesIntf);
  LServices.Context := TFakeContext.Create(FDeveloperMode);
  LPresent := TDynLightFactory.CreateLoader(FSourceIntf, nil,
    TDynLightFactory.CreateParser(LServices, FLogIntf, FCoefficient)).Load(FGldefs);

  AOutput.Add('=== ' + ACaseName);
  AOutput.Add('output=' + Quote(FLog.Output));
  AOutput.Add('warnings=' + Quote(FLog.Warnings));
  AOutput.Add('lightdeflumppresent=' + IntToStr(Ord(LPresent)));
  AOutput.Add('lights.count=' + IntToStr(FRegistry.Count));
  for LIndex := 0 to FRegistry.Count - 1 do
  begin
    LLight := FRegistry.Get(LIndex);
    AOutput.Add('light[' + IntToStr(LIndex) + ']');
    AOutput.Add('  name=' + Quote(LLight.Name));
    AOutput.Add('  type=' + IntToStr(Ord(LLight.Kind)));
    AOutput.Add('  color1=' + Bits(LLight.R1) + ',' + Bits(LLight.G1) + ',' + Bits(LLight.B1));
    AOutput.Add('  color2=' + Bits(LLight.R2) + ',' + Bits(LLight.G2) + ',' + Bits(LLight.B2));
    AOutput.Add('  colorinterval=' + IntToStr(LLight.ColorInterval));
    AOutput.Add('  colorchance=' + IntToStr(LLight.ColorChance));
    AOutput.Add('  size1=' + Bits(LLight.Size1));
    AOutput.Add('  size2=' + Bits(LLight.Size2));
    AOutput.Add('  interval=' + IntToStr(LLight.Interval));
    AOutput.Add('  chance=' + IntToStr(LLight.Chance));
    AOutput.Add('  offset1=' + Bits(LLight.OffsetX1) + ',' + Bits(LLight.OffsetY1) + ',' + Bits(LLight.OffsetZ1));
    AOutput.Add('  offset2=' + Bits(LLight.OffsetX2) + ',' + Bits(LLight.OffsetY2) + ',' + Bits(LLight.OffsetZ2));
    AOutput.Add('  randomoffset=' + IntToStr(Ord(LLight.RandomOffset)));
    AOutput.Add('  randomseed=' + IntToStr(LLight.RandomSeed));
  end;
  for LIndex := 0 to FFinds.Count - 1 do
    AOutput.Add('find ' + FFinds[LIndex] + '=' + IntToStr(FRegistry.Find(FFinds[LIndex])));
  for LState := 0 to FStates.StateCount - 1 do
    if FStates.Describe(LState, LText) then
      AOutput.Add('state[' + IntToStr(LState) + ']=' + LText);

  LAnimator := TDynLightFactory.CreateAnimator(FRegistry, FRandom);
  for LTime := 0 to Length(FTimes) - 1 do
    for LIndex := 0 to FRegistry.Count - 1 do
    begin
      LRender := LAnimator.GetRender(LIndex, StrToInt(FTimes[LTime]));
      AOutput.Add('anim ' + IntToStr(LIndex) + '@' + FTimes[LTime] + '=' + Bits(LRender.R) + ',' +
        Bits(LRender.G) + ',' + Bits(LRender.B) + ',' + Bits(LRender.Radius) + ',' +
        Bits(LRender.X) + ',' + Bits(LRender.Y) + ',' + Bits(LRender.Z) + ',' +
        IntToStr(Ord(LRender.Shadow)));
    end;
end;

{ TDynLightCorpus }

class function TDynLightCorpus.LoadLines(const AFileName: string): TStringList;
var
  LBytes: TBytes;
  LIndex: Integer;
  LLine: string;
begin
  Result := TStringList.Create;
  LBytes := TFile.ReadAllBytes(AFileName);
  LLine := '';
  for LIndex := 0 to High(LBytes) do
    if LBytes[LIndex] = 10 then
    begin
      if (LLine <> '') and (LLine[Length(LLine)] = #13) then
        Delete(LLine, Length(LLine), 1);
      Result.Add(LLine);
      LLine := '';
    end
    else
      LLine := LLine + Char(LBytes[LIndex]);
  if LLine <> '' then
    Result.Add(LLine);
end;

constructor TDynLightCorpus.Create(const ACasesFileName: string);
begin
  inherited Create;
  FLines := LoadLines(ACasesFileName);
end;

destructor TDynLightCorpus.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TDynLightCorpus.Dump(AMapCoefficient: Double): TStringList;
var
  LIndex: Integer;
  LLine: string;
  LParts: TArray<string>;
  LRun: TCaseRun;
  LCaseName: string;
  LBlockKind: string;
  LBlockName: string;
  LBody: string;
  LHasBlock: Boolean;
  LList: TStringList;

  procedure FlushBlock;
  begin
    if LHasBlock then
      LRun.AddText(LBlockKind, LBlockName, LBody);
    LHasBlock := False;
    LBody := '';
  end;

  procedure FinishCase;
  begin
    FlushBlock;
    if Assigned(LRun) then
    begin
      LRun.Finish(LList, LCaseName);
      FreeAndNil(LRun);
    end;
  end;

begin
  LList := TStringList.Create;
  LRun := nil;
  LHasBlock := False;
  LBody := '';
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      LLine := FLines[LIndex];
      if Copy(LLine, 1, 4) = '@@@ ' then
      begin
        FinishCase;
        LCaseName := Copy(LLine, 5, MaxInt);
        LRun := TCaseRun.Create(AMapCoefficient);
      end
      else if Copy(LLine, 1, 3) = '@@ ' then
      begin
        FlushBlock;
        LParts := Copy(LLine, 4, MaxInt).Split([' ']);
        LBlockKind := LParts[0];
        if (LBlockKind = 'lump') or (LBlockKind = 'pak') then
        begin
          LBlockName := LParts[1];
          LHasBlock := True;
        end
        else if LBlockKind = 'opt' then
          LRun.SetOption(LParts[1], LParts[2])
        else if LBlockKind = 'times' then
          LRun.SetTimes(Copy(LParts, 1, Length(LParts) - 1))
        else if LBlockKind = 'find' then
          LRun.AddFind(Copy(LLine, 9, MaxInt));
      end
      else if LHasBlock then
        LBody := LBody + LLine + #13#10;
    end;
    FinishCase;
  except
    LRun.Free;
    LList.Free;
    raise;
  end;
  Result := LList;
end;

end.
