{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the external songs                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.ExternalMusicCache;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Audio.Intf, DelphiDoom.Audio.Factory;

type
  TFakeExternalMusicClip = class(TInterfacedObject, IExternalMusicClip)
  private
    FSize: Integer;
  public
    Loaded: Boolean;
    constructor Create(ASize: Integer);
    function GetData: Pointer;
    function GetSize: Integer;
    function GetIsLoaded: Boolean;
  end;

  TFakeExternalMusicSource = class(TInterfacedObject, IExternalMusicSource)
  public
    /// <summary>The file names that exist, with the size of the clip</summary>
    Existing: TDictionary<string, Integer>;
    Requested: TList<string>;
    LastClip: TFakeExternalMusicClip;
    constructor Create;
    destructor Destroy; override;
    function TryLoad(const AFileName: string): IExternalMusicClip;
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioExternalMusicCache = class(TObject)
  private
    FSource: TFakeExternalMusicSource;
    FSourceIntf: IExternalMusicSource;
    FCache: IExternalMusicCache;
    function RequestedNames: string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareErroreConSorgenteNil;
    [Test]
    procedure DovrebbeDareNilSeNonCeIlFile;
    [Test]
    procedure DovrebbeProvareLeEstensioniNellOrdine;
    [Test]
    procedure DovrebbeFermarsiAlPrimoFileTrovato;
    [Test]
    procedure DovrebbeDareLaMusicaTrovata;
    [Test]
    procedure DovrebbeRicordareLaMusicaTrovata;
    [Test]
    procedure DovrebbeNonDistinguereMaiuscoleENelNome;
    [Test]
    procedure DovrebbeRicercareUnFileNonTrovatoOgniVolta;
    [Test]
    procedure DovrebbeRicaricareSeLaMemoriaERitornataAlMotore;
    [Test]
    procedure DovrebbeDimenticareTuttoConClear;
    [Test]
    procedure DovrebbeTenereSeparateMusicheDiversi;
    [Test]
    procedure DovrebbeUsareLeEstensioniDelMotore;
  end;

implementation

{ TFakeExternalMusicClip }

constructor TFakeExternalMusicClip.Create(ASize: Integer);
begin
  inherited Create;
  FSize := ASize;
  Loaded := True;
end;

function TFakeExternalMusicClip.GetData: Pointer;
begin
  if Loaded then
    Result := Pointer(1)
  else
    Result := nil;
end;

function TFakeExternalMusicClip.GetSize: Integer;
begin
  Result := FSize;
end;

function TFakeExternalMusicClip.GetIsLoaded: Boolean;
begin
  Result := Loaded;
end;

{ TFakeExternalMusicSource }

constructor TFakeExternalMusicSource.Create;
begin
  inherited Create;
  Existing := TDictionary<string, Integer>.Create;
  Requested := TList<string>.Create;
end;

destructor TFakeExternalMusicSource.Destroy;
begin
  Existing.Free;
  Requested.Free;
  inherited Destroy;
end;

function TFakeExternalMusicSource.TryLoad(const AFileName: string): IExternalMusicClip;
var
  LSize: Integer;
begin
  Requested.Add(AFileName);
  Result := nil;
  if Existing.TryGetValue(AFileName, LSize) then
  begin
    LastClip := TFakeExternalMusicClip.Create(LSize);
    Result := LastClip;
  end;
end;

{ TTestAudioExternalMusicCache }

procedure TTestAudioExternalMusicCache.Setup;
begin
  FSource := TFakeExternalMusicSource.Create;
  FSourceIntf := FSource;
  FCache := TAudioFactory.CreateExternalMusicCache(FSourceIntf);
end;

function TTestAudioExternalMusicCache.RequestedNames: string;
var
  LName: string;
begin
  Result := '';
  for LName in FSource.Requested do
    Result := Result + '[' + LName + ']';
end;

procedure TTestAudioExternalMusicCache.DovrebbeDareErroreConSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TAudioFactory.CreateExternalMusicCache(nil);
    end, EArgumentNilException);
end;

procedure TTestAudioExternalMusicCache.DovrebbeDareNilSeNonCeIlFile;
begin
  Assert.IsNull(FCache.Find('D_E1M1'));
end;

procedure TTestAudioExternalMusicCache.DovrebbeProvareLeEstensioniNellOrdine;
begin
  FCache.Find('D_E1M1');
  Assert.AreEqual('[D_E1M1.MOD][D_E1M1.S3M][D_E1M1.IT][D_E1M1.XM]', RequestedNames);
end;

procedure TTestAudioExternalMusicCache.DovrebbeFermarsiAlPrimoFileTrovato;
begin
  FSource.Existing.Add('D_E1M1.S3M', 10);
  FSource.Existing.Add('D_E1M1.XM', 20);
  FCache.Find('D_E1M1');
  Assert.AreEqual('[D_E1M1.MOD][D_E1M1.S3M]', RequestedNames);
end;

procedure TTestAudioExternalMusicCache.DovrebbeDareLaMusicaTrovata;
var
  LClip: IExternalMusicClip;
begin
  FSource.Existing.Add('D_E1M1.IT', 1234);
  LClip := FCache.Find('D_E1M1');
  Assert.IsNotNull(LClip);
  Assert.AreEqual(1234, LClip.Size);
  Assert.IsTrue(LClip.IsLoaded);
  Assert.IsTrue(LClip.Data <> nil);
end;

procedure TTestAudioExternalMusicCache.DovrebbeRicordareLaMusicaTrovata;
var
  LFirst, LSecond: IExternalMusicClip;
begin
  FSource.Existing.Add('D_E1M1.MOD', 10);
  LFirst := FCache.Find('D_E1M1');
  LSecond := FCache.Find('D_E1M1');
  Assert.AreEqual(1, FSource.Requested.Count);
  Assert.IsTrue(LFirst = LSecond);
end;

procedure TTestAudioExternalMusicCache.DovrebbeNonDistinguereMaiuscoleENelNome;
begin
  FSource.Existing.Add('d_e1m1.MOD', 10);
  FCache.Find('d_e1m1');
  FCache.Find('D_E1M1');
  Assert.AreEqual(1, FSource.Requested.Count);
end;

procedure TTestAudioExternalMusicCache.DovrebbeRicercareUnFileNonTrovatoOgniVolta;
begin
  FCache.Find('D_E1M1');
  FCache.Find('D_E1M1');
  Assert.AreEqual(8, FSource.Requested.Count);
end;

procedure TTestAudioExternalMusicCache.DovrebbeRicaricareSeLaMemoriaERitornataAlMotore;
var
  LFirst, LSecond: IExternalMusicClip;
begin
  FSource.Existing.Add('D_E1M1.MOD', 10);
  LFirst := FCache.Find('D_E1M1');
  FSource.LastClip.Loaded := False;
  LSecond := FCache.Find('D_E1M1');
  Assert.AreEqual(2, FSource.Requested.Count);
  Assert.IsFalse(LFirst = LSecond);
  Assert.IsTrue(LSecond.IsLoaded);
end;

procedure TTestAudioExternalMusicCache.DovrebbeDimenticareTuttoConClear;
begin
  FSource.Existing.Add('D_E1M1.MOD', 10);
  FCache.Find('D_E1M1');
  FCache.Clear;
  FCache.Find('D_E1M1');
  Assert.AreEqual(2, FSource.Requested.Count);
end;

procedure TTestAudioExternalMusicCache.DovrebbeTenereSeparateMusicheDiversi;
var
  LFirst, LSecond: IExternalMusicClip;
begin
  FSource.Existing.Add('D_E1M1.MOD', 10);
  FSource.Existing.Add('D_E1M2.MOD', 20);
  LFirst := FCache.Find('D_E1M1');
  LSecond := FCache.Find('D_E1M2');
  Assert.AreEqual(10, LFirst.Size);
  Assert.AreEqual(20, LSecond.Size);
end;

procedure TTestAudioExternalMusicCache.DovrebbeUsareLeEstensioniDelMotore;
begin
  // the old table: .MOD, .S3M, .IT, .XM and nothing else
  FCache.Find('X');
  Assert.AreEqual(4, FSource.Requested.Count);
end;

end.
