{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - a small assembler of .qvm images     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Assembler;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Builds a .qvm file in memory, instruction by instruction: the programs of the tests are made here,
  ///   no file of a game is needed. A label is the number of an instruction (what OP_JUMP, OP_CALL and the
  ///   branches take), known when the image is written. Data are 32 bit words; the literals follow them.
  ///   It writes what it is told: wrong programs (for the tests of the checks) are made with Raw, with a
  ///   forced instruction count and by patching the bytes of the result
  /// </summary>
  TQvmAssembler = class
  strict private
    type
      TFixup = record
        Offset: Integer;
        LabelId: Integer;
        InData: Boolean;
      end;
    var
      FCode: TBytes;
      FData: TBytes;
      FLit: TBytes;
      FBss: Integer;
      FInstructions: Integer;
      FLabels: TArray<Integer>;
      FFixups: TArray<TFixup>;
      FForcedCount: Integer;
      FJumpTargets: TArray<Integer>;
    procedure AppendCode(AValue: Byte);
    procedure AppendCodeInt(AValue: Integer);
  public
    constructor Create;
    /// <summary>An instruction without operand</summary>
    procedure Op(AOpcode: Integer); overload;
    /// <summary>An instruction with its operand: four bytes, one for OP_ARG</summary>
    procedure Op(AOpcode, AOperand: Integer); overload;
    /// <summary>OP_CONST of a float</summary>
    procedure ConstFloat(AValue: Single);
    /// <summary>The number of the next instruction</summary>
    function Here: Integer;
    function NewLabel: Integer;
    /// <summary>The label is the next instruction</summary>
    procedure Mark(ALabel: Integer);
    /// <summary>A label that is the next instruction</summary>
    function MarkNew: Integer;
    /// <summary>A conditional branch to a label</summary>
    procedure Branch(AOpcode, ALabel: Integer);
    /// <summary>OP_CONST of the instruction number of a label (for OP_JUMP and OP_CALL)</summary>
    procedure ConstLabel(ALabel: Integer);
    /// <summary>OP_CONST label, OP_JUMP</summary>
    procedure Jump(ALabel: Integer);
    /// <summary>OP_CONST label, OP_CALL</summary>
    procedure CallLabel(ALabel: Integer);
    /// <summary>OP_CONST -(number + 1), OP_CALL</summary>
    procedure SystemCall(ANumber: Integer);
    /// <summary>OP_LOCAL offset, OP_LOAD4</summary>
    procedure LoadLocal(AOffset: Integer);
    /// <summary>A byte of code that is not counted as an instruction</summary>
    procedure Raw(AValue: Byte);
    /// <summary>Words of data; returns the address of the first</summary>
    function Data(const AValues: array of Integer): Integer;
    /// <summary>A word of data that is the instruction number of a label (a jump table)</summary>
    function DataLabel(ALabel: Integer): Integer;
    /// <summary>A zero terminated text in the data segment, padded to four bytes; returns its address</summary>
    function DataText(const AText: AnsiString): Integer;
    /// <summary>Bytes of the literal segment; returns the offset in the segment (the address is DataLength + offset)</summary>
    function Lit(const AText: AnsiString): Integer;
    function DataLength: Integer;
    /// <summary>The bss is made as large as needed for the data image to be ATotal bytes</summary>
    procedure ImageSize(ATotal: Integer);
    procedure Bss(ASize: Integer);
    /// <summary>The header will say this count instead of the real one</summary>
    procedure ForceInstructionCount(ACount: Integer);
    /// <summary>The jump table of a version 2 file</summary>
    procedure JumpTargets(const AValues: array of Integer);
    /// <summary>The file: header, code (padded to four bytes), data, literals, and the jump table of version 2</summary>
    function ToBytes(AVersion2: Boolean = False): TBytes;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Opcodes;

const
  SUnmarkedLabel = 'Label %d was never marked';

{ TQvmAssembler }

constructor TQvmAssembler.Create;
begin
  inherited Create;
  FForcedCount := -1;
end;

procedure TQvmAssembler.AppendCode(AValue: Byte);
begin
  FCode := FCode + [AValue];
end;

procedure TQvmAssembler.AppendCodeInt(AValue: Integer);
begin
  FCode := FCode + [Byte(AValue), Byte(AValue shr 8), Byte(AValue shr 16), Byte(AValue shr 24)];
end;

procedure TQvmAssembler.Op(AOpcode: Integer);
begin
  AppendCode(Byte(AOpcode));
  Inc(FInstructions);
end;

procedure TQvmAssembler.Op(AOpcode, AOperand: Integer);
begin
  AppendCode(Byte(AOpcode));
  if AOpcode = OP_ARG then
    AppendCode(Byte(AOperand))
  else
    AppendCodeInt(AOperand);
  Inc(FInstructions);
end;

procedure TQvmAssembler.ConstFloat(AValue: Single);
begin
  Op(OP_CONST, PInteger(@AValue)^);
end;

function TQvmAssembler.Here: Integer;
begin
  Result := FInstructions;
end;

function TQvmAssembler.NewLabel: Integer;
begin
  Result := Length(FLabels);
  FLabels := FLabels + [-1];
end;

procedure TQvmAssembler.Mark(ALabel: Integer);
begin
  FLabels[ALabel] := FInstructions;
end;

function TQvmAssembler.MarkNew: Integer;
begin
  Result := NewLabel;
  Mark(Result);
end;

procedure TQvmAssembler.Branch(AOpcode, ALabel: Integer);
var
  LFixup: TFixup;
begin
  LFixup.Offset := Length(FCode) + 1;
  LFixup.LabelId := ALabel;
  LFixup.InData := False;
  FFixups := FFixups + [LFixup];
  Op(AOpcode, 0);
end;

procedure TQvmAssembler.ConstLabel(ALabel: Integer);
begin
  Branch(OP_CONST, ALabel);
end;

procedure TQvmAssembler.Jump(ALabel: Integer);
begin
  ConstLabel(ALabel);
  Op(OP_JUMP);
end;

procedure TQvmAssembler.CallLabel(ALabel: Integer);
begin
  ConstLabel(ALabel);
  Op(OP_CALL);
end;

procedure TQvmAssembler.SystemCall(ANumber: Integer);
begin
  Op(OP_CONST, -(ANumber + 1));
  Op(OP_CALL);
end;

procedure TQvmAssembler.LoadLocal(AOffset: Integer);
begin
  Op(OP_LOCAL, AOffset);
  Op(OP_LOAD4);
end;

procedure TQvmAssembler.Raw(AValue: Byte);
begin
  AppendCode(AValue);
end;

function TQvmAssembler.Data(const AValues: array of Integer): Integer;
var
  LValue: Integer;
begin
  Result := Length(FData);
  for LValue in AValues do
    FData := FData + [Byte(LValue), Byte(LValue shr 8), Byte(LValue shr 16), Byte(LValue shr 24)];
end;

function TQvmAssembler.DataLabel(ALabel: Integer): Integer;
var
  LFixup: TFixup;
begin
  LFixup.Offset := Length(FData);
  LFixup.LabelId := ALabel;
  LFixup.InData := True;
  FFixups := FFixups + [LFixup];
  Result := Data([0]);
end;

function TQvmAssembler.DataText(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := Length(FData);
  for LIndex := 1 to Length(AText) do
    FData := FData + [Byte(AText[LIndex])];
  FData := FData + [0];
  while (Length(FData) and 3) <> 0 do
    FData := FData + [0];
end;

function TQvmAssembler.Lit(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := Length(FLit);
  for LIndex := 1 to Length(AText) do
    FLit := FLit + [Byte(AText[LIndex])];
end;

function TQvmAssembler.DataLength: Integer;
begin
  Result := Length(FData);
end;

procedure TQvmAssembler.ImageSize(ATotal: Integer);
begin
  FBss := ATotal - Length(FData) - Length(FLit);
end;

procedure TQvmAssembler.Bss(ASize: Integer);
begin
  FBss := ASize;
end;

procedure TQvmAssembler.ForceInstructionCount(ACount: Integer);
begin
  FForcedCount := ACount;
end;

procedure TQvmAssembler.JumpTargets(const AValues: array of Integer);
var
  LValue: Integer;
begin
  for LValue in AValues do
    FJumpTargets := FJumpTargets + [LValue];
end;

function TQvmAssembler.ToBytes(AVersion2: Boolean): TBytes;
var
  LHeader: TQvmHeader;
  LCode, LData: TBytes;
  LFixup: TFixup;
  LHeaderSize, LJumpLength, LTarget: Integer;
begin
  LCode := Copy(FCode);
  LData := Copy(FData);
  for LFixup in FFixups do
  begin
    LTarget := FLabels[LFixup.LabelId];
    if LTarget < 0 then
      raise Exception.CreateFmt(SUnmarkedLabel, [LFixup.LabelId]);
    if LFixup.InData then
      Move(LTarget, LData[LFixup.Offset], SizeOf(Integer))
    else
      Move(LTarget, LCode[LFixup.Offset], SizeOf(Integer));
  end;
  while (Length(LCode) and 3) <> 0 do
    LCode := LCode + [0];

  LHeaderSize := SizeOf(TQvmHeader);
  if AVersion2 then
    Inc(LHeaderSize, SizeOf(Integer));
  if AVersion2 then
    LHeader.Magic := QVM_MAGIC_VER2
  else
    LHeader.Magic := QVM_MAGIC;
  if FForcedCount >= 0 then
    LHeader.InstructionCount := FForcedCount
  else
    LHeader.InstructionCount := FInstructions;
  LHeader.CodeOffset := LHeaderSize;
  LHeader.CodeLength := Length(LCode);
  LHeader.DataOffset := LHeaderSize + Length(LCode);
  LHeader.DataLength := Length(LData);
  LHeader.LitLength := Length(FLit);
  LHeader.BssLength := FBss;

  SetLength(Result, SizeOf(TQvmHeader));
  Move(LHeader, Result[0], SizeOf(TQvmHeader));
  if AVersion2 then
  begin
    LJumpLength := Length(FJumpTargets) * SizeOf(Integer);
    Result := Result + [Byte(LJumpLength), Byte(LJumpLength shr 8), Byte(LJumpLength shr 16),
      Byte(LJumpLength shr 24)];
  end;
  Result := Result + LCode + LData + FLit;
  if AVersion2 then
    for LTarget in FJumpTargets do
      Result := Result + [Byte(LTarget), Byte(LTarget shr 8), Byte(LTarget shr 16), Byte(LTarget shr 24)];
end;

end.
