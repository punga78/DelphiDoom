{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiSaveWriter and TGuiSaveReader                     }
{                                                                              }
{  The files of the save game of the guis (idFile in WriteToSaveGame and ReadFromSaveGame)}
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.SaveStream;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>A save file that is damaged: it ends early, a length is negative or too big</summary>
  EGuiSaveException = class(Exception);

  /// <summary>
  ///   The writing side of the save game of the guis (idFile::Write of integers, floats and strings): little
  ///   endian, a string is its length as a 4 byte integer and its bytes.
  /// </summary>
  TGuiSaveWriter = class
  strict private
    FStream: TStream;
  public
    constructor Create(const AStream: TStream);
    procedure WriteInt(const AValue: Integer);
    procedure WriteFloat(const AValue: Single);
    procedure WriteBool(const AValue: Boolean);
    procedure WriteString(const AValue: AnsiString);
  end;

  /// <summary>
  ///   The reading side. Input is not trusted: a read past the end, a length below zero or over <c>MaxStringLength</c>
  ///   raise <c>EGuiSaveException</c> (the original warns about a negative length and goes on to read through it).
  /// </summary>
  TGuiSaveReader = class
  strict private
    FStream: TStream;
  public
    const MaxStringLength = 1 shl 24;
    constructor Create(const AStream: TStream);
    function ReadInt: Integer;
    function ReadFloat: Single;
    function ReadBool: Boolean;
    function ReadString: AnsiString;
  end;

implementation

constructor TGuiSaveWriter.Create(const AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
end;

procedure TGuiSaveWriter.WriteInt(const AValue: Integer);
begin
  FStream.WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TGuiSaveWriter.WriteFloat(const AValue: Single);
begin
  FStream.WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TGuiSaveWriter.WriteBool(const AValue: Boolean);
var
  LByte: Byte;
begin
  LByte := Ord(AValue);
  FStream.WriteBuffer(LByte, SizeOf(LByte));
end;

procedure TGuiSaveWriter.WriteString(const AValue: AnsiString);
begin
  WriteInt(Length(AValue));
  if Length(AValue) > 0 then
    FStream.WriteBuffer(AValue[1], Length(AValue));
end;

constructor TGuiSaveReader.Create(const AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
end;

function TGuiSaveReader.ReadInt: Integer;
begin
  if FStream.Read(Result, SizeOf(Result)) <> SizeOf(Result) then
    raise EGuiSaveException.Create('the save game ends inside an integer');
end;

function TGuiSaveReader.ReadFloat: Single;
begin
  if FStream.Read(Result, SizeOf(Result)) <> SizeOf(Result) then
    raise EGuiSaveException.Create('the save game ends inside a float');
end;

function TGuiSaveReader.ReadBool: Boolean;
var
  LByte: Byte;
begin
  if FStream.Read(LByte, SizeOf(LByte)) <> SizeOf(LByte) then
    raise EGuiSaveException.Create('the save game ends inside a boolean');
  Result := LByte <> 0;
end;

function TGuiSaveReader.ReadString: AnsiString;
var
  LLength: Integer;
begin
  LLength := ReadInt;
  if (LLength < 0) or (LLength > MaxStringLength) or (FStream.Size - FStream.Position < LLength) then
    raise EGuiSaveException.CreateFmt('the save game has a string of %d bytes', [LLength]);
  SetLength(Result, LLength);
  if LLength > 0 then
    FStream.ReadBuffer(Result[1], LLength);
end;

end.