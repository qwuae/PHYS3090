function gen_gaussian(sigma)
if (~exist('sigma', 'var'))
    sigma = 50;
end
dt = 0.1;
wr = sigma * 6;
wt = -wr:dt:wr;
wf = normpdf(wt, 0, sigma);
wf = wf ./ max(wf);
plot(wt, wf);
save(['Gaussian_',num2str(sigma),'.mat'],...
     'dt', 'wr', 'wt', 'wf');
end