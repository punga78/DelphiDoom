{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the scenarios of the AdLib sound     }
{  effects that the port and the original id_sd.c both run                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.AdLibScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Scripts for the sound manager in the AdLib mode. A script is text, one command per line, that the C harness
  ///   (Tools\Verifica\165\audio\sdharn.c, linked with the original id_sd.c) and Run both read:
  ///   S name kind (start), D sound length priority 17 bytes (instrument and block) count data... (an AdLib sound),
  ///   M mode (SD_SetSoundMode: 0 off, 2 AdLib), P sound (SD_PlaySound), T count (services of the timer),
  ///   X (SD_StopSound), Q (SD_SoundPlaying), E (end). What comes out: "w register value" for each alOut, "t" before
  ///   each service, "m result", "p", "x", "q number"
  /// </summary>
  TKeenAdLibScenarios = class
  public
    /// <summary>ACount scripts from a fixed seed: the same on every machine</summary>
    class function Generate(ACount: Integer): TArray<string>; static;
    /// <summary>What the port does with a script, in the format of the harness (LF line ends)</summary>
    class function Run(const AScript: string): string; static;
    /// <summary>FNV-1a (32 bit) of the bytes of the text</summary>
    class function Hash(const AText: string): Cardinal; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.SoundManager;

type
  /// <summary>xorshift32</summary>
  TAdLibRandom = record
    State: Cardinal;
    function Next: Cardinal;
    function Below(ALimit: Integer): Integer;
  end;

  TLogPort = class(TInterfacedObject, IKeenAdLibPort)
  strict private
    FLog: TStringBuilder;
    FEnabled: Boolean;
  public
    constructor Create(ALog: TStringBuilder);
    procedure Write(ARegister, AValue: Byte);
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TQuietSpeaker = class(TInterfacedObject, IKeenSpeaker)
  public
    procedure Tone(ADivisor: Word);
    procedure Silence;
    procedure Stop;
  end;

  TScriptAudio = class(TInterfacedObject, IKeenChunkSource)
  strict private
    FChunks: TDictionary<Integer, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(AIndex: Integer; const ABytes: TBytes);
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
  end;

{ TAdLibRandom }

function TAdLibRandom.Next: Cardinal;
begin
  State := State xor (State shl 13);
  State := State xor (State shr 17);
  State := State xor (State shl 5);
  Result := State;
end;

function TAdLibRandom.Below(ALimit: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(ALimit));
end;

{ TLogPort }

constructor TLogPort.Create(ALog: TStringBuilder);
begin
  inherited Create;
  FLog := ALog;
  FEnabled := True;
end;

procedure TLogPort.Write(ARegister, AValue: Byte);
begin
  if FEnabled then
    FLog.Append('w ').Append(Integer(ARegister)).Append(' ').Append(Integer(AValue)).Append(#10);
end;

{ TQuietSpeaker }

procedure TQuietSpeaker.Tone(ADivisor: Word);
begin
end;

procedure TQuietSpeaker.Silence;
begin
end;

procedure TQuietSpeaker.Stop;
begin
end;

{ TScriptAudio }

constructor TScriptAudio.Create;
begin
  inherited Create;
  FChunks := TDictionary<Integer, TBytes>.Create;
end;

destructor TScriptAudio.Destroy;
begin
  FChunks.Free;
  inherited Destroy;
end;

procedure TScriptAudio.Put(AIndex: Integer; const ABytes: TBytes);
begin
  FChunks.AddOrSetValue(AIndex, ABytes);
end;

function TScriptAudio.GetChunkCount: Integer;
begin
  Result := KEEN_NUMSNDCHUNKS;
end;

function TScriptAudio.HasChunk(AIndex: Integer): Boolean;
begin
  Result := FChunks.ContainsKey(AIndex);
end;

function TScriptAudio.ReadCompressed(AIndex: Integer): TBytes;
begin
  Result := Read(AIndex);
end;

function TScriptAudio.Read(AIndex: Integer): TBytes;
begin
  if not FChunks.TryGetValue(AIndex, Result) then
    SetLength(Result, 0);
end;

{ TKeenAdLibScenarios }

class function TKeenAdLibScenarios.Generate(ACount: Integer): TArray<string>;
var
  LRandom: TAdLibRandom;
  LScenario: Integer;
  LBuilder: TStringBuilder;
  LSounds: TArray<Integer>;
  LSoundCount: Integer;
  LIndex: Integer;
  LByte: Integer;
  LLength: Integer;
  LSound: Integer;
  LOps: Integer;
  LValue: Integer;
  LUsed: array[0..KEEN_NUMSOUNDS - 1] of Boolean;
begin
  LRandom.State := $1651A0D5;
  SetLength(Result, ACount);
  for LScenario := 0 to ACount - 1 do
  begin
    LBuilder := TStringBuilder.Create;
    try
      LBuilder.Append('S adlib A').Append(#10);
      FillChar(LUsed, SizeOf(LUsed), 0);
      LSoundCount := 3 + LRandom.Below(3);
      SetLength(LSounds, LSoundCount);
      for LIndex := 0 to LSoundCount - 1 do
      begin
        repeat
          LSound := LRandom.Below(KEEN_NUMSOUNDS);
        until not LUsed[LSound];
        LUsed[LSound] := True;
        LSounds[LIndex] := LSound;
        LLength := 1 + LRandom.Below(40);
        LBuilder.Append('D ').Append(LSound).Append(' ').Append(LLength).Append(' ').Append(LRandom.Below(6));
        // the instrument (16 bytes) and the block: the two sustain bytes (6 and 7) are never both 0 (Quit in the C)
        for LByte := 0 to 16 do
        begin
          LValue := LRandom.Below(256);
          if (LByte = 7) and (LValue = 0) then
            LValue := 1;
          LBuilder.Append(' ').Append(LValue);
        end;
        LBuilder.Append(' ').Append(LLength);
        for LByte := 0 to LLength - 1 do
        begin
          // a quarter of the bytes turn the note off
          if LRandom.Below(4) = 0 then
            LValue := 0
          else
            LValue := 1 + LRandom.Below(255);
          LBuilder.Append(' ').Append(LValue);
        end;
        LBuilder.Append(#10);
      end;
      if LRandom.Below(8) <> 0 then
        LBuilder.Append('M 2').Append(#10);
      LOps := 10 + LRandom.Below(15);
      for LIndex := 1 to LOps do
      begin
        case LRandom.Below(16) of
          0:
            LBuilder.Append('M 0').Append(#10);
          1, 2:
            LBuilder.Append('M 2').Append(#10);
          3, 4, 5, 6, 7:
            LBuilder.Append('P ').Append(LSounds[LRandom.Below(LSoundCount)]).Append(#10);
          8, 9, 10, 11, 12:
            LBuilder.Append('T ').Append(1 + LRandom.Below(25)).Append(#10);
          13:
            LBuilder.Append('X').Append(#10);
        else
          LBuilder.Append('Q').Append(#10);
        end;
      end;
      LBuilder.Append('T 45').Append(#10).Append('Q').Append(#10).Append('E').Append(#10);
      Result[LScenario] := LBuilder.ToString;
    finally
      LBuilder.Free;
    end;
  end;
end;

class function TKeenAdLibScenarios.Run(const AScript: string): string;
var
  LLog: TStringBuilder;
  LPort: TLogPort;
  LPortIntf: IKeenAdLibPort;
  LAudio: TScriptAudio;
  LAudioIntf: IKeenChunkSource;
  LManager: IKeenSoundManager;
  LLines: TArray<string>;
  LLine: string;
  LParts: TArray<string>;
  LChunk: TBytes;
  LIndex: Integer;
  LModeResult: Integer;
  LCount: Integer;
  LLength: Cardinal;
  LPriority: Integer;

  procedure NeedManager;
  begin
    if Assigned(LManager) then
      Exit;
    // the harness starts each script with the mode off and nothing in the log
    LPort.Enabled := False;
    LManager := TKeenSoundManager.Create(LAudioIntf, TQuietSpeaker.Create, LPortIntf);
    LManager.TrySetMode(ksmOff);
    LPort.Enabled := True;
  end;

begin
  LLog := TStringBuilder.Create;
  try
    LPort := TLogPort.Create(LLog);
    LPortIntf := LPort;
    LAudio := TScriptAudio.Create;
    LAudioIntf := LAudio;
    LManager := nil;
    LLines := AScript.Split([#10]);
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      LParts := LLine.Split([' ']);
      case LParts[0][1] of
        'S':
          LLog.Append(LLine).Append(#10);
        'D':
          begin
            LLength := Cardinal(StrToInt(LParts[2]));
            LPriority := StrToInt(LParts[3]);
            LCount := StrToInt(LParts[21]);
            SetLength(LChunk, 23 + LCount);
            LChunk[0] := Byte(LLength);
            LChunk[1] := Byte(LLength shr 8);
            LChunk[2] := Byte(LLength shr 16);
            LChunk[3] := Byte(LLength shr 24);
            LChunk[4] := Byte(LPriority);
            LChunk[5] := Byte(LPriority shr 8);
            for LIndex := 0 to 16 do
              LChunk[6 + LIndex] := Byte(StrToInt(LParts[4 + LIndex]));
            for LIndex := 0 to LCount - 1 do
              LChunk[23 + LIndex] := Byte(StrToInt(LParts[22 + LIndex]));
            LAudio.Put(KEEN_STARTADLIBSOUNDS + StrToInt(LParts[1]), Copy(LChunk));
          end;
        'M':
          begin
            NeedManager;
            // the call writes to the same log: it runs first (as the 32 bit compiler did in the chain), then the line
            if StrToInt(LParts[1]) = 2 then
              LModeResult := Ord(LManager.TrySetMode(ksmAdLib))
            else
              LModeResult := Ord(LManager.TrySetMode(ksmOff));
            LLog.Append('m ').Append(LModeResult).Append(#10);
          end;
        'P':
          begin
            NeedManager;
            LLog.Append('p').Append(#10);
            LManager.PlaySound(StrToInt(LParts[1]));
          end;
        'T':
          begin
            NeedManager;
            for LIndex := 1 to StrToInt(LParts[1]) do
            begin
              LLog.Append('t').Append(#10);
              LManager.Service;
            end;
          end;
        'X':
          begin
            NeedManager;
            LLog.Append('x').Append(#10);
            LManager.StopSound;
          end;
        'Q':
          begin
            NeedManager;
            LLog.Append('q ').Append(LManager.SoundPlaying).Append(#10);
          end;
        'E':
          LLog.Append('E').Append(#10);
      end;
    end;
    Result := LLog.ToString;
  finally
    LLog.Free;
  end;
end;

class function TKeenAdLibScenarios.Hash(const AText: string): Cardinal;
var
  LBytes: TBytes;
  LByte: Byte;
begin
  LBytes := TEncoding.ASCII.GetBytes(AText);
  Result := 2166136261;
  for LByte in LBytes do
    Result := (Result xor LByte) * 16777619;
end;

end.
