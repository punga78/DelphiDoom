{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - builds the nodes of one level                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of LoadLevel / SaveLevel of level.c and of HandleLevel of glbsp.c      }
{  (glBSP 2.24, C) 2000-2007 Andrew Apted                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Processor;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Document;

type
  /// <summary>
  ///   Does all the steps for the current level of a WAD: reads the lumps,
  ///   prunes and analyzes, creates the segs, builds the tree and writes the
  ///   GL and (when asked) the normal lumps back to the WAD
  /// </summary>
  TGlbspLevelProcessor = class
  private
    FWad: TGlbspWad;
    FOptions: TGlbspOptions;
    FMessages: TStrings;
    FTimeProvider: TFunc<string>;
    function CurrentTimeText: string;
  public
    /// <param name="AWad">WAD already read; its CurrentLevel is processed</param>
    /// <param name="AOptions">Options of the build</param>
    /// <param name="AMessages">Receives the warnings; may be nil</param>
    constructor Create(const AWad: TGlbspWad; const AOptions: TGlbspOptions;
      const AMessages: TStrings);

    /// <summary>Builds the nodes of the current level of the WAD</summary>
    procedure Process;

    /// <summary>
    ///   Text of the TIME line of the GL marker. By default the current time
    ///   in the format of glbsp; tests set a fixed value
    /// </summary>
    property TimeProvider: TFunc<string> read FTimeProvider write FTimeProvider;
  end;

const
  /// <summary>Version of glbsp that this code follows</summary>
  GLBSP_VERSION = '2.24';

implementation

uses
  Winapi.Windows,
  DelphiDoom.Glbsp.Blockmap.Builder,
  DelphiDoom.Glbsp.Level.Analyzer,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Loader,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Level.Writer,
  DelphiDoom.Glbsp.Node.Builder,
  DelphiDoom.Glbsp.Node.Partitioner,
  DelphiDoom.Glbsp.Reject.Builder,
  DelphiDoom.Glbsp.Wad.Types;

{ TGlbspLevelProcessor }

constructor TGlbspLevelProcessor.Create(const AWad: TGlbspWad; const AOptions: TGlbspOptions;
  const AMessages: TStrings);
begin
  inherited Create;
  FWad := AWad;
  FOptions := AOptions;
  FMessages := AMessages;
end;

function TGlbspLevelProcessor.CurrentTimeText: string;
var
  LTime: TSystemTime;
begin
  if Assigned(FTimeProvider) then
    Exit(FTimeProvider());

  GetSystemTime(LTime);
  Result := Format('%.4d-%.2d-%.2d %.2d:%.2d:%.2d.%.4d', [LTime.wYear, LTime.wMonth,
    LTime.wDay, LTime.wHour, LTime.wMinute, LTime.wSecond, LTime.wMilliseconds * 10]);
end;

procedure TGlbspLevelProcessor.Process;
var
  LData: TGlbspLevelData;
  LLoader: TGlbspLevelLoader;
  LAnalyzer: TGlbspLevelAnalyzer;
  LPartitioner: TGlbspPartitioner;
  LBuilder: TGlbspNodeBuilder;
  LBlockmap: TGlbspBlockmapBuilder;
  LWriter: TGlbspLevelWriter;
  LSegList: TGlbspSuperBlock;
  LRootNode: TGlbspNode;
  LRootSub: TGlbspSubsec;
  LRootStale: TGlbspNode;
  LNormalExists: Boolean;
  LForceV5, LForceV3: Boolean;
begin
  LData := TGlbspLevelData.Create;
  try
    LLoader := TGlbspLevelLoader.Create(FWad, LData);
    LAnalyzer := TGlbspLevelAnalyzer.Create(LData, FOptions, FMessages);
    LPartitioner := TGlbspPartitioner.Create(LData, LAnalyzer, FOptions, FMessages);
    LBuilder := TGlbspNodeBuilder.Create(LData, LAnalyzer, LPartitioner, FOptions, FWad,
      FMessages);
    LBlockmap := TGlbspBlockmapBuilder.Create(LData, FWad, FOptions, FMessages);
    LWriter := TGlbspLevelWriter.Create(LData, FWad);
    try
      // LoadLevel
      LNormalExists := LLoader.CheckForNormalNodes;

      LData.DoingNormal := not FOptions.GwaMode and (FOptions.ForceNormal or
        (not FOptions.NoNormal and not LNormalExists));

      // Hexen is identified by the BEHAVIOR lump
      LData.DoingHexen := Assigned(FWad.FindLevelLump('BEHAVIOR')) or FOptions.ForceHexen;

      LLoader.GetVertices;
      LLoader.GetSectors;
      LLoader.GetSidedefs;

      if LData.DoingHexen then
      begin
        LLoader.GetLinedefsHexen;
        LLoader.GetThingsHexen;
      end
      else
      begin
        LLoader.GetLinedefs;
        LLoader.GetThings;
      end;

      if FOptions.Fast and not LData.DoingNormal and LNormalExists and
        (LData.Sectors.Count > 5) and (LData.Linedefs.Count > 100) then
        LLoader.GetStaleNodes;

      if LData.DoingNormal then
      begin
        // The order here is critical
        if FOptions.PackSides then
          LAnalyzer.DetectDuplicateSidedefs;

        if FOptions.MergeVert then
          LAnalyzer.DetectDuplicateVertices;

        if not FOptions.NoPrune then
          LAnalyzer.PruneLinedefs;

        // The vertices are always pruned (-noprune is ignored): otherwise all
        // the unused vertices of the seg splits would keep accumulating
        LAnalyzer.PruneVertices;

        if not FOptions.NoPrune then
          LAnalyzer.PruneSidedefs;

        if FOptions.PruneSect then
          LAnalyzer.PruneSectors;
      end;

      LAnalyzer.CalculateWallTips;

      // Sectors that contain polyobjs
      if LData.DoingHexen then
        LAnalyzer.DetectPolyobjSectors;

      LAnalyzer.DetectOverlappingLines;

      if FOptions.WindowFx then
        LAnalyzer.DetectWindowEffects;

      // HandleLevel
      LBlockmap.InitBlockmap;

      LSegList := LBuilder.CreateSegs(LBlockmap.GetBounds);
      try
        if LData.StaleNodes.Count = 0 then
          LRootStale := nil
        else
          LRootStale := LData.StaleNodes[LData.StaleNodes.Count - 1];

        LBuilder.BuildNodes(LSegList, LRootNode, LRootSub, 0, LRootStale);
      finally
        LSegList.Free;
      end;

      LBuilder.ClockwiseBspTree;

      // SaveLevel
      LForceV3 := FOptions.SpecVersion = 3;
      LForceV5 := FOptions.SpecVersion = 5;

      // RoundOffBspTree converts the GL vertices of the segs to their normal
      // counterparts (a pointer change: normal_dup is used)
      if FOptions.SpecVersion = 1 then
        LBuilder.RoundOffBspTree;

      // The GL nodes
      if (LData.NumNormalVert > 32767) or (LData.NumGlVert > 32767) then
      begin
        if FOptions.SpecVersion < 3 then
        begin
          LForceV5 := True;
          FWad.MarkV5Switch(LIMIT_VERTEXES or LIMIT_GL_SEGS);
        end;
      end;

      if LData.Segs.Count > 65534 then
      begin
        if FOptions.SpecVersion < 3 then
        begin
          LForceV5 := True;
          FWad.MarkV5Switch(LIMIT_GL_SSECT or LIMIT_GL_SEGS);
        end;
      end;

      if LData.Nodes.Count > 32767 then
      begin
        if FOptions.SpecVersion < 5 then
        begin
          LForceV5 := True;
          FWad.MarkV5Switch(LIMIT_GL_NODES);
        end;
      end;

      if FOptions.SpecVersion = 1 then
        LWriter.PutVertices('GL_VERT', True)
      else
        LWriter.PutV2Vertices(LForceV5);

      if LForceV3 or LForceV5 then
        LWriter.PutV3Segs(LForceV5)
      else
        LWriter.PutGLSegs;

      if LForceV3 or LForceV5 then
        LWriter.PutV3Subsecs(LForceV5)
      else
        LWriter.PutSubsecs('GL_SSECT', True);

      LWriter.PutNodes('GL_NODES', True, LForceV5, LRootNode);

      // An empty PVS lump
      FWad.CreateGLLump('GL_PVS');

      if LData.DoingNormal then
      begin
        if FOptions.SpecVersion <> 1 then
          LBuilder.RoundOffBspTree;

        LBuilder.NormaliseBspTree;

        LWriter.PutVertices('VERTEXES', False);
        LWriter.PutSectors;
        LWriter.PutSidedefs;

        if LData.DoingHexen then
          LWriter.PutLinedefsHexen
        else
          LWriter.PutLinedefs;

        if LForceV5 then
        begin
          // No problem is reported when -v5 was given explicitly
          if FOptions.SpecVersion < 5 then
            FWad.MarkZDSwitch;

          LWriter.SaveZDFormat(LRootNode);
        end
        else
        begin
          LWriter.PutSegs;
          LWriter.PutSubsecs('SSECTORS', False);
          LWriter.PutNodes('NODES', False, False, LRootNode);
        end;

        // BLOCKMAP and REJECT are not touched when the normal nodes are not built
        LBlockmap.PutBlockmap;

        if not FOptions.NoReject or not Assigned(FWad.FindLevelLump('REJECT')) then
          with TGlbspRejectBuilder.Create(LData, FWad) do
          try
            PutReject;
          finally
            Free;
          end;
      end;

      // The keywords (version 5.0 of the specs)
      FWad.AddGLTextLine('BUILDER', AnsiString('glBSP ' + GLBSP_VERSION));
      LWriter.PutGLOptions(FOptions);
      FWad.AddGLTextLine('TIME', AnsiString(CurrentTimeText));

      // After the normal nodes are built, so that the new VERTEXES lump is used
      LWriter.PutGLChecksum;
    finally
      LWriter.Free;
      LBlockmap.Free;
      LBuilder.Free;
      LPartitioner.Free;
      LAnalyzer.Free;
      LLoader.Free;
    end;
  finally
    LData.Free;
  end;
end;

end.
