{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the text of the console                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): Com_Printf and  }
{  Q_CleanStr (q_shared.c). Copyright (C) 1999-2005 Id Software, Inc. This     }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.ConsoleOutput;

interface

uses
  System.SysUtils, DelphiDoom.Q3Host.Intf, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   Com_Printf of the program: what the server, the game, the bots and the console say goes to one writer
  ///   (the standard output, or a list in the tests) without the color codes (^1, ^7 ...) that the in-game console
  ///   would draw in color. It is both the print of the host of the game modules and the log of the console
  /// </summary>
  TQ3ConsoleOutput = class(TInterfacedObject, IQ3HostConsole, IQ3ConsoleLog)
  strict private
    FWriter: TProc<string>;
  public
    constructor Create(const AWriter: TProc<string>);
    /// <summary>Q_CleanStr: the "^x" color escapes are taken out (a caret followed by a caret is not one, a caret at the end stays)</summary>
    class function CleanText(const AText: AnsiString): string; static;
    procedure Print(const AText: AnsiString); overload;
    procedure Print(const AText: string); overload;
    /// <summary>Com_DPrintf: the program runs with developer 0, so nothing is written</summary>
    procedure DevPrint(const AText: string);
  end;

implementation

{ TQ3ConsoleOutput }

constructor TQ3ConsoleOutput.Create(const AWriter: TProc<string>);
begin
  inherited Create;
  FWriter := AWriter;
end;

class function TQ3ConsoleOutput.CleanText(const AText: AnsiString): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    // Q_IsColorString: a caret followed by a character that is not a caret
    if (AText[LIndex] = '^') and (LIndex < Length(AText)) and (AText[LIndex + 1] <> '^') then
      Inc(LIndex, 2)
    else
    begin
      Result := Result + Char(Ord(AText[LIndex]));
      Inc(LIndex);
    end;
  end;
end;

procedure TQ3ConsoleOutput.Print(const AText: AnsiString);
begin
  if Assigned(FWriter) then
    FWriter(CleanText(AText));
end;

procedure TQ3ConsoleOutput.Print(const AText: string);
begin
  Print(AnsiString(AText));
end;

procedure TQ3ConsoleOutput.DevPrint(const AText: string);
begin
end;

end.
