L = [0 1 2 3 4 5 6];
Q = zeros(length(L));
P = zeros(length(L));
Q = sampling_function(L);
P = pricing_function(L, Q);
