{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - reader of the demo files of Quake III (.dm_68)    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_main.c       }
{  (CL_ReadDemoMessage) and cl_cgame.c. Copyright (C) 1999-2005 id Software.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.DemoReader;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types;

type
  /// <summary>How the reading of a demo message ended</summary>
  TQ3DemoReadResult = (
    /// <summary>a message was read</summary>
    drMessage,
    /// <summary>the end of the demo: no more data or the length -1 that marks it</summary>
    drEnd,
    /// <summary>the file stops in the middle of a message</summary>
    drTruncated);

  /// <summary>
  ///   The container of a demo: a list of messages, each a 4 byte sequence number (little endian), a 4 byte
  ///   length and that many bytes, ended by the length -1. The bytes are the server message as it came off
  ///   the wire (after the netchan header), for <c>TQ3ServerMessageParser</c>. The stream is not owned.
  ///   A demo is played by the protocol it was recorded with (68 for Quake III and OpenArena 0.8.8, 66 and
  ///   67 for older versions); this reader does not look at the name
  /// </summary>
  TQ3DemoReader = class
  strict private
    FStream: TStream;
    FLog: ILog;
    FMessageCount: Integer;
    function ReadInteger(out AValue: Integer): Boolean;
  public
    /// <summary>The stream is required (EArgumentNilException); ALog gets "Demo file was truncated" (nil = silence)</summary>
    constructor Create(AStream: TStream; const ALog: ILog = nil);
    /// <summary>
    ///   CL_ReadDemoMessage: the next message. A length over MAX_MSGLEN (or below -1) is an
    ///   <c>EQ3DemoException</c>
    /// </summary>
    function ReadMessage(out ASequence: Integer; out AData: TBytes): TQ3DemoReadResult;
    /// <summary>How many messages were read</summary>
    property MessageCount: Integer read FMessageCount;
  end;

implementation

{ TQ3DemoReader }

constructor TQ3DemoReader.Create(AStream: TStream; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
  FLog := ALog;
end;

function TQ3DemoReader.ReadInteger(out AValue: Integer): Boolean;
var
  LBytes: array[0..3] of Byte;
begin
  Result := FStream.Read(LBytes[0], 4) = 4;
  if Result then
    AValue := Integer(Cardinal(LBytes[0]) or (Cardinal(LBytes[1]) shl 8) or (Cardinal(LBytes[2]) shl 16) or
      (Cardinal(LBytes[3]) shl 24))
  else
    AValue := 0;
end;

function TQ3DemoReader.ReadMessage(out ASequence: Integer; out AData: TBytes): TQ3DemoReadResult;
var
  LLength: Integer;
begin
  AData := nil;
  Result := drEnd;
  if not ReadInteger(ASequence) then
    Exit;
  if not ReadInteger(LLength) then
    Exit;
  if LLength = -1 then
    Exit;
  if (LLength < 0) or (LLength > Q3_MAX_MSGLEN) then
    raise EQ3DemoException.Create(SQ3DemoMessageTooLong);
  SetLength(AData, LLength);
  if (LLength > 0) and (FStream.Read(AData[0], LLength) <> LLength) then
  begin
    AData := nil;
    if Assigned(FLog) then
      FLog.Info(SQ3DemoTruncated);
    Result := drTruncated;
    Exit;
  end;
  Inc(FMessageCount);
  Result := drMessage;
end;

end.
