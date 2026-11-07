{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a TDStream of the engine seen as a TStream, to write   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Serializer.Stream;

interface

uses
  System.Classes, d_delphi;

type
  /// <summary>
  ///   Lets the serializer library (which reads and writes System.Classes streams) work on the
  ///   streams of the engine (the memory streams of the save game). The engine stream is not
  ///   owned. (DelphiDoom.Wad.DStreamAdapter is the read only twin, for the WAD library)
  /// </summary>
  TEngineSerializerStream = class(TStream)
  strict private
    FStream: TDStream;
  protected
    function GetSize: Int64; override;
  public
    constructor Create(const AStream: TDStream);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

uses
  System.SysUtils;

{ TEngineSerializerStream }

constructor TEngineSerializerStream.Create(const AStream: TDStream);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
end;

function TEngineSerializerStream.GetSize: Int64;
begin
  Result := FStream.Size;
end;

function TEngineSerializerStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FStream.Read(Buffer, Count);
end;

function TEngineSerializerStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FStream.Write(Buffer, Count);
end;

function TEngineSerializerStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // TStream asks for the position with Seek(0, soCurrent): the engine stream has Position
  if (Origin = soCurrent) and (Offset = 0) then
    Exit(FStream.Position);
  // sFromBeginning, sFromCurrent and sFromEnd have the values of TSeekOrigin
  Result := FStream.Seek(Longint(Offset), Word(Ord(Origin)));
end;

end.
