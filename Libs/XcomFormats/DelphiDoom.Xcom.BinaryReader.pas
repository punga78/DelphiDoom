{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - a sequential reader with the habits of    }
{  the std::ifstream that OpenXcom reads its files with                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.BinaryReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The bytes of a file read one after the other, the way std::ifstream::read does it: a read that finds
  ///   fewer bytes than it asks for COPIES the ones that are there (the rest of the variable is not touched) and
  ///   fails, and after the first failure every read does nothing and fails. The decoders of OpenXcom do not
  ///   check what they read, so a file that ends early gives them "the old value of the variable": the decoders
  ///   of this library keep the same variables to give the same pixels
  /// </summary>
  TXcomBinaryReader = class
  strict private
    FBytes: TBytes;
    FPosition: Integer;
    FFailed: Boolean;
    function GetSize: Integer;
  public
    constructor Create(const ABytes: TBytes);
    /// <summary>Reads a byte; on false AValue is the same as before</summary>
    function ReadByte(var AValue: Byte): Boolean;
    /// <summary>Reads a little endian word; with one byte left only the low byte of AValue changes</summary>
    function ReadWord(var AValue: Word): Boolean;
    /// <summary>Reads ACount bytes; with fewer left only those are copied</summary>
    function ReadBlock(var ABuffer; ACount: Integer): Boolean;
    /// <summary>The next byte without reading it, -1 at the end or after a failure (std::ifstream::peek)</summary>
    function Peek: Integer;
    /// <summary>Moves to a position (seekg); after a failure nothing changes</summary>
    procedure Seek(APosition: Integer);
    property Position: Integer read FPosition;
    property Size: Integer read GetSize;
    /// <summary>True after a read that could not give everything it was asked for</summary>
    property Failed: Boolean read FFailed;
  end;

implementation

{ TXcomBinaryReader }

constructor TXcomBinaryReader.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
end;

function TXcomBinaryReader.GetSize: Integer;
begin
  Result := Length(FBytes);
end;

function TXcomBinaryReader.ReadBlock(var ABuffer; ACount: Integer): Boolean;
var
  LAvailable: Integer;
  LCopied: Integer;
begin
  if FFailed then
    Exit(False);
  LAvailable := Length(FBytes) - FPosition;
  if LAvailable < 0 then
    LAvailable := 0;
  LCopied := ACount;
  if LCopied > LAvailable then
    LCopied := LAvailable;
  if LCopied > 0 then
    Move(FBytes[FPosition], ABuffer, LCopied);
  Inc(FPosition, LCopied);
  Result := LCopied = ACount;
  if not Result then
    FFailed := True;
end;

function TXcomBinaryReader.ReadByte(var AValue: Byte): Boolean;
begin
  Result := ReadBlock(AValue, 1);
end;

function TXcomBinaryReader.ReadWord(var AValue: Word): Boolean;
begin
  // Delphi on x86 and x64 is little endian: the first byte read is the low one, as in the C++ on the same CPUs
  Result := ReadBlock(AValue, 2);
end;

function TXcomBinaryReader.Peek: Integer;
begin
  if FFailed or (FPosition >= Length(FBytes)) then
    Exit(-1);
  Result := FBytes[FPosition];
end;

procedure TXcomBinaryReader.Seek(APosition: Integer);
begin
  if not FFailed then
    FPosition := APosition;
end;

end.
