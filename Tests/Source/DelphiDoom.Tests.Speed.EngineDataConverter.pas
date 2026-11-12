{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineSpeedDataConverter                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.EngineDataConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Speed.Fakes,
  DelphiDoom.Engine.Wad.Converter.Intf, DelphiDoom.Engine.Speed.DataConverter;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedEngineDataConverter = class(TObject)
  strict private
    FFileName: string;
    FConverter: TEngineSpeedDataConverter;
    FKeepAlive: IEngineWadConverter;
    procedure WriteFile(const ABytes: TBytes);
    function ContainsName(const AWad: TBytes; const AName: AnsiString): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTradurreUnContenitoreInUnWad;
    [Test]
    procedure DovrebbeAggiungereIlFontConINomiDiDoom;
    [Test]
    procedure DovrebbeDareIModelliDelContenitore;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileCheNonEUnContenitore;
    [Test]
    procedure DovrebbeDareEccezioneSenzaLog;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Speed.JclBuilder;

{ TTestSpeedEngineDataConverter }

procedure TTestSpeedEngineDataConverter.Setup;
begin
  FFileName := TPath.Combine(TPath.GetTempPath, 'ddtest_' + TPath.GetGUIDFileName + '.jcl');
  FConverter := TEngineSpeedDataConverter.Create(TFakeLog.Create);
  FKeepAlive := FConverter;
end;

procedure TTestSpeedEngineDataConverter.TearDown;
begin
  FKeepAlive := nil;
  FConverter := nil;
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

procedure TTestSpeedEngineDataConverter.WriteFile(const ABytes: TBytes);
begin
  TFile.WriteAllBytes(FFileName, ABytes);
end;

function TTestSpeedEngineDataConverter.ContainsName(const AWad: TBytes; const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to Length(AWad) - Length(AName) do
  begin
    if CompareMem(@AWad[LIndex], PAnsiChar(AName), Length(AName)) then
      Exit(True);
  end;
end;

procedure TTestSpeedEngineDataConverter.DovrebbeTradurreUnContenitoreInUnWad;
var
  LWad: TBytes;
begin
  WriteFile(TJclBuilder.SyntheticGame);

  Assert.IsTrue(FKeepAlive.TryConvert(FFileName, LWad));

  Assert.IsTrue(Length(LWad) > 12);
  Assert.AreEqual('WAD', string(AnsiString(AnsiChar(LWad[1]) + AnsiChar(LWad[2]) + AnsiChar(LWad[3]))));
  Assert.IsTrue(ContainsName(LWad, 'PLAYPAL'));
  Assert.IsTrue(ContainsName(LWad, 'COLORMAP'));
end;

procedure TTestSpeedEngineDataConverter.DovrebbeAggiungereIlFontConINomiDiDoom;
var
  LWad: TBytes;
begin
  WriteFile(TJclBuilder.SyntheticGame);

  Assert.IsTrue(FKeepAlive.TryConvert(FFileName, LWad));

  Assert.IsTrue(ContainsName(LWad, 'SFNTA033'));
  Assert.IsTrue(ContainsName(LWad, 'STCFN033'));
  Assert.IsTrue(ContainsName(LWad, 'STCFN095'));
  Assert.IsFalse(ContainsName(LWad, 'STCFN096'));
end;

procedure TTestSpeedEngineDataConverter.DovrebbeDareIModelliDelContenitore;
var
  LWad: TBytes;
begin
  WriteFile(TJclBuilder.SyntheticGame);

  Assert.IsTrue(FKeepAlive.TryConvert(FFileName, LWad));

  Assert.AreEqual(2, Integer(Length(FConverter.Models)));
  Assert.AreEqual('MODELS\CAR0N0A.I3D', FConverter.Models[0].Name);
  Assert.AreEqual(77, FConverter.Models[0].Size);
end;

procedure TTestSpeedEngineDataConverter.DovrebbeDareFalsoPerUnFileCheNonEUnContenitore;
var
  LWad: TBytes;
begin
  WriteFile(TJclBuilder.RandomBytes(3, 4096, 255));

  Assert.IsFalse(FKeepAlive.TryConvert(FFileName, LWad));
  Assert.AreEqual(0, Integer(Length(LWad)));
end;

procedure TTestSpeedEngineDataConverter.DovrebbeDareEccezioneSenzaLog;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineSpeedDataConverter.Create(nil);
    end, EArgumentNilException);
end;

end.
