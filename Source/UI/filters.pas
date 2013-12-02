///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit Filters;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls, ExtCtrls,

  DirectShow9, FilterBox, FilterCommander, FilterBase;

type
  TfrFilters = class(TForm)
    cbStopBeforeProps: TCheckBox;
    btFilterProps: TButton;
    pnFltBox: TPanel;
    mmProps: TMemo;
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btFilterPropsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FltBox:TFilterBox;

    procedure FilterDialog(Filter:IBaseFilter);
    procedure TuneLang;
    procedure FillProps;
    procedure OnFilter(Sender:TObject);
    function MeritText(Merit:DWORD):String;
  public
    procedure RefreshList;
    function GetFilterByName(FilterName:string):IBaseFilter;
  end;

var
  frFilters: TfrFilters;

implementation

uses
  MainUnit, DShowHlp, LACore;

{$R *.DFM}

{ TfrFilters }

procedure TfrFilters.RefreshList;
begin
  btFilterProps.Enabled:=FALSE;

  mmProps.Clear;
  if Assigned(DSH.Graph) then
    FltBox.EnumGraph(DSH.Graph);
end;

procedure TfrFilters.FormKeyUp;
begin
  if (Key=VK_ESCAPE) then Close;
end;

function TfrFilters.GetFilterByName;
var
  FEnum:IEnumFilters;
  Filter:IBaseFilter;
  Fetched:LongInt;
begin
  Result:=NIL;

  DSH.Graph.EnumFilters(FEnum);
  while (FEnum.Next(1,Filter,@Fetched)=S_OK) do begin
    if SameText(DSH.GetFilterName(Filter),FilterName) then begin
      Result:=Filter;
      Filter:=NIL;
    end;
  end;
  FEnum:=NIL;
end;

procedure TfrFilters.btFilterPropsClick(Sender: TObject);
var
  Filter:IBaseFilter;
begin
  if not(btFilterProps.Enabled) then Exit;

  Filter:=FltBox.GetFocusedFilter;
  if (Filter=NIL) then Exit;

  FilterDialog(Filter);

  Filter:=NIL;
end;

procedure TfrFilters.TuneLang;
begin
  Caption:=MS('Filters');
  btFilterProps.Caption:=MS('Filters.PropertiesDialog');
    cbStopBeforeProps.Caption:=MS('Filters.StopBeforeChange')
end;

procedure TfrFilters.FormCreate(Sender: TObject);
begin
  FltBox:=TFilterBox.Create(Self);
  with FltBox do begin
    Parent:=pnFltBox;
    Align:=alClient;
    OnSelectFilter:=OnFilter;
    OnFilterDblClick:=btFilterPropsClick;
  end;

  TuneLang;

  mmProps.Width:=Width*35 div 100;
  mmProps.Height:=Height-100;

  pnFltBox.Left:=mmProps.Width+8;
  pnFltBox.Width:=Width-12-pnFltBox.Left;

  btFilterProps.Top:=Height-90;
  cbStopBeforeProps.Top:=Height-60;
end;

procedure TfrFilters.FormDestroy(Sender: TObject);
begin
  FltBox.Free;
end;

procedure TfrFilters.FillProps;
var
  Filter:IBaseFilter;
  CLSID:TGUID;
  FltCmd:TFilterCommander;
  FInfo:TFilterInf;

  Name, ID, FriendlyName, Merit, FileName, Module, Status, Company: string;
begin
  mmProps.Clear;

  Filter:=FltBox.GetFocusedFilter;
  if (Filter=NIL) then Exit;

  Name:=DSH.GetFilterName(Filter);
  CLSID:=DSH.GetCLSID(Filter);
  ID:=GUIDTOString(CLSID);

  FltCmd:=TFilterCommander.Create;
  if not(IsEqualGUID(CLSID,GUID_NULL)) then begin
    FltCmd.ExamineFilter(CLSID);

    FriendlyName:=FltCmd.FriendlyName;
    Merit:=Format('0x%.8X (%s)',[FltCmd.Merit,MeritText(FltCmd.Merit)]);
    FileName:=ExtractFileName(FltCmd.ModuleName);
    Module:=FltCmd.ModuleName;
    Status:='System';
    Company:=FltCmd.Company;
  end;
  FltCmd.Free;

  if DSH.FLibrary.ActiveLocalFilters.GetFInfo(CLSID,FInfo) then begin
    FriendlyName:=FInfo.NAME;
    FileName:=FInfo.FILENAME;
    Module:=FInfo.LOCALPATH;
    Status:='Local';
    Company:=FltCmd.GetCompanyName(FInfo.LOCALPATH);
  end;

  with mmProps.Lines do begin
    Add('Name: '+Name);
    Add('CLSID: '+ID);
    Add('FriendlyName: '+FriendlyName);
    Add('Merit: '+Merit);
    Add('FileName: '+FileName);
    Add('Module: '+Module);
    Add('Filter: '+Status);
    Add('Manufacturer: '+Company);
  end;

  Filter:=NIL;
end;

procedure TfrFilters.OnFilter(Sender: TObject);
var
  Filter:IBaseFilter;
begin
  FillProps;

  Filter:=FltBox.GetFocusedFilter;
  if (Filter=NIL) then Exit;

  btFilterProps.Enabled:=DSH.HasProperties(Filter);
  Filter:=NIL;
end;

function TfrFilters.MeritText(Merit: DWORD): String;
begin
  Result:='Special case';

  if (Merit>=$200000) then Result:='Avoid';
  if (Merit>=$400000) then Result:='Unlikely';
  if (Merit>=$600000) then Result:='Normal';
  if (Merit>=$800000) then Result:='High';

{
    MERIT_PREFERRED     = 0x800000,
    MERIT_NORMAL        = 0x600000,
    MERIT_UNLIKELY      = 0x400000,
    MERIT_DO_NOT_USE    = 0x200000,
    MERIT_SW_COMPRESSOR = 0x100000,
    MERIT_HW_COMPRESSOR = 0x100050
}
end;

procedure TfrFilters.FilterDialog;
begin
  if cbStopBeforeProps.Checked then
    DSH.MediaControl.Stop;

  if Assigned(Filter) then
    DSH.FilterProperties(Handle,Filter);

  SetForeGroundWindow(Self.Handle);
  frMain.RestoreState;
end;

end.
