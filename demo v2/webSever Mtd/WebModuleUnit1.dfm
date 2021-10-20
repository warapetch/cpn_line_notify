object WebModule1: TWebModule1
  OldCreateOrder = False
  Actions = <
    item
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end
    item
      Default = True
      Name = 'WebActionItem1'
      PathInfo = '/callback'
      OnAction = WebModule1WebActionItem1Action
    end>
  Height = 230
  Width = 415
  object DSServer1: TDSServer
    Left = 96
    Top = 11
  end
  object DSHTTPWebDispatcher1: TDSHTTPWebDispatcher
    Server = DSServer1
    Filters = <>
    WebDispatch.PathInfo = 'datasnap*'
    Left = 96
    Top = 75
  end
end
