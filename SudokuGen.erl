% To run:
% > cd [This file's path]
% > erl
% > c(sudokuGen).
% > sudokuGen:start().

-module(sudokuGen).
-export([start/0]).

% This is main(), essentially
start() ->
    rand:seed(exsplus, os:timestamp()),
    EmptyGrid = new_grid(),
    case generate(EmptyGrid, 0, 0) of
      {ok, FullGrid} ->
         Puzzle = make_puzzle(FullGrid),
         print_grid(Puzzle);
      {fail, _} ->
         io:format("Generation failed~n", [])
    end.

% Creates an empty 9x9 grid
new_grid() ->
   maps:from_list([{{Row, Col}, 0} || Row <- lists:seq(0, 8), Col <- lists:seq(0, 8)]).

% Extracts a row as a list of values
get_row(Grid, Row) ->
   [maps:get({Row, Col}, Grid) || Col <- lists:seq(0, 8)].

% Extracts a column as a list of values
get_col(Grid, Col) ->
   [maps:get({Row, Col}, Grid) || Row <- lists:seq(0, 8)].

% Extracts a 3x3 box as a list of values
get_block(Grid, BlockRow, BlockCol) ->
   Rows = lists:seq(BlockRow * 3, BlockRow * 3 + 2),
   Cols = lists:seq(BlockCol * 3, BlockCol * 3 + 2),
   [maps:get({Row, Col}, Grid) || Row <- Rows, Col <- Cols].

% Updates a single cell in the grid
set_cell(Row, Col, Value, Grid) ->
   maps:put({Row, Col}, Value, Grid).

% Displays the grid, including horizontal dividers and intersection points
print_grid(Grid) ->
    lists:foreach(
      fun(Row) ->
         case Row of
            3 -> io:format("------+-------+------~n", []);
            6 -> io:format("------+-------+------~n", []);
            _ -> ok
         end,
         Values = [maps:get({Row, Col}, Grid) || Col <- lists:seq(0, 8)],
         Line = format_row(Values),
         io:format("~s~n", [Line])
      end,
      lists:seq(0 ,8)
    ).

% Formats a row into a string with spaces and vertical dividers
format_row(Values) ->
   Digits = [if V =:= 0 -> " "; true -> integer_to_list(V) end || V <- Values],
   string:join(
      [
        string:join(lists:sublist(Digits, 1, 3), " "),
        string:join(lists:sublist(Digits, 4, 3), " "),
        string:join(lists:sublist(Digits, 7, 3), " ")
      ],
      " | ").

% Checks whether a value can legally be placed in a cell
valid_move(Grid, Row, Col, Value) ->
   not lists:member(Value, get_row(Grid, Row)) andalso
   not lists:member(Value, get_col(Grid, Col)) andalso
   not lists:member(Value, get_block(Grid, Row div 3, Col div 3)).

% Tries filling a cell with a randomized digit
generate(Grid, 9, _) ->
   {ok, Grid};
generate(Grid, Row, 9) ->
   generate(Grid, Row + 1, 0);
generate(Grid, Row, Col) ->
   Digits = shuffle(lists:seq(1, 9)),
   try_digits(Grid, Row, Col, Digits).

% Tries to place a digit; if it fails, tries the next digit
try_digits(Grid, _Row, _Col, []) -> {fail, Grid};
try_digits(Grid, Row, Col, [Digit|Rest]) ->
   case valid_move(Grid, Row, Col, Digit) of
      true ->
         NewGrid = set_cell(Row, Col, Digit, Grid),
         case generate(NewGrid, Row, Col + 1) of
            {ok, FinalGrid} -> {ok, FinalGrid};
            {fail, _} -> try_digits(Grid, Row, Col, Rest)
         end;
      false ->
         try_digits(Grid, Row, Col, Rest)
   end.

% Shuffles a list
shuffle(List) ->
   [X || {_,X} <- lists:sort([{rand:uniform(), E} || E <- List])].

% Counts the number of solutions for the grid
count_solutions(Grid) -> count_solutions(Grid, 0).
count_solutions(_Grid, Count) when Count > 1 -> 2;
count_solutions(Grid, Count) ->
   case find_empty(Grid) of
      none -> Count + 1;
      {Row, Col} ->
         Digits = lists:seq(1,9),
         lists:foldl(
            fun(D, Acc) ->
               case valid_move(Grid, Row, Col, D) of
                  true ->
                     NewGrid = set_cell(Row, Col, D, Grid),
                     count_solutions(NewGrid, Acc);
                  false -> Acc
               end
            end,
            Count,
            Digits)
   end.

% Finds the first empty cell
find_empty(Grid) ->
   case [ {R,C} || R <- lists:seq(0,8), C <- lists:seq(0,8),
      maps:get({R,C}, Grid) =:= 0 ] of
         [] -> none;
         [First|_] -> First
   end.

% Takes a filled grid (a solution) and creates a puzzle based off of it
make_puzzle(Grid) ->
   Cells = shuffle([ {R,C} || R <- lists:seq(0,8), C <- lists:seq(0,8) ]),
   dig(Grid, Cells).

% Try removing a cell; keep it empty only if there's still a unique solution
dig(Grid, []) -> Grid;
dig(Grid, [{Row,Col}|Rest]) ->
   NewGrid = set_cell(Row, Col, 0, Grid),
   case count_solutions(NewGrid) of
      1 -> dig(NewGrid, Rest);
      _ -> dig(Grid, Rest)
   end.