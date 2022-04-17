using Dice
using Dice: num_flips, num_nodes, ifelse
include("wordle_wordbank.jl")

code = @dice begin
    function generate_wordle_answer()
        n_flips = ndigits(length(bank) - 1, base=2)
        answer_i = DistInt([flip(0.5) for _ in 1:n_flips])
        observe(length(bank) > answer_i)
        answer = DistString(bank[1])
        for i in 2:length(bank)
            answer = if prob_equals(i - 1, answer_i) DistString(bank[i]) else answer end
        end
        answer
    end
    function make_guess(answer, guess)
        row = DistString("_____")
        used = [prob_equals(answer[i], guess[i]) for i in 1:5]
        for i in 1:5
            row = if used[i] prob_setindex(row, i, 'G') else row end
        end
        for i in 1:5
            for j in [1:(i-1);(i+1):5]
                yellow = prob_equals(row[i], '_') & !used[j] & prob_equals(answer[j], guess[i])
                used[j] = used[j] | yellow
                row = if yellow prob_setindex(row, i, 'Y') else row end 
            end
        end
        row
    end

    answer = generate_wordle_answer()
    observe(prob_equals(make_guess(answer, "ROAST"), "Y__G_"))
    observe(prob_equals(make_guess(answer, "GREED"), "_G___"))
    answer
end

bdd = compile(code)
infer(bdd)
