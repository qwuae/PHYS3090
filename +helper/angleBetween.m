function [a] = angleBetween(x1,x2)
   import helper.*;
   assert(sum(size(x1)~=size(x2))==0, ...
      'two vectors must have the same size')
   shape = size(x1);
   % vector length
   N = shape(1);
   % dimension number for each vector entry
   L = shape;
   L(1) = 1;
   st = zeros(L); % total inner product
   n1 = zeros(L); % norm of the first input
   n2 = zeros(L); % norm of the second input
   for i = 1:N
      p1 = x1(i,:);
      p2 = x2(i,:);
      st = st + p1 .* p2;
      n1 = n1 + p1 .* p1;
      n2 = n2 + p2 .* p2;
   end
   % calculate angle
   a = acos(st ./ sqrt(n1 .* n2)) / pi * 180;
end