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
unit codecs;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DirectShow9, DShowHlp, ActiveX, MMSystem, ShellAPI;

type
  TfrCodecs = class(TForm)
    btOK: TButton;
    lbNoCodec: TLabel;
    lbLink: TLabel;
    Image1: TImage;
    procedure btOKClick(Sender: TObject);
    procedure lbLinkClick(Sender: TObject);
    procedure BtnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
    FileName:string;
    procedure CheckPins;
    procedure CheckFile;
    procedure ShowRequest(Request:string);
  end;

var
  frCodecs: TfrCodecs;

implementation

{$R *.DFM}

uses MainUnit;

{ TfrCodecs }

procedure TfrCodecs.CheckFile;
var
  MediaDet:IMediaDet;
  Streams,i:LongInt;
  guid:TGUID;
  AM:TAMMEDIATYPE;
  Request:string;
begin
  Request:='';

  try
    DSH.E(CoCreateInstance(CLSID_MediaDet,NIL,CLSCTX_INPROC,IID_IMediaDet,MediaDet),'CoCreateInstance(CLSID_MediaDet)');
    DSH.E(MediaDet.put_FileName(FileName),'MediaDet.put_FileName');
    DSH.E(MediaDet.get_OutputStreams(Streams),'MediaDet.get_OutputStreams');
    for i:=0 to Streams-1 do begin
      DSH.E(MediaDet.put_CurrentStream(i),'MediaDet.put_CurrentStream');
      DSH.E(MediaDet.get_StreamType(guid),'MediaDet.get_StreamType');
      DSH.E(MediaDet.get_StreamMediaType(AM),'MediaDet.get_StreamMediaType');
      if IsEqualGUID(guid,KSDATAFORMAT_TYPE_VIDEO) then begin
        if IsEqualGUID(AM.FormatType,FORMAT_VideoInfo) then begin
          Request:=Format('vidc=%.8x',[AM.SubType.D1]);
          Break;
        end;
      end;
      if frMain.IsSoundCard and IsEqualGUID(guid,KSDATAFORMAT_TYPE_AUDIO) then begin
        if IsEqualGUID(AM.FormatType,FORMAT_WaveFormatEx) then
          with TWAVEFORMATEX(AM.pbFormat^) do begin
            Request:=Format('audc=%.4x',[wFormatTag]);
            Break;
          end;
      end;
      DSH.FreeMediaType(AM);
    end;
    MediaDet:=NIL;
  except
  end;
  if (Request<>'') then ShowRequest(Request);
end;

procedure TfrCodecs.btOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfrCodecs.lbLinkClick(Sender: TObject);
begin
  ShellExecute(0,NIL,PChar(lbLink.Caption),NIL,NIL,SW_MAXIMIZE);
end;

procedure TfrCodecs.CheckPins;
var
  Pin:IPin;
  Request:string;
  PAM:PAMMEDIATYPE;
  MediaTypes:IEnumMediaTypes;
  Fetched:LongInt;
begin
  Request:='';
  Pin:=DSH.FindUnconnectedPin;
  if Assigned(Pin) then begin
    DSH.E(Pin.EnumMediaTypes(MediaTypes),'Pin.EnumMediaTypes');
    while (Request='') and (MediaTypes.Next(1,PAM,@Fetched)=S_OK) do begin
      if IsEqualGUID(PAM^.MajorType,MEDIATYPE_VIDEO) then
        if IsEqualGUID(PAM^.FormatType,FORMAT_VideoInfo) then
          Request:=Format('vidc=%.8x',[PAM.SubType.D1]);

      if frMain.IsSoundCard and IsEqualGUID(PAM^.MajorType,MEDIATYPE_AUDIO) then
        if IsEqualGUID(PAM^.FormatType,FORMAT_WaveFormatEx) then
          with TWAVEFORMATEX(PAM^.pbFormat^) do
            Request:=Format('audc=%.4x',[wFormatTag]);

      DSH.DeleteMediaType(PAM);
    end;
    MediaTypes:=NIL;
  end;
  Pin:=NIL;
  if (Request<>'') then ShowRequest(Request);
end;

procedure TfrCodecs.ShowRequest;
begin
  if (Request='') then Exit;
  lbLink.Caption:='http://www.light-alloy.ru/filters/?'+Request;
  ShowModal;
end;

procedure TfrCodecs.BtnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) or (Key = VK_SPACE) then frCodecs.Close;
end;

end.
