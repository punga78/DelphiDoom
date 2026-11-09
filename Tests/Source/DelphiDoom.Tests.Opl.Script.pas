{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OPL library - the script runner                     }
{                                                                              }
{  opl.script.txt and adlib.script.txt are lists of commands (scenarios of the  }
{  chip, songs of the player) that the C harness ran against the real fmopl.cpp }
{  and adlplayer.cpp of OpenXcom; this unit runs the same commands on the       }
{  Pascal classes and prints the same lines (Tests\Data\README.md)              }
{                                                                              }
{  Derived from fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later) and   }
{  OpenXcom (GPL v3 or later): see Libs\Opl\README.md                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Opl.Script;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf,
  DelphiDoom.Opl.Tables, DelphiDoom.Opl.Noise, DelphiDoom.Opl.Chip, DelphiDoom.XcomAdlib.Intf,
  DelphiDoom.XcomAdlib.Factory, DelphiDoom.Tests.Opl.Recorder;

type
  /// <summary>The handlers of the C harness: they print a line for each call</summary>
  TOplScriptListener = class(TInterfacedObject, IOplChipListener)
  strict private
    FEmit: TProc<string>;
    FCurrent: TFunc<Integer>;
  public
    constructor Create(const AEmit: TProc<string>; const ACurrent: TFunc<Integer>);
    procedure TimerChanged(AChannel: Integer; AIntervalSeconds: Double);
    procedure IrqChanged(AParam: Integer; ALevel: Integer);
    procedure BeforeDataWrite(AParam: Integer);
  end;

  /// <summary>Runs the scripts and gives the lines the C harness printed (the list belongs to the runner)</summary>
  TOplScriptRunner = class
  strict private
    FLines: TStringList;
    FSongs: TList<TBytes>;
    FTables: IOplTables;
    FNoise: IOplNoiseSource;
    FChips: array[0..1] of IOplChip;
    FCurrent: Integer;
    FPlayer: IXcomAdlibPlayer;
    FPlayerChips: array[0..1] of IOplChip;
    FHash: UInt64;
    procedure Emit(const AText: string);
    procedure ResetHash;
    function HashText(AValue: UInt64): string;
    function Fnv16(const ABuffer: TArray<SmallInt>; ACount: Integer): UInt64;
    procedure Scenario(const AName: string);
    procedure RunLine(const ALine: string);
    procedure CreateChip(ANumber, AClock, ARate, AType: Integer);
    procedure StartSong(ASong, ARate: Integer; AVolume: Single);
    class function BitsToSingle(AValue: Cardinal): Single; static;
    function GetCurrent: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadSongs(const ALines: TStrings);
    /// <summary>The lines printed for a script</summary>
    function Run(const AScript: TStrings): TStringList;
  end;

implementation

{$Q-}
{$R-}

{ TOplScriptListener }

constructor TOplScriptListener.Create(const AEmit: TProc<string>; const ACurrent: TFunc<Integer>);
begin
  inherited Create;
  FEmit := AEmit;
  FCurrent := ACurrent;
end;

procedure TOplScriptListener.TimerChanged(AChannel: Integer; AIntervalSeconds: Double);
var
  LBits: UInt64;
begin
  Move(AIntervalSeconds, LBits, SizeOf(LBits));
  FEmit(Format('T %d %d %s', [FCurrent(), AChannel, LowerCase(IntToHex(LBits, 16))]));
end;

procedure TOplScriptListener.IrqChanged(AParam: Integer; ALevel: Integer);
begin
  FEmit(Format('I %d %d %d', [FCurrent(), AParam, ALevel]));
end;

procedure TOplScriptListener.BeforeDataWrite(AParam: Integer);
begin
  FEmit(Format('U %d', [AParam]));
end;

{ TOplScriptRunner }

constructor TOplScriptRunner.Create;
begin
  inherited Create;
  FSongs := TList<TBytes>.Create;
  FTables := TOplTables.Create;
  FNoise := TOplMsvcrtNoise.Create(1);
end;

destructor TOplScriptRunner.Destroy;
begin
  FPlayer := nil;
  FChips[0] := nil;
  FChips[1] := nil;
  FPlayerChips[0] := nil;
  FPlayerChips[1] := nil;
  FSongs.Free;
  FLines.Free;
  inherited Destroy;
end;

procedure TOplScriptRunner.Emit(const AText: string);
begin
  FLines.Add(AText);
end;

procedure TOplScriptRunner.ResetHash;
begin
  FHash := UInt64($CBF29CE484222325);
end;

function TOplScriptRunner.HashText(AValue: UInt64): string;
begin
  Result := LowerCase(IntToHex(AValue, 16));
end;

function TOplScriptRunner.Fnv16(const ABuffer: TArray<SmallInt>; ACount: Integer): UInt64;
var
  LIndex: Integer;
  LValue: Word;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to ACount - 1 do
  begin
    LValue := Word(ABuffer[LIndex]);
    Result := (Result xor (LValue and $FF)) * UInt64($100000001B3);
    Result := (Result xor (LValue shr 8)) * UInt64($100000001B3);
  end;
end;

class function TOplScriptRunner.BitsToSingle(AValue: Cardinal): Single;
begin
  Move(AValue, Result, SizeOf(Single));
end;

function TOplScriptRunner.GetCurrent: Integer;
begin
  Result := FCurrent;
end;

procedure TOplScriptRunner.LoadSongs(const ALines: TStrings);
var
  LLine: string;
  LParts: TArray<string>;
  LBytes: TBytes;
  LIndex: Integer;
begin
  for LLine in ALines do
  begin
    LParts := LLine.Split([' ']);
    if (Length(LParts) = 3) and (LParts[0] = 'SONG') then
    begin
      SetLength(LBytes, Length(LParts[2]) div 2);
      for LIndex := 0 to High(LBytes) do
        LBytes[LIndex] := StrToInt('$' + Copy(LParts[2], LIndex * 2 + 1, 2));
      FSongs.Add(LBytes);
    end;
  end;
end;

procedure TOplScriptRunner.CreateChip(ANumber, AClock, ARate, AType: Integer);
begin
  FChips[ANumber] := TOplChip.Create(FTables, FNoise, TOplChipType(AType), AClock, ARate);
end;

procedure TOplScriptRunner.StartSong(ASong, ARate: Integer; AVolume: Single);
var
  LLeft: IOplChip;
  LRight: IOplChip;
begin
  if not Assigned(FPlayer) then
  begin
    FPlayerChips[0] := TOplChip.Create(FTables, FNoise, octYm3812, 3579545, ARate);
    FPlayerChips[1] := TOplChip.Create(FTables, FNoise, octYm3812, 3579545, ARate);
    LLeft := TOplRecorderChip.Create(FPlayerChips[0], 0, @FHash);
    LRight := TOplRecorderChip.Create(FPlayerChips[1], 1, @FHash);
    FPlayer := TXcomAdlibFactory.CreatePlayer(LLeft, LRight, ARate);
  end;
  FPlayer.Load(FSongs[ASong]);
  ResetHash;
  FPlayer.Play(AVolume);
end;

procedure TOplScriptRunner.Scenario(const AName: string);
begin
  Emit('SCENARIO ' + AName);
  FChips[0] := nil;
  FChips[1] := nil;
  FPlayer := nil;
  FPlayerChips[0] := nil;
  FPlayerChips[1] := nil;
end;

procedure TOplScriptRunner.RunLine(const ALine: string);
var
  LParts: TArray<string>;
  LCommand: string;
  LBuffer: TArray<SmallInt>;
  LIndex: Integer;
  LNumber: Integer;
  LLength: Integer;

  function Num(AIndex: Integer): Integer;
  begin
    Result := StrToInt(LParts[AIndex]);
  end;

  function Bits(AIndex: Integer): Single;
  begin
    Result := BitsToSingle(Cardinal(StrToUInt64('$' + LParts[AIndex])));
  end;

begin
  LParts := ALine.Split([' ']);
  LCommand := LParts[0];
  if LCommand = 'SCENARIO' then
    Scenario(LParts[1])
  else if LCommand = 'SRAND' then
    FNoise := TOplMsvcrtNoise.Create(Cardinal(Num(1)))
  else if LCommand = 'CHIP' then
    CreateChip(Num(1), Num(2), Num(3), Num(4))
  else if LCommand = 'HANDLERS' then
    FChips[Num(1)].SetListener(TOplScriptListener.Create(
      procedure(AText: string)
      begin
        Emit(AText);
      end,
      function: Integer
      begin
        Result := GetCurrent;
      end), 0, 7, Num(1))
  else if LCommand = 'W' then
  begin
    FCurrent := Num(1);
    FChips[FCurrent].Write(0, Num(2));
    Emit(Format('W %d', [FChips[FCurrent].Write(1, Num(3))]));
  end
  else if LCommand = 'A' then
  begin
    FCurrent := Num(1);
    Emit(Format('A %d', [FChips[FCurrent].Write(Num(2), Num(3))]));
  end
  else if LCommand = 'RD' then
    Emit(Format('RD %d', [FChips[Num(1)].Read(Num(2))]))
  else if LCommand = 'TO' then
  begin
    FCurrent := Num(1);
    Emit(Format('TO %d', [FChips[FCurrent].TimerOver(Num(2))]));
  end
  else if LCommand = 'RESET' then
  begin
    FCurrent := Num(1);
    FChips[FCurrent].Reset;
  end
  else if LCommand = 'GEN' then
  begin
    LNumber := Num(1);
    LLength := Num(2);
    SetLength(LBuffer, LLength);
    for LIndex := 0 to LLength - 1 do
      LBuffer[LIndex] := $1234;
    FChips[LNumber].GenerateSamples(LBuffer, 0, LLength, Num(3), Bits(4));
    Emit(Format('G %d %d %s', [LNumber, LLength, HashText(Fnv16(LBuffer, LLength))]));
  end
  else if LCommand = 'PSETUP' then
  begin
    StartSong(Num(1), Num(2), Bits(3));
    Emit(Format('S %s %d %d', [HashText(FHash), Ord(FPlayer.IsPlaying), FPlayer.Polyphony]));
  end
  else if LCommand = 'PRENDER' then
  begin
    LLength := Num(1);
    SetLength(LBuffer, LLength div 2);
    for LIndex := 0 to High(LBuffer) do
      LBuffer[LIndex] := $1234;
    ResetHash;
    FPlayer.Render(LBuffer, LLength, Bits(2));
    Emit(Format('P %d %s %s %d %d %d', [LLength, HashText(Fnv16(LBuffer, Length(LBuffer))), HashText(FHash),
      Ord(FPlayer.IsPlaying), FPlayer.Polyphony, FPlayer.PendingBytes]));
  end
  else if LCommand = 'PFADE' then
  begin
    ResetHash;
    FPlayer.Fade;
    Emit(Format('PF %s %d', [HashText(FHash), Ord(FPlayer.IsPlaying)]));
  end
  else if LCommand = 'PTEMPO' then
    FPlayer.SetTempo(Num(1))
  else if LCommand = 'PVOL' then
  begin
    ResetHash;
    FPlayer.SetVolume(Num(1));
    Emit(Format('PV %s', [HashText(FHash)]));
  end
  else if LCommand = 'PSAVE' then
    FPlayer.SaveState(Num(1))
  else if LCommand = 'PLOAD' then
  begin
    ResetHash;
    FPlayer.LoadState(Num(1));
    Emit(Format('PL %s', [HashText(FHash)]));
  end
  else if LCommand = 'PMUTE' then
  begin
    ResetHash;
    FPlayer.Stop;
    Emit(Format('PM %s %d', [HashText(FHash), Ord(FPlayer.IsPlaying)]));
  end
  else if LCommand = 'PEND' then
    Emit('PEND')
  else
    raise Exception.CreateFmt('Unknown command "%s"', [LCommand]);
end;

function TOplScriptRunner.Run(const AScript: TStrings): TStringList;
var
  LLine: string;
begin
  FreeAndNil(FLines);
  FLines := TStringList.Create;
  Result := FLines;
  for LLine in AScript do
    if Trim(LLine) <> '' then
      RunLine(Trim(LLine));
  Scenario('end');
  FLines.Delete(FLines.Count - 1);
end;

end.
