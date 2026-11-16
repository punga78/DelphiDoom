{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the fakes                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Support;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Intf;

type
  /// <summary>Keeps what the modules print, as the "P" lines of the driver of the C write it</summary>
  TQ3RecordingConsole = class(TInterfacedObject, IQ3HostConsole)
  strict private
    FLines: TStrings;
    FTexts: TStringList;
  public
    /// <param name="ALines">Where the "P text" lines go; may be nil</param>
    constructor Create(ALines: TStrings);
    destructor Destroy; override;
    procedure Print(const AText: AnsiString);
    property Texts: TStringList read FTexts;
  end;

  TQ3FixedTime = class(TInterfacedObject, IQ3HostTime)
  strict private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    function Milliseconds: Integer;
    property Value: Integer read FValue write FValue;
  end;

  /// <summary>
  ///   Counts the system calls and fingerprints them (FNV-1a 64 on the 40 bytes of the arguments and the 4 of
  ///   the result), as the "M" line of the driver of the C does, and passes them to the host it wraps
  /// </summary>
  TQ3FingerprintHost = class(TInterfacedObject, IQvmHost)
  strict private
    FInner: IQvmHost;
    FCount: Integer;
    FHash: UInt64;
  public
    constructor Create(const AInner: IQvmHost);
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    property Count: Integer read FCount;
    property Hash: UInt64 read FHash;
  end;

implementation

uses
  DelphiDoom.Tests.Shared.Fnv, DelphiDoom.Tests.Qvm.Support;

constructor TQ3RecordingConsole.Create(ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FTexts := TStringList.Create;
end;

destructor TQ3RecordingConsole.Destroy;
begin
  FTexts.Free;
  inherited Destroy;
end;

procedure TQ3RecordingConsole.Print(const AText: AnsiString);
begin
  FTexts.Add(string(AText));
  if Assigned(FLines) then
    FLines.Add('P ' + TQvmScenarioRunner.Escaped(AText));
end;

constructor TQ3FixedTime.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TQ3FixedTime.Milliseconds: Integer;
begin
  Result := FValue;
end;

constructor TQ3FingerprintHost.Create(const AInner: IQvmHost);
begin
  inherited Create;
  FInner := AInner;
  FHash := TTestFnv.OFFSET_64;
end;

function TQ3FingerprintHost.SystemCall(const AMachine: IQvmMachine;
  const AArguments: TQvmSystemCallArguments): Integer;
begin
  Inc(FCount);
  TTestFnv.Mix64(FHash, @AArguments[0], 40);
  Result := FInner.SystemCall(AMachine, AArguments);
  TTestFnv.Mix64(FHash, @Result, 4);
end;

end.
