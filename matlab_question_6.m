clear;
close all;
I_real = 0;
T = 0;
t = 0;

t = input('choose time from those numbers 0.166 or 0.5 or 1 or 2 or 3 or 6 or 12 or 24 in hours');

if t ~= (0.166 || 0.5 || 1 || 2 || 3 || 6 || 12 || 24)
    error('Invalid Input t shoudlnt be that value');
end

T = input('choose freqency (any number In years:)');

I_real = caculate_intensity_gumbel('execel_tirgul_for_matlab.xlsx', t, T);
