section	.text
    global mdiv     
	
mdiv:	                          
    mov r8, rdx                   ; zapisuje dzielnik (y) w r8, 
                                  ; podany wczesniej w rdx
    mov r9, 1                     ; powie mi czy dzielna jest ujemna 
    ; 0 - ujemna, 1 - dodatnia, gdy y = 0 mamy special case
    mov r10, 1                    ; powie mi czy dzielnik jest ujemny

    ; pierwszy bit (ostatniej komorki) powie czy cala jest dodatnia czy
    ; ujemna
    mov r11, [rdi + rsi*8 - 8]
    test r11, r11                 ; jesli dzielna jest ujemna,
    js negation_array             ; wpp kontynuuj

check_divisor:
    ; sprawdzam pierwszy bit dzielnika czy ujemny czy dodatni (czyli znak)
    test r8, r8
    js negation_divisor           ; jesli ujemny dzielnik, a jesli nie to:
    ; teraz pora ustawic rcx i rdx i przechodzimy do glownego algorytmu

loop_main_prepair:
    mov rcx, rsi                  ; liczba n znajduje sie w rsi, 
                                  ; daje do rcx dla petli
    mov rdx, 0                    ; *poczatkowo reszta wynosi 0 
    ; o co chodzi z reszta? Moj algorytm dziala tak, ze dzieli 
    ; kolejne komorki tablicy, iloraz zapisuje do tablicy zgodnie z poleceniem
    ; natomiast reszte daje do rdx, do rax kolejna komorke tablicy i wykonuje
    ; dzielenie, reszta do rdx, kolejna komorka do rax itd. Poczatkowo dzielac
    ; pierwsza komorke nie ma oczywiscie reszty z dzielenia poprzedniej

loop_main:
    mov rax, [rdi + rcx*8 - 8]    ; do rax wstawiam komorke tablicy 
                                  ; poczatkowo ostatnia potem przedost.. itd.
    div r8                        ; dziele pare rdx:rax przez y
    ; reszta jest w rdx, iloraz w rax
    mov [rdi + rcx*8 - 8], rax    ; iloraz do tablicy x, do aktualnej komorki

    dec rcx                       ; zmniejszam loop countera                    
    jnz loop_main                 ; i tak n razy wykonuje petle
                                  ; poki rcx != 0

    cmp r9, 1 
    je check_second_condition     ; dzielna jest dodatnia

    cmp r10, 1  
    je negation_array             ; r9 bylo rowne 0, zatem jesli r10 = 1 
                                  ; to nalezy zamienic iloraz na przeciwny

    ; r9 = 0 i r10 = 0, zatem reszta powinna byc ujemna, iloraz dodatni
    jmp negation_rest

negation_array:                   ; odwraca liczbe na przeciwna
    ; zaczynam od 1. komorki, najmniej znaczacych bitow
    ; warto zrozumiec ze etykieta ta jest wywolywana w dwoch przypadkach:
    ; na poczatku gdy podana dzielna jest ujemna to nalezy zamienic ja na
    ; dodatnia (zeby div dobrze zadzialal), a w drugim przypadku gdy
    ; iloraz zapisany w x powinien byc ujemny. W 1. przypadku r9 ustawione
    ; jest na 1 i nalezy zmienic je na 0 gdyz dzielna jest ujemna, gdy 
    ; natomiast przed podaniem wyniku okaze sie ze zaszedl przypadek,
    ; w ktorym iloraz powinien byc ujemny, na pewno chodz jeden z rejestrow 
    ; r9 i r10 musi byc rowny 0 (dzielnik xor dzielna byla/byl ujemna/y)
    not qword [rdi]               ; negacja bitow
    add qword [rdi], 1            ; zwieksz o 1
    setc r11b                     ; r11b = 1 gdy nastapilo przeniesienie 
    mov rcx, 1                    ; sprawdzilem 0. el tablicy, teraz 1. itd.
    cmp rcx, rsi
    jne loop_opposite

    cmp r9, 0                     ; przeczytaj dlugi komentarz wyzej 
    je negation_rest              ; gdy dzielna jest ujemna to i reszta
    cmp r10, 0
    je end                        ; skoro r9 = 1 to reszta dodatnia     

    xor r9, r9                    ; skoro ta petla sie "odpalila"
    ; znaczy ze dzielna jest ujemna, wiec r9 ustawiam na 0 
    ; dzielna ustawiona, teraz kolei na dzielnik
    jmp is_minimal

loop_opposite:
    not qword [rdi + rcx*8]       ; neguje bity w kolejnej komorce
    add [rdi + rcx*8], r11b       ; jesli nastapilo przeniesienie to zwieksz
                                  ; liczbe w tej komorce o 1
    setc r11b                     ; r11b = 0 gdy nie nastapilo przeniesienie 
    inc rcx                       ; zwiekszam loop countera      
    cmp rcx, rsi                  ; chce aby petla wykonala sie rsi razy
    ; w rsi trzymam n oczywiscie
    jne loop_opposite 

    cmp r9, 0                ; przeczytaj dlugi komentarz z negation_array
    je negation_rest         ; gdy dzielna jest ujemna to na pewno i reszta
    cmp r10, 0
    je end                   ; skoro r9 = 1 to reszta dodatnia i mozna konczyc     
    
    xor r9, r9               ; patrz komentarz z negation_array
    jmp is_minimal

negation_divisor: 
    neg r8
    
    xor r10, r10                  ; dzielnik jest negatywny
    ; mamy ustalona reszte, teraz glowny algorytm:
    jmp loop_main_prepair         ; nalezy odpowiednio ustawic rdx i rcx

check_second_condition:
    ; r9 = 1:
    cmp r10, 0
    je negation_array             ; trzeba zamienic iloraz na przeciwny

    ; r9 = 1 i r10 = 1, zatem mozemy juz zwrocic wynik
    jmp end

negation_rest:
    neg rdx                    

end:
    mov rax, rdx                  ; reszta jest wynikiem funkcji
    ret

is_minimal:
    mov r11, [rdi + rsi*8 - 8]    ; r11 nie jest juz 
    ; potrzebny, bo jest juz po negacji dzielnej do ktorej byl potrzebny
    test r11, r11                 ; gdy najwazniejszy bit 
    ; nadal jest zapalony oznacza to ze dzielna jest najmniejsza liczba
    ; ujemna, jesli dzielnik jest wtedy = -1 to mamy SIGFPE
    jns check_divisor

    ; gdy mamy dzielenie najmniejszej
    ; dzielnej przez dzielnik rowny -1 to chcemy wyslac SIGFPE
    cmp r8, 0xFFFFFFFFFFFFFFFF 
    jne check_divisor

    xor r8, r8                    ; zwykle dzielenie przez 0 zeby dostac
    div r8                        ; SIGFPE