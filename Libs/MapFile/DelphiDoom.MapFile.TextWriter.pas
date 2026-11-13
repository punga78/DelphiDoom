{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the output buffer of the writers             }
{                                                                              }
{  Port of the formatting of idFile::WriteFloatString (File.cpp, framework),   }
{  Doom 3 GPL Source Code. Based on the Doom 3 GPL Source Code (id Software).  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.TextWriter;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Collects the 8-bit text of a file. A float is written as WriteFloatString writes the
  ///   format "%f": ten decimals, then the trailing zeros and the dot taken off (0.5 gives
  ///   "0.5", 2 gives "2", the float 0.1 gives "0.1000000015")
  /// </summary>
  TMapTextWriter = class
  strict private
    FBuffer: TMemoryStream;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AText: AnsiString);
    procedure AddFloat(const AValue: Single);
    procedure AddInteger(const AValue: Integer);
    /// <summary>The text written so far</summary>
    function GetText: AnsiString;
    function GetBytes: TBytes;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TMapTextWriter }

constructor TMapTextWriter.Create;
begin
  inherited Create;
  FBuffer := TMemoryStream.Create;
end;

destructor TMapTextWriter.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TMapTextWriter.Add(const AText: AnsiString);
begin
  if Length(AText) > 0 then
    FBuffer.WriteBuffer(AText[1], Length(AText));
end;

procedure TMapTextWriter.AddFloat(const AValue: Single);
begin
  Add(TIdStrings.FloatArrayToString([AValue], 10));
end;

procedure TMapTextWriter.AddInteger(const AValue: Integer);
begin
  Add(AnsiString(IntToStr(AValue)));
end;

function TMapTextWriter.GetText: AnsiString;
begin
  SetLength(Result, FBuffer.Size);
  if FBuffer.Size > 0 then
    Move(FBuffer.Memory^, Result[1], FBuffer.Size);
end;

function TMapTextWriter.GetBytes: TBytes;
begin
  SetLength(Result, FBuffer.Size);
  if FBuffer.Size > 0 then
    Move(FBuffer.Memory^, Result[0], FBuffer.Size);
end;

end.
