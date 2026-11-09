{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the loader of the DLLs of the PAK files                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.DllLoader;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Recorder,
  DelphiDoom.ScriptHost.Dll.Intf;

type
  /// <summary>Knows some DLLs by name: the key is the upper case name without folders</summary>
  TFakeDllSource = class(TInterfacedObject, IScriptDllSource)
  public
    Known: TStringList;
    Extracted: Integer;
    constructor Create;
    destructor Destroy; override;
    function KeyOf(const AName: string): string;
    function Extract(const AName: string; out APath: string): Boolean;
  end;

  /// <summary>Gives a new handle to every library, unless the path is on the list of the ones that fail</summary>
  TFakeDllLibrary = class(TInterfacedObject, IScriptDllLibrary)
  public
    Failing: TStringList;
    Loaded: TStringList;
    Unloaded: TList;
    NextHandle: NativeUInt;
    constructor Create;
    destructor Destroy; override;
    function Load(const APath: string): NativeUInt;
    procedure Unload(const AHandle: NativeUInt);
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostDllLoader = class(TObject)
  strict private
    FSource: TFakeDllSource;
    FSourceRef: IScriptDllSource;
    FLibrary: TFakeDllLibrary;
    FLibraryRef: IScriptDllLibrary;
    FRecorder: TLogRecorder;
    FRecorderRef: ILogSink;
    FLoader: IScriptDllLoader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnaDllNuovaDaUnFileTemporaneo;
    [Test]
    procedure DovrebbeDareLoStessoHandleSenzaRicaricareConUnNomeUguale;
    [Test]
    procedure DovrebbeDareZeroSeLaDllNonSiTrova;
    [Test]
    procedure DovrebbeDareZeroERiprovareSeIlSistemaNonLaCarica;
    [Test]
    procedure DovrebbeScaricareAllUltimoUso;
    [Test]
    procedure DovrebbeDareFalsoPerUnaDllNonCaricata;
    [Test]
    procedure DovrebbeRicaricareDopoLoScaricoCompleto;
    [Test]
    procedure DovrebbeTenereDistinteLeDllDiNomeDiverso;
    [Test]
    procedure DovrebbeDimenticareLeDllSenzaScaricarleAllaChiusura;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    [Test]
    procedure DovrebbeCaricareEScaricareUnaLibreriaDiWindows;
    [Test]
    procedure DovrebbeDareZeroPerUnaLibreriaDiWindowsCheNonEsiste;
  end;

implementation

uses
  DelphiDoom.Logging.Factory,
  DelphiDoom.ScriptHost.Factory;

{ TFakeDllSource }

constructor TFakeDllSource.Create;
begin
  inherited Create;
  Known := TStringList.Create;
end;

destructor TFakeDllSource.Destroy;
begin
  Known.Free;
  inherited;
end;

function TFakeDllSource.KeyOf(const AName: string): string;
begin
  Result := UpperCase(ExtractFileName(AName));
end;

function TFakeDllSource.Extract(const AName: string; out APath: string): Boolean;
begin
  Result := Known.IndexOf(KeyOf(AName)) >= 0;
  if Result then
  begin
    Inc(Extracted);
    APath := 'tmp\' + KeyOf(AName);
  end
  else
    APath := '';
end;

{ TFakeDllLibrary }

constructor TFakeDllLibrary.Create;
begin
  inherited Create;
  Failing := TStringList.Create;
  Loaded := TStringList.Create;
  Unloaded := TList.Create;
  NextHandle := 1000;
end;

destructor TFakeDllLibrary.Destroy;
begin
  Unloaded.Free;
  Loaded.Free;
  Failing.Free;
  inherited;
end;

function TFakeDllLibrary.Load(const APath: string): NativeUInt;
begin
  Loaded.Add(APath);
  if Failing.IndexOf(APath) >= 0 then
    Result := 0
  else
  begin
    Result := NextHandle;
    Inc(NextHandle);
  end;
end;

procedure TFakeDllLibrary.Unload(const AHandle: NativeUInt);
begin
  Unloaded.Add(Pointer(AHandle));
end;

{ TTestScriptHostDllLoader }

procedure TTestScriptHostDllLoader.Setup;
begin
  FSource := TFakeDllSource.Create;
  FSourceRef := FSource;
  FSource.Known.Add('MODEL.DLL');
  FSource.Known.Add('OTHER.DLL');
  FLibrary := TFakeDllLibrary.Create;
  FLibraryRef := FLibrary;
  FRecorder := TLogRecorder.Create;
  FRecorderRef := FRecorder;
  FLoader := TScriptHostFactory.CreateDllLoader(FSourceRef, FLibraryRef,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderRef), nil));
end;

procedure TTestScriptHostDllLoader.TearDown;
begin
  FLoader := nil;
  FRecorderRef := nil;
  FLibraryRef := nil;
  FSourceRef := nil;
end;

procedure TTestScriptHostDllLoader.DovrebbeCaricareUnaDllNuovaDaUnFileTemporaneo;
begin
  Assert.AreEqual(NativeUInt(1000), FLoader.Load('dll\model.dll'));
  Assert.AreEqual(1, FSource.Extracted);
  Assert.AreEqual('tmp\MODEL.DLL', FLibrary.Loaded[0]);
end;

procedure TTestScriptHostDllLoader.DovrebbeDareLoStessoHandleSenzaRicaricareConUnNomeUguale;
begin
  Assert.AreEqual(NativeUInt(1000), FLoader.Load('model.dll'));
  Assert.AreEqual(NativeUInt(1000), FLoader.Load('DLL\Model.DLL'));
  Assert.AreEqual(1, FSource.Extracted);
  Assert.AreEqual(1, FLibrary.Loaded.Count);
end;

procedure TTestScriptHostDllLoader.DovrebbeDareZeroSeLaDllNonSiTrova;
begin
  Assert.AreEqual(NativeUInt(0), FLoader.Load('missing.dll'));
  Assert.AreEqual(0, FLibrary.Loaded.Count);
end;

procedure TTestScriptHostDllLoader.DovrebbeDareZeroERiprovareSeIlSistemaNonLaCarica;
begin
  FLibrary.Failing.Add('tmp\MODEL.DLL');
  Assert.AreEqual(NativeUInt(0), FLoader.Load('model.dll'));
  Assert.AreEqual(NativeUInt(0), FLoader.Load('model.dll'));
  // a failure is not remembered: both times the file was extracted and loaded
  Assert.AreEqual(2, FSource.Extracted);
  Assert.AreEqual(2, FLibrary.Loaded.Count);
  Assert.IsFalse(FLoader.Unload('model.dll'));
end;

procedure TTestScriptHostDllLoader.DovrebbeScaricareAllUltimoUso;
begin
  FLoader.Load('model.dll');
  FLoader.Load('model.dll');
  Assert.IsTrue(FLoader.Unload('model.dll'));
  Assert.AreEqual(0, FLibrary.Unloaded.Count);
  Assert.IsTrue(FLoader.Unload('model.dll'));
  Assert.AreEqual(1, FLibrary.Unloaded.Count);
  Assert.AreEqual(NativeUInt(1000), NativeUInt(FLibrary.Unloaded[0]));
end;

procedure TTestScriptHostDllLoader.DovrebbeDareFalsoPerUnaDllNonCaricata;
begin
  Assert.IsFalse(FLoader.Unload('model.dll'));
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestScriptHostDllLoader.DovrebbeRicaricareDopoLoScaricoCompleto;
begin
  FLoader.Load('model.dll');
  FLoader.Unload('model.dll');
  Assert.AreEqual(NativeUInt(1001), FLoader.Load('model.dll'));
  Assert.AreEqual(2, FSource.Extracted);
end;

procedure TTestScriptHostDllLoader.DovrebbeTenereDistinteLeDllDiNomeDiverso;
begin
  Assert.AreEqual(NativeUInt(1000), FLoader.Load('model.dll'));
  Assert.AreEqual(NativeUInt(1001), FLoader.Load('other.dll'));
  FLoader.Unload('model.dll');
  Assert.AreEqual(1, FLibrary.Unloaded.Count);
  Assert.AreEqual(NativeUInt(1001), FLoader.Load('other.dll'));
end;

procedure TTestScriptHostDllLoader.DovrebbeDimenticareLeDllSenzaScaricarleAllaChiusura;
begin
  FLoader.Load('model.dll');
  FLoader.Shutdown;
  // as ps_dll.pas did: the libraries stay loaded until the process ends
  Assert.AreEqual(0, FLibrary.Unloaded.Count);
  Assert.IsFalse(FLoader.Unload('model.dll'));
end;

procedure TTestScriptHostDllLoader.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateDllLoader(nil, FLibraryRef, TLogFactory.CreateLog(nil, nil));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateDllLoader(FSourceRef, nil, TLogFactory.CreateLog(nil, nil));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateDllLoader(FSourceRef, FLibraryRef, nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostDllLoader.DovrebbeCaricareEScaricareUnaLibreriaDiWindows;
var
  LLibrary: IScriptDllLibrary;
  LHandle: NativeUInt;
begin
  LLibrary := TScriptHostFactory.CreateWindowsDllLibrary;
  LHandle := LLibrary.Load('kernel32.dll');
  Assert.AreNotEqual(NativeUInt(0), LHandle);
  LLibrary.Unload(LHandle);
end;

procedure TTestScriptHostDllLoader.DovrebbeDareZeroPerUnaLibreriaDiWindowsCheNonEsiste;
begin
  Assert.AreEqual(NativeUInt(0),
    TScriptHostFactory.CreateWindowsDllLibrary.Load('this_dll_does_not_exist_dd.dll'));
end;

end.
