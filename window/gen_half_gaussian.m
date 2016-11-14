function gen_half_gaussian(sigma)
if (~exist('sigma', 'var'))
    sigma = 50;
end
dt = 0.1;
wr = sigma * 6;
wt = -wr:dt:wr;
wf = 2.0 * normpdf(wt, 0, sigma); wf(1:ceil(length(wt)/2)) = 0.0;
wf = wf ./ max(wf);
plot(wt, wf);
save(['Half_Gaussian_',num2str(sigma),'.mat'],...
     'dt', 'wr', 'wt', 'wf');
end