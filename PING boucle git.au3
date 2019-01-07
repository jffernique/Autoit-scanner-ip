#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#pragma compile(AutoItExecuteAllowed, True)


#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <GuiIPAddress.au3>
#include <ListViewConstants.au3>
#include <GuiImageList.au3>

Opt("GUIOnEventMode", 1)


; Variables à changer #########################################################################
Global $sTitle = " Status" ; titre de la GUI
Global $iW = 300, $iH = 1000 ; taille de la GUI
Global $iTimeOut = 1000 ; Timeout du Ping
Global $iMaxRunningProcess = 10 ; nombre de Ping simultanés
Global $sTextStart = "Ping", $sTextStop = "Stop", $sTextStopping = "Arrêt...", $sTextRunning = "En cours" ; texte de la GUI
Global $iColorStatus1 = 0xFFFFFF, $iColorStatus2 = 0x999999, $iColorStatus3 = 0x00ff33, $iColorStatus4 = 0xff0000 ; couleurs des vignettes
Global $sTempFile = @TempDir & "\MultiPingsofrelAU3.ini" ; fichier INI temporaire qui stocke les résultats
; #############################################################################################

Global $iRunning = 0
Global $aPingRunning
Global $iRunningCount = 0

Global $hGui = GUICreate($sTitle, $iW, $iH)
;Global $hIPAddress = _GUICtrlIpAddress_Create ( $hGui, 10, 10, 125, 20)

;Global $ID_Add = GUICtrlCreateButton( ChrW (0xBB), 140, 10, 20, 20)

Global $ID_Listview = GUICtrlCreateListView("Adresse IP|Resultat", 10, 10, 250, 960, BitOR($LVS_NOCOLUMNHEADER, $LVS_SORTASCENDING) )
_GUICtrlListView_SetColumnWidth ( $ID_Listview, 0, 145 )

Global $ID_Go = GUICtrlCreateButton($sTextStart, 50, 970, 140, 25)

;Global $ID_Remove = GUICtrlCreateButton( ChrW (0xAB), 210, 740, 20, 20)

;GUICtrlSetTip($ID_Add, "Ajouter l'adresse IP à  la liste")
;GUICtrlSetTip($ID_Remove, "Supprimer l'adresse IP sélectionnée de la liste")


Global $hImage = _GUIImageList_Create()
_GUIImageList_Add($hImage, _GUICtrlListView_CreateSolidBitMap($ID_Listview, $iColorStatus1, 16, 16)) ; en attente
_GUIImageList_Add($hImage, _GUICtrlListView_CreateSolidBitMap($ID_Listview, $iColorStatus2, 16, 16)) ; en cours
_GUIImageList_Add($hImage, _GUICtrlListView_CreateSolidBitMap($ID_Listview, $iColorStatus3, 16, 16)) ; ping
_GUIImageList_Add($hImage, _GUICtrlListView_CreateSolidBitMap($ID_Listview, $iColorStatus4, 16, 16)) ; ping pas
_GUICtrlListView_SetImageList($ID_Listview, $hImage, 1)


; Pré-remplissage #################################################
;_GUICtrlListView_AddItem ( $ID_Listview, @IPAddress1, 0)
_GUICtrlListView_AddItem ( $ID_Listview, "www.google.fr",0)
_GUICtrlListView_AddItem ( $ID_Listview, "www.yahoo.fr",0)
_GUICtrlListView_AddItem ( $ID_Listview, "www.github.com",0)


; #################################################################


GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
;GUICtrlSetOnEvent($ID_Add, "_AddIP")
;GUICtrlSetOnEvent($ID_Remove, "_RemoveIP")
GUICtrlSetOnEvent($ID_Go, "_Go")

GUISetState()
GUICtrlSetData($ID_Go, $sTextStop)
While 1
	_go()
    ;Sleep(0xFFFF)
	sleep(10000)
WEnd



Func _Go()
    Local $sIP, $iPing, $iResult

    If $iRunning Then Return _StopPing()

    $iRunning = 1
    ;;GUICtrlSetData($ID_Go, $sTextStop)
    ;ControlDisable($hGui, "", $hIPAddress)
    ;GUICtrlSetState($ID_Add, $GUI_DISABLE)
    ;GUICtrlSetState($ID_Remove, $GUI_DISABLE)

    FileDelete($sTempFile)
    Local $iCount = _GUICtrlListView_GetItemCount ( $ID_Listview )

    Local $aTemp[$iCount][3]
    $aPingRunning = $aTemp

    For $i = 0 To $iCount - 1
        $sIP = _GUICtrlListView_GetItemText($ID_Listview, $i)
        $aPingRunning[$i][0] = $sIP
    Next
    AdlibRegister("_PingProcess", 500)
EndFunc




Func _PingProcess()
    Local $iResult

    For $i = 0 To UBound($aPingRunning) - 1
        If $aPingRunning[$i][2] == "" Then
            If $aPingRunning[$i][1] = ""  Then
                If $iRunningCount < $iMaxRunningProcess AND $iRunning Then
                    $aPingRunning[$i][1] = Run(@AutoItExe & ' /AutoIt3ExecuteLine "IniWrite(''' & $sTempFile & ''', ''RUNNING'', ''' & $aPingRunning[$i][0] & ''', Ping(''' & $aPingRunning[$i][0] & ''', ' & $iTimeOut & ') )"')
                    $iRunningCount += 1
                    _GUICtrlListView_SetItemImage ( $ID_Listview, $i, 1)
                    _GUICtrlListView_SetItemText($ID_Listview, $i, $sTextRunning, 1)
                EndIf
            Else
                If NOT ProcessExists($aPingRunning[$i][1]) Then
                    $iRunningCount -= 1
                    $iResult = Number(IniRead($sTempFile, "RUNNING", $aPingRunning[$i][0], "0"))
                    $aPingRunning[$i][2] = $iResult

                    If $iResult Then
                        $sRes = $iResult & " ms"
                    Else
                        $sRes = "-"
                    EndIf
                    _GUICtrlListView_SetItemText($ID_Listview, $i, $sRes, 1)
                    _GUICtrlListView_SetItemImage ( $ID_Listview, $i,     ( $iResult ? 2 : 3)     )
                EndIf
            EndIf

        EndIf
    Next

    If $iRunningCount = 0 Then
        AdlibUnRegister("_PingProcess")
        FileDelete($sTempFile)
        _EndPing()
    EndIf

    Return $iRunningCount
EndFunc



Func _StopPing()
    AdlibUnRegister("_PingProcess")
    GUICtrlSetData($ID_Go, $sTextStopping)
    GUICtrlSetState($ID_Go, $GUI_DISABLE)

    AdlibRegister("_PingProcessWait")
EndFunc





Func _PingProcessWait()
    If NOT _PingProcess() Then
        _EndPing()
        AdlibUnRegister("_PingProcessWait")
    EndIf
EndFunc





Func _EndPing()
    $iRunning = 0
    GUICtrlSetData($ID_Go, $sTextStart)
    GUICtrlSetState($ID_Go, $GUI_ENABLE)
    ;ControlEnable($hGui, "", $hIPAddress)
    ;GUICtrlSetState($ID_Remove, $GUI_ENABLE)
    ;GUICtrlSetState($ID_Add, $GUI_ENABLE)
EndFunc






Func _Exit()
    Exit
EndFunc
