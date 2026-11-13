{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the network options of the command line }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.NetCommandLineReader;

// Port of I_InitNetwork of i_net.pas (issue #185). The sockets are not opened here: they belong
// to the network library. The queries to the command line are the ones of the old code, in the
// same order, because the queried command line remembers which parameters the program asked for.

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>
  ///   Reads -dup, -extratic, -port, -left, -right, -back and -net &lt;consoleplayer&gt; &lt;host&gt;... from
  ///   the command line. It changes nothing in the engine: the caller applies the options
  /// </summary>
  TNetCommandLineReader = class(TInterfacedObject, INetCommandLineReader)
  strict private
    FCommandLine: ICommandLine;
    FLog: ILog;
    function ArgumentAt(AIndex: Integer): string;
    class function FirstCharacter(const AText: string): Integer; static;
    function ReadDrone: TNetDroneView;
    procedure ReadPeers(AIndex: Integer; var AOptions: TNetCommandLineOptions);
  public
    /// <summary>
    ///   ACommandLine answers the questions (the queried one in the engine); ALog gets the lines the
    ///   old code printed; EArgumentNilException if one of them is nil
    /// </summary>
    constructor Create(const ACommandLine: ICommandLine; const ALog: ILog);
    function Read(APreviousPort: Integer): TNetCommandLineOptions;
  end;

implementation

uses
  DelphiDoom.Console.Numbers, DelphiDoom.Net.Types, DelphiDoom.Net.NodeListParser;

{ TNetCommandLineReader }

constructor TNetCommandLineReader.Create(const ACommandLine: ICommandLine; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ACommandLine']);
  if not Assigned(ALog) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ALog']);
  FCommandLine := ACommandLine;
  FLog := ALog;
end;

function TNetCommandLineReader.ArgumentAt(AIndex: Integer): string;
begin
  // the old code read myargv, which is filled with empty strings after the last argument
  if (AIndex >= 0) and (AIndex < FCommandLine.Count) then
    Result := FCommandLine[AIndex]
  else
    Result := '';
end;

class function TNetCommandLineReader.FirstCharacter(const AText: string): Integer;
begin
  // myargv[i][1] of an empty argument is the terminator of the string
  if AText = '' then
    Result := 0
  else
    Result := Ord(AText[1]);
end;

function TNetCommandLineReader.ReadDrone: TNetDroneView;
begin
  if FCommandLine.IndexOf('-left') > 0 then
    Result := ndvLeft
  else if FCommandLine.IndexOf('-right') > 0 then
    Result := ndvRight
  else if FCommandLine.IndexOf('-back') > 0 then
    Result := ndvBack
  else
    Result := ndvNone;
end;

procedure TNetCommandLineReader.ReadPeers(AIndex: Integer; var AOptions: TNetCommandLineOptions);
var
  LArguments: TArray<string>;
  LNode: Integer;
begin
  SetLength(LArguments, FCommandLine.Count);
  for LNode := 0 to FCommandLine.Count - 1 do
    LArguments[LNode] := FCommandLine[LNode];
  AOptions.Peers := TNetNodeListParser.Parse(LArguments, AIndex + 2, Word(AOptions.Port));
  AOptions.NumNodes := 1 + Length(AOptions.Peers);

  for LNode := 0 to Length(AOptions.Peers) - 1 do
    if AOptions.Peers[LNode].IsLiteral then
      FLog.Info(Format('Node number %d address %s'#13#10, [LNode + 1, AOptions.Peers[LNode].Host]))
    else
      FLog.Info(Format('Node number %d hostname %s'#13#10, [LNode + 1, AOptions.Peers[LNode].Host]));
  FLog.Info(Format('Total number of players : %d'#13#10, [AOptions.NumNodes]));
end;

function TNetCommandLineReader.Read(APreviousPort: Integer): TNetCommandLineOptions;
var
  LIndex: Integer;
begin
  Result.Port := APreviousPort;
  Result.Peers := nil;
  Result.ConsolePlayer := 0;
  Result.NumNodes := 1;
  Result.IsNetGame := False;

  // set up for network
  Result.TicDup := 1;
  LIndex := FCommandLine.IndexOf('-dup');
  if (LIndex > 0) and (LIndex < FCommandLine.Count - 1) then
  begin
    Result.TicDup := FirstCharacter(ArgumentAt(LIndex + 1)) - Ord('0');
    if Result.TicDup < 1 then
      Result.TicDup := 1
    else if Result.TicDup > 9 then
      Result.TicDup := 9;
  end;

  if FCommandLine.IndexOf('-extratic') > 0 then
    Result.ExtraTics := 1
  else
    Result.ExtraTics := 0;

  LIndex := FCommandLine.IndexOf('-port');
  if (LIndex > 0) and (LIndex < FCommandLine.Count - 1) then
  begin
    Result.Port := TConsoleNumbers.ParseInteger(ArgumentAt(LIndex + 1));
    FLog.Info(Format('Using Port %d'#13#10, [Result.Port]));
  end;

  Result.Drone := ReadDrone;

  // parse network game options,
  //  -net <consoleplayer> <host> <host> ...
  LIndex := FCommandLine.IndexOf('-net');
  if LIndex = 0 then
    // single player game
    Exit;

  Result.IsNetGame := True;

  // parse player number and host list
  Result.ConsolePlayer := FirstCharacter(ArgumentAt(LIndex + 1)) - Ord('1');
  FLog.Info(Format('console player number: %d'#13#10, [Result.ConsolePlayer]));
  ReadPeers(LIndex, Result);
end;

end.
