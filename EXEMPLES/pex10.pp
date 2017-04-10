var X1 : integer,
var X2 : integer

defun foo(X : integer): integer
var n : integer
  if X = 0
     then foo := 1
  else
    foo := X * foo (X - 1)

X1 := 5;
X2 := foo(X1)
