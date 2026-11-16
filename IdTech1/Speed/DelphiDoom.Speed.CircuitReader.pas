{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedCircuitReader                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the reading of CIRCUITS.LST in GenerateLevels (speed_xlat_wad.pas)  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.CircuitReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Reads CIRCUITS.LST: the number of circuits and then, for each, the words Circuit, Name,
  ///   Number, Level, Length, Best, Record (two numbers) and NBack with their values. The words that
  ///   name a field are skipped without being looked at, as the old reader did
  /// </summary>
  TSpeedCircuitReader = class(TInterfacedObject, ISpeedCircuitReader)
  strict private
    FLog: ILog;
  public
    /// <param name="ALog">Receives the warnings of the scanner; EArgumentNilException when nil</param>
    constructor Create(const ALog: ILog);
    function Parse(const AText: string): TArray<TSpeedCircuit>;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner;

const
  /// <summary>The name of a circuit was a string[64]</summary>
  MAX_NAME_LENGTH = 64;

{ TSpeedCircuitReader }

constructor TSpeedCircuitReader.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TSpeedCircuitReader.Parse(const AText: string): TArray<TSpeedCircuit>;
var
  LScanner: TScriptScanner;
  LCount: Integer;
  LIndex: Integer;
  LCircuit: TSpeedCircuit;

  function ReadInteger(var AValue: Integer): Boolean;
  begin
    Result := LScanner.GetInteger;
    if Result then
      AValue := LScanner.AsInteger;
  end;

begin
  SetLength(Result, SPEED_MAX_CIRCUITS);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Default(TSpeedCircuit);
  if AText = '' then
    Exit;
  LScanner := TScriptScanner.Create(AText, FLog);
  try
    if not LScanner.MustGetInteger then
      Exit;
    LCount := LScanner.AsInteger;
    for LIndex := 0 to LCount - 1 do
    begin
      if LIndex = SPEED_MAX_CIRCUITS then
        Break;
      LCircuit := Default(TSpeedCircuit);
      LScanner.GetString; // Circuit
      LScanner.GetString; // Name
      if LScanner.GetString then
        LCircuit.Name := Copy(LScanner.AsString, 1, MAX_NAME_LENGTH);
      LScanner.GetString; // Number
      ReadInteger(LCircuit.Number);
      LScanner.GetString; // Level
      ReadInteger(LCircuit.Level);
      LScanner.GetString; // Length
      ReadInteger(LCircuit.Length);
      LScanner.GetString; // Best
      ReadInteger(LCircuit.Best);
      LScanner.GetString; // Record
      ReadInteger(LCircuit.FirstRecord);
      ReadInteger(LCircuit.SecondRecord);
      LScanner.GetString; // NBack
      ReadInteger(LCircuit.Background);
      Result[LIndex] := LCircuit;
    end;
  finally
    LScanner.Free;
  end;
end;

end.
