function [P] = pricing_function(L,Q)
%PRICING_FUNCTION Summary of this function goes here
%   Detailed explanation goes here
P = zeros(size(L)); 
    for i=1:length(P)
        if Q(i) == 3
            P(i) = 10; 
        elseif Q(i) == 2
            P(i) = 5; 
        elseif Q(i) == 1
            P(i) = 3; 
        else 
            % do nothing here 
        end         
    end 
    disp(P);
end

