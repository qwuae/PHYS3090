function [x, y] = alignLeft(X,Y)
import helper.*;
% get all lengths
lx = length(X);
ly = length(Y);
% adjust sizes
if lx > ly
    x = X(1:ly);
    y = Y(1:ly);
else
   	x = X(1:lx);
    y = Y(1:lx);
end
end