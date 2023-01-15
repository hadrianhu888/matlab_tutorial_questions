function [Q] = sampling_function(L)
%SAMPLING_FUNCTION Summary of this function goes here
%   Detailed explanation goes here
Q = zeros(size(L));
    for i=1:length(L)
        if L(i) < 2
            Q(i) = 1; 
        elseif L(i) >= 2 && L(i) <= 4
            Q(i) = 2; 
        else 
            Q(i) = 3;
        end 
    end 
    disp(L);
    disp('Quality of the samples:');
    disp('');
    disp('');
    disp(Q);
end

