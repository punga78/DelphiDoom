{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the one place that knows the classes              }
{                                                                              }
{  Written for this library. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

type
  /// <summary>Makes the objects of the library; the rest of the code knows only the interfaces</summary>
  TAasFactory = class
  public
    /// <summary>
    ///   A reader of AAS files. The import gets the messages, the files give the bytes of a file,
    ///   the variables give sv_mapChecksum; ASwapBytes: the machine is big endian
    /// </summary>
    class function CreateReader(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVars; const ASwapBytes: Boolean = False): IAasReader; static;
    class function CreateSampler(const AFile: IAasFile; const AImport: IBotImport;
      const AInitialized: Boolean = False): IAasSampler; static;
    class function CreateTracer(const AFile: IAasFile; const AImport: IBotImport): IAasTracer; static;
    class function CreateFaceTester(const AFile: IAasFile; const AImport: IBotImport): IAasFaceTester; static;
    class function CreateBoxAreas(const AFile: IAasFile; const AImport: IBotImport): IAasBoxAreas; static;
    class function CreateAreaQuery(const AFile: IAasFile; const AImport: IBotImport): IAasAreaQuery; static;
  end;

implementation

uses
  DelphiDoom.Aas.Reader, DelphiDoom.Aas.Sampler, DelphiDoom.Aas.Tracer, DelphiDoom.Aas.FaceTester,
  DelphiDoom.Aas.BoxAreas, DelphiDoom.Aas.AreaQuery;

{ TAasFactory }

class function TAasFactory.CreateReader(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars; const ASwapBytes: Boolean): IAasReader;
begin
  Result := TAasReader.Create(AImport, AFiles, ALibVars, ASwapBytes);
end;

class function TAasFactory.CreateSampler(const AFile: IAasFile; const AImport: IBotImport;
  const AInitialized: Boolean): IAasSampler;
begin
  Result := TAasSampler.Create(AFile, AImport, AInitialized);
end;

class function TAasFactory.CreateTracer(const AFile: IAasFile; const AImport: IBotImport): IAasTracer;
begin
  Result := TAasTracer.Create(AFile, AImport);
end;

class function TAasFactory.CreateFaceTester(const AFile: IAasFile; const AImport: IBotImport): IAasFaceTester;
begin
  Result := TAasFaceTester.Create(AFile, AImport);
end;

class function TAasFactory.CreateBoxAreas(const AFile: IAasFile; const AImport: IBotImport): IAasBoxAreas;
begin
  Result := TAasBoxAreas.Create(AFile, AImport);
end;

class function TAasFactory.CreateAreaQuery(const AFile: IAasFile; const AImport: IBotImport): IAasAreaQuery;
begin
  Result := TAasAreaQuery.Create(AFile, AImport);
end;

end.
