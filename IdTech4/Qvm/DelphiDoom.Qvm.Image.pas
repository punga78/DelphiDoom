{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - a .qvm file read and validated                    }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of the first half of VM_Create (code/qcommon/vm.c), Quake III Arena    }
{  1.32; the VM_MAGIC_VER2 header is the one of ioquake3                       }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Image;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types;

type
  /// <summary>
  ///   The segments of a .qvm file. The file is not trusted: the header is checked as VM_Create does (magic,
  ///   lengths not negative, some code) and, where the original trusts it, against the size of the file and
  ///   the limits. The data image is data + literals + bss rounded up to a power of two, so that every
  ///   address can be masked
  /// </summary>
  TQvmImage = class
  strict private
    FVersion2: Boolean;
    FInstructionCount: Integer;
    FCode: TBytes;
    FInitialData: TBytes;
    FDataLength: Integer;
    FLitLength: Integer;
    FBssLength: Integer;
    FDataSize: Integer;
    FJumpTargets: TArray<Integer>;
    procedure Parse(const AData: TBytes; const ALimits: TQvmLimits; const AName: string);
  public
    /// <summary>Raises EQvmFormatException when AData is not a file the machine can load</summary>
    /// <param name="AName">Only for the messages</param>
    constructor Create(const AData: TBytes; const ALimits: TQvmLimits; const AName: string);
    /// <summary>The file has the header of ioquake3 (QVM_MAGIC_VER2)</summary>
    property Version2: Boolean read FVersion2;
    property InstructionCount: Integer read FInstructionCount;
    /// <summary>The code segment as it is in the file</summary>
    property Code: TBytes read FCode;
    /// <summary>Data and literals, the part of the image that is not zero at the start</summary>
    property InitialData: TBytes read FInitialData;
    property DataLength: Integer read FDataLength;
    property LitLength: Integer read FLitLength;
    property BssLength: Integer read FBssLength;
    /// <summary>The size of the data image: the power of two that holds data, literals and bss</summary>
    property DataSize: Integer read FDataSize;
    /// <summary>The jump table of a version 2 file, as instruction numbers (not checked here)</summary>
    property JumpTargets: TArray<Integer> read FJumpTargets;
  end;

implementation

const
  MAX_DATA_SIZE = 1 shl 30;
  // the message of the original
  SBadHeader = '%s has bad header';
  STooShort = '%s is too short to be a QVM image (%d bytes)';
  SSegmentOutside = '%s: the %s segment lies outside the file';
  SBadInstructionCount = '%s: %d instructions cannot fit in %d bytes of code';
  SDataTooLarge = '%s: the data image of %d bytes is above the limit of %d';
  SCodeSegment = 'code';
  SDataSegment = 'data';
  SJumpSegment = 'jump table';

{ TQvmImage }

constructor TQvmImage.Create(const AData: TBytes; const ALimits: TQvmLimits; const AName: string);
begin
  inherited Create;
  Parse(AData, ALimits, AName);
end;

procedure TQvmImage.Parse(const AData: TBytes; const ALimits: TQvmLimits; const AName: string);
var
  LHeader: TQvmHeader;
  LFileSize, LInitialSize, LNeeded, LSize: Int64;
  LJumpLength, LIndex: Integer;
begin
  LFileSize := Length(AData);
  if LFileSize < SizeOf(TQvmHeader) then
    raise EQvmFormatException.CreateFmt(STooShort, [AName, LFileSize]);
  Move(AData[0], LHeader, SizeOf(TQvmHeader));

  // validate (the test of VM_Create, plus the second magic)
  if ((LHeader.Magic <> QVM_MAGIC) and (LHeader.Magic <> QVM_MAGIC_VER2)) or (LHeader.BssLength < 0) or
     (LHeader.DataLength < 0) or (LHeader.LitLength < 0) or (LHeader.CodeLength <= 0) then
    raise EQvmFormatException.CreateFmt(SBadHeader, [AName]);

  FVersion2 := LHeader.Magic = QVM_MAGIC_VER2;
  LJumpLength := 0;
  if FVersion2 then
  begin
    if LFileSize < SizeOf(TQvmHeader) + SizeOf(Integer) then
      raise EQvmFormatException.CreateFmt(STooShort, [AName, LFileSize]);
    Move(AData[SizeOf(TQvmHeader)], LJumpLength, SizeOf(Integer));
    if LJumpLength < 0 then
      raise EQvmFormatException.CreateFmt(SBadHeader, [AName]);
  end;

  // the original copies from these offsets without looking at the size of the file
  if (LHeader.CodeOffset < 0) or (Int64(LHeader.CodeOffset) + LHeader.CodeLength > LFileSize) then
    raise EQvmFormatException.CreateFmt(SSegmentOutside, [AName, SCodeSegment]);
  LInitialSize := Int64(LHeader.DataLength) + LHeader.LitLength;
  if (LHeader.DataOffset < 0) or (LHeader.DataOffset + LInitialSize > LFileSize) then
    raise EQvmFormatException.CreateFmt(SSegmentOutside, [AName, SDataSegment]);
  if LHeader.DataOffset + LInitialSize + LJumpLength > LFileSize then
    raise EQvmFormatException.CreateFmt(SSegmentOutside, [AName, SJumpSegment]);
  // every instruction is at least one byte
  if (LHeader.InstructionCount <= 0) or (LHeader.InstructionCount > LHeader.CodeLength) then
    raise EQvmFormatException.CreateFmt(SBadInstructionCount,
      [AName, LHeader.InstructionCount, LHeader.CodeLength]);

  // round up to next power of 2 so all data operations can be mask protected
  LNeeded := LInitialSize + LHeader.BssLength;
  if LNeeded > ALimits.MaxDataSize then
    raise EQvmFormatException.CreateFmt(SDataTooLarge, [AName, LNeeded, ALimits.MaxDataSize]);
  LSize := 1;
  while LNeeded > LSize do
    LSize := LSize shl 1;
  // an address is a positive 32 bit integer
  if (LSize > ALimits.MaxDataSize) or (LSize > MAX_DATA_SIZE) then
    raise EQvmFormatException.CreateFmt(SDataTooLarge, [AName, LSize, ALimits.MaxDataSize]);
  FDataSize := Integer(LSize);

  FInstructionCount := LHeader.InstructionCount;
  FDataLength := LHeader.DataLength;
  FLitLength := LHeader.LitLength;
  FBssLength := LHeader.BssLength;
  FCode := Copy(AData, LHeader.CodeOffset, LHeader.CodeLength);
  FInitialData := Copy(AData, LHeader.DataOffset, Integer(LInitialSize));
  SetLength(FJumpTargets, LJumpLength div SizeOf(Integer));
  for LIndex := 0 to High(FJumpTargets) do
    Move(AData[LHeader.DataOffset + LInitialSize + Int64(LIndex) * SizeOf(Integer)], FJumpTargets[LIndex],
      SizeOf(Integer));
end;

end.
