fm = 1e3; 
fc = 10e3; 
ts = power(10.*fc,-1); 
t = (0:1:200).*ts; 
phi = 0; 
x = @(t) cos(2.*pi*fm.*t); 
y = @(t) x(t).*cos(2.*pi.*fc.*t); 
w = @(t) y(t).*cos(2.*pi.*fc.*t + phi); 
order = 1; 

figure(1);

subplot(3,1,1);
plot(t,x(t));
grid on; 
xlabel('t');
ylabel('x(t)'); 
axis([0 0.002 -1.1 1.1]);

subplot(3,1,2);
plot(t,y(t));
grid on; 
xlabel('t');
ylabel('y(t)'); 
axis([0 0.002 -1.1 1.1]);

subplot(3,1,3);
plot(t,w(t));
grid on; 
xlabel('t');
ylabel('w(t)'); 
axis([0 0.002 -1.1 1.1]);

[A,B,C,D] = butter(order,[fm fc],"bandpass","s"); 
sys = ss(A,B,C,D, 1/fc); 
figure(2);
bode(sys); 
grid on;
