{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - one cheat                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CheatSequence;

interface

uses
  DelphiDoom.Console.Types;

type
  /// <summary>
  ///   The keys of a cheat and how far the player went (old cheatseq_t and cht_CheckCheat).
  ///   The sequence is a string of scrambled bytes. Two bytes have a meaning: 1 means "the next
  ///   keys are a parameter" and 0 is the place where a key of the parameter goes. After
  ///   the cheat is acquired the keys of the parameter stay available in Param
  /// </summary>
  TCheatSequence = class
  private
    FSequence: AnsiString;
    FProgress: AnsiString;
    function GetParam: string;
  public
    /// <summary>ASequence is not empty and has no end mark: see TCheatSequenceReader</summary>
    constructor Create(const ASequence: AnsiString);
    /// <summary>
    ///   Gives the key to the cheat. AKey is the key of the game (a letter): a value that is not a
    ///   byte can not be part of a cheat and is read as the byte $FF
    /// </summary>
    function Check(AKey: Integer): TCheatStatus;
    /// <summary>Starts again from the first key</summary>
    procedure Reset;
    /// <summary>
    ///   One character for every byte that was left by the last check (the parameter of the cheat),
    ///   with the code of the byte (the old code converted with the code page: the same up to $7F)
    /// </summary>
    property Param: string read GetParam;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.CheatScrambler;

const
  PARAMETER_MARK = #1;
  PARAMETER_PLACE = #0;
  END_MARK = #$FF;

{ TCheatSequence }

constructor TCheatSequence.Create(const ASequence: AnsiString);
begin
  inherited Create;
  if ASequence = '' then
    raise EConsoleException.Create('A cheat needs at least one key');
  FSequence := ASequence;
  FProgress := '';
end;

procedure TCheatSequence.Reset;
begin
  FProgress := '';
end;

function TCheatSequence.GetParam: string;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(FProgress));
  for LIndex := 1 to Length(FProgress) do
    Result[LIndex] := Char(Ord(FProgress[LIndex]));
end;

function TCheatSequence.Check(AKey: Integer): TCheatStatus;
var
  LKey: Byte;
begin
  if (AKey < 0) or (AKey > 255) then
    LKey := $FF
  else
    LKey := Byte(AKey);

  Result := csUnknown;
  if FProgress = '' then
    FProgress := FSequence;

  if FProgress[1] = PARAMETER_PLACE then
    FProgress[1] := AnsiChar(LKey)
  else if (Length(FProgress) > 1) and (FProgress[2] = PARAMETER_PLACE) then
  begin
    FProgress[2] := AnsiChar(LKey);
    Result := csAcquired;
  end
  else if AnsiChar(TCheatScrambler.Scramble(LKey)) = FProgress[1] then
  begin
    Result := csPending;
    Delete(FProgress, 1, 1);
  end
  else
    FProgress := FSequence;

  if Length(FProgress) > 0 then
  begin
    if FProgress[1] = PARAMETER_MARK then
      Delete(FProgress, 1, 1)
    else if FProgress[1] = END_MARK then
    begin
      FProgress := FSequence;
      Result := csAcquired;
    end;
  end
  else
    Result := csAcquired;
end;

end.
