%omega = zeros(1,600);
%Iz = zeros(1,600);

omega = 1:600; 
deg2rad = pi / 180; 
theta = 20; 
Vo = 10; 
R = 100;
L = 0.4;
C = 3.0e-5; 
Io = 1; 

Iz = Io * cos((omega + theta) * deg2rad); 
subplot(3,1,1);
plot(omega, angle(Iz));
grid on;
title('Iz Angle vs Omega for Iz =  Io * cos(w * t)');

Iz = Vo ./ (R + (omega * L) - (omega * C).^(-1)); 
subplot(3,1,2);
plot(omega, angle(Iz));
grid on; 
title('Iz Angle vs Omega for RLC Circuit');

subplot(3,1,3);
plot(omega,Iz);
grid on; 
title('Iz vs Omega');

