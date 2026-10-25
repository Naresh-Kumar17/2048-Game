InitRandom   PROTO                      ; call once at startup
CountEmpty   PROTO                      ; EAX = number of empty cells
FindNthEmpty PROTO, n:DWORD             ; EAX = cell index, or -1
SpawnTile    PROTO                      ; EAX = 1 placed, 0 board full
