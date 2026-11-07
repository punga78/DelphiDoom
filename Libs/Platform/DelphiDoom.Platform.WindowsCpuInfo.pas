{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the processor, as Windows tells it           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.WindowsCpuInfo;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   ICpuInfo on GetSystemInfo and IsProcessorFeaturePresent: no CPUID by hand (the old
  ///   assembler is gone), so it works the same at 32 and 64 bit
  /// </summary>
  TWindowsCpuInfo = class(TInterfacedObject, ICpuInfo)
  public
    function ProcessorCount: Integer;
    function HasMmx: Boolean;
    function Has3DNow: Boolean;
  end;

implementation

uses
  Winapi.Windows;

const
  PROCESSOR_FEATURE_MMX = 3;
  PROCESSOR_FEATURE_3DNOW = 7;

{ TWindowsCpuInfo }

function TWindowsCpuInfo.ProcessorCount: Integer;
var
  LInfo: TSystemInfo;
begin
  GetSystemInfo(LInfo);
  Result := Integer(LInfo.dwNumberOfProcessors);
end;

function TWindowsCpuInfo.HasMmx: Boolean;
begin
  Result := IsProcessorFeaturePresent(PROCESSOR_FEATURE_MMX);
end;

function TWindowsCpuInfo.Has3DNow: Boolean;
begin
  Result := IsProcessorFeaturePresent(PROCESSOR_FEATURE_3DNOW);
end;

end.
