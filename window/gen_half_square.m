function gen_half_square(width)
if (~exist('width', 'var'))
    width = 50;
end
dt = 0.1;
wr = 0.5 * width;
wt = -wr:dt:wr;
wf = zeros(1, length(wt)); 
for i = 1:length(wt)
   if wt(i) <= 0.5 * width && wt(i) >= 0.0;
       wf(i) = 2.0 / width; 
   end
end
plot(wt, wf);
save(['Half_Square_',num2str(width),'.mat'],...
     'dt', 'wr', 'wt', 'wf');
end