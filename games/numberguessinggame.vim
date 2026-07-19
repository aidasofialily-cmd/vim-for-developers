" games/numberguessinggame.vim
" A simple number guessing game to practice Vimscript logic.
" Run :source numberguessinggame.vim and then type :GuessNumber

fun! GuessNumber()
    let l:target = float2nr(strftime("%S")) % 100 + 1
    let l:guess = -1
    let l:attempts = 0

    echo "--- Vim Number Guessing Game ---"
    echo "I'm thinking of a number between 1 and 100."

    while l:guess != l:target
        let l:input_str = input("Enter your guess: ")
        
        " Validate input is a number
        if l:input_str !~ '^\d\+$'
            echo "Please enter a valid number!"
            continue
        endif

        let l:guess = str2nr(l:input_str)
        let l:attempts += 1

        if l:guess < l:target
            echo "Too low! Try again."
        elseif l:guess > l:target
            echo "Too high! Try again."
        else
            echo "Congratulations! You guessed it in " . l:attempts . " attempts."
        endif
    endwhile
endfun

" Define the command to trigger the game
command! GuessNumber call GuessNumber()
