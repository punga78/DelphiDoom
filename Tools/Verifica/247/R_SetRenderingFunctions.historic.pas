procedure R_SetRenderingFunctions;
begin
  case setdetail of
    DL_LOWEST:
      begin
        basebatchcolfunc := R_DrawColumnLow_Batch;
        batchcolfunc := R_DrawColumnLow_Batch;
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        batchfuzzcolfunc1 := R_DrawFuzzColumn1_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2_Batch;
{$ELSE}
        batchfuzzcolfunc := R_DrawFuzzColumn_Batch;
{$ENDIF}
        batchlightcolfunc := nil;
        batchwhitelightcolfunc := nil;
        batchredlightcolfunc := nil;
        batchgreenlightcolfunc := nil;
        batchbluelightcolfunc := nil;
        batchyellowlightcolfunc := nil;
        batchtranscolfunc := R_DrawTranslatedColumn_Batch;
{$IFDEF STRIFE}

        fuzztranscolfunc := R_DrawFuzzColumnTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnTL_Batch;
{$ENDIF}

        if usemultithread then
        begin
          basebatchcolfunc_mt := R_DrawColumnLow_BatchMT;
          batchcolfunc_mt := R_DrawColumnLow_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageMedium_BatchMT;
          if diher8bittransparency then
            batchtalphacolfunc_mt := nil
          else
            batchtalphacolfunc_mt := R_DrawColumnAlphaMedium_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddMedium_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractMedium_BatchMT;
          maskedcolfunc_mt := R_DrawColumnLowestMT;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageLowestMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddLowestMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddLowestMT;
          subtractcolfunc_mt := R_DrawColumnSubtractLowestMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

        colfunc := R_DrawColumnLowest;
        wallcolfunc := R_DrawColumnLowest;
        basewallcolfunc := R_DrawColumnLowest;
        tallwallcolfunc := R_DrawTallColumnLowest;
        transcolfunc := R_DrawTranslatedColumn;
        if diher8bittransparency then
        begin
          averagecolfunc := R_DrawColumnAlphaMediumDiher;
          alphacolfunc := R_DrawColumnAlphaMediumDiher;
          batchtaveragecolfunc := nil;
          batchtalphacolfunc := nil;
        end
        else
        begin
          averagecolfunc := R_DrawColumnAverageLowest;
          alphacolfunc := R_DrawColumnAlphaLowest;
          batchtaveragecolfunc := R_DrawColumnAverageMedium_Batch;
          batchtalphacolfunc := R_DrawColumnAlphaMedium_Batch;
        end;
        addcolfunc := R_DrawColumnAddLowest;
        addcolfunc_smallstep := R_DrawColumnAddLowest;
        batchaddcolfunc := R_DrawColumnAddMedium_Batch;
        subtractcolfunc := R_DrawColumnSubtractLowest;
        batchsubtractcolfunc := R_DrawColumnSubtractMedium_Batch;

        maskedcolfunc := R_DrawColumnLowest;
        maskedcolfunc2 := R_DrawColumnLowest;

        if usemultithread then
        begin
          spanfunc := R_StoreFlatSpan8;
          basespanfunc := R_StoreFlatSpan8;
          ripplespanfunc := R_StoreFlatSpan8;
          slopefunc := R_StoreFlatSpan8;
          baseslopefunc := R_StoreFlatSpan8;
          rippleslopefunc := R_StoreFlatSpan8;

          spanfuncMT := R_DrawSpanLowMT;
          basespanfuncMT := R_DrawSpanLowMT;
          ripplespanfuncMT := R_DrawSpanLowMT;
          slopefuncMT := R_DrawSpanLowMT;
          baseslopefuncMT := R_DrawSpanLowMT;
          rippleslopefuncMT := R_DrawSpanLowMT;
        end
        else
        begin
          spanfunc := R_DrawSpanLow;
          basespanfunc := R_DrawSpanLow;
          ripplespanfunc := R_DrawSpanLow;
          slopefunc := R_DrawSpanLow; // JVAL: Slopes
          baseslopefunc := R_DrawSpanLow;
          rippleslopefunc := R_DrawSpanLow;
        end;

{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn
        else
          fuzzcolfunc := R_DrawNewFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ELSEIF DEFINED(STRIFE)}
        fuzzcolfunc1 := R_DrawFuzzColumn1;
        fuzzcolfunc2 := R_DrawFuzzColumn2;
        lightcolfunc := R_DrawFuzzColumn1;
        whitelightcolfunc := R_DrawFuzzColumn1;
        redlightcolfunc := R_DrawFuzzColumn1;
        greenlightcolfunc := R_DrawFuzzColumn1;
        bluelightcolfunc := R_DrawFuzzColumn1;
        yellowlightcolfunc := R_DrawFuzzColumn1;
{$ELSE}
        fuzzcolfunc := R_DrawFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ENDIF}
        skycolfunc := R_DrawSkyColumnLow;
        videomode := vm8bit;
      end;
    DL_LOW:
      begin
        basebatchcolfunc := R_DrawColumnLow_Batch;
        batchcolfunc := R_DrawColumnLow_Batch;
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        batchfuzzcolfunc1 := R_DrawFuzzColumn1_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2_Batch;
{$ELSE}
        batchfuzzcolfunc := R_DrawFuzzColumn_Batch;
{$ENDIF}
        batchlightcolfunc := nil;
        batchwhitelightcolfunc := nil;
        batchredlightcolfunc := nil;
        batchgreenlightcolfunc := nil;
        batchbluelightcolfunc := nil;
        batchyellowlightcolfunc := nil;
        batchtranscolfunc := R_DrawTranslatedColumn_Batch;
{$IFDEF STRIFE}

        fuzztranscolfunc := R_DrawFuzzColumnTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnTL_Batch;
{$ENDIF}

        if usemultithread then
        begin
          basebatchcolfunc_mt := R_DrawColumnLow_BatchMT;
          batchcolfunc_mt := R_DrawColumnLow_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageMedium_BatchMT;
          if diher8bittransparency then
            batchtalphacolfunc_mt := nil
          else
            batchtalphacolfunc_mt := R_DrawColumnAlphaMedium_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddMedium_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractMedium_BatchMT;
          maskedcolfunc_mt := R_DrawColumnLowMT;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageLowMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddLowMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddLowMT;
          subtractcolfunc_mt := R_DrawColumnSubtractLowMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

        colfunc := R_DrawColumnLow;
        wallcolfunc := R_DrawColumnLow;
        basewallcolfunc := R_DrawColumnLow;
        tallwallcolfunc := R_DrawTallColumnLow;
        transcolfunc := R_DrawTranslatedColumn;
        if diher8bittransparency then
        begin
          averagecolfunc := R_DrawColumnAlphaMediumDiher;
          alphacolfunc := R_DrawColumnAlphaMediumDiher;
          batchtaveragecolfunc := nil;
          batchtalphacolfunc := nil;
        end
        else
        begin
          averagecolfunc := R_DrawColumnAverageLow;
          alphacolfunc := R_DrawColumnAlphaLow;
          batchtaveragecolfunc := R_DrawColumnAverageMedium_Batch;
          batchtalphacolfunc := R_DrawColumnAlphaMedium_Batch;
        end;
        addcolfunc := R_DrawColumnAddLow;
        addcolfunc_smallstep := R_DrawColumnAddLow;
        batchaddcolfunc := R_DrawColumnAddMedium_Batch;
        subtractcolfunc := R_DrawColumnSubtractLow;
        batchsubtractcolfunc := R_DrawColumnSubtractMedium_Batch;

        maskedcolfunc := R_DrawColumnLow;
        maskedcolfunc2 := R_DrawColumnLow;

        if usemultithread then
        begin
          spanfunc := R_StoreFlatSpan8;
          basespanfunc := R_StoreFlatSpan8;
          ripplespanfunc := R_StoreFlatSpan8;
          slopefunc := R_StoreFlatSpan8;
          baseslopefunc := R_StoreFlatSpan8;
          rippleslopefunc := R_StoreFlatSpan8;

          spanfuncMT := R_DrawSpanLowMT;
          basespanfuncMT := R_DrawSpanLowMT;
          ripplespanfuncMT := R_DrawSpanLowMT;
          slopefuncMT := R_DrawSpanLowMT;
          baseslopefuncMT := R_DrawSpanLowMT;
          rippleslopefuncMT := R_DrawSpanLowMT;
        end
        else
        begin
          spanfunc := R_DrawSpanLow;
          basespanfunc := R_DrawSpanLow;
          ripplespanfunc := R_DrawSpanLow;
          slopefunc := R_DrawSpanLow; // JVAL: Slopes
          baseslopefunc := R_DrawSpanLow;
          rippleslopefunc := R_DrawSpanLow;
        end;

{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn
        else
          fuzzcolfunc := R_DrawNewFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ELSEIF DEFINED(STRIFE)}
        fuzzcolfunc1 := R_DrawFuzzColumn1;
        fuzzcolfunc2 := R_DrawFuzzColumn2;
        lightcolfunc := R_DrawFuzzColumn1;
        whitelightcolfunc := R_DrawFuzzColumn1;
        redlightcolfunc := R_DrawFuzzColumn1;
        greenlightcolfunc := R_DrawFuzzColumn1;
        bluelightcolfunc := R_DrawFuzzColumn1;
        yellowlightcolfunc := R_DrawFuzzColumn1;
{$ELSE}
        fuzzcolfunc := R_DrawFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ENDIF}
        skycolfunc := R_DrawSkyColumnLow;
        videomode := vm8bit;
      end;
    DL_MEDIUM:
      begin
        basebatchcolfunc := R_DrawColumnMedium_Batch;
        batchcolfunc := R_DrawColumnMedium_Batch;
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        batchfuzzcolfunc1 := R_DrawFuzzColumn1_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2_Batch;
{$ELSE}
        batchfuzzcolfunc := R_DrawFuzzColumn_Batch;
{$ENDIF}
        batchlightcolfunc := nil;
        batchwhitelightcolfunc := nil;
        batchredlightcolfunc := nil;
        batchgreenlightcolfunc := nil;
        batchbluelightcolfunc := nil;
        batchyellowlightcolfunc := nil;
        batchtranscolfunc := R_DrawTranslatedColumn_Batch;
{$IFDEF STRIFE}

        fuzztranscolfunc := R_DrawFuzzColumnTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnTL_Batch;
{$ENDIF}

        if usemultithread then
        begin
          basebatchcolfunc_mt := R_DrawColumnMedium_BatchMT;
          batchcolfunc_mt := R_DrawColumnMedium_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageMedium_BatchMT;
          if diher8bittransparency then
            batchtalphacolfunc_mt := nil
          else
            batchtalphacolfunc_mt := R_DrawColumnAlphaMedium_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddMedium_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractMedium_BatchMT;
          maskedcolfunc_mt := R_DrawColumnMediumMT;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageMediumMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddMediumMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddMediumMT;
          subtractcolfunc_mt := R_DrawColumnSubtractMediumMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

        colfunc := R_DrawColumnMedium;
        wallcolfunc := R_DrawColumnMedium;
        basewallcolfunc := R_DrawColumnMedium;
        tallwallcolfunc := R_DrawTallColumnMedium;
        transcolfunc := R_DrawTranslatedColumn;
        if diher8bittransparency then
        begin
          averagecolfunc := R_DrawColumnAlphaMediumDiher;
          alphacolfunc := R_DrawColumnAlphaMediumDiher;
          batchtaveragecolfunc := nil;
          batchtalphacolfunc := nil;
        end
        else
        begin
          averagecolfunc := R_DrawColumnAverageMedium;
          alphacolfunc := R_DrawColumnAlphaMedium;
          batchtaveragecolfunc := R_DrawColumnAverageMedium_Batch;
          batchtalphacolfunc := R_DrawColumnAlphaMedium_Batch;
        end;
        addcolfunc := R_DrawColumnAddMedium;
        addcolfunc_smallstep := R_DrawColumnAddMedium;
        batchaddcolfunc := R_DrawColumnAddMedium_Batch;
        subtractcolfunc := R_DrawColumnSubtractMedium;
        batchsubtractcolfunc := R_DrawColumnSubtractMedium_Batch;

        maskedcolfunc := R_DrawColumnMedium;
        maskedcolfunc2 := R_DrawColumnMedium;

        if usemultithread then
        begin
          spanfunc := R_StoreFlatSpan8;
          basespanfunc := R_StoreFlatSpan8;
          ripplespanfunc := R_StoreFlatSpan8;
          slopefunc := R_StoreFlatSpan8;
          baseslopefunc := R_StoreFlatSpan8;
          rippleslopefunc := R_StoreFlatSpan8;

          spanfuncMT := R_DrawSpanMediumMT;
          basespanfuncMT := R_DrawSpanMediumMT;
          ripplespanfuncMT := R_DrawSpanMedium_RippleMT;
          slopefuncMT := R_DrawSpanMediumMT;
          baseslopefuncMT := R_DrawSpanMediumMT;
          rippleslopefuncMT := R_DrawSpanMedium_RippleMT;
        end
        else
        begin
          spanfunc := R_DrawSpanMedium;
          basespanfunc := R_DrawSpanMedium;
          ripplespanfunc := R_DrawSpanMedium_Ripple;
          slopefunc := R_DrawSlopeMedium; // JVAL: Slopes
          baseslopefunc := R_DrawSlopeMedium;
          rippleslopefunc := R_DrawSlopeMedium_Ripple;
        end;

{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn
        else
          fuzzcolfunc := R_DrawNewFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ELSEIF DEFINED(STRIFE)}
        fuzzcolfunc1 := R_DrawFuzzColumn1;
        fuzzcolfunc2 := R_DrawFuzzColumn2;
        lightcolfunc := R_DrawFuzzColumn1;
        whitelightcolfunc := R_DrawFuzzColumn1;
        redlightcolfunc := R_DrawFuzzColumn1;
        greenlightcolfunc := R_DrawFuzzColumn1;
        bluelightcolfunc := R_DrawFuzzColumn1;
        yellowlightcolfunc := R_DrawFuzzColumn1;
{$ELSE}
        fuzzcolfunc := R_DrawFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
{$ENDIF}
        skycolfunc := R_DrawSkyColumn;
        videomode := vm8bit;
      end;
{$IFDEF DOOM}
    DL_NORMAL:  // JVAL: 32 bit color - Default
{$ELSE}
    DL_NORMAL:
{$ENDIF}
      begin
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        batchfuzzcolfunc1 := R_DrawFuzzColumn1Hi_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2Hi_Batch;
{$ELSE}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        if use32bitfuzzeffect then
          batchfuzzcolfunc := R_DrawFuzzColumn32_Batch
        else
          batchfuzzcolfunc := R_DrawFuzzColumnHi_Batch;
{$ENDIF}
        batchlightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchwhitelightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchredlightcolfunc := R_DrawRedLightColumnHi_Batch;
        batchgreenlightcolfunc := R_DrawGreenLightColumnHi_Batch;
        batchbluelightcolfunc := R_DrawBlueLightColumnHi_Batch;
        batchyellowlightcolfunc := R_DrawYellowLightColumnHi_Batch;
        batchtranscolfunc := R_DrawTranslatedColumnHi_Batch;
        batchtaveragecolfunc := R_DrawColumnAverageHi_Batch;
        batchtalphacolfunc := R_DrawColumnAlphaHi_Batch;
        batchaddcolfunc := R_DrawColumnAddHi_Batch;
        batchsubtractcolfunc := R_DrawColumnSubtractHi_Batch;

{$IFDEF HEXEN}
        if usemultithread and not LevelUseFog then
{$ELSE}
        if usemultithread then
{$ENDIF}
        begin
          basebatchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageHi_BatchMT;
          batchtalphacolfunc_mt := R_DrawColumnAlphaHi_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddHi_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractHi_BatchMT;
          maskedcolfunc_mt := R_DrawMaskedColumnNormalMT;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageHiMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddHiMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddHi_SmallStepMT;
          subtractcolfunc_mt := R_DrawColumnSubtractHiMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

{$IF DEFINED(HEXEN)}
        if LevelUseFog then
        begin
          basebatchcolfunc := nil;
          batchcolfunc := nil;
          colfunc := R_DrawColumnHi_Fog;
          wallcolfunc := R_DrawColumnHi_Fog;
          basewallcolfunc := R_DrawColumnHi_Fog;
          tallwallcolfunc := R_DrawTallColumnHi_Fog;
        end
        else
        begin
          basebatchcolfunc := R_DrawColumnHi_Batch;
          batchcolfunc := R_DrawColumnHi_Batch;
          colfunc := R_DrawColumnHi;
          wallcolfunc := R_DrawColumnHi;
          basewallcolfunc := R_DrawColumnHi;
          tallwallcolfunc := R_DrawTallColumnHi;
        end;
{$ELSEIF DEFINED(STRIFE)}
        fuzztranscolfunc := R_DrawFuzzColumnHiTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnHiTL_Batch;

        colfunc := R_DrawColumnHi;
        wallcolfunc := R_DrawColumnHi;
        basewallcolfunc := R_DrawColumnHi;
        tallwallcolfunc := R_DrawTallColumnHi;
{$ELSE}
        colfunc := R_DrawColumnHi;
        wallcolfunc := R_DrawColumnHi;
        basewallcolfunc := R_DrawColumnHi;
        tallwallcolfunc := R_DrawTallColumnHi;
{$ENDIF}
        transcolfunc := R_DrawTranslatedColumnHi;
        averagecolfunc := R_DrawColumnAverageHi;
        alphacolfunc := R_DrawColumnAlphaHi;
        addcolfunc := R_DrawColumnAddHi;
        addcolfunc_smallstep := R_DrawColumnAddHi_SmallStep;
        subtractcolfunc := R_DrawColumnSubtractHi;
{$IFNDEF HEXEN}
        maskedcolfunc := R_DrawMaskedColumnNormal;
        maskedcolfunc2 := R_DrawMaskedColumnHi32;
{$ENDIF}

{$IFDEF HEXEN}
        if LevelUseFog then
{$ELSE}
        if usemultithread then
{$ENDIF}
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnNormal_Fog;
          maskedcolfunc2 := R_DrawMaskedColumnHi32_Fog;
          spanfunc := R_DrawSpanNormal_Fog;
          basespanfunc := R_DrawSpanNormal_Fog;
          ripplespanfunc := R_DrawSpanNormal_Fog_Ripple;
          slopefunc := R_DrawSpanNormal_Fog;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal_Fog;
          rippleslopefunc := R_DrawSpanNormal_Fog_Ripple;
{$ELSE}
          spanfunc := R_StoreFlatSpan32;
          basespanfunc := R_StoreFlatSpan32;
          ripplespanfunc := R_StoreFlatSpan32;
          slopefunc := R_StoreFlatSpan32;
          baseslopefunc := R_StoreFlatSpan32;
          rippleslopefunc := R_StoreFlatSpan32;

          spanfuncMT := R_DrawSpanNormalMT;
          basespanfuncMT := R_DrawSpanNormalMT;
          ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
          slopefuncMT := R_DrawSpanNormalMT;
          baseslopefuncMT := R_DrawSpanNormalMT;
          rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
{$ENDIF}
        end
        else
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnNormal;
          maskedcolfunc2 := R_DrawMaskedColumnHi32;

          if usemultithread then
          begin
            spanfunc := R_StoreFlatSpan32;
            basespanfunc := R_StoreFlatSpan32;
            ripplespanfunc := R_StoreFlatSpan32;
            slopefunc := R_StoreFlatSpan32;
            baseslopefunc := R_StoreFlatSpan32;
            rippleslopefunc := R_StoreFlatSpan32;

            spanfuncMT := R_DrawSpanNormalMT;
            basespanfuncMT := R_DrawSpanNormalMT;
            ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
            slopefuncMT := R_DrawSpanNormalMT;
            baseslopefuncMT := R_DrawSpanNormalMT;
            rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
          end
          else
          begin
            spanfunc := R_DrawSpanNormal;
            basespanfunc := R_DrawSpanNormal;
            ripplespanfunc := R_DrawSpanNormal_Ripple;
            slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
            baseslopefunc := R_DrawSpanNormal;
            rippleslopefunc := R_DrawSpanNormal_Ripple;
          end;
{$ELSE}
          spanfunc := R_DrawSpanNormal;
          basespanfunc := R_DrawSpanNormal;
          ripplespanfunc := R_DrawSpanNormal_Ripple;
          slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal;
          rippleslopefunc := R_DrawSpanNormal_Ripple;
{$ENDIF}
        end;

{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawNewFuzzColumnHi;
{$ELSEIF DEFINED(STRIFE)}
        fuzzcolfunc1 := R_DrawFuzzColumn1Hi;
        fuzzcolfunc2 := R_DrawFuzzColumn2Hi;
{$ELSE}
        if use32bitfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawFuzzColumnHi;
{$ENDIF}
        lightcolfunc := R_DrawWhiteLightColumnHi;
        whitelightcolfunc := R_DrawWhiteLightColumnHi;
        redlightcolfunc := R_DrawRedLightColumnHi;
        greenlightcolfunc := R_DrawGreenLightColumnHi;
        bluelightcolfunc := R_DrawBlueLightColumnHi;
        yellowlightcolfunc := R_DrawYellowLightColumnHi;
        skycolfunc := R_DrawSkyColumnHi;
        videomode := vm32bit;
      end;
    DL_HIRES:
      begin
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        batchfuzzcolfunc1 := R_DrawFuzzColumn1Hi_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2Hi_Batch;
{$ELSE}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        if use32bitfuzzeffect then
          batchfuzzcolfunc := R_DrawFuzzColumn32_Batch
        else
          batchfuzzcolfunc := R_DrawFuzzColumnHi_Batch;
{$ENDIF}
        batchlightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchwhitelightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchredlightcolfunc := R_DrawRedLightColumnHi_Batch;
        batchgreenlightcolfunc := R_DrawGreenLightColumnHi_Batch;
        batchbluelightcolfunc := R_DrawBlueLightColumnHi_Batch;
        batchyellowlightcolfunc := R_DrawYellowLightColumnHi_Batch;
        batchtranscolfunc := R_DrawTranslatedColumnHi_Batch;
        batchtaveragecolfunc := R_DrawColumnAverageHi_Batch;
        batchtalphacolfunc := R_DrawColumnAlphaHi_Batch;
        batchaddcolfunc := R_DrawColumnAddHi_Batch;
        batchsubtractcolfunc := R_DrawColumnSubtractHi_Batch;
{$IFDEF STRIFE}

        fuzztranscolfunc := R_DrawFuzzColumnHiTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnHiTL_Batch;
{$ENDIF}

{$IFDEF HEXEN}
        if usemultithread and not LevelUseFog then
{$ELSE}
        if usemultithread then
{$ENDIF}
        begin
          basebatchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageHi_BatchMT;
          batchtalphacolfunc_mt := R_DrawColumnAlphaHi_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddHi_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractHi_BatchMT;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageHiMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddHiMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddHi_SmallStepMT;
          subtractcolfunc_mt := R_DrawColumnSubtractHiMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

{$IFDEF HEXEN}
        if LevelUseFog then
        begin
          basebatchcolfunc := nil;
          batchcolfunc := nil;
          colfunc := R_DrawColumnHi_Fog;
          wallcolfunc := R_DrawColumnUltra_Fog;
          basewallcolfunc := R_DrawColumnUltra_Fog;
          tallwallcolfunc := R_DrawTallColumnUltra_Fog;
        end
        else
        begin
          basebatchcolfunc := R_DrawColumnHi_Batch;
          batchcolfunc := R_DrawColumnHi_Batch;
          colfunc := R_DrawColumnHi;
          wallcolfunc := R_DrawColumnUltra;
          basewallcolfunc := R_DrawColumnUltra;
          tallwallcolfunc := R_DrawTallColumnUltra;
        end;
{$ELSE}
        colfunc := R_DrawColumnHi;
        wallcolfunc := R_DrawColumnUltra;
        basewallcolfunc := R_DrawColumnUltra;
        tallwallcolfunc := R_DrawTallColumnUltra;
{$ENDIF}
        transcolfunc := R_DrawTranslatedColumnHi;
        averagecolfunc := R_DrawColumnAverageHi;
        alphacolfunc := R_DrawColumnAlphaHi;
        addcolfunc := R_DrawColumnAddHi;
        addcolfunc_smallstep := R_DrawColumnAddHi_SmallStep;
        subtractcolfunc := R_DrawColumnSubtractHi;
{$IFNDEF HEXEN}
        maskedcolfunc := R_DrawMaskedColumnHi;
        maskedcolfunc2 := R_DrawMaskedColumnHi32;
{$ENDIF}

{$IFDEF HEXEN}
        if LevelUseFog then
{$ELSE}
        if usemultithread then
{$ENDIF}
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnHi_Fog;
          maskedcolfunc2 := R_DrawMaskedColumnHi32_Fog;
          spanfunc := R_DrawSpanNormal_Fog;
          basespanfunc := R_DrawSpanNormal_Fog;
          ripplespanfunc := R_DrawSpanNormal_Fog_Ripple;
          slopefunc := R_DrawSpanNormal_Fog;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal_Fog;
          rippleslopefunc := R_DrawSpanNormal_Fog_Ripple;
{$ELSE}
          spanfunc := R_StoreFlatSpan32;
          basespanfunc := R_StoreFlatSpan32;
          ripplespanfunc := R_StoreFlatSpan32;
          slopefunc := R_StoreFlatSpan32;
          baseslopefunc := R_StoreFlatSpan32;
          rippleslopefunc := R_StoreFlatSpan32;

          spanfuncMT := R_DrawSpanNormalMT;
          basespanfuncMT := R_DrawSpanNormalMT;
          ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
          slopefuncMT := R_DrawSpanNormalMT;
          baseslopefuncMT := R_DrawSpanNormalMT;
          rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
{$ENDIF}
        end
        else
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnHi;
          maskedcolfunc2 := R_DrawMaskedColumnHi32;

          if usemultithread then
          begin
            spanfunc := R_StoreFlatSpan32;
            basespanfunc := R_StoreFlatSpan32;
            ripplespanfunc := R_StoreFlatSpan32;
            slopefunc := R_StoreFlatSpan32;
            baseslopefunc := R_StoreFlatSpan32;
            rippleslopefunc := R_StoreFlatSpan32;

            spanfuncMT := R_DrawSpanNormalMT;
            basespanfuncMT := R_DrawSpanNormalMT;
            ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
            slopefuncMT := R_DrawSpanNormalMT;
            baseslopefuncMT := R_DrawSpanNormalMT;
            rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
          end
          else
          begin
            spanfunc := R_DrawSpanNormal;
            basespanfunc := R_DrawSpanNormal;
            ripplespanfunc := R_DrawSpanNormal_Ripple;
            slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
            baseslopefunc := R_DrawSpanNormal;
            rippleslopefunc := R_DrawSpanNormal_Ripple;
          end;
{$ELSE}
          spanfunc := R_DrawSpanNormal;
          basespanfunc := R_DrawSpanNormal;
          ripplespanfunc := R_DrawSpanNormal_Ripple;
          slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal;
          rippleslopefunc := R_DrawSpanNormal_Ripple;
{$ENDIF}
        end;
{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawNewFuzzColumnHi;
{$ELSEIF DEFINED(STRIFE)}

        fuzzcolfunc1 := R_DrawFuzzColumn1Hi;
        fuzzcolfunc2 := R_DrawFuzzColumn2Hi;
{$ELSE}

        if use32bitfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawFuzzColumnHi;
{$ENDIF}
        lightcolfunc := R_DrawWhiteLightColumnHi;
        whitelightcolfunc := R_DrawWhiteLightColumnHi;
        redlightcolfunc := R_DrawRedLightColumnHi;
        greenlightcolfunc := R_DrawGreenLightColumnHi;
        bluelightcolfunc := R_DrawBlueLightColumnHi;
        yellowlightcolfunc := R_DrawYellowLightColumnHi;
        skycolfunc := R_DrawSkyColumnHi;
        videomode := vm32bit;
      end;
    DL_ULTRARES:
      begin
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        batchfuzzcolfunc1 := R_DrawFuzzColumn1Hi_Batch;
        batchfuzzcolfunc2 := R_DrawFuzzColumn2Hi_Batch;
{$ELSE}
        basebatchcolfunc := R_DrawColumnHi_Batch;
        batchcolfunc := R_DrawColumnHi_Batch;
        if use32bitfuzzeffect then
          batchfuzzcolfunc := R_DrawFuzzColumn32_Batch
        else
          batchfuzzcolfunc := R_DrawFuzzColumnHi_Batch;
{$ENDIF}
        batchlightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchwhitelightcolfunc := R_DrawWhiteLightColumnHi_Batch;
        batchredlightcolfunc := R_DrawRedLightColumnHi_Batch;
        batchgreenlightcolfunc := R_DrawGreenLightColumnHi_Batch;
        batchbluelightcolfunc := R_DrawBlueLightColumnHi_Batch;
        batchyellowlightcolfunc := R_DrawYellowLightColumnHi_Batch;
        batchtranscolfunc := R_DrawTranslatedColumnHi_Batch;
        batchtaveragecolfunc := R_DrawColumnAverageHi_Batch;
        batchtalphacolfunc := R_DrawColumnAlphaHi_Batch;
        batchaddcolfunc := R_DrawColumnAddHi_Batch;
        batchsubtractcolfunc := R_DrawColumnSubtractHi_Batch;
{$IFDEF STRIFE}

        fuzztranscolfunc := R_DrawFuzzColumnHiTL;
        batchfuzztranscolfunc := R_DrawFuzzColumnHiTL_Batch;
{$ENDIF}

{$IFDEF HEXEN}
        if usemultithread and not LevelUseFog then
{$ELSE}
        if usemultithread then
{$ENDIF}
        begin
          basebatchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchcolfunc_mt := R_DrawColumnHi_BatchMT;
          batchtaveragecolfunc_mt := R_DrawColumnAverageHi_BatchMT;
          batchtalphacolfunc_mt := R_DrawColumnAlphaHi_BatchMT;
          batchaddcolfunc_mt := R_DrawColumnAddHi_BatchMT;
          batchsubtractcolfunc_mt := R_DrawColumnSubtractHi_BatchMT;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := R_DrawColumnAverageHiMT;
          alphacolfunc_mt := nil;
          addcolfunc_mt := R_DrawColumnAddHiMT;
          addcolfunc_smallstep_mt := R_DrawColumnAddHi_SmallStepMT;
          subtractcolfunc_mt := R_DrawColumnSubtractHiMT;
        end
        else
        begin
          basebatchcolfunc_mt := nil;
          batchcolfunc_mt := nil;
          batchtaveragecolfunc_mt := nil;
          batchtalphacolfunc_mt := nil;
          batchaddcolfunc_mt := nil;
          batchsubtractcolfunc_mt := nil;
          maskedcolfunc_mt := nil;
          colfunc_mt := nil;
          averagecolfunc_mt := nil;
          alphacolfunc_mt := nil;
          addcolfunc_mt := nil;
          addcolfunc_smallstep_mt := nil;
          subtractcolfunc_mt := nil;
        end;

{$IFDEF HEXEN}
        if LevelUseFog then
        begin
          basebatchcolfunc := nil;
          batchcolfunc := nil;
          colfunc := R_DrawColumnUltra_Fog;
          wallcolfunc := R_DrawColumnUltra_Fog;
          basewallcolfunc := R_DrawColumnUltra_Fog;
          tallwallcolfunc := R_DrawTallColumnUltra_Fog;
        end
        else
        begin
          basebatchcolfunc := R_DrawColumnHi_Batch;
          batchcolfunc := R_DrawColumnHi_Batch;
          colfunc := R_DrawColumnUltra;
          wallcolfunc := R_DrawColumnUltra;
          basewallcolfunc := R_DrawColumnUltra;
          tallwallcolfunc := R_DrawTallColumnUltra;
        end;
{$ELSE}
        colfunc := R_DrawColumnUltra;
        wallcolfunc := R_DrawColumnUltra;
        basewallcolfunc := R_DrawColumnUltra;
        tallwallcolfunc := R_DrawTallColumnUltra;
{$ENDIF}
        transcolfunc := R_DrawTranslatedColumnHi;
        averagecolfunc := R_DrawColumnAverageUltra;
        addcolfunc := R_DrawColumnAddHi;
        addcolfunc_smallstep := R_DrawColumnAddHi_SmallStep;
        subtractcolfunc := R_DrawColumnSubtractHi;
        alphacolfunc := R_DrawColumnAlphaHi;
{$IFDEF HEXEN}
        if LevelUseFog then
{$ELSE}
        maskedcolfunc := R_DrawMaskedColumnHi;
        maskedcolfunc2 := R_DrawMaskedColumnUltra32;

        if usemultithread then
{$ENDIF}
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnHi_Fog;
          maskedcolfunc2 := R_DrawMaskedColumnUltra32_Fog;
          spanfunc := R_DrawSpanNormal_Fog;
          basespanfunc := R_DrawSpanNormal_Fog;
          ripplespanfunc := R_DrawSpanNormal_Fog_Ripple;
          slopefunc := R_DrawSpanNormal_Fog;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal_Fog;
          rippleslopefunc := R_DrawSpanNormal_Fog_Ripple;
{$ELSE}
          spanfunc := R_StoreFlatSpan32;
          basespanfunc := R_StoreFlatSpan32;
          ripplespanfunc := R_StoreFlatSpan32;
          slopefunc := R_StoreFlatSpan32;
          baseslopefunc := R_StoreFlatSpan32;
          rippleslopefunc := R_StoreFlatSpan32;

          spanfuncMT := R_DrawSpanNormalMT;
          basespanfuncMT := R_DrawSpanNormalMT;
          ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
          slopefuncMT := R_DrawSpanNormalMT;
          baseslopefuncMT := R_DrawSpanNormalMT;
          rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
{$ENDIF}
        end
        else
        begin
{$IFDEF HEXEN}
          maskedcolfunc := R_DrawMaskedColumnHi;
          maskedcolfunc2 := R_DrawMaskedColumnUltra32;

          if usemultithread then
          begin
            spanfunc := R_StoreFlatSpan32;
            basespanfunc := R_StoreFlatSpan32;
            ripplespanfunc := R_StoreFlatSpan32;
            slopefunc := R_StoreFlatSpan32;
            baseslopefunc := R_StoreFlatSpan32;
            rippleslopefunc := R_StoreFlatSpan32;

            spanfuncMT := R_DrawSpanNormalMT;
            basespanfuncMT := R_DrawSpanNormalMT;
            ripplespanfuncMT := R_DrawSpanNormal_RippleMT;
            slopefuncMT := R_DrawSpanNormalMT;
            baseslopefuncMT := R_DrawSpanNormalMT;
            rippleslopefuncMT := R_DrawSpanNormal_RippleMT;
          end
          else
          begin
            spanfunc := R_DrawSpanNormal;
            basespanfunc := R_DrawSpanNormal;
            ripplespanfunc := R_DrawSpanNormal_Ripple;
            slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
            baseslopefunc := R_DrawSpanNormal;
            rippleslopefunc := R_DrawSpanNormal_Ripple;
          end;
{$ELSE}
          spanfunc := R_DrawSpanNormal; //R_DrawSpanUltra;
          basespanfunc := R_DrawSpanNormal;
          ripplespanfunc := R_DrawSpanNormal_Ripple;
          slopefunc := R_DrawSpanNormal;  // JVAL: Slopes
          baseslopefunc := R_DrawSpanNormal;
          rippleslopefunc := R_DrawSpanNormal_Ripple;
{$ENDIF}
        end;
{$IF DEFINED(HEXEN)}
        if useclassicfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawNewFuzzColumnHi;
{$ELSEIF DEFINED(STRIFE)}

        fuzzcolfunc1 := R_DrawFuzzColumn1Hi;
        fuzzcolfunc2 := R_DrawFuzzColumn2Hi;
{$ELSE}

        if use32bitfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawFuzzColumnHi;
{$ENDIF}
        lightcolfunc := R_DrawWhiteLightColumnHi;
        whitelightcolfunc := R_DrawWhiteLightColumnHi;
        redlightcolfunc := R_DrawRedLightColumnHi;
        greenlightcolfunc := R_DrawGreenLightColumnHi;
        bluelightcolfunc := R_DrawBlueLightColumnHi;
        yellowlightcolfunc := R_DrawYellowLightColumnHi;
        skycolfunc := R_DrawSkyColumnUltra;
        videomode := vm32bit;
      end;
  end;

end;
