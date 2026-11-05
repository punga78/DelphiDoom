{******************************************************************************}
{                                                                              }
{  DelphiDoom: the operations of the Ogg port behind one interface, for the tests  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Backends;

interface

uses
  System.SysUtils,
  DelphiDoom.Ogg.Types;

type
  /// <summary>The operations of the framing and of the bit packing, as one backend or the other does them</summary>
  TOggBackend = class abstract
  public
    function Name: string; virtual; abstract;

    function StreamInit(const AState: POggStreamState; const ASerial: Integer): Integer; virtual; abstract;
    function StreamClear(const AState: POggStreamState): Integer; virtual; abstract;
    function StreamReset(const AState: POggStreamState): Integer; virtual; abstract;
    function StreamResetSerial(const AState: POggStreamState; const ASerial: Integer): Integer; virtual; abstract;
    function PacketIn(const AState: POggStreamState; const APacket: POggPacket): Integer; virtual; abstract;
    function IoVecIn(const AState: POggStreamState; const AVectors: POggIoVec; const ACount: Integer;
      const AEnd: Longint; const AGranule: Int64): Integer; virtual; abstract;
    function Flush(const AState: POggStreamState; const APage: POggPage): Integer; virtual; abstract;
    function FlushFill(const AState: POggStreamState; const APage: POggPage; const AFill: Integer): Integer; virtual; abstract;
    function PageOut(const AState: POggStreamState; const APage: POggPage): Integer; virtual; abstract;
    function PageOutFill(const AState: POggStreamState; const APage: POggPage; const AFill: Integer): Integer; virtual; abstract;
    function PageIn(const AState: POggStreamState; const APage: POggPage): Integer; virtual; abstract;
    function PacketOut(const AState: POggStreamState; const APacket: POggPacket): Integer; virtual; abstract;
    function PacketPeek(const AState: POggStreamState; const APacket: POggPacket): Integer; virtual; abstract;
    function StreamEnd(const AState: POggStreamState): Integer; virtual; abstract;

    function PageVersion(const APage: POggPage): Integer; virtual; abstract;
    function PageContinued(const APage: POggPage): Integer; virtual; abstract;
    function PageBeginning(const APage: POggPage): Integer; virtual; abstract;
    function PageEnd(const APage: POggPage): Integer; virtual; abstract;
    function PageGranule(const APage: POggPage): Int64; virtual; abstract;
    function PageSerial(const APage: POggPage): Integer; virtual; abstract;
    function PageNumber(const APage: POggPage): Longint; virtual; abstract;
    function PagePackets(const APage: POggPage): Integer; virtual; abstract;
    procedure PageChecksum(const APage: POggPage); virtual; abstract;

    function SyncInit(const AState: POggSyncState): Integer; virtual; abstract;
    function SyncClear(const AState: POggSyncState): Integer; virtual; abstract;
    function SyncReset(const AState: POggSyncState): Integer; virtual; abstract;
    function SyncBuffer(const AState: POggSyncState; const ASize: Longint): PByte; virtual; abstract;
    function SyncWrote(const AState: POggSyncState; const ABytes: Longint): Integer; virtual; abstract;
    function SyncPageSeek(const AState: POggSyncState; const APage: POggPage): Longint; virtual; abstract;
    function SyncPageOut(const AState: POggSyncState; const APage: POggPage): Integer; virtual; abstract;

    procedure PackWriteInit(const ABuffer: POggPackBuffer); virtual; abstract;
    function PackWriteCheck(const ABuffer: POggPackBuffer): Integer; virtual; abstract;
    procedure PackWriteTruncate(const ABuffer: POggPackBuffer; const ABits: Longint); virtual; abstract;
    procedure PackWrite(const ABuffer: POggPackBuffer; const AValue: Cardinal; const ABits: Integer); virtual; abstract;
    procedure PackWriteAlign(const ABuffer: POggPackBuffer); virtual; abstract;
    procedure PackWriteCopy(const ABuffer: POggPackBuffer; const ASource: Pointer; const ABits: Longint); virtual; abstract;
    procedure PackReset(const ABuffer: POggPackBuffer); virtual; abstract;
    procedure PackWriteClear(const ABuffer: POggPackBuffer); virtual; abstract;
    procedure PackReadInit(const ABuffer: POggPackBuffer; const AData: PByte; const ABytes: Integer); virtual; abstract;
    function PackLook(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; virtual; abstract;
    function PackLook1(const ABuffer: POggPackBuffer): Longint; virtual; abstract;
    procedure PackAdvance(const ABuffer: POggPackBuffer; const ABits: Integer); virtual; abstract;
    procedure PackAdvance1(const ABuffer: POggPackBuffer); virtual; abstract;
    function PackRead(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; virtual; abstract;
    function PackRead1(const ABuffer: POggPackBuffer): Longint; virtual; abstract;
    function PackBytes(const ABuffer: POggPackBuffer): Longint; virtual; abstract;
    function PackBits(const ABuffer: POggPackBuffer): Longint; virtual; abstract;
    function PackGetBuffer(const ABuffer: POggPackBuffer): PByte; virtual; abstract;
  end;

  /// <summary>The Pascal port</summary>
  TPascalOggBackend = class(TOggBackend)
  public
    function Name: string; override;
    function StreamInit(const AState: POggStreamState; const ASerial: Integer): Integer; override;
    function StreamClear(const AState: POggStreamState): Integer; override;
    function StreamReset(const AState: POggStreamState): Integer; override;
    function StreamResetSerial(const AState: POggStreamState; const ASerial: Integer): Integer; override;
    function PacketIn(const AState: POggStreamState; const APacket: POggPacket): Integer; override;
    function IoVecIn(const AState: POggStreamState; const AVectors: POggIoVec; const ACount: Integer;
      const AEnd: Longint; const AGranule: Int64): Integer; override;
    function Flush(const AState: POggStreamState; const APage: POggPage): Integer; override;
    function FlushFill(const AState: POggStreamState; const APage: POggPage; const AFill: Integer): Integer; override;
    function PageOut(const AState: POggStreamState; const APage: POggPage): Integer; override;
    function PageOutFill(const AState: POggStreamState; const APage: POggPage; const AFill: Integer): Integer; override;
    function PageIn(const AState: POggStreamState; const APage: POggPage): Integer; override;
    function PacketOut(const AState: POggStreamState; const APacket: POggPacket): Integer; override;
    function PacketPeek(const AState: POggStreamState; const APacket: POggPacket): Integer; override;
    function StreamEnd(const AState: POggStreamState): Integer; override;
    function PageVersion(const APage: POggPage): Integer; override;
    function PageContinued(const APage: POggPage): Integer; override;
    function PageBeginning(const APage: POggPage): Integer; override;
    function PageEnd(const APage: POggPage): Integer; override;
    function PageGranule(const APage: POggPage): Int64; override;
    function PageSerial(const APage: POggPage): Integer; override;
    function PageNumber(const APage: POggPage): Longint; override;
    function PagePackets(const APage: POggPage): Integer; override;
    procedure PageChecksum(const APage: POggPage); override;
    function SyncInit(const AState: POggSyncState): Integer; override;
    function SyncClear(const AState: POggSyncState): Integer; override;
    function SyncReset(const AState: POggSyncState): Integer; override;
    function SyncBuffer(const AState: POggSyncState; const ASize: Longint): PByte; override;
    function SyncWrote(const AState: POggSyncState; const ABytes: Longint): Integer; override;
    function SyncPageSeek(const AState: POggSyncState; const APage: POggPage): Longint; override;
    function SyncPageOut(const AState: POggSyncState; const APage: POggPage): Integer; override;
    procedure PackWriteInit(const ABuffer: POggPackBuffer); override;
    function PackWriteCheck(const ABuffer: POggPackBuffer): Integer; override;
    procedure PackWriteTruncate(const ABuffer: POggPackBuffer; const ABits: Longint); override;
    procedure PackWrite(const ABuffer: POggPackBuffer; const AValue: Cardinal; const ABits: Integer); override;
    procedure PackWriteAlign(const ABuffer: POggPackBuffer); override;
    procedure PackWriteCopy(const ABuffer: POggPackBuffer; const ASource: Pointer; const ABits: Longint); override;
    procedure PackReset(const ABuffer: POggPackBuffer); override;
    procedure PackWriteClear(const ABuffer: POggPackBuffer); override;
    procedure PackReadInit(const ABuffer: POggPackBuffer; const AData: PByte; const ABytes: Integer); override;
    function PackLook(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; override;
    function PackLook1(const ABuffer: POggPackBuffer): Longint; override;
    procedure PackAdvance(const ABuffer: POggPackBuffer; const ABits: Integer); override;
    procedure PackAdvance1(const ABuffer: POggPackBuffer); override;
    function PackRead(const ABuffer: POggPackBuffer; const ABits: Integer): Longint; override;
    function PackRead1(const ABuffer: POggPackBuffer): Longint; override;
    function PackBytes(const ABuffer: POggPackBuffer): Longint; override;
    function PackBits(const ABuffer: POggPackBuffer): Longint; override;
    function PackGetBuffer(const ABuffer: POggPackBuffer): PByte; override;
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker,
  DelphiDoom.Ogg.PageReader,
  DelphiDoom.Ogg.Stream,
  DelphiDoom.Ogg.Sync;

{ TPascalOggBackend }

function TPascalOggBackend.Name: string;
begin
  Result := 'Pascal';
end;

function TPascalOggBackend.StreamInit(const AState: POggStreamState; const ASerial: Integer): Integer;
begin
  Result := TOggStream.Init(AState, ASerial);
end;

function TPascalOggBackend.StreamClear(const AState: POggStreamState): Integer;
begin
  Result := TOggStream.Clear(AState);
end;

function TPascalOggBackend.StreamReset(const AState: POggStreamState): Integer;
begin
  Result := TOggStream.Reset(AState);
end;

function TPascalOggBackend.StreamResetSerial(const AState: POggStreamState; const ASerial: Integer): Integer;
begin
  Result := TOggStream.ResetSerialNumber(AState, ASerial);
end;

function TPascalOggBackend.PacketIn(const AState: POggStreamState; const APacket: POggPacket): Integer;
begin
  Result := TOggStream.PacketIn(AState, APacket);
end;

function TPascalOggBackend.IoVecIn(const AState: POggStreamState; const AVectors: POggIoVec;
  const ACount: Integer; const AEnd: Longint; const AGranule: Int64): Integer;
begin
  Result := TOggStream.IoVecIn(AState, AVectors, ACount, AEnd, AGranule);
end;

function TPascalOggBackend.Flush(const AState: POggStreamState; const APage: POggPage): Integer;
begin
  Result := TOggStream.Flush(AState, APage);
end;

function TPascalOggBackend.FlushFill(const AState: POggStreamState; const APage: POggPage;
  const AFill: Integer): Integer;
begin
  Result := TOggStream.FlushFill(AState, APage, AFill);
end;

function TPascalOggBackend.PageOut(const AState: POggStreamState; const APage: POggPage): Integer;
begin
  Result := TOggStream.PageOut(AState, APage);
end;

function TPascalOggBackend.PageOutFill(const AState: POggStreamState; const APage: POggPage;
  const AFill: Integer): Integer;
begin
  Result := TOggStream.PageOutFill(AState, APage, AFill);
end;

function TPascalOggBackend.PageIn(const AState: POggStreamState; const APage: POggPage): Integer;
begin
  Result := TOggStream.PageIn(AState, APage);
end;

function TPascalOggBackend.PacketOut(const AState: POggStreamState; const APacket: POggPacket): Integer;
begin
  Result := TOggStream.PacketOut(AState, APacket);
end;

function TPascalOggBackend.PacketPeek(const AState: POggStreamState; const APacket: POggPacket): Integer;
begin
  Result := TOggStream.PacketPeek(AState, APacket);
end;

function TPascalOggBackend.StreamEnd(const AState: POggStreamState): Integer;
begin
  Result := TOggStream.EndOfStream(AState);
end;

function TPascalOggBackend.PageVersion(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.Version(APage);
end;

function TPascalOggBackend.PageContinued(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.Continued(APage);
end;

function TPascalOggBackend.PageBeginning(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.BeginningOfStream(APage);
end;

function TPascalOggBackend.PageEnd(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.EndOfStream(APage);
end;

function TPascalOggBackend.PageGranule(const APage: POggPage): Int64;
begin
  Result := TOggPageReader.GranulePosition(APage);
end;

function TPascalOggBackend.PageSerial(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.SerialNumber(APage);
end;

function TPascalOggBackend.PageNumber(const APage: POggPage): Longint;
begin
  Result := TOggPageReader.PageNumber(APage);
end;

function TPascalOggBackend.PagePackets(const APage: POggPage): Integer;
begin
  Result := TOggPageReader.Packets(APage);
end;

procedure TPascalOggBackend.PageChecksum(const APage: POggPage);
begin
  TOggPageReader.SetChecksum(APage);
end;

function TPascalOggBackend.SyncInit(const AState: POggSyncState): Integer;
begin
  Result := TOggSync.Init(AState);
end;

function TPascalOggBackend.SyncClear(const AState: POggSyncState): Integer;
begin
  Result := TOggSync.Clear(AState);
end;

function TPascalOggBackend.SyncReset(const AState: POggSyncState): Integer;
begin
  Result := TOggSync.Reset(AState);
end;

function TPascalOggBackend.SyncBuffer(const AState: POggSyncState; const ASize: Longint): PByte;
begin
  Result := TOggSync.Buffer(AState, ASize);
end;

function TPascalOggBackend.SyncWrote(const AState: POggSyncState; const ABytes: Longint): Integer;
begin
  Result := TOggSync.Wrote(AState, ABytes);
end;

function TPascalOggBackend.SyncPageSeek(const AState: POggSyncState; const APage: POggPage): Longint;
begin
  Result := TOggSync.PageSeek(AState, APage);
end;

function TPascalOggBackend.SyncPageOut(const AState: POggSyncState; const APage: POggPage): Integer;
begin
  Result := TOggSync.PageOut(AState, APage);
end;

procedure TPascalOggBackend.PackWriteInit(const ABuffer: POggPackBuffer);
begin
  TOggBitPacker.WriteInit(ABuffer);
end;

function TPascalOggBackend.PackWriteCheck(const ABuffer: POggPackBuffer): Integer;
begin
  Result := TOggBitPacker.WriteCheck(ABuffer);
end;

procedure TPascalOggBackend.PackWriteTruncate(const ABuffer: POggPackBuffer; const ABits: Longint);
begin
  TOggBitPacker.WriteTruncate(ABuffer, ABits);
end;

procedure TPascalOggBackend.PackWrite(const ABuffer: POggPackBuffer; const AValue: Cardinal;
  const ABits: Integer);
begin
  TOggBitPacker.Write(ABuffer, AValue, ABits);
end;

procedure TPascalOggBackend.PackWriteAlign(const ABuffer: POggPackBuffer);
begin
  TOggBitPacker.WriteAlign(ABuffer);
end;

procedure TPascalOggBackend.PackWriteCopy(const ABuffer: POggPackBuffer; const ASource: Pointer;
  const ABits: Longint);
begin
  TOggBitPacker.WriteCopy(ABuffer, ASource, ABits);
end;

procedure TPascalOggBackend.PackReset(const ABuffer: POggPackBuffer);
begin
  TOggBitPacker.Reset(ABuffer);
end;

procedure TPascalOggBackend.PackWriteClear(const ABuffer: POggPackBuffer);
begin
  TOggBitPacker.WriteClear(ABuffer);
end;

procedure TPascalOggBackend.PackReadInit(const ABuffer: POggPackBuffer; const AData: PByte;
  const ABytes: Integer);
begin
  TOggBitPacker.ReadInit(ABuffer, AData, ABytes);
end;

function TPascalOggBackend.PackLook(const ABuffer: POggPackBuffer; const ABits: Integer): Longint;
begin
  Result := TOggBitPacker.Look(ABuffer, ABits);
end;

function TPascalOggBackend.PackLook1(const ABuffer: POggPackBuffer): Longint;
begin
  Result := TOggBitPacker.Look1(ABuffer);
end;

procedure TPascalOggBackend.PackAdvance(const ABuffer: POggPackBuffer; const ABits: Integer);
begin
  TOggBitPacker.Advance(ABuffer, ABits);
end;

procedure TPascalOggBackend.PackAdvance1(const ABuffer: POggPackBuffer);
begin
  TOggBitPacker.Advance1(ABuffer);
end;

function TPascalOggBackend.PackRead(const ABuffer: POggPackBuffer; const ABits: Integer): Longint;
begin
  Result := TOggBitPacker.Read(ABuffer, ABits);
end;

function TPascalOggBackend.PackRead1(const ABuffer: POggPackBuffer): Longint;
begin
  Result := TOggBitPacker.Read1(ABuffer);
end;

function TPascalOggBackend.PackBytes(const ABuffer: POggPackBuffer): Longint;
begin
  Result := TOggBitPacker.Bytes(ABuffer);
end;

function TPascalOggBackend.PackBits(const ABuffer: POggPackBuffer): Longint;
begin
  Result := TOggBitPacker.Bits(ABuffer);
end;

function TPascalOggBackend.PackGetBuffer(const ABuffer: POggPackBuffer): PByte;
begin
  Result := TOggBitPacker.GetBuffer(ABuffer);
end;

end.
