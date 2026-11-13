{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - a RoQ file in a stream                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.StreamSource;

interface

uses
  System.Classes,
  DelphiDoom.Cinematic.Intf;

type
  /// <summary>
  ///   A RoQ file read from a stream, from the position it has when the source is made. The
  ///   stream belongs to the caller
  /// </summary>
  TRoqStreamSource = class(TInterfacedObject, IRoqSource)
  strict private
    FStream: TStream;
    FStart: Int64;
    function GetSize: Int64;
    function GetPosition: Int64;
  public
    constructor Create(const AStream: TStream);
    function Read(var ABuffer; ACount: Integer): Integer;
    procedure Seek(APosition: Int64);
  end;

implementation

{ TRoqStreamSource }

constructor TRoqStreamSource.Create(const AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
  FStart := AStream.Position;
end;

function TRoqStreamSource.GetSize: Int64;
begin
  Result := FStream.Size - FStart;
end;

function TRoqStreamSource.GetPosition: Int64;
begin
  Result := FStream.Position - FStart;
end;

function TRoqStreamSource.Read(var ABuffer; ACount: Integer): Integer;
begin
  Result := FStream.Read(ABuffer, ACount);
end;

procedure TRoqStreamSource.Seek(APosition: Int64);
begin
  FStream.Position := FStart + APosition;
end;

end.
