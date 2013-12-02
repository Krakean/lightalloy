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
unit Filter;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Registry,
  Dialogs, StdCtrls, ActiveX, ComCtrls, DirectShow9;

const
  IID_IPropertyBag :TGUID = '{55272A00-42CB-11CE-8135-00AA004BB851}';
  IID_IPersist     :TGUID = '{0000010C-0000-0000-C000-000000000046}';

type
  TfrFilter = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    lbFilters: TListBox;
    procedure lbFiltersDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbFiltersDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure frFilterClose(Sender: TObject);
  private
    function IsStdFilter(CLSID:String):Boolean;
  public
    Selected:TGUID;

    procedure Init;
    procedure EnumFilters;
    function SelectFilter:TGUID;
  end;

var
  frFilter: TfrFilter;

implementation

uses
  DShowHlp;

{$R *.dfm}

procedure TfrFilter.EnumFilters;
var
  CDEnum:ICreateDevEnum;
  EnumMon:IEnumMoniker;
  Moniker:IMoniker;
  Fetched:LongInt;
  PropBag:IPropertyBag;
  varName:OleVariant;
  s:string;
begin
  DSH.E(CoCreateInstance(CLSID_SystemDeviceEnum,NIL,CLSCTX_INPROC_SERVER,
    IID_ICreateDevEnum,CDENum),'CoCreateInstance(CLSID_SystemDeviceEnum)');
  DSH.E(CDENum.CreateClassEnumerator(CLSID_LegacyAmFilterCategory,EnumMon,0),'CDENum.CreateClassEnumerator()');

  if Assigned(EnumMon) then begin
    while (EnumMon.Next(1,Moniker,@Fetched)=S_OK) do begin
      s:='CLSID';
      if SUCCEEDED(Moniker.BindToStorage(NIL,NIL,IID_IPropertyBag,PropBag)) then begin
        s:='Noname';
        if SUCCEEDED(PropBag.Read('FriendlyName',varName,NIL)) then s:=varName;
        if SUCCEEDED(PropBag.Read('CLSID',varName,NIL)) then begin
          s:=s+varName;
          if not(IsStdFilter(varName)) then
            lbFilters.Items.Add(s);
        end;
        PropBag:=NIL;
        Moniker:=NIL;
      end;
    end;
  end;

  EnumMon:=NIL;
  CDEnum:=NIL;
end;

function TfrFilter.SelectFilter;
var
  s:string;
begin
  EnumFilters;
  Result:=GUID_NULL;
  if (ShowModal=mrOk) then
    if (lbFilters.ItemIndex>=0) then
      try
        s:=lbFilters.Items[lbFilters.ItemIndex];
        s:=Copy(s,Length(s)-37,38);
        Result:=StringToGUID(s);
      except
        Result:=GUID_NULL;
      end;
end;

procedure TfrFilter.lbFiltersDrawItem;
var
  s:string;
begin
  with lbFilters.Canvas do begin
    s:=lbFilters.Items[Index];
    TextRect(Rect,Rect.Left+2,Rect.Top+1,Copy(s,1,Length(s)-38));
  end;
end;

procedure TfrFilter.lbFiltersDblClick;
begin
  ModalResult:=mrOK;
end;

function TfrFilter.IsStdFilter;
var
  R:TRegistry;
  ModuleName:string;
begin
  Result:=False;
  R := TRegistry.Create;
  R.RootKey:=HKEY_LOCAL_MACHINE;
  if R.KeyExists('\SOFTWARE\Classes\CLSID\'+CLSID+'\InprocServer32') then
  begin
    R.OpenKeyReadOnly('\SOFTWARE\Classes\CLSID\'+CLSID+'\InprocServer32');
    ModuleName:=R.ReadString('');
    // Other system directshow libraries also must be here
    if ExtractFileName(ModuleName) = 'quartz.dll' then Result:=True;
    R.CloseKey;
  end;
end;

procedure TfrFilter.Init;
begin
  EnumFilters;
  Selected:=GUID_NULL;
end;

procedure TfrFilter.FormClose(Sender: TObject; var Action: TCloseAction);
var
  S:String;
begin
  Selected:=GUID_NULL;
  if (lbFilters.ItemIndex>=0) then
    try
      s:=lbFilters.Items[lbFilters.ItemIndex];
      s:=Copy(s,Length(s)-37,38);
      Selected:=StringToGUID(s);
    except
    end;
end;

procedure TfrFilter.frFilterClose(Sender: TObject);
begin
  Close;
end;

end.
