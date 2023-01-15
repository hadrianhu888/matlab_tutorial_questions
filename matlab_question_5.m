clear;
close all;

function I_real = caculate_intensity_gumbel(execel_tirgul_for_matlab, t , T)
    [data, textdata] = xlsread('execel_tirgul_for_matlab.xlsx');   
    p_katan = 1-(1/T);
    gumbel = log(-1/log(p_katan));

    switch t
        case 0.166
            col = 3;
        case 0.5
            col = 4;
        case 1
            col = 5;
        case 2
            col = 6;
        case 3
            col = 7;
        case 6
            col = 8;
        case 12
            col = 9;
        case 24
            col = 10;
            
    end
    I_avg = mean(data(2:10,col));
    I_std = std(data(2:10,col));
    I_real = gumbel*0.78*I_std+I_avg-0.45*I_std;
   
end