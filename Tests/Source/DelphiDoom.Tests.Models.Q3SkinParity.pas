{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - parity of the skins and of the }
{  search of the files of a Quake III player with the original code            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3SkinParity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Tests\Data\Models\q3player\q3skin.golden.txt comes from RE_RegisterSkin, CommaParse,
  ///   R_GetSkinByHandle, CG_FindClientModelFile and CG_FindClientHeadFile of Quake III compiled with
  ///   gcc (Tools\Verifica\126\build-skin.sh) on the files of Tests\Data\Models\q3player\skins; a
  ///   line is "inputs | outputs", the strings are between brackets and a "[surface]=[shader]" is two
  ///   words.
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsQ3SkinParity = class(TObject)
  strict private
    FLines: TList<AnsiString>;
    FLog: TObject;
    class function Words(const ALine: AnsiString): TArray<AnsiString>; static;
    procedure CheckMessages(var AIndex: Integer; const AContext: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseSkinELeStesseManiglieDelCodiceVero;
    [Test]
    procedure DovrebbeTrovareGliStessiFileDelCodiceVero;
    [Test]
    procedure DovrebbeAvereLeRigheDelCodiceVeroInQuantitaAttesa;
  end;

implementation

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf,
  DelphiDoom.Models.Q3Player.Factory,
  DelphiDoom.Tests.Models.Q3PlayerSupport,
  DelphiDoom.Tests.Models.Q3SkinSupport;

procedure CheckSame(const AExpected, AActual: AnsiString; const AContext: AnsiString);
begin
  Assert.IsTrue(AExpected = AActual, string(Format('%s: expected [%s] got [%s]', [AContext, AExpected, AActual])));
end;

procedure TTestModelsQ3SkinParity.Setup;
var
  LText, LLine: AnsiString;
  LStart, LIndex: Integer;
begin
  FLines := TList<AnsiString>.Create;
  FLog := TObject(nil);
  LText := ReadAnsiFile(Q3SkinDataPath('..\q3skin.golden.txt'));
  LStart := 1;
  for LIndex := 1 to Length(LText) do
    if LText[LIndex] = #10 then
    begin
      LLine := Copy(LText, LStart, LIndex - LStart);
      if (LLine <> '') and (LLine[Length(LLine)] = #13) then
        SetLength(LLine, Length(LLine) - 1);
      FLines.Add(LLine);
      LStart := LIndex + 1;
    end;
end;

procedure TTestModelsQ3SkinParity.TearDown;
begin
  FLines.Free;
end;

class function TTestModelsQ3SkinParity.Words(const ALine: AnsiString): TArray<AnsiString>;
var
  LPosition, LStop: Integer;
  LList: TList<AnsiString>;
begin
  LList := TList<AnsiString>.Create;
  try
    LPosition := 1;
    while LPosition <= Length(ALine) do
    begin
      if (ALine[LPosition] = ' ') or (ALine[LPosition] = '=') then
        Inc(LPosition)
      else if ALine[LPosition] = '[' then
      begin
        LStop := LPosition + 1;
        while (LStop <= Length(ALine)) and (ALine[LStop] <> ']') do
          Inc(LStop);
        LList.Add(Copy(ALine, LPosition + 1, LStop - LPosition - 1));
        LPosition := LStop + 1;
      end
      else
      begin
        LStop := LPosition;
        while (LStop <= Length(ALine)) and (ALine[LStop] <> ' ') do
          Inc(LStop);
        LList.Add(Copy(ALine, LPosition, LStop - LPosition));
        LPosition := LStop;
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

// the "msg" lines that follow a case are the warnings it raised
procedure TTestModelsQ3SkinParity.CheckMessages(var AIndex: Integer; const AContext: AnsiString);
var
  LLog: TFakeQ3Log;
  LWords: TArray<AnsiString>;
  LCount: Integer;
begin
  LLog := TFakeQ3Log(FLog);
  LCount := 0;
  while (AIndex + 1 < FLines.Count) and (Copy(FLines[AIndex + 1], 1, 4) = 'msg ') do
  begin
    Inc(AIndex);
    LWords := Words(FLines[AIndex]);
    Assert.IsTrue(LCount < LLog.Warnings.Count, string(AContext + ': missing message ' + LWords[3]));
    CheckSame(LWords[3], AnsiString(LLog.Warnings[LCount]), AContext);
    Inc(LCount);
  end;
  Assert.AreEqual(LCount, LLog.Warnings.Count, string(AContext + ': more messages than the original'));
  LLog.Warnings.Clear;
end;

procedure TTestModelsQ3SkinParity.DovrebbeAvereLeRigheDelCodiceVeroInQuantitaAttesa;
var
  LLine: AnsiString;
  LRegs, LFinds: Integer;
begin
  LRegs := 0;
  LFinds := 0;
  for LLine in FLines do
  begin
    if Copy(LLine, 1, 4) = 'reg ' then
      Inc(LRegs)
    else if Copy(LLine, 1, 4) = 'find' then
      Inc(LFinds);
  end;
  Assert.AreEqual(16, LRegs);
  Assert.AreEqual(384 + 1024, LFinds);
end;

procedure TTestModelsQ3SkinParity.DovrebbeDareLeStesseSkinELeStesseManiglieDelCodiceVero;
var
  LLog: TFakeQ3Log;
  LLogIntf: ILog;
  LRegistry: IQ3SkinRegistry;
  LWords: TArray<AnsiString>;
  LIndex, LHandle, LSurface: Integer;
  LSkin: IQ3Skin;
  LContext: AnsiString;
begin
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  FLog := LLog;
  LRegistry := TQ3PlayerFactory.CreateSkinRegistry(TFolderQ3TextSource.Create(Q3SkinDataPath), LLogIntf);
  LIndex := 0;
  while LIndex < FLines.Count do
  begin
    LWords := Words(FLines[LIndex]);
    LContext := FLines[LIndex];
    if LWords[0] = 'reg' then
    begin
      // [name] | handle count
      LHandle := LRegistry.RegisterSkin(LWords[1]);
      Assert.AreEqual(StrToInt(string(LWords[3])), LHandle, string(LContext));
      Assert.AreEqual(StrToInt(string(LWords[4])), LRegistry.SkinCount, string(LContext));
      CheckMessages(LIndex, LContext);
    end
    else if LWords[0] = 'skin' then
    begin
      // handle | [name] count [surface]=[shader]...
      LSkin := LRegistry.GetSkin(StrToInt(string(LWords[1])));
      CheckSame(LWords[3], LSkin.Name, LContext);
      Assert.AreEqual(StrToInt(string(LWords[4])), LSkin.SurfaceCount, string(LContext));
      if (StrToInt(string(LWords[1])) >= 1) and (StrToInt(string(LWords[1])) < Q3_MAX_SKINS) then
        for LSurface := 0 to LSkin.SurfaceCount - 1 do
        begin
          CheckSame(LWords[5 + LSurface * 2], LSkin.Surfaces[LSurface].Name, LContext);
          CheckSame(LWords[6 + LSurface * 2], LSkin.Surfaces[LSurface].Shader, LContext);
        end;
    end;
    Inc(LIndex);
  end;
  FLog := nil;
end;

procedure TTestModelsQ3SkinParity.DovrebbeTrovareGliStessiFileDelCodiceVero;
var
  LLog: TFakeQ3Log;
  LLogIntf: ILog;
  LFinder: IQ3PlayerFileFinder;
  LWords: TArray<AnsiString>;
  LIndex, LCases: Integer;
  LContext: TQ3TeamContext;
  LFileName, LTeamName: AnsiString;
  LFound: Boolean;
begin
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  FLog := LLog;
  LFinder := TQ3PlayerFactory.CreateFileFinder(TListQ3FileProbe.Create(Q3SkinDataPath('fs.txt')), LLogIntf);
  LCases := 0;
  LIndex := 0;
  while LIndex < FLines.Count do
  begin
    LWords := Words(FLines[LIndex]);
    if (LWords[0] = 'findm') or (LWords[0] = 'findh') then
    begin
      LContext.TeamGame := LWords[1] = '1';
      LContext.Team := TQ3Team(StrToInt(string(LWords[2])));
      LTeamName := LWords[3];
      if LWords[0] = 'findm' then
      begin
        // gt team [teamName] [model] [skin] [base] | found [file]
        LFound := LFinder.FindModelFile(LContext, LTeamName, LWords[4], LWords[5], LWords[6], 'skin', LFileName);
        Assert.AreEqual(LWords[8] = '1', LFound, string(FLines[LIndex]));
        CheckSame(LWords[9], LFileName, FLines[LIndex]);
      end
      else
      begin
        // gt team [teamName] [head] [skin] [base] [ext] | found [file]
        LFound := LFinder.FindHeadFile(LContext, LTeamName, LWords[4], LWords[5], LWords[6], LWords[7], LFileName);
        Assert.AreEqual(LWords[9] = '1', LFound, string(FLines[LIndex]));
        CheckSame(LWords[10], LFileName, FLines[LIndex]);
      end;
      CheckMessages(LIndex, FLines[LIndex]);
      Inc(LCases);
    end;
    Inc(LIndex);
  end;
  Assert.AreEqual(384 + 1024, LCases);
  FLog := nil;
end;

end.
