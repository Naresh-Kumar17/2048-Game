main PROC
    call InitRandom          ; once, before the menu, never per game
menuTop:
    call ShowMenu
    ...
newGame:
    call AskBoardSize        ; Burhan, M2
    call Clrscr
    call InitBoard           ; Burhan, M2
    call SpawnTile           ; Naresh, M7: two starting tiles
    call SpawnTile