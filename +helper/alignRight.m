function [x, y] = alignRight(X,Y)
import helper.*;
% get all lengths
lx = length(X);
ly = length(Y);
% adjust sizes
if lx > ly
    x = X(lx - ly + 1:lx);
    y = Y(1:ly);
else
   	x = X(1:lx);
    y = Y(ly - lx + 1:ly);
end
end