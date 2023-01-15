clear; clc; 
% hold on;
a = zeros(100, 100);
% a(50,50) = 1;
% a(49,49)=1;
% a(59,86)=1;
% a(10,10)=1;
a(41:60,41:60) = 1;
size_a = size(a);
x_length = size_a(2);
y_length = size_a(1);
i = 1;
while i < 100000
    [yList,xList] = find(a==1); % note x,y are backwards in your code
    for k = 1:numel(yList)
        x = xList(k);
        y = yList(k);
        
        atTop = (y == 1);
        atBottom = (y == y_length);
        atLeft = (x == 1);
        atRight = (x == x_length);
        r = floor(rand() * 4);
        x_new = x;
        y_new = y;
        
        if r == 0
            if ~atTop
                y_new = y + 1;
            end
        elseif r == 1
            if ~atBottom
                y_new = y - 1;
            end
        elseif r == 2
            if ~atLeft
                x_new = x + 1;
            end
        elseif r == 3
            if ~atRight
                x_new = x - 1;
            end
        end
        a(y,x) = 0;
        a(y_new,x_new)=1;
        
    end
    pause(0.01);
    imagesc(a)
    i = i+1;
end