function [ratex,ratey] = alignShrink(rateX,rateY,timeX,timeY,tcutX,tcutY)
import helper.*;
tcut = [max(tcutX(1),tcutY(1)),max(tcutX(2),tcutY(2))];
id_x = timeX > tcut(1) & timeX < tcut(2);
id_y = timeY > tcut(1) & timeY < tcut(2);
ratex = rateX(id_x);
ratey = rateY(id_y);
[ratex,ratey] = alignLeft(ratex,ratey);
end