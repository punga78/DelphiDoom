{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_delphi for the per-game OpenGL scene tests        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Common\d_delphi.pas in DelphiDoom.Tests.OpenGl.<Game> only: the scene units take
// from it the type float, the allocation helpers of the light buffer, the list of pairs, the string list
// of the extensions and printf (which here writes a line in EventLog, the list the test reads, if it is
// assigned).
unit d_delphi;

interface

uses
  System.Classes;

type
  float = Single;
  Pfloat = ^float;

  twointeger_t = record
    num1, num2: integer;
  end;

  /// <summary>The list of pairs of d_delphi (only what the scene units use: Add, Count, Numbers)</summary>
  T2DNumberList = class
  strict private
    FItems: array of twointeger_t;
    function Get(Index: Integer): twointeger_t;
  public
    function Add(const value1, value2: integer): integer;
    function Count: integer;
    property Numbers[Index: Integer]: twointeger_t read Get; default;
  end;

  /// <summary>The string list of d_delphi (a plain TStringList here: Text, IndexOf, count, strings)</summary>
  TDStringList = class(TStringList);

var
  /// <summary>Where printf writes (one line per call, the line breaks of the text shown as "|"); nil = nowhere</summary>
  EventLog: TStringList = nil;

/// <summary>The realloc of d_delphi</summary>
procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);

/// <summary>Writes a line in EventLog (the shims of the units that the scene calls use it to be seen)</summary>
procedure ShimEvent(const AText: string);

procedure printf(const str: string); overload;
procedure printf(const Fmt: string; const Args: array of const); overload;
function strupper(const S: string): string;
function tan(const x: extended): extended;
function StringVal(const Str: PAnsiChar): string;

implementation

uses
  System.Math,
  System.SysUtils;

function T2DNumberList.Get(Index: Integer): twointeger_t;
begin
  Result := FItems[Index];
end;

function T2DNumberList.Add(const value1, value2: integer): integer;
begin
  Result := Length(FItems);
  SetLength(FItems, Result + 1);
  FItems[Result].num1 := value1;
  FItems[Result].num2 := value2;
end;

function T2DNumberList.Count: integer;
begin
  Result := Length(FItems);
end;

procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);
begin
  if NewSize = 0 then
  begin
    FreeMem(P, OldSize);
    P := nil;
  end
  else if NewSize <> OldSize then
    ReallocMem(P, NewSize);
end;

procedure ShimEvent(const AText: string);
begin
  if Assigned(EventLog) then
    EventLog.Add(AText);
end;

procedure printf(const str: string);
begin
  if Assigned(EventLog) then
    EventLog.Add('printf ' + StringReplace(str, #13#10, '|', [rfReplaceAll]));
end;

procedure printf(const Fmt: string; const Args: array of const);
begin
  printf(Format(Fmt, Args));
end;

function tan(const x: extended): extended;
begin
  Result := System.Math.Tan(x);
end;

function strupper(const S: string): string;
begin
  Result := UpperCase(S);
end;

function StringVal(const Str: PAnsiChar): string;
begin
  Result := string(AnsiString(Str));
end;

end.
