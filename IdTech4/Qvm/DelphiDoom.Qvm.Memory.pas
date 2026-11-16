{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the data image of a machine                       }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of the data part of VM_Create and VM_Restart, of VM_ArgPtr and of the  }
{  block copy of VM_CallInterpreted (code/qcommon/vm.c, vm_interpreted.c),     }
{  Quake III Arena 1.32                                                        }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Memory;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Image;

type
  /// <summary>How a block copy ended</summary>
  TQvmBlockCopyResult = (Copied, NotAligned, OutOfRange);

  /// <summary>
  ///   The memory of the program: data, literals and bss in a buffer whose size is a power of two, followed
  ///   by QVM_DATA_PADDING zero bytes that nothing writes. The interpreter works on <c>Base</c> with the
  ///   mask; everything else goes through the checked methods, which never leave the image
  /// </summary>
  TQvmMemory = class
  strict private
    FBuffer: TBytes;
    FSize: Integer;
    FMask: Integer;
    function GetBase: PByte; inline;
    procedure RaiseOutOfRange(AAddress: Integer; ALength: NativeInt);
  public
    constructor Create(const AImage: TQvmImage);
    /// <summary>Zero everywhere, then data and literals of the image (which must have the same data size)</summary>
    procedure Load(const AImage: TQvmImage);
    /// <summary>VM_ArgPtr with the range checked: nil for 0</summary>
    function ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
    /// <summary>The masked address as a pointer good for ALength bytes; raises EQvmExecutionException</summary>
    function Range(AAddress: Integer; ALength: NativeInt): Pointer;
    function ReadByte(AAddress: Integer): Byte;
    procedure WriteByte(AAddress: Integer; AValue: Byte);
    function ReadInt32(AAddress: Integer): Integer;
    procedure WriteInt32(AAddress: Integer; AValue: Integer);
    function ReadString(AAddress: Integer): AnsiString;
    procedure WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
    function ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
    procedure WriteBytes(AAddress: Integer; const ABytes: TBytes);
    procedure Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
    procedure Copy(ADestination, ASource: Integer; ALength: NativeInt);
    /// <summary>
    ///   OP_BLOCK_COPY with the range check of the original ("MrE: copy range check"): the count is cut
    ///   where source or destination would wrap, and the integers are copied from the last to the first.
    ///   The check of the original lets a negative count become a huge one that leaves the image: that is
    ///   OutOfRange here, and nothing is copied
    /// </summary>
    function BlockCopy(ADestination, ASource, ACount: Integer): TQvmBlockCopyResult;
    /// <summary>The first byte of the image; valid as long as the object lives</summary>
    property Base: PByte read GetBase;
    property Size: Integer read FSize;
    property Mask: Integer read FMask;
  end;

implementation

{$POINTERMATH ON}
// the count of a block copy wraps as the int of the original
{$Q-}
{$R-}

const
  SOutOfRange = 'QVM memory access out of range: %d bytes at %d (image of %d)';
  SNoTerminator = 'QVM string at %d has no end inside the image';
  SDifferentSize = 'The data image changed size: %d, it was %d';

{ TQvmMemory }

constructor TQvmMemory.Create(const AImage: TQvmImage);
begin
  inherited Create;
  FSize := AImage.DataSize;
  FMask := FSize - 1;
  SetLength(FBuffer, FSize + QVM_DATA_PADDING);
  Load(AImage);
end;

function TQvmMemory.GetBase: PByte;
begin
  Result := PByte(FBuffer);
end;

procedure TQvmMemory.Load(const AImage: TQvmImage);
begin
  if AImage.DataSize <> FSize then
    raise EQvmFormatException.CreateFmt(SDifferentSize, [AImage.DataSize, FSize]);
  // clear the data
  FillChar(FBuffer[0], FSize, 0);
  // copy the intialized data
  if Length(AImage.InitialData) > 0 then
    Move(AImage.InitialData[0], FBuffer[0], Length(AImage.InitialData));
end;

procedure TQvmMemory.RaiseOutOfRange(AAddress: Integer; ALength: NativeInt);
begin
  raise EQvmExecutionException.CreateFmt(SOutOfRange, [Int64(ALength), AAddress, FSize]);
end;

function TQvmMemory.Range(AAddress: Integer; ALength: NativeInt): Pointer;
var
  LMasked: Integer;
begin
  LMasked := AAddress and FMask;
  if (ALength < 0) or (ALength > FSize - LMasked) then
    RaiseOutOfRange(AAddress, ALength);
  Result := GetBase + LMasked;
end;

function TQvmMemory.ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
begin
  if AAddress = 0 then
    Result := nil
  else
    Result := Range(AAddress, ALength);
end;

function TQvmMemory.ReadByte(AAddress: Integer): Byte;
begin
  Result := PByte(Range(AAddress, 1))^;
end;

procedure TQvmMemory.WriteByte(AAddress: Integer; AValue: Byte);
begin
  PByte(Range(AAddress, 1))^ := AValue;
end;

function TQvmMemory.ReadInt32(AAddress: Integer): Integer;
begin
  Result := PInteger(Range(AAddress, SizeOf(Integer)))^;
end;

procedure TQvmMemory.WriteInt32(AAddress: Integer; AValue: Integer);
begin
  PInteger(Range(AAddress, SizeOf(Integer)))^ := AValue;
end;

function TQvmMemory.ReadString(AAddress: Integer): AnsiString;
var
  LStart, LEnd: Integer;
begin
  LStart := AAddress and FMask;
  LEnd := LStart;
  while (LEnd < FSize) and (FBuffer[LEnd] <> 0) do
    Inc(LEnd);
  if LEnd >= FSize then
    raise EQvmExecutionException.CreateFmt(SNoTerminator, [AAddress]);
  SetString(Result, PAnsiChar(@FBuffer[LStart]), LEnd - LStart);
end;

procedure TQvmMemory.WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
var
  LTarget: PByte;
  LLength: Integer;
begin
  if ABufferSize < 1 then
    Exit;
  LLength := Length(AText);
  if LLength > ABufferSize - 1 then
    LLength := ABufferSize - 1;
  // strncpy fills what is left of the buffer with zeroes: the whole buffer must be in the image
  LTarget := Range(AAddress, ABufferSize);
  if LLength > 0 then
    Move(AText[1], LTarget^, LLength);
  FillChar(LTarget[LLength], ABufferSize - LLength, 0);
end;

function TQvmMemory.ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
var
  LSource: PByte;
begin
  LSource := Range(AAddress, ALength);
  SetLength(Result, ALength);
  if ALength > 0 then
    Move(LSource^, Result[0], ALength);
end;

procedure TQvmMemory.WriteBytes(AAddress: Integer; const ABytes: TBytes);
var
  LTarget: PByte;
begin
  LTarget := Range(AAddress, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], LTarget^, Length(ABytes));
end;

procedure TQvmMemory.Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
begin
  FillChar(Range(AAddress, ALength)^, ALength, AValue);
end;

procedure TQvmMemory.Copy(ADestination, ASource: Integer; ALength: NativeInt);
var
  LSource, LTarget: PByte;
begin
  LSource := Range(ASource, ALength);
  LTarget := Range(ADestination, ALength);
  Move(LSource^, LTarget^, ALength);
end;

function TQvmMemory.BlockCopy(ADestination, ASource, ACount: Integer): TQvmBlockCopyResult;
var
  LSource, LTarget: PInteger;
  LSourceIndex, LTargetIndex, LCount, LIndex: Integer;
begin
  // MrE: copy range check
  LSourceIndex := ASource and FMask;
  LTargetIndex := ADestination and FMask;
  LCount := ((LSourceIndex + ACount) and FMask) - LSourceIndex;
  LCount := ((LTargetIndex + LCount) and FMask) - LTargetIndex;
  if ((LSourceIndex or LTargetIndex or LCount) and 3) <> 0 then
    Exit(TQvmBlockCopyResult.NotAligned);
  if LCount <= 0 then
    Exit(TQvmBlockCopyResult.Copied);
  if (LCount > FSize - LSourceIndex) or (LCount > FSize - LTargetIndex) then
    Exit(TQvmBlockCopyResult.OutOfRange);
  LSource := PInteger(GetBase + LSourceIndex);
  LTarget := PInteger(GetBase + LTargetIndex);
  for LIndex := (LCount shr 2) - 1 downto 0 do
    LTarget[LIndex] := LSource[LIndex];
  Result := TQvmBlockCopyResult.Copied;
end;

end.
