section .data
; tablica z kodami Morse'a, po pierwszym "db" mamy litery a po drugim cyfry
morse_codes db ".-", "-...", "-.-.", "-..", ".", "..-.", \
            "--.", "....", "..", ".---", "-.-", ".-..", \
            "--", "-.", "---", ".--.", "--.-", ".-.", \
            "...", "-", "..-", "...-", ".--", "-..-", \
            "-.--", "--.."                
            db "-----", ".----", "..---", "...--", \
            "....-", ".....", "-....", "--...", "---..", \
            "----." 

; tablica długości kodów Morse'a (liczba znaków dla kolejnych liter i liczb)
; i ponownie po pierwszym "db" mamy długości liter a po drugim cyfr
morse_lens  db 2, 4, 4, 3, 1, 4, 3, 4, 2, 4, 3, 4, 2, 2, \
            3, 4, 4, 3, 3, 1, 3, 4, 3, 4, 4, 4
            db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

letters     db 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', \
            'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', \
            'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
            db '0', '1', '2', '3', '4', '5', '6', '7', \
            '8', '9'

section .bss
input resb 4096             ; bufor wejścia
output resb 4096            ; bufor wyjścia
one_code resb 6             ; bufor na kod Morse'a (5 znaków - najdłuższy kod)

section .text
global _start

_start:
    ; zapisz wskaźnik na wyjście i i zrób odczyt (stdin)
    mov rdi, output          ; w rdi wskaźnik na wyjście

; Czyta strumień danych na standardowym wejściu i przekazuje 
; do bufora wejścia
reading:
    mov r9, rdi              ; zapamiętaj wskaźnik na wyjście (**)

    ; Wczytaj dane wejściowe
    mov eax, 0               ; sys_read
    mov edi, 0               ; stdin
    mov rsi, input           ; wskaźnik na wejście
    mov edx, 4096            ; liczba bajtów do odczytu
    syscall

    mov rdi, r9              ; przywracam (**)

    ; Sprawdź poprawność odczytu (sys_read)
    test rax, rax
    js error
    ; Jeśli operacja sys_read zwróci 0 (koniec strumienia), 
    ; wyświetl bufor wyjścia i zakończ program
    je print_output

    mov r8, rax              ; zapisz [liczbe odczytanych bajtow]

; Sprawdź pierwszy niebędący spacją znak, aby określić 
; kierunek konwersji
check_first_char:
    cmp byte [rsi], ' '      ; sprawdzam czy jest to spacja  
    jne which_way            ; jeśli nie
    
    ; muszę przepisać spację na wyjście 
    mov byte [rdi], ' '      ; Przepisz spację 
    inc rdi                  ; kolejny znak outputu
    
    ; Sprawdź, czy rdi nie przekroczyło rozmiaru bufora
    mov rax, rdi             ; miejsce w wyjściu
    sub rax, output          ; odejmij początkowy adres [output]
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, 4096            ; 4096 to rozmiar bufora wyjścia
    je print_first_spaces    ; jeśli musimy wypisać to pamiętamy
    ; że po skończonej operacji musimy jeszcze przesunąć wskaźnik
    ; na wejściu
    
another_char:
    inc rsi                  ; przesuwam wskaźnik na wejście

    ; Sprawdź, czy rsi nie przekroczyło rozmiaru odczytanych danych
    mov rax, rsi             ; miejsce w wejściu
    sub rax, input           ; odejmij początkowy adres [input] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, r8              ; porównaj to przesunięcie z r8 
    ; (liczba odczytanych bajtów)
    je reading

    jmp check_first_char     ; szukam dalej nie-spacji 

; Wypisuje wynik na standardowe wyjście, korzystając z bufora wyjścia
; (w którym znajdują się dane do wypisania)
print_first_spaces:
    mov r9, rsi              ; zapamiętaj wskaźnik na input *

    ; obliczamy długość wyjścia [output]
    mov rdx, rdi             ; rdi wskazuje na koniec wyjścia [output]
    sub rdx, output          ; obliczamy długość

    ; Wypisz wynik na wyjście
    mov eax, 1               ; sys_write
    mov edi, 1               ; stdout
    mov rsi, output          ; wskaźnik na wyjście
    syscall

    ; Sprawdź poprawność odczytu
    test rax, rax
    js error

    mov rdi, output          ; wskaźnik na wyjście będzie w rdi
    mov rsi, r9              ; możemy przenieść wskaźnik wejścia do rsi
    jmp another_char         ; pamiętamy, że po wyświetleniu należy 
    ; również przesunąć wskaźnik na wejściu

; Pierwszy znak decyduje o kierunku konwersji 
which_way:
    ; Sprawdź czy pierwszy znak to kropka, kreska, litera czy cyfra
    cmp byte [rsi], '.'       
    je convert_morse_loop
    cmp byte [rsi], '-'
    ; jeśli kropka lub kreska to chcemy konwertowac z Morse'a, 
    ; jeśli nie to na odwrót
    je convert_morse_loop

    jmp convert_loop

;;;;;;;;;;;;;;;;; tekst -> Morse ;;;;;;;;;;;;;;;;;

; Czyta kolejne litery i cyfry ze standardowego wejścia do bufora
reading_text: 
    mov r9, rdi              ; zapamiętaj wskaźnik na wyjście (**)

    ; Wczytaj dane wejściowe
    mov eax, 0               ; sys_read
    mov edi, 0               ; stdin
    mov rsi, input           ; wskaźnik na wejście
    mov edx, 4096            ; liczba bajtów do odczytu
    syscall

    mov rdi, r9              ; przywracam (**)

    ; Sprawdź poprawność odczytu
    test rax, rax
    js error
    ; Jeśli operacja sys_read zwróci 0 (koniec strumienia), 
    ; wyświetl bufor wyjścia i zakończ program
    je print_output

    mov r8, rax              ; zapisz [liczbe odczytanych bajtow]

; Przepisuje spacje na wyjście i sprawdza poprawność danych wejściowych 
convert_loop:
    mov al, byte [rsi]       ; biorę znak wejścia
    cmp al, ' '              ; przepisz spację
    je space_text_to_morse

    ; Sprawdź poprawność danych wejściowych
    cmp al, 'A'
    jb check_if_number   ; jeśli ma niższy numer w tablicy ASCII od 'A'
    ; to może być jeszcze cyfrą, jeśli wyższy od 'Z' to na pewno błąd
    cmp al, 'Z'
    ja error

; Ustawienie wskaźników na tablice (patrz sekcja data)
valid_char:
    ; Znajdź odpowiednik Morse'a dla litery lub cyfry
    mov r10, letters         ; wskaźnik na litery
    mov rdx, morse_codes     ; wskaźnik na kody Morse'a
    mov r9, morse_lens       ; wskaźnik na długości kodów 

; Pętla szukająca litery/cyfry odpowiadającej tej z wejścia 
find_letter:
    cmp al, [r10]
    je found_letter          ; aktualna litera jest równa 
    ; tej na którą wskazuje r10

    ; jeśli nie, to szukam dalej
    inc r10                  ; przesuwam wskaźnik: litera/cyfra
    mov r11, rdx             ; przesuwam wskaźnik: kod
    movzx rdx, byte [r9]     ; przesuwam o długość aktualnego kodu
    add rdx, r11
    inc r9                   ; przesuwam wskaźnik: długość kodu
    jmp find_letter

; Wskaźniki ustawione w tablicach w miejscach 
; odpowiadających wczytanemu znakowi
found_letter:
    ; Skopiuj kod Morse'a do wyjścia
    movzx rcx, byte [r9]     ; długość kodu

; Pętla ta po kolei przepisuje tłumaczenie danego na wejściu znaku
; na kod Morse'a do bufora wyjścia, w rdi jest wskaźnik na aktualny
; znak w buforze wyjścia, a w rdx na kod który chcemy przekopiować 
; na wyjście w tablicy kodów Morse'a
copy_morse:
    mov al, byte [rdx]       ; skopiuj do wyjścia [output]
    ; znak z odpowiadającego kodu Morse'a
    mov byte [rdi], al      
    inc rdi                  ; przejdź do następnego znaku w wyjściu 
    inc rdx                  ; oraz w danej literze/cyfrze w kodzie Morse'a

    ; wykonaj tyle razy, jakiej długości jest kod Morse'a
    loop copy_morse

; Po każdym kodzie Morse'a mamy spację
; po odczytaniu/przepisaniu każdego znaku pamiętamy o przesunięciu 
; wskaźników na wejściu i wyjściu
space_text_to_morse:
    mov byte [rdi], ' '      ; Przepisz spację 
    inc rdi                  ; kolejny znak outputu

    ; Sprawdź, czy rdi nie przekroczyło rozmiaru bufora,
    ; pamiętaj, że aby kolejny kod Morse'a mógł się zmieścić
    ; do bufora wyjścia, musi w nim być miejsce na conajmniej
    ; 6 bajtów (5 bajtów to najdłuższy znak + spacja po znaku)
    mov rax, rdi             ; miejsce w wyjściu
    sub rax, output          ; odejmij początkowy adres [output] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, 4090            ; 4096 to rozmiar bufora wyjścia
    ja print_morse           ; jeśli musimy wypisać to pamiętamy
    ; że po skończonej operacji musimy jeszcze przesunąć wskaźnik
    ; na wejściu

next_char:
    inc rsi                  ; kolejny znak wejścia

    ; Sprawdź, czy rsi nie przekroczyło rozmiaru odczytanych danych
    mov rax, rsi             ; miejsce w wejściu
    sub rax, input           ; odejmij początkowy adres [input] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, r8              ; porównaj to przesunięcie z r8 
    ; (liczba odczytanych bajtów)
    je reading_text

    jmp convert_loop         ; kontynuuj tłumaczenie

; Sprawdź czy podano poprawną cyfrę 
check_if_number:
    cmp al, '0'
    jb error
    cmp al, '9'
    ja error

    jmp valid_char           ; jeśli poprawna cyfra

; Wypisuje wynik (kody Morse'a przetłumaczonych liter/cyfr) na standardowe
; wyjście, korzystając z bufora wyjścia (w którym znajdują się dane 
; do wypisania)
print_morse:
    mov r9, rsi              ; zapamiętaj wskaźnik na wejście *

    ; obliczamy długość wyjścia [output]
    mov rdx, rdi             ; rdi wskazuje na koniec wyjścia [output]
    sub rdx, output          ; obliczamy długość

    ; Wypisz wynik na wyjście
    mov eax, 1               ; sys_write
    mov edi, 1               ; stdout
    mov rsi, output          ; wskaźnik na wyjście
    syscall

    ; Sprawdź poprawność operacji wypisania (sys_write)
    test rax, rax
    js error

    mov rdi, output          ; wskaźnik na wyjście w rdi
    mov rsi, r9              ; możemy przenieść wskaźnik wejścia do rsi
    jmp next_char            ; pamiętamy, że po wyświetleniu należy 
    ; również przesunąć wskaźnik na wejściu

;;;;;;;;;;;;;;;;; Morse -> tekst ;;;;;;;;;;;;;;;;;

; Czyta kolejne kody Morse'a ze standardowego wejścia do bufora
reading_morse: 
    mov r10, rdi             ; zapamiętaj wskaźnik na wyjście (**)

    ; Wczytaj dane wejściowe
    mov eax, 0               ; sys_read
    mov edi, 0               ; stdin
    mov rsi, input           ; wskaźnik na wejście
    mov edx, 4096            ; liczba bajtów do odczytu
    syscall

    mov rdi, r10             ; przywracam (**)

    ; Sprawdź poprawność operacji sys_read
    test rax, rax
    js error
    ; Jeśli operacja sys_read zwróci 0 (koniec strumienia), 
    ; wyświetl bufor wyjścia i zakończ program
    je print_output

    mov r8, rax              ; zapisz [liczbe odczytanych bajtow]

    cmp r9, one_code         ; jeśli r9 wskazuje na początek bufora 
    ; z kodem znaczy to, że cały kod został przetłumaczony na wyjście
    jne find_morse_end       ; jeśli nie, to kontynuuj tłumaczenie kodu

; Trzymam w buforze "one_code" aktualnie sprawdzany kod Morse'a 
; (pojedynczego znaku), wcześniej przepisując go tam z wejścia,
; następnie tłumaczę ten kod na literę/cyfrę i umieszczam w buforze
; wyjścia
convert_morse_loop:
    mov r9, one_code         ; w r9 będzie wskaźnik na kod Morse'a
    ; jednej litery/cyfry, który będę trzymał w buforze 

    mov al, byte [rsi]       ; aktualna litera wejścia
    cmp al, ' '              ; przepisz spację
    je space_morse_to_text

; Przepisuje kolejne znaki do bufora [one_code]
find_morse_end:
    cmp byte [rsi], ' '      ; jeśli spacja - koniec kodu 
    je found_morse_end

    ; Sprawdź, czy podany kod Morse'a nie jest za długi
    mov rax, r9              ; miejsce w buforze z aktualnym kodem Morse'a 
    sub rax, one_code        ; odejmij początkowy adres [one_code] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, 5               ; jeśli przeczytano już 5 znaków kodu
    ; i 6. nie jest spacją, to oczywiście mamy błąd
    je error

    mov al, byte [rsi]       ; przepisz '.' lub '-' kodu Morse'a
    mov byte [r9], al        ; z wejścia do bufora [one_code]
    inc rsi                  ; jeśli jeszcze nie znaleziono końca - kontynuuj
    inc r9                   ; przesuwam więc wskaźniki na wejście i bufor
    ; z kodem

    ; Sprawdź, czy rsi nie przekroczyło rozmiaru odczytanych danych
    mov rax, rsi             ; miejsce w wejściu
    sub rax, input           ; odejmij początkowy adres [input] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, r8              ; porównaj to przesunięcie z r8 
    ; (liczba odczytanych bajtów)
    je reading_morse

    jmp find_morse_end

; Cały kod przepisano do bufora (one_code), ustawiamy więc odpowiednio
; wskaźniki i szukamy tłumaczenia dla podanego kodu i czy kod ten jest
; poprawny, to znaczy czy istnieje litera/cyfra o takim kodzie
found_morse_end:
    ; Porównaj kod Morse'a z tablicą
    mov rdx, morse_codes     ; wskaźnik na kody Morse'a 
    mov r10, letters         ; wskaźnik na litery/cyfry

; Szuka kodu Morse'a odpowiadającego wejściu
compare_morse:
    movzx rcx, byte [morse_lens + r10 - letters] 
    ; r10 - letters, czyli ile bajtów od początku tablicy
    ; letters (jak i morse_lens) znajduje się aktualna litera
    ; i wartość tą dodajemy do morse_lens
    
    ; zatem w rcx będzie długość kodu Morse'a który 
    ; porównujemy z tym z wejścia

    mov r11, r9              ; w r11 będzie szukana długość kodu
    ; Morse'a (tego z wejścia), bo r9 wskazuje na koniec 
    ; tego kodu, a [one_code] na początek
    sub r11, one_code
    
    cmp rcx, r11             ; sprawdzamy czy długość szukanego kodu
    ; zgadza się z aktualnym w tablicy
    jne next_morse           ; jeśli nie zgadza się

    ; a jeśli ta sama długość to sprawdzamy znaki:
    mov rax, rdi             ; zapamiętaj miejsce w wyjściu (***)
    mov rdi, rdx             ; przepisz do rdi miejsce w tablicy [morse_code] 
    mov r11, rsi             ; zapamiętaj miejsce w wejściu (+++)
    mov rsi, one_code        ; przepisz do rsi miejsce w buforze 
    ; z aktualnym kodem Morse'a

    repe cmpsb
    ; cmpsb porównuje bajty danych, na które wskazują 
    ; rejestry rsi (wejścia) oraz rdi (kodu w tablicy kodów
    ; Morse'a). Po porównaniu, rejestry te są automatycznie
    ; inkrementowane. 
    ; repe powtarza następną instrukcję, dopóki licznik 
    ; w rejestrze rcx nie osiągnie zera lub dopóki 
    ; porównywane wartości są równe
    je found_morse_letter
    
    ; jeśli jakiś bajt się nie zgadzał to kontynuujemy 
    ; poszukiwania od następnego kodu Morse'a
    ; nie zapominamy o przywróceniu rejestrów
    mov rdi, rax             ; przywracam (***)
    mov rsi, r11             ; przywracam (+++)

; To nie ten kod Morse'a, szukaj więc dalej
next_morse:
    movzx r11, byte [morse_lens + r10 - letters]
    add rdx, r11             ; przesuń się o długość aktualnie 
    ; sprawdzanego kodu w tablicy kodów Morse'a
    inc r10                  ; oraz do następnej litery/cyfry

    ; sprawdzamy, czy nie porównaliśmy przypadkiem
    ; już ze wszystkimi literami/cyframi
    mov r11, r10             ; wskaźnik w tablicy letters
    sub r11, letters
    cmp r11, 36              ; (26 + 10 = tyle jest cyfr i liter)
    jne compare_morse

    jmp error                ; jeśli podano niepoprawny kod Morse'a,
    ; np 6-znakowy, wtedy r11 = 36 ponieważ nie mogliśmy 
    ; dopasować jakiegokolwiek kodu do danego na wejściu

; Jeśli znaleźliśmy tłumaczenie (znak) dla danego na wejściu kodu
found_morse_letter:
    mov rdi, rax             ; przywracamy rejestr wyjścia (***)
    mov rsi, r11             ; przywracamy rejestr wejścia (+++)

    ; Skopiuj znaleziony znak w tablicy liter i cyfr do wyjścia
    mov al, [r10]            ; w r10 jest znaleziony znak
    mov [rdi], al            ; rdi - wskaźnik na miejsce w wyjściu
    mov r9, one_code         ; ustaw r9 na początek bufora z kodem znaku
    
; Przesuwamy wskaźniki (na wejściu musimy pominąć spację po kodzie 
; Morse'a pojedynczego znaku, której nie wypisujemy)    
check_buffer_out:
    inc rdi                  ; przechodzimy dalej w wyjściu

    ; Sprawdź, czy rdi nie przekroczyło rozmiaru bufora
    mov rax, rdi             ; miejsce w wyjściu
    sub rax, output          ; odejmij początkowy adres output 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, 4096            ; 4096 to rozmiar bufora wyjścia
    je print_text            ; jeśli musimy wypisać to pamiętamy
    ; że po skończonej operacji musimy jeszcze przesunąć wskaźnik
    ; na wejściu

check_buffer_in:
    inc rsi                  ; przesuń wskaźnik wejścia
    
    ; Sprawdź, czy rsi nie przekroczyło rozmiaru odczytanych danych
    mov rax, rsi             ; miejsce w wejściu
    sub rax, input           ; odejmij początkowy adres [input] 
    ; od rax, żeby uzyskać przesunięcie
    cmp rax, r8              ; porównaj to przesunięcie z r8 
    ; (liczba odczytanych bajtów)
    je reading_morse

    jmp convert_morse_loop

space_morse_to_text:
    mov byte [rdi], ' '      ; Przepisz spację
    jmp check_buffer_out     ; przesuń wskaźniki na wejściu i wyjściu

; Wypisuje wynik (przetłumaczone kody Morse'a na litery/cyfry) 
; na standardowe wyjście, korzystając z bufora wyjścia (w którym
; znajdują się dane do wypisania)
print_text:
    mov r10, rsi             ; zapamiętaj wskaźnik na wejście *

    ; obliczamy długość wyjścia [output]
    mov rdx, rdi             ; rdi wskazuje na koniec wyjścia [output]
    sub rdx, output          ; obliczamy długość

    ; Wypisz wynik na wyjście
    mov eax, 1               ; sys_write
    mov edi, 1               ; stdout
    mov rsi, output          ; wskaźnik na wyjście
    syscall

    ; Sprawdź poprawność operacji wypisania (sys_write)
    test rax, rax
    js error

    mov rdi, output          ; wskaźnik na wyjście w rdi
    mov rsi, r10             ; przywracam * 
    jmp check_buffer_in      ; pamiętamy, że po wyświetleniu należy 
    ; również przesunąć wskaźnik na wejściu

; Wypisz resztę wyjścia i zakończ program
print_output:
    ; obliczamy długość wyjścia [outputu]
    mov rdx, rdi             ; rdi wskazuje na koniec wyjścia [output]
    sub rdx, output          ; obliczamy długość

    ; Wypisz wynik na wyjście
    mov eax, 1               ; sys_write
    mov edi, 1               ; stdout
    mov rsi, output          ; wskaźnik na wyjście
    syscall

    ; Sprawdź poprawność sys_write
    test rax, rax
    js error

exit:
    ; Zakończ program z kodem 0 
    mov eax, 60              ; sys_exit
    xor edi, edi             ; kod 0
    syscall
    
error:
    ; Zakończ program z kodem 1
    mov eax, 60              ; sys_exit
    mov edi, 1               ; kod 1
    syscall