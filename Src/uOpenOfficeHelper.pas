{ ******************************************************* }

{ Delphi openOffice Library }

{ File     : uOpenOfficeHelper.pas }
{ Developer: Daniel Fernandes Rodrigures }
{ Email    : danielfernandesroddrigues@gmail.com }
{ this unit is a part of the Open Source. }
{ licensed under a MPL/GPL/LGPL three license - see LICENSE.md}

{ ******************************************************* }

unit uOpenOfficeHelper;

interface

uses vcl.stdCtrls, System.SysUtils, uOpenOffice, uOpenOfficeCollors, math,
  System.Variants;

type

  TBorder = (bAll, bLeft, bRight, bBottom, bTop);

  TBoderSheet = set of TBorder;

  { STANDARD : � o alinhamento padr�o tanto para n�meros como para textos, sendo a esqueda para as strings e a direita para os n�meros;
    LEFT : o conte�do � alinhado no lado esquerdo da c�lula;
    CENTER : o conte�do � alinhado no centro da c�lula;
    RIGHT : o conte�do � alinhado no lado direito da c�lula;
    BLOCK : o conte�do � alinhando em rela��o ao comprimento da c�lula;
    REPEAT : o conte�do � repetido dentro da c�lula para preench�-la. }
  THoriJustify = (fthSTANDARD, fthLEFT, fthCENTER, fthRIGHT, fthBLOCK,
    fthREPEAT);
  { STANDARD : � o valor usado como padr�o;
    TOP : o conte�do da c�lula � alinhado pelo topo;
    CENTER : o conte�do da c�lula � alinhado pelo centro;
    BOTTOM : o conte�do da c�lula � alinhado pela base. }
  TVertJustify = (ftvSTANDARD, ftvTOP, ftvCENTER, ftvBOTTOM);

  TTypeChart = (ctDefault, ctVertical, ctPie, ctLine);

  THelperHoriJustify = record helper for THoriJustify
  public
    function toInteger: Integer;
  end;

  THelperVertJustify = record helper for TVertJustify
  public
    function toInteger: Integer;
  end;

  THelperOpenOffice = class helper for TOpenOffice
    procedure addChart(typeChart: TTypeChart; StartRow, EndRow: Integer; StartColumn, EndColumn, ChartName: string; PositionSheet: Integer);
    function setBorder(borderPosition: TBoderSheet; opColor: TOpenColor; RemoveBorder: boolean = false) : TOpenOffice;
    function changeFont(aNameFont: string; aHeight: Integer): TOpenOffice;
    function changeJustify(aTypeHori: THoriJustify; aTypeVert: TVertJustify) : TOpenOffice;
    function setColor(aFontColor, aBackgroud: TOpenColor): TOpenOffice;
    function setBold(aBold: boolean): TOpenOffice;
    function SetUnderline(aUnderline: boolean): TOpenOffice;
    function CountRow: Integer;
    function CountCell: Integer;
  end;

implementation

procedure THelperOpenOffice.addChart(typeChart: TTypeChart;
  StartRow, EndRow: Integer; StartColumn, EndColumn, ChartName: string;
  PositionSheet: Integer);
var
  Chart, Rect, sheet, cursor: OleVariant;
  RangeAddress: Variant;
  countChart: Integer;
begin
  countChart := 1;

  if ChartName.trim.IsEmpty then
    ChartName := 'MyChar_' + (StartColumn + StartRow.ToString) + ':' +
      (EndColumn + EndRow.ToString);

  sheet := objDocument.Sheets.getByIndex(PositionSheet);
  // getByName(aCollName);
  Charts := sheet.Charts;

  while Charts.hasByName(ChartName) do
  begin
    ChartName := ChartName + '_' + countChart.ToString;
    inc(countChart);
  end;

  Rect := objServiceManager.Bridge_GetStruct('com.sun.star.awt.Rectangle');
  RangeAddress := sheet.Bridge_GetStruct('com.sun.star.table.CellRangeAddress');

  Rect.Width := 12000;
  Rect.Height := 12000;
  Rect.X := 8000 * countChart + 1;
  Rect.Y := 1000;

  RangeAddress.sheet := PositionSheet;
  RangeAddress.StartColumn := Fields.getIndex(StartColumn);
  RangeAddress.StartRow := StartRow;
  RangeAddress.EndColumn := Fields.getIndex(EndColumn);
  RangeAddress.EndRow := EndRow;

  Charts.addNewByName(ChartName, Rect, VarArrayOf(RangeAddress), true, true);

  if typeChart <> ctDefault then
  begin
    Chart := Charts.getByName(ChartName).embeddedObject;
    Chart.Title.String := ChartName;
    case typeChart of
      ctVertical:
        Chart.Diagram.Vertical := true;
      ctPie:
        begin
          Chart.Diagram := Chart.createInstance
            ('com.sun.star.chart.PieDiagram');
          Chart.HasMainTitle := true;
        end;
      ctLine:
        begin
          Chart.Diagram := Chart.createInstance
            ('com.sun.star.chart.LineDiagram');
        end;
    end;
  end;

end;

function THelperOpenOffice.changeFont(aNameFont: string; aHeight: Integer)
  : TOpenOffice;
begin
  // Cell := Table.getCellRangeByName(aCollName+aCellNumber.ToString);
  Cell.CharFontName := aNameFont;
  Cell.CharHeight := inttostr(aHeight);
  result := self;
end;

function THelperOpenOffice.changeJustify(aTypeHori: THoriJustify;
  aTypeVert: TVertJustify): TOpenOffice;
begin
  Cell.HoriJustify := aTypeHori.toInteger;
  Cell.VertJustify := aTypeVert.toInteger;
  result := self;
end;

function THelperOpenOffice.CountRow: Integer;
var
  FRow, FCountRow: Integer;
  FCountBlank: Integer;
  FBreak, allBlank: boolean;
  I: Integer;
begin
  FBreak := false;
  FRow := 1;
  FCountRow := 0;
  FCountBlank := 0;

  while not FBreak do
  begin
    for I := 0 to 21 do
    begin
      if GetValue(FRow, Fields.getField(I)).Value.trim.IsEmpty then
      begin
        allBlank := true;
      end
      else
      begin
        if FCountBlank > 0 then // An empty column behind a valued column
          FCountRow := FCountRow + FCountBlank;

        allBlank := false;
        FCountBlank := 0;

        inc(FCountRow);
        break;
      end;
    end;
    inc(FRow);

    if FCountBlank = 50 then
      FBreak := true;

    if allBlank then
      inc(FCountBlank);

  end;
  result := FCountRow;
end;

function THelperOpenOffice.CountCell: Integer;
var
  FCell, FCountCell, FCountBlank: Integer;
  I: Integer;
  allBlank: boolean;
begin
  FCell := 1;
  FCountCell := 0;
  FCountBlank := 0;

  for I := 0 to 21 do
  begin
    for FCell := 1 to 10 do
    begin
      if not GetValue(FCell, Fields.getField(I)).Value.trim.IsEmpty then
      begin

        if FCountBlank > 0 then
          FCountCell := FCountCell + FCountBlank;

        allBlank := false;

        inc(FCountCell);
        break;
      end
      else
        allBlank := true;
    end;

    if FCountBlank = 10 then
    begin
      FCountBlank := 0;
      break;
    end;

    if allBlank then
      inc(FCountBlank);
  end;

  result := FCountCell;
end;

function THelperOpenOffice.seTBorder(borderPosition: TBoderSheet; opColor: TOpenColor; RemoveBorder: boolean): TOpenOffice;
var
  border: Variant;
  settings: Variant;
begin
  border := ServicesManager.createInstance('com.sun.star.reflection.CoreReflection');
  border.forName('com.sun.star.table.BorderLine2').createObject(settings);

 if not RemoveBorder then
  begin
    settings.Color := opColor;
    settings.InnerLineWidth := 20;
    settings.LineDistance := 60;
    settings.LineWidth := 2;
    settings.OuterLineWidth := 20;
  end else
  begin
    settings.Color := 0;
    settings.InnerLineWidth := 0;
    settings.LineDistance := 0;
    settings.LineWidth := 0;
    settings.OuterLineWidth := 0;
  end;

  if bAll in borderPosition then
  begin
    Cell.TopBorder := settings;
    Cell.LeftBorder := settings;
    Cell.RightBorder := settings;
    Cell.BottomBorder := settings;
  end;

  if bTop in borderPosition then
    Cell.TopBorder := settings;

  if bLeft in borderPosition then
    Cell.LeftBorder := settings;

  if bRight in borderPosition then
    Cell.RightBorder := settings;

  if bBottom in borderPosition then
    Cell.BottomBorder := settings;

  result := self;
end;

function THelperOpenOffice.setColor(aFontColor, aBackgroud: TOpenColor)
  : TOpenOffice;
begin
  Cell.CharColor := aFontColor;
  Cell.CellBackColor := aBackgroud;
  result := self;
end;

function THelperOpenOffice.setBold(aBold: boolean): TOpenOffice;
begin
  Cell.CharWeight := ifthen(aBold, 150, 0);
  result := self;
end;

function THelperOpenOffice.SetUnderline(aUnderline: boolean): TOpenOffice;
begin
  Cell.CharUnderline := ifthen(aUnderline, 1, 0);
  result := self;
end;

{ THelperOpenOffice }

function THelperHoriJustify.toInteger: Integer;
begin
  case self of
    fthSTANDARD:
      result := 0;
    fthLEFT:
      result := 1;
    fthCENTER:
      result := 2;
    fthRIGHT:
      result := 3;
    fthBLOCK:
      result := 4;
    fthREPEAT:
      result := 5;
  end;
end;

{ THelperVertJustify }

function THelperVertJustify.toInteger: Integer;
begin
  case self of
    ftvSTANDARD:
      result := 0;
    ftvTOP:
      result := 1;
    ftvCENTER:
      result := 2;
    ftvBOTTOM:
      result := 3;
  end;
end;

end.
