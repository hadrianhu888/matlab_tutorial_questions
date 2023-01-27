n = 1:0.001:3;
X = @(n) sin (2 * pi * n);
x = X(n);
% dilation
xd = X(3 .* n);
%translation;
xt = X(3 .* n + 3);
plot(n, x, 'r', n, xd, 'b', n, xt, 'go');
legend('x', 'xd', 'xt', 'Location', 'south');
grid on;
title('X versus Time plots - original, dilation, and translation');
xlabel('time (sec)');
ylabel('x(t) plots');
axis([1 3 -1.1 1.1]);
