{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the list of voices         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.VoiceList;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.AudioMix.Intf, DelphiDoom.AudioMix.VoiceList;

type
  /// <summary>A voice that lives for a number of blocks and writes its name in a log</summary>
  TFakeVoice = class(TInterfacedObject, IPcmVoice)
  strict private
    FName: Integer;
    FBlocksLeft: Integer;
    FLog: TList<Integer>;
  public
    constructor Create(AName, ABlocks: Integer; ALog: TList<Integer>);
    function Mix(ADestination: Pointer; ACount: Integer): Boolean;
  end;

  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixVoiceList = class
  strict private
    FList: TPcmVoiceList;
    FLog: TList<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareHandleCrescentiDaUno;
    [Test]
    procedure DovrebbeRifiutareUnaVoceNil;
    [Test]
    procedure DovrebbeMescolareNellOrdineDiInserimento;
    [Test]
    procedure DovrebbeTogliereLeVociFinitEContarle;
    [Test]
    procedure DovrebbeTogliereUnaVocePerHandle;
    [Test]
    procedure DovrebbeIgnorareUnHandleSconosciuto;
    [Test]
    procedure DovrebbeSvuotare;
    [Test]
    procedure DovrebbeNonRiusareUnHandleDopoSvuotare;
    [Test]
    procedure DovrebbeDareLoStessoNumeroDiVociTraDueThread;
  end;

implementation

{ TFakeVoice }

constructor TFakeVoice.Create(AName, ABlocks: Integer; ALog: TList<Integer>);
begin
  inherited Create;
  FName := AName;
  FBlocksLeft := ABlocks;
  FLog := ALog;
end;

function TFakeVoice.Mix(ADestination: Pointer; ACount: Integer): Boolean;
begin
  if Assigned(FLog) then
    FLog.Add(FName);
  Dec(FBlocksLeft);
  Result := FBlocksLeft <= 0;
end;

{ TTestAudioMixVoiceList }

procedure TTestAudioMixVoiceList.Setup;
begin
  FList := TPcmVoiceList.Create;
  FLog := TList<Integer>.Create;
end;

procedure TTestAudioMixVoiceList.TearDown;
begin
  FLog.Free;
  FList.Free;
end;

procedure TTestAudioMixVoiceList.DovrebbeDareHandleCrescentiDaUno;
begin
  Assert.AreEqual(1, FList.Add(TFakeVoice.Create(10, 5, FLog)));
  Assert.AreEqual(2, FList.Add(TFakeVoice.Create(20, 5, FLog)));
  Assert.AreEqual(3, FList.Add(TFakeVoice.Create(30, 5, FLog)));
  Assert.AreEqual(3, FList.Count);
end;

procedure TTestAudioMixVoiceList.DovrebbeRifiutareUnaVoceNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FList.Add(nil);
    end, EArgumentNilException);
end;

procedure TTestAudioMixVoiceList.DovrebbeMescolareNellOrdineDiInserimento;
begin
  FList.Add(TFakeVoice.Create(10, 5, FLog));
  FList.Add(TFakeVoice.Create(20, 5, FLog));
  FList.Add(TFakeVoice.Create(30, 5, FLog));
  FList.MixAll(nil, 8);
  Assert.AreEqual(3, FLog.Count);
  Assert.AreEqual(10, FLog[0]);
  Assert.AreEqual(20, FLog[1]);
  Assert.AreEqual(30, FLog[2]);
end;

procedure TTestAudioMixVoiceList.DovrebbeTogliereLeVociFinitEContarle;
begin
  FList.Add(TFakeVoice.Create(10, 1, FLog));
  FList.Add(TFakeVoice.Create(20, 3, FLog));
  FList.Add(TFakeVoice.Create(30, 1, FLog));
  Assert.AreEqual(2, FList.MixAll(nil, 8));
  Assert.AreEqual(1, FList.Count);
  Assert.AreEqual(0, FList.MixAll(nil, 8));
  Assert.AreEqual(1, FList.MixAll(nil, 8) + FList.MixAll(nil, 8));
  Assert.AreEqual(0, FList.Count);
end;

procedure TTestAudioMixVoiceList.DovrebbeTogliereUnaVocePerHandle;
var
  LSecond: Integer;
begin
  FList.Add(TFakeVoice.Create(10, 5, FLog));
  LSecond := FList.Add(TFakeVoice.Create(20, 5, FLog));
  FList.Add(TFakeVoice.Create(30, 5, FLog));
  FList.Remove(LSecond);
  FList.MixAll(nil, 8);
  Assert.AreEqual(2, FLog.Count);
  Assert.AreEqual(10, FLog[0]);
  Assert.AreEqual(30, FLog[1]);
end;

procedure TTestAudioMixVoiceList.DovrebbeIgnorareUnHandleSconosciuto;
begin
  FList.Add(TFakeVoice.Create(10, 5, FLog));
  FList.Remove(99);
  Assert.AreEqual(1, FList.Count);
end;

procedure TTestAudioMixVoiceList.DovrebbeSvuotare;
begin
  FList.Add(TFakeVoice.Create(10, 5, FLog));
  FList.Add(TFakeVoice.Create(20, 5, FLog));
  FList.Clear;
  Assert.AreEqual(0, FList.Count);
  Assert.AreEqual(0, FList.MixAll(nil, 8));
  Assert.AreEqual(0, FLog.Count);
end;

procedure TTestAudioMixVoiceList.DovrebbeNonRiusareUnHandleDopoSvuotare;
begin
  FList.Add(TFakeVoice.Create(10, 5, FLog));
  FList.Clear;
  Assert.AreEqual(2, FList.Add(TFakeVoice.Create(20, 5, FLog)));
end;

procedure TTestAudioMixVoiceList.DovrebbeDareLoStessoNumeroDiVociTraDueThread;
const
  VOICES = 400;
var
  LAdder: TThread;
  LEnded: Integer;
  LIndex: Integer;
begin
  // the game thread adds voices that last one block while this thread mixes: none is lost and none twice
  LAdder := TThread.CreateAnonymousThread(
    procedure
    var
      LCount: Integer;
    begin
      for LCount := 1 to VOICES do
        FList.Add(TFakeVoice.Create(LCount, 1, nil));
    end);
  LAdder.FreeOnTerminate := False;
  LEnded := 0;
  LAdder.Start;
  for LIndex := 1 to 2000 do
    Inc(LEnded, FList.MixAll(nil, 8));
  LAdder.WaitFor;
  LAdder.Free;
  Inc(LEnded, FList.MixAll(nil, 8));
  Assert.AreEqual(VOICES, LEnded);
  Assert.AreEqual(0, FList.Count);
end;

end.
