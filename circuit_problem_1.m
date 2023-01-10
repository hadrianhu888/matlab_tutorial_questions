omega = zeros(1,600);
Iz = zeros(1,600);

for j = 1:1:600
    %disp('Omega: ')
    omega(j) = j;
    %disp(omega)
end 

Io = 1; 

for t = 1:60
    for k = 1:1:600
        Iz = Io * cos(omega(k) * t * (pi / 180));
        Iz(k) = Iz;
        %disp('Iz: ')
        %disp(Iz)
    end
end 

for k = 1:1:600
    Iz = Io * cos(omega(k) * (pi / 180));
    Iz(k) = Iz;
    %disp('Iz: ')
    %disp(Iz)
end

plot(angle(Iz),omega);

Vo = 10;
R = 100;
L = 0.4;
C = 3e-5; 
theta = 360; 





