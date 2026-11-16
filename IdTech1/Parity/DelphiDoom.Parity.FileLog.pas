{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - a log in a text file                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.FileLog;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Parity.Intf;

type
  /// <summary>
  ///   IParityLog on a file of ASCII text, one line ends with a line feed (never a carriage return: the
  ///   same bytes on every machine). The lines are kept in a buffer and written when it is full, on
  ///   Flush and when the log is freed
  /// </summary>
  TParityFileLog = class(TInterfacedObject, IParityLog)
  strict private
    FStream: TFileStream;
    FBuffer: TBytes;
    FBufferCount: Integer;
    procedure WriteBuffer;
  public
    /// <summary>Creates the file (an existing one is overwritten); EParityException if it cannot be created</summary>
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure WriteLine(const ALine: string);
    procedure Flush;
  end;

implementation

uses
  DelphiDoom.Parity.Types;

const
  BUFFER_SIZE = 64 * 1024;
  SCannotCreate = 'Cannot create the log file %s';

{ TParityFileLog }

constructor TParityFileLog.Create(const AFileName: string);
begin
  inherited Create;
  try
    FStream := TFileStream.Create(AFileName, fmCreate or fmShareDenyWrite);
  except
    on E: EFCreateError do
      raise EParityException.CreateFmt(SCannotCreate, [AFileName]);
  end;
  SetLength(FBuffer, BUFFER_SIZE);
end;

destructor TParityFileLog.Destroy;
begin
  if Assigned(FStream) then
  begin
    WriteBuffer;
    FStream.Free;
  end;
  inherited Destroy;
end;

procedure TParityFileLog.WriteBuffer;
begin
  if FBufferCount > 0 then
  begin
    FStream.WriteBuffer(FBuffer[0], FBufferCount);
    FBufferCount := 0;
  end;
end;

procedure TParityFileLog.WriteLine(const ALine: string);
var
  LIndex: Integer;
begin
  if FBufferCount + Length(ALine) + 1 > Length(FBuffer) then
    WriteBuffer;
  if Length(ALine) + 1 > Length(FBuffer) then
    SetLength(FBuffer, Length(ALine) + 1);
  for LIndex := 1 to Length(ALine) do
  begin
    FBuffer[FBufferCount] := Byte(Ord(ALine[LIndex]) and $FF);
    Inc(FBufferCount);
  end;
  FBuffer[FBufferCount] := 10;
  Inc(FBufferCount);
end;

procedure TParityFileLog.Flush;
begin
  WriteBuffer;
end;

end.
