{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD - a TDStream of the engine seen as a TStream                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.DStreamAdapter;

interface

uses
  System.SysUtils, System.Classes, d_delphi;

type
  /// <summary>
  ///   Lets the WAD library (which reads System.Classes streams) read through the
  ///   streams of the engine: cached files and PAK entries. Read only; the
  ///   engine stream is not owned and is not closed with the adapter
  /// </summary>
  TDStreamAdapter = class(TStream)
  private
    FStream: TDStream;
  protected
    function GetSize: Int64; override;
  public
    constructor Create(AStream: TDStream);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

const
  SReadOnly = 'The stream of the engine is read only';

{ TDStreamAdapter }

constructor TDStreamAdapter.Create(AStream: TDStream);
begin
  inherited Create;
  FStream := AStream;
end;

function TDStreamAdapter.GetSize: Int64;
begin
  Result := FStream.Size;
end;

function TDStreamAdapter.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FStream.Read(Buffer, Count);
end;

function TDStreamAdapter.Write(const Buffer; Count: Longint): Longint;
begin
  raise EStreamError.Create(SReadOnly);
end;

function TDStreamAdapter.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // sFromBeginning, sFromCurrent and sFromEnd have the values of TSeekOrigin
  Result := FStream.Seek(Longint(Offset), Word(Ord(Origin)));
end;

end.
