{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - what the machine is                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.MachineProfileBuilder;

// The decisions of I_DetectCPU of i_system.pas (issue #185): MMX, 3DNow!, how many cores and
// whether the renderer uses more than one. The engine writes the result to its variables.

interface

uses
  System.SysUtils, DelphiDoom.Platform.Intf, DelphiDoom.EngineSystem.Types;

type
  /// <summary>Reads the processor and tells what the engine should do with it</summary>
  TMachineProfileBuilder = class
  public
    /// <summary>
    ///   ADecideMultithread is true when there is no configuration yet (the first start, or the
    ///   defaults are not loaded): the renderer then uses the threads if there is more than one
    ///   processor. Otherwise ACurrentMultithread, what the configuration says, stays
    /// </summary>
    class function Detect(const ACpu: ICpuInfo; ADecideMultithread: Boolean;
      ACurrentMultithread: Boolean): TMachineProfile; static;
  end;

implementation

{ TMachineProfileBuilder }

class function TMachineProfileBuilder.Detect(const ACpu: ICpuInfo; ADecideMultithread: Boolean;
  ACurrentMultithread: Boolean): TMachineProfile;
var
  LLines: TArray<string>;

  procedure AddLine(const AText: string);
  begin
    SetLength(LLines, Length(LLines) + 1);
    LLines[High(LLines)] := AText;
  end;

begin
  if not Assigned(ACpu) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ACpu']);

  Result.HasMmx := ACpu.HasMmx;
  Result.Has3DNow := ACpu.Has3DNow;
  Result.ProcessorCount := ACpu.ProcessorCount;

  if Result.HasMmx then
    AddLine(' MMX extentions detected'#13#10);
  if Result.Has3DNow then
    AddLine(' AMD 3D Now! extentions detected'#13#10);

  if Result.ProcessorCount > 1 then
    AddLine(Format(' Multi-core system detected (%d CPUs)'#13#10, [Result.ProcessorCount]));

  if ADecideMultithread then
    Result.UseMultithread := Result.ProcessorCount > 1
  else
    Result.UseMultithread := ACurrentMultithread;

  if Result.UseMultithread then
    AddLine(' Multithreading mode ON'#13#10)
  else if Result.ProcessorCount > 1 then
    AddLine(' Multithreading mode OFF (will not use all cores)'#13#10)
  else
    AddLine(' Multithreading mode OFF'#13#10);

  Result.Lines := LLines;
end;

end.
