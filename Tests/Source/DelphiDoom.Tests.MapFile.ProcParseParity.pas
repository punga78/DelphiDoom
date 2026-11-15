{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MapFile library - parity of the .proc sections     }
{                                                                              }
{  ParseNodes and ParseInterAreaPortals of Doom 3 (RenderWorld_load.cpp, real  }
{  code on the real idLexer and idWinding, bcc32c; Tests\Data\MapFile\harness  }
{  procparse_build.ps1.txt, proc_parse.golden.txt).                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcParseParity;

interface

uses
  System.SysUtils, System.IOUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('MapFile')]
  TTestProcParseParity = class
  strict private
    FLines: TDictionary<string, TArray<string>>;
    function Tokens(const AKey: string): TArray<string>;
    function Float(const AToken: string): Single;
    function Expected(const AName: string; const AKey: string): TArray<string>;
    procedure CheckNodes(const AName, AText: string);
    procedure CheckPortals(const AName, AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('nodi', 'nodes,{ 3 ( 1 0 0 -5 ) 1 2 ( 0 1 0 12.5 ) -1 -2 ( 0 0 1 .25 ) 2 -3 }')]
    [TestCase('nessun nodo', 'nodes0,{ 0 }')]
    [TestCase('numero negativo', 'nodesneg,{ -1 }')]
    [TestCase('graffa mancante', 'nodesnoclose,{ 1 ( 1 0 0 0 ) 1 2')]
    [TestCase('piano corto', 'nodesbadplane,{ 1 ( 1 0 0 ) 1 2 }')]
    [TestCase('esponenti e meno zero', 'nodesexp,{ 1 ( 1e-5 -0 0.5 2.5e1 ) 0 -1 }')]
    procedure DovrebbeLeggereINodiComeIlCpp(const AName, AText: string);
    [TestCase('tre aree', 'portals,{ 3 2 4 0 1 ( 0 0 0 ) ( 64 0 0 ) ( 64 64 0 ) ( 0 64 0 ) 3 1 2 ( 0 0 8 ) ( 16 0 8 ) ( 0 16 8 ) }')]
    [TestCase('tre portali', 'portals3,{ 4 3 3 0 1 ( 0 0 0 ) ( 8 0 0 ) ( 0 8 0 ) 3 0 2 ( 0 0 0 ) ( 0 8 0 ) ( 0 0 8 ) 3 3 0 ( 1 1 1 ) ( 2 5 1 ) ( 7 2 3 ) }')]
    [TestCase('nessun portale', 'portalsnone,{ 2 0 }')]
    [TestCase('aree negative', 'portalsbadareas,{ -1 0 }')]
    [TestCase('portali negativi', 'portalsbadportals,{ 1 -2 }')]
    [TestCase('graffa mancante nei portali', 'portalsnoclose,{ 1 0')]
    procedure DovrebbeLeggereIPortaliComeIlCpp(const AName, AText: string);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.Types,
  DelphiDoom.MapFile.Proc.ProcFile, DelphiDoom.MapFile.Proc.Portal, DelphiDoom.MapFile.Proc.NodeReader,
  DelphiDoom.MapFile.Proc.PortalReader;

const
  LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES;

procedure TTestProcParseParity.Setup;
var
  LLines: TStringList;
  LLine, LKey: string;
  LPos: Integer;
begin
  FLines := TDictionary<string, TArray<string>>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\..\..\Tests\Data\MapFile\proc_parse.golden.txt')));
    for LLine in LLines do
    begin
      LPos := Pos(' |', LLine);
      if LPos = 0 then
        Continue;
      LKey := Copy(LLine, 1, LPos - 1);
      FLines.AddOrSetValue(LKey, Trim(Copy(LLine, LPos + 2, MaxInt)).Split([' '], TStringSplitOptions.ExcludeEmpty));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestProcParseParity.TearDown;
begin
  FLines.Free;
end;

function TTestProcParseParity.Tokens(const AKey: string): TArray<string>;
begin
  Assert.IsTrue(FLines.TryGetValue('PROC ' + AKey, Result), 'missing golden key ' + AKey);
end;

function TTestProcParseParity.Float(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := StrToUInt('$' + Copy(AToken, 2, 8));
  Result := PSingle(@LBits)^;
end;

function TTestProcParseParity.Expected(const AName, AKey: string): TArray<string>;
begin
  Result := Tokens(AName + ' ' + AKey);
end;

procedure TTestProcParseParity.CheckNodes(const AName, AText: string);
var
  LLexer: TIdLexer;
  LFile: TProcFile;
  LFailed: Boolean;
  LExpected: TArray<string>;
  LIndex: Integer;
begin
  LFile := TProcFile.Create;
  LLexer := TIdLexer.Create(LEXER_FLAGS);
  try
    LLexer.LoadMemory(AnsiString(AText), AnsiString(AName));
    LFailed := False;
    try
      TProcNodeReader.Parse(LLexer, LFile);
    except
      on Exception do
        LFailed := True;
    end;
    Assert.AreEqual(FLines.ContainsKey('PROC ' + AName + ' error'), LFailed, AName + ': error');
    if LFailed then
      Exit;
    Assert.AreEqual(StrToInt(Expected(AName, 'nodes')[0]), LFile.Nodes.Count, AName + ': count');
    for LIndex := 0 to LFile.Nodes.Count - 1 do
    begin
      LExpected := Tokens(Format('%s n%d', [AName, LIndex]));
      Assert.AreEqual(Float(LExpected[0]), LFile.Nodes[LIndex].Plane.A, 0.0);
      Assert.AreEqual(Float(LExpected[1]), LFile.Nodes[LIndex].Plane.B, 0.0);
      Assert.AreEqual(Float(LExpected[2]), LFile.Nodes[LIndex].Plane.C, 0.0);
      Assert.AreEqual(Float(LExpected[3]), LFile.Nodes[LIndex].Plane.D, 0.0);
      Assert.AreEqual(StrToInt(LExpected[4]), LFile.Nodes[LIndex].PositiveChild);
      Assert.AreEqual(StrToInt(LExpected[5]), LFile.Nodes[LIndex].NegativeChild);
    end;
  finally
    LLexer.Free;
    LFile.Free;
  end;
end;

procedure TTestProcParseParity.CheckPortals(const AName, AText: string);
var
  LLexer: TIdLexer;
  LFile: TProcFile;
  LFailed: Boolean;
  LHeader, LForward, LReverse: TArray<string>;
  LIndex, LPoint, LCount: Integer;
  LPortal: TProcPortal;
begin
  LFile := TProcFile.Create;
  LLexer := TIdLexer.Create(LEXER_FLAGS);
  try
    LLexer.LoadMemory(AnsiString(AText), AnsiString(AName));
    LFailed := False;
    try
      TProcPortalReader.Parse(LLexer, LFile);
    except
      on Exception do
        LFailed := True;
    end;
    Assert.AreEqual(FLines.ContainsKey('PROC ' + AName + ' error'), LFailed, AName + ': error');
    if LFailed then
      Exit;
    LHeader := Expected(AName, 'portals');
    Assert.AreEqual(StrToInt(LHeader[0]), LFile.NumAreas, AName + ': areas');
    Assert.AreEqual(StrToInt(LHeader[1]), LFile.Portals.Count, AName + ': portals');
    for LIndex := 0 to LFile.Portals.Count - 1 do
    begin
      LPortal := LFile.Portals[LIndex];
      // the original keeps the winding as read on the side that looks into the second area, and its reverse for the first
      LForward := Tokens(Format('%s p%d_0', [AName, LIndex]));
      LReverse := Tokens(Format('%s p%d_1', [AName, LIndex]));
      Assert.AreEqual(StrToInt(LForward[0]), LPortal.NegativeArea, 'into area 0');
      Assert.AreEqual(StrToInt(LReverse[0]), LPortal.PositiveArea, 'into area 1');
      LCount := StrToInt(LForward[1]);
      Assert.AreEqual<Integer>(LCount, Length(LPortal.Points));
      for LPoint := 0 to LCount - 1 do
      begin
        Assert.AreEqual(Float(LForward[2 + LPoint * 3]), LPortal.Points[LPoint].X, 0.0);
        Assert.AreEqual(Float(LForward[3 + LPoint * 3]), LPortal.Points[LPoint].Y, 0.0);
        Assert.AreEqual(Float(LForward[4 + LPoint * 3]), LPortal.Points[LPoint].Z, 0.0);
        // the reverse winding lists the points the other way round
        Assert.AreEqual(Float(LReverse[2 + (LCount - 1 - LPoint) * 3]), LPortal.Points[LPoint].X, 0.0);
      end;
    end;
  finally
    LLexer.Free;
    LFile.Free;
  end;
end;

procedure TTestProcParseParity.DovrebbeLeggereINodiComeIlCpp(const AName, AText: string);
begin
  CheckNodes(AName, AText);
end;

procedure TTestProcParseParity.DovrebbeLeggereIPortaliComeIlCpp(const AName, AText: string);
begin
  CheckPortals(AName, AText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProcParseParity);

end.
