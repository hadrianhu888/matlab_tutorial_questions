fc = 10e4; 
f = 10e3; 
fs = 1/(10*fc); 
ts = power((10*fc),-1); 
t = 0:ts:1e-4;
m = @(t) cos(2*pi*fs*t);
x = @(t) cos(2*pi*fc*t); 
y = @(t) x(t).*m(t);
w = @(t) y(t).*m(t);

[b,a] = butter(2,[f fc],"bandpass","s");
figure(1);
h = fvtool(b,a);

figure(2); 
plot(t,x(t), t, y(t), t, w(t)); 
grid on; 
title('Telecommunications Plots');
