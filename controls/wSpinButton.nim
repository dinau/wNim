## A wSpinButton has two small up and down (or left and right) arrow buttons.
##
## :Superclass:
##    wControl
##
## :Styles:
##    ==============================  =============================================================
##    Styles                          Description
##    ==============================  =============================================================
##    wSpVertical                     Specifies a vertical spin button.
##    wSpHorizontal                   Specifies a horizontal spin button.
##    ==============================  =============================================================
##
## :Events:
##    ==============================  =============================================================
##    wSpinEvent                      Description
##    ==============================  =============================================================
##    wEvent_Spin                     Pressing an arrow.
##    wEvent_SpinUp                   Pressing up arrow.
##    wEvent_SpinDown                 Pressing down arrow.
##    wEvent_SpinLeft                 Pressing left arrow.
##    wEvent_SpinRight                Pressing right arrow.
##    ==============================  =============================================================

const
  wSpVertical* = 0
  wSpHorizontal* = UDS_HORZ

proc isVertical*(self: wSpinButton): bool {.validate, inline.} =
  ## Returns true if the spin button is vertical and false otherwise.
  result = (GetWindowLongPtr(mHwnd, GWL_STYLE) and UDS_HORZ) == 0

method getDefaultSize*(self: wSpinButton): wSize {.property.} =
  ## Returns the default size for the control.
  let isVert = isVertical()
  result.width = GetSystemMetrics(if isVert: SM_CXVSCROLL else: SM_CXHSCROLL)
  result.height = GetSystemMetrics(if isVert: SM_CYVSCROLL else: SM_CYHSCROLL)
  if isVert:
      result.height *= 2
  else:
      result.width *= 2

method getBestSize*(self: wSpinButton): wSize {.property, inline.} =
  ## Returns the best acceptable minimal size for the control.
  result = getDefaultSize()

proc wSpinButton_OnNotify(self: wSpinButton, event: wEvent) =
  var processed = false
  defer: event.skip(if processed: false else: true)

  let lpnmud = cast[LPNMUPDOWN](event.lParam)
  if lpnmud.hdr.hwndFrom == mHwnd and lpnmud.hdr.code == UDN_DELTAPOS:
    var
      spinEvent = Event(window=self, msg=wEvent_Spin, wParam=event.wParam, lParam=event.lParam)
      directionMsg = 0

    if isVertical():
      if lpnmud.iDelta > 0: directionMsg = wEvent_SpinDown
      elif lpnmud.iDelta < 0: directionMsg = wEvent_SpinUp
    else:
      if lpnmud.iDelta > 0: directionMsg = wEvent_SpinLeft
      elif lpnmud.iDelta < 0: directionMsg = wEvent_SpinRight

    if directionMsg != 0:
      spinEvent.mMsg = directionMsg
      processed = self.processEvent(spinEvent)

    if not processed:
      spinEvent.mMsg = wEvent_Spin
      processed = self.processEvent(spinEvent)

    if processed:
      event.result = spinEvent.result

proc init(self: wSpinButton, parent: wWindow, id: wCommandID = -1, pos = wDefaultPoint,
    size = wDefaultSize, style: wStyle = 0) =

  # up-down control without buddy window cannot have a focus
  # (in fact, it do have a focus but without any visual change)
  # so UDS_ARROWKEYS have no use here. How to fix?
  # since that, just don't add WS_TAB

  self.wControl.init(className=UPDOWN_CLASS, parent=parent, id=id, pos=pos, size=size,
    style=style or UDS_HOTTRACK or WS_CHILD or WS_VISIBLE)

  parent.hardConnect(WM_NOTIFY) do (event: wEvent):
    wSpinButton_OnNotify(self, event)

proc SpinButton*(parent: wWindow, id: wCommandID = wDefaultID, pos = wDefaultPoint,
    size = wDefaultSize, style: wStyle = wSpVertical): wSpinButton {.discardable.} =
  ## Constructor, creating and showing a spin button.
  wValidate(parent)
  new(result)
  result.init(parent=parent, id=id, pos=pos, size=size, style=style)