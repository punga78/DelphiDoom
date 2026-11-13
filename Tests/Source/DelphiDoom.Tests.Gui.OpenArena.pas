{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the menus and fonts of OpenArena     }
{                                                                              }
{  The files are read where they are (Reference\openarena, GPL v2, not in the  }
{  repository; the folder can be given in the environment variable             }
{  DELPHIDOOM_OPENARENA) and the tests are skipped when they are missing.      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.OpenArena;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip, DUnitX.TestFramework, DelphiDoom.Tests.Gui.Fakes;

type
  [TestFixture]
  [Category('gui')]
  [Category('openarena')]
  TTestGuiOpenArena = class(TObject)
  private
    FWorld: TGuiWorld;
    FFound: Boolean;
    FMenuFiles: TStringList;
    FFontFiles: TStringList;
    function BaseFolder: string;
    procedure LoadPackages;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereITuttiIMenuSenzaErrori;
    [Test]
    procedure DovrebbeLeggereITuttiIFontDat;
  end;

implementation

uses
  DelphiDoom.Gui.Font;

procedure TTestGuiOpenArena.Setup;
begin
  FWorld := TGuiWorld.Create;
  FMenuFiles := TStringList.Create;
  FFontFiles := TStringList.Create;
  LoadPackages;
end;

procedure TTestGuiOpenArena.TearDown;
begin
  FFontFiles.Free;
  FMenuFiles.Free;
  FWorld.Free;
end;

function TTestGuiOpenArena.BaseFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if Result = '' then
    Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Reference\openarena\openarena-0.8.8\');
  Result := IncludeTrailingPathDelimiter(Result);
end;

procedure TTestGuiOpenArena.LoadPackages;
var
  LPackage: string;
  LZip: TZipFile;
  LIndex: Integer;
  LName: string;
  LBytes: TBytes;
  LFolder: string;
begin
  FFound := False;
  for LFolder in ['baseoa', 'missionpack'] do
    if TDirectory.Exists(BaseFolder + LFolder) then
    for LPackage in TDirectory.GetFiles(BaseFolder + LFolder, '*.pk3') do
    begin
      LZip := TZipFile.Create;
      try
        LZip.Open(LPackage, zmRead);
        for LIndex := 0 to LZip.FileCount - 1 do
        begin
          LName := LZip.FileNames[LIndex];
          if (Pos('ui/', LName) = 1) or ((Pos('fonts/', LName) = 1) and (ExtractFileExt(LName) = '.dat')) then
          begin
            LZip.Read(LIndex, LBytes);
            FWorld.Files.Add(AnsiString(LName), LBytes);
            if (Pos('ui/', LName) = 1) and (ExtractFileExt(LName) = '.menu') and (Pos('/', Copy(LName, 4, MaxInt)) = 0) then
              if FMenuFiles.IndexOf(LName) < 0 then
                FMenuFiles.Add(LName);
            if Pos('fonts/', LName) = 1 then
              if FFontFiles.IndexOf(LName) < 0 then
                FFontFiles.Add(LName);
            FFound := True;
          end;
        end;
      finally
        LZip.Free;
      end;
    end;
end;

procedure TTestGuiOpenArena.DovrebbeLeggereITuttiIMenuSenzaErrori;
var
  LName: string;
  LErrors: TStringList;
  LLine: string;
begin
  if (not FFound) or (FMenuFiles.Count = 0) then
  begin
    Assert.Pass('OpenArena data not found: skipped');
    Exit;
  end;
  LErrors := TStringList.Create;
  try
    for LName in FMenuFiles do
    begin
      FWorld.Transcript.Clear;
      FWorld.Reader.ParseMenu(AnsiString(LName));
      for LLine in FWorld.Transcript do
        if Pos('ERROR', LLine) > 0 then
          LErrors.Add(LName + ': ' + LLine);
    end;
    Assert.AreEqual('', Trim(LErrors.Text), IntToStr(FMenuFiles.Count) + ' menu files');
    Assert.IsTrue(FWorld.Menus.Count > 0);
  finally
    LErrors.Free;
  end;
end;

procedure TTestGuiOpenArena.DovrebbeLeggereITuttiIFontDat;
var
  LName: string;
  LFont: TGuiFont;
  LSize: Integer;
begin
  if FFontFiles.Count = 0 then
  begin
    Assert.Pass('OpenArena data not found: skipped');
    Exit;
  end;
  LFont := TGuiFont.Create;
  try
    for LName in FFontFiles do
    begin
      // fonts/fontImage_16.dat
      LSize := StrToInt(Copy(LName, Pos('fontImage_', LName) + Length('fontImage_'), Length(LName) - Length('.dat') -
        (Pos('fontImage_', LName) + Length('fontImage_')) + 1));
      Assert.IsTrue(FWorld.Fonts.Register('x', LSize, LFont), LName);
      Assert.AreEqual(LName, string(LFont.Name));
    end;
  finally
    LFont.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiOpenArena);

end.
