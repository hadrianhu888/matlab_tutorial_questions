    function Grafix_mzip
    %   MATLAB zip file, a self-extracting MATLAB archive.
    %   Usage: Run this file to recreate the original directory.

        fname = mfilename;
        fin = fopen([fname '.m'],'r');
        dname = fname(1:find(fname=='_',1,'last')-1);
        mkdir(dname);
        mkdir([dname filesep 'lib'])
        
        L = fgetl(fin);
        while length(L) < 2 || ~isequal(L(1:2),'%%')
            L = fgetl(fin);
        end
        while ~isequal(L,'%% EOF')
            F = [dname filesep L(4:end)];
            disp(F)
            fout = fopen(F,'w');
            L = fgetl(fin);
            while length(L) < 2 || ~isequal(L(1:2),'%%')
                fprintf(fout,'%s\n',L);
                L = fgetl(fin);
            end
            fclose(fout);
        end
        fclose(fin);
        addpath(dname)
        addpath([dname filesep 'lib'])
    end
    %% Grafix.m
    function Gout = Grafix(varargin)
        % Grafix, version 2.20, Feb. 10, 2023
        % Mathematics of Computer Graphics.
        % Simulate 3D rotation and translation.
        %
        % Grafix, with no arguments, starts the interactive tool.
        %
        % Grafix is programmable, in a primitive sort of way.
        % This script produces an animation.
        %
        %    G = Grafix('plane',0);
        %    for t = 0:0.1:2
        %        M = Tx(t-0.5) * Ty(0.333*t) * Rz(22.5*t);
        %        Grafix(G,M)
        %        drawnow
        %    end
            
        % Copyright 2023 Cleve Moler
        
        % Use uifigure and hgtransform.

        if nargin == 0 || nargin > 1 && ~isstruct(varargin{1})
            % Initial entry, create G and M
            [uifig,axs] = uifig_init(varargin{:}); 
            G.item = 'plane';
            G.scale = 0;
            G.vue = 'xyz';
            G.H = hgtransform(axs);
            knobs_init(uifig,varargin{:});
            view_cb(G)
            M = eye(4,4);
    
        elseif nargin == 1
            % Internal callbacks
            G = varargin{1};
            delete(G.H.Children)
            M = G.H.Matrix;
            
        else
            % "Programs"
            G = varargin{1};
            M = varargin{2};
            delete(G.H.Children)
            view_cb(G)
        end
        
        % The matrix M
        G.H.Matrix = M;
        framed_matrix(M);
        set(G.H.Parent.Parent.UserData(26:30),'visible','off');
        switch G.item
            case 'plane'
                plane(G);
            case 'bucky'         
                bucky_graph(G)
            case 'cube'
                cube(G)
            case 'teapot'
                teapot(G)
        end

        finish(G)

        if nargout > 0
        Gout = G;
        end

        function info_cb(~,~)
            web('https://blogs.mathworks.com/cleve/2023/02/10/grafix-users-guide/')
        end
        
        function items_cb(arg,~)
            delete(G.H.Children) 
            G.item = arg.Value;
            Grafix(G)
            end
        
        function start_cb(~,~)  
            % Start over
            Grafix
        end
        
        function offset_cb(~,~)  
            delete(G.H.Children)
            teapot(G)
        end
        
        function reset_cb(~,~)
            % Warm restart
            H = G.H;
            knobs = H.Parent.Parent.UserData;
            set(knobs(1:7),'value',0)
            set(knobs(26),'value',8)
            set(knobs(28),'value',0)
            set(knobs(30),'value',3)
            H.Parent.Clipping = 'off';
            H.Parent.Visible = 'off';
            H.Matrix = eye(4,4);
            %delete(H.Children)
            M = eye(4,4);
            Grafix(G,M)
        end
        
        function view_cb(arg,~)
            if nargin == 2
                vue = arg.Value;
                ax = arg.UserData;
            else
                vue = arg.vue;
                ax = arg.H.Parent;
            end
            switch vue
                case 'xy', view(ax,0,90)
                case 'xz', view(ax,0,0)
                case 'yz', view(ax,90,0)
                case 'xyz', view(ax,-37.5,30)
            end
        end 
        
        function axis_cb(arg,~)
            arg.UserData = 1-arg.UserData;
            if arg.UserData
                arg.BackgroundColor = [.5 .8 .9]/.9;
                ax = G.H.Parent;
                x = 1.66*max(ax.XLim);
                xt = 1.1*x;
                xu = 0.95*x;
                line(ax,[0,x,x],[0 0,0],[0 0 0],'linewidth',2,'color','k');
                line(ax,[0 0 0],[x x 0],[0,0,0],'linewidth',2,'color','k');
                line(ax,[0 0 0],[0,0,0],[x 0 x],'linewidth',2,'color','k');
                text(ax,xt,0,0,'+x','horiz','center','fontsize',16,'fontweight','bold')
                text(ax,0,xt,0,'+y','horiz','center','fontsize',16,'fontweight','bold')
                text(ax,0,0,xt,'+z','horiz','center','fontsize',16,'fontweight','bold')
                text(ax,xu,0,0,'\^','rotation',-60,'horiz','center','fontsize',20, ...
                    'fontweight','bold');
                text(ax,0,xu,0,'\^','rotation',+60,'horiz','center','fontsize',20, ...
                    'fontweight','bold');
                text(ax,0,0,xu,'\^','rotation',0,'horiz','center','fontsize',20, ...
                    'fontweight','bold');
            else
                arg.BackgroundColor = [1 1 1];
                ax = G.H.Parent;
                ch = ax.Children;
                delete(ch(1:end-1));
            end
        end

        function knobs_cb(knob,delta)
            op = knob.Tag;
            fin = isequal(delta.EventName,'ValueChanged');
            mu = median(diff(knob.MinorTicks));
            v = mu*round(knob.Value/mu);
            knob.Value = v;
            if fin
                v = v - delta.PreviousValue;
            else
                v = delta.Value - knob.Value;
            end
            r = pi/180;
            s = sqrt(2);
            switch op
                case 'Rx', A = makehgtform(xrotate = r*v);
                case 'Ry', A = makehgtform(yrotate = r*v);
                case 'Rz', A = makehgtform(zrotate = r*v);
                case 'Tx', A = makehgtform('translate',v,0,0);
                case 'Ty', A = makehgtform('translate',0,v,0);  
                case 'Tz', A = makehgtform('translate',0,0,v);
                case 'S',  A = makehgtform(scale = s^v);
            end
            if fin
                M = A*M;
                G.H.Matrix = M;
                framed_matrix(M)
            else
                Htemp = G.H;
                Htemp.Matrix = A*M;
                framed_matrix(A*M)
            end
        end
        
        function [uifig,axs] = uifig_init(varargin)
            close all force
            sze = get(0,'screensize');
            uifig = uifigure(Position = [20 40 sze(3)-40 sze(4)-80]);
            axs = axes(uifig, ...
                Units = 'normalized', ...
                Position = [.25 .21 .75 .75], ...
                Clipping='off');
            txa = uitextarea(uifig,Position = [60 sze(4)-280 400 165], ...
                FontWeight = 'bold', ...
                FontSize = 24);            
            uifig.Name = 'Grafix_2.0';
            axs.Visible = 'off';
            axs.DataAspectRatio = [ 1 1 1];
            axs.Toolbar.Visible = 'off';
            txa.FontName = 'Lucida Console';
            txa.Tag = 'matframe';
        end
        
    function knobs_init(fig,varargin)

            sze = get(0,'ScreenSize');
            xm = sze(3)-40;
            ym = sze(4)-80;
            fs = 14;

            knobs = zeros(32,1);
            for k = 1:3
                % Knobs Rx, Ry, Rz
                op = ['R' char('w'+k)];
                pos = [xm-700+180*k,50,80,80];
                knobs(k) = uiknob(fig, ...
                    Position = pos, ...
                    Limits = [-180,180], ...
                    MajorTicks = (-180:45:180), ...
                    MinorTicks = (-180:15:180), ...
                    Tag = op,  ...
                    ValueChangingFcn = @knobs_cb, ...
                    ValueChangedFcn = @knobs_cb);
                knobs(k+7) = uilabel(fig, ...
                    Position = [pos(1)+30,pos(2)-40,40,25], ...
                    Text = op); 
            end
            
            for k = 1:4
                % Sliders Tx, Ty, Tz, S
                if k < 4
                    op = ['T' char('w'+k)];
                else
                    op = 'S';
                end
                if k < 4
                    pos = [200*k-130,100,150,3];
                else
                    pos = [70,190,150,3];
                end 
                knobs(k+3) = uislider(fig, ...
                    Position = pos, ...
                    Limits = [-3,3], ...
                    Tag = op,  ...
                    MajorTicks = -3:1:3, ...
                    MinorTicks = -3:0.25:3, ...
                    ValueChangingFcn = @knobs_cb, ...
                    ValueChangedFcn = @knobs_cb);
                knobs(k+10) = uilabel(fig, ...
                    Position = [pos(1)+65,pos(2)-60,40,25], ...
                    Text = op);
            end
                
            % Items knob
            items = {'plane','cube','bucky','teapot'}; 
            knobs(15) = uiknob(fig,'discrete', ...
                    Value = G.item, ...
                    Position = [100,ym-320,50,50], ...
                    Items = items, ...
                    ValueChangedFcn = @items_cb);
            
            % View
            knobs(16) = uiknob(fig,'discrete', ...
                    Position = [310,ym-320,50,50], ...
                    Items = {'xy','xz','yz','xyz'}, ...
                    UserData = fig.Children(end), ...
                    Value = G.vue, ...
                    ValueChangedFcn = @view_cb);
            
            % Info
            knobs(17) = uibutton(fig, ...
                    Position = [xm-100,ym-80,60,30], ...
                    Text = 'Info', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @info_cb); 

            % Start        
            knobs(19) = uibutton(fig, ...
                    Position = [xm-100,ym-120,60,30], ...
                    Text = 'Start', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @start_cb); 
                
            % Reset         
            knobs(18) = uibutton(fig, ...
                    Position = [xm-100,ym-160,60,30], ...
                    Text = 'Reset', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @reset_cb); 
                
            % Axis         
            knobs(20) = uibutton(fig, ...
                    Position = [xm-100,ym-200,60,30], ...
                    Text = 'Axis', ...
                    UserData = 0, ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @axis_cb); 
                
            % Pitch    
            knobs(21) = uibutton(fig, ...
                    Position = [xm-100,ym-240,60,30], ...
                    Text = 'Pitch', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    UserData = G, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @pitch_roll_yaw);
            
            % Roll        
            knobs(22) = uibutton(fig, ...
                    Position = [xm-100,ym-280,60,30], ...
                    Text = 'Roll', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    UserData = G, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @pitch_roll_yaw);
            
            % Yaw        
            knobs(23) = uibutton(fig, ...
                    Position = [xm-100,ym-320,60,30], ...
                    Text = 'Yaw', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    UserData = G, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @pitch_roll_yaw);
            
            % Prop         
            knobs(24) = uibutton(fig, ...
                    Position = [xm-100,ym-360,60,30], ...
                    Text = 'Prop', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    UserData = 0, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @prop);       

            % Viz         
            knobs(25) = uibutton(fig, ...
                    Position = [xm-100,ym-400,60,30], ...
                    Text = 'Viz', ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    UserData = 0, ...
                    BackgroundColor = 'w', ...
                    ButtonPushedFcn = @viz);       

            % Resolution, Offset
            knobs(26) = uislider(fig, ...
                Position = [70,280,150,3], ...
                Limits = [0,16], ...
                Value = 8, ...
                MajorTicks = 0:4:16, ...
                MinorTicks = 0:1:16, ...
                Visible = 'off', ...        
                ValueChangedFcn = @offset_cb);
            knobs(27) = uilabel(fig, ...
                Position = [110,220,60,25], ...
                Text = 'resolution', ...
                Visible = 'off');        
            knobs(28) = uislider(fig, ...
                Position = [270,280,150,3], ...
                Limits = [-10,10], ...
                Value = 0, ...
                MajorTicks = -10:5:10, ...
                MinorTicks = -10:1:10, ...
                Visible = 'off', ...        
                ValueChangedFcn = @offset_cb);
            knobs(29) = uilabel(fig, ...
                Position = [325,220,60,25], ...
                Text = 'offset', ...
                Visible = 'off'); 

            % Speed
            knobs(30) = uiknob(fig, ...
                Position = [100,260,50,50], ...
                Limits = [0,20], ...
                MajorTicks = (0:5:20), ...
                MinorTicks = (0:1:20), ...
                Value = 3);
            knobs(31) = uilabel(fig, ...
                Position = [110,220,40,25], ...
                Text = 'speed'); 
    
        % Apps
            apps = {'Apps','rotate','taxi','bounce','takeoff'}';
            knobs(32) = uidropdown(fig, ...
                    Position = [xm-110,ym-440,90,30], ...
                    Items = apps, ...
                    FontWeight = 'bold', ...
                    FontSize = fs, ...
                    BackgroundColor = 'w', ...
                    ValueChangedFcn = @apps_cb);

            fig.UserData = knobs;
        end 
        
        function framed_matrix(M)
            txt = mat4(M);
            ch = get(G.H.Parent.Parent,'children');
            textObj = findobj(ch,'Type','uitextarea');
            set(textObj,'value',txt)
        end
        
        function finish(G)
            axe = G.H.Parent;
            sc = 1/(sqrt(2)^G.scale);
            axis(axe,sc*[-1 1 -1 1 -1 1])
            axis(axe,'square')
            set(axe,Box ='on', ...
                XTick = [], YTick = [], ZTick = [])
        end
        
        function apps_cb(arg,~)
            uic = flipud(arg.Parent.Children);
            viz(uic)
            switch arg.Value
                case 'rotate', rotate(G)
                case 'taxi',   taxi(G)
                case 'bounce', bounce(G)
                case 'takeoff', takeoff(G)
            end     
            arg.Value = 'Apps';
            viz(uic)
        end

        function png_it(G,fname)
            fig = G.H.Parent.Parent;
            knobs = fig.UserData;
            % set(knobs,'vis','off')
            F = getframe(fig);
            F = F.cdata;
            f = imresize(F,2/5);
            imwrite(f,fname,'png')
        end
    end
    %% bounce.m
    function bounce(G)
        G.scale = -3;
        G.vue = 'xy';
        G.H.Parent.Clipping = 'on';
        G.H.Parent.Visible = 'on';
        G.H.Parent.Box = 'on';
        x = -3;
        y = -3;
        dx = 1/4;
        dy = 1/3;
        while abs(x) <= 3 || abs(y) <= 3
            x = x + dx;
            y = y + dy;
            if abs(x) > 3
                dx = -dx;
            end
            if abs(y) > 3
                dy = -dy;
            end
            beta = 15*(abs(x) + abs(y));
            M = Ty(y) * Tx(x) * Ry(3*beta) * Rx(2*beta);
            G = Grafix(G,M);
            pause(.10)
        end
    end
    %% bucky_graph.m
    function bucky_graph(G)
        B = bucky;
        P = plot(graph(B), Layout = 'force3', Parent = G.H);
        V = [P.XData.', P.YData.', P.ZData.'];
        V = V/max(max(abs(V)));
        delete(P)

        G.vue = 'xy';
        ax = G.H.Parent;
        view(ax,0,90)
        C = allcycles(graph(B), maxCycleLength = 6);
        L = cellfun(@length, C);
        F = NaN(height(C), max(L));
        for k = 1:height(C)
            F(k,1:L(k)) = C{k};
        end
        
        colors = [0 0 .5; 1 1 1];
        faceColor = colors((L == max(L))+1, :);
        % faceColor(randi(height(C)),:) = NaN;
                
        patch(Parent = G.H, ...
            Faces = F, ...
            Vertices = V, ...
            EdgeColor = colors(1,:), ...
            FaceVertexCData = faceColor, ...
            FaceColor = 'flat')
    end
    %% cube.m
    function cube(G)
        V = [-1 -1 -1
            -1 -1  1
            -1  1 -1
            -1  1  1
            1 -1 -1
            1 -1  1
            1  1 -1
            1  1  1];
        F = [ 1 3 7 5
            3 4 8 7
            1 2 4 3
            2 4 8 6
            1 2 6 5
            5 6 8 7];
        rgb = [0 0 1; 0 1 0; 1 0 0; 1 1 0; 1 0 1; 0 1 1];
        C = [rgb;rgb;rgb;rgb];
        lw = 2;
        alfa = 1.0;

        V = 2/3*V;

        for k = 1:6
            patch(Parent = G.H, ...
            Vertices = V, ...
            Faces = F(k,:), ...
            FaceColor = C(k,:), ...
            LineWidth = lw, ...
            FaceAlpha = alfa, ...
            EdgeColor = 'k');
        end 

    end
    %% pitch_roll_yaw.m
    function pitch_roll_yaw(arg,~)
        % Pitch, roll, yaw callback
        arg.BackgroundColor = [.5 .8 .9]/.9;
        txt = arg.Text;
        G = arg.UserData;
        uic = flipud(arg.Parent.Children);
        item = uic(17).Value;
        G.item = item;
        viz(uic)
        if isequal(item,'plane')
            delta = 10;
        else
            delta = 3;
        end
        for d = [0:delta:90-delta 90:-delta:-90 -90+delta:delta:0]
            switch txt
                case 'Pitch', M = Rx(d);
                case 'Roll',  M = Ry(d);
                case 'Yaw',   M = Rz(d);
            end
            G = Grafix(G,M);
            drawnow
        end
        arg.BackgroundColor = [1 1 1];
        viz(uic)
    end
    %% plane.m
    function plane(G)
    % Aero Toolbox
    % A = Aero.Animation;
    % A.createBody('pa24-250_blue.ac','Ac3d');
    % Body = A.Bodies{1};
    % Plane = Body.Geometry.FaceVertexColorData;
    % See Grafix/lib/make_plane.

    format compact
    H = G.H;
    bluegreen = [.5 .8 .9]/.9;
    offwhite = .8*[1 1 1];
    sigma = 5.3;
    mu = [3.18 0 0];
    D = diag([-1 1 -1]);
    Z = [0 -1 0;  0 0 1; -1  0 0];
    scale = 2;

    % #1 NoseCylinder
    F = [ ...
        17     9    10    18
        16     8     9    17
        15     7     8    16
        14     6     7    15
        13     5     6    14
        12     4     5    13
        11     3     4    12
        18    10     3    11
        2    17    18   NaN
        2    16    17   NaN
        2    15    16   NaN
        2    14    15   NaN
        2    13    14   NaN
        2    12    13   NaN
        2    11    12   NaN
        2    18    11   NaN
        1    10     9   NaN
        1     9     8   NaN
        1     8     7   NaN
        1     7     6   NaN
        1     6     5   NaN
        1     5     4   NaN
        1     4     3   NaN
        1     3    10   NaN
    ];
    V = [ ...
        1.2130   -0.5704   -0.0016
        1.2425   -0.3606   -0.0016
        1.2582   -0.5768   -0.0016
        1.2449   -0.5749   -0.0355
        1.2130   -0.5704   -0.0495
        1.1811   -0.5659   -0.0355
        1.1679   -0.5641   -0.0016
        1.1811   -0.5659    0.0322
        1.2130   -0.5704    0.0463
        1.2449   -0.5749    0.0322
        1.2877   -0.3670   -0.0016
        1.2744   -0.3651   -0.0355
        1.2425   -0.3606   -0.0495
        1.2106   -0.3561   -0.0355
        1.1974   -0.3543   -0.0016
        1.2106   -0.3561    0.0322
        1.2425   -0.3606    0.0463
        1.2744   -0.3651    0.0322
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #2 NoseWheelStrut
    F = [ ...
        58    56    49   NaN
        58    55    56   NaN
        58    54    55   NaN
        58    53    54   NaN
        58    52    53   NaN
        58    51    52   NaN
        58    50    51   NaN
        58    49    50   NaN
        57    41    48   NaN
        57    48    47   NaN
        57    47    46   NaN
        57    46    45   NaN
        57    45    44   NaN
        57    44    43   NaN
        57    43    42   NaN
        57    42    41   NaN
        41    49    56    48
        48    56    55    47
        47    55    54    46
        46    54    53    45
        45    53    52    44
        44    52    51    43
        43    51    50    42
        42    50    49    41
        9     4     5    10
        8     3     4     9
        7     2     3     8
        6     1     2     7
        10     5     1     6
        14     9    10    15
        13     8     9    14
        12     7     8    13
        11     6     7    12
        15    10     6    11
        19    14    15    20
        18    13    14    19
        17    12    13    18
        16    11    12    17
        20    15    11    16
        24    19    20    25
        23    18    19    24
        22    17    18    23
        21    16    17    22
        25    20    16    21
        29    24    25    30
        28    23    24    29
        27    22    23    28
        26    21    22    27
        30    25    21    26
        34    29    30    35
        33    28    29    34
        32    27    28    33
        31    26    27    32
        35    30    26    31
        39    34    35    40
        38    33    34    39
        37    32    33    38
        36    31    32    37
        40    35    31    36
    ];
    V = [ ...
        1.1115   -1.0143    0.1072
        1.1472   -1.0249    0.1131
        1.1829   -1.0221    0.1072
        1.1971   -0.9970    0.0837
        1.1049   -0.9823    0.0837
        1.1446   -0.7743    0.1048
        1.1820   -0.7775    0.1101
        1.2187   -0.7848    0.1048
        1.2291   -0.7947    0.0835
        1.1342   -0.7813    0.0835
        1.1496   -0.7393    0.0725
        1.1871   -0.7407    0.0762
        1.2236   -0.7497    0.0725
        1.2330   -0.7666    0.0576
        1.1382   -0.7533    0.0576
        1.1523   -0.7196    0.0252
        1.1900   -0.7200    0.0266
        1.2264   -0.7300    0.0252
        1.2352   -0.7508    0.0197
        1.1404   -0.7375    0.0197
        1.1524   -0.7192   -0.0275
        1.1901   -0.7196   -0.0288
        1.2264   -0.7296   -0.0275
        1.2353   -0.7505   -0.0225
        1.1404   -0.7372   -0.0225
        1.1497   -0.7382   -0.0752
        1.1873   -0.7395   -0.0788
        1.2238   -0.7486   -0.0752
        1.2331   -0.7657   -0.0607
        1.1383   -0.7524   -0.0607
        1.1449   -0.7728   -0.1082
        1.1822   -0.7758   -0.1135
        1.2189   -0.7832   -0.1082
        1.2293   -0.7934   -0.0871
        1.1344   -0.7801   -0.0871
        1.1121   -1.0098   -0.1116
        1.1478   -1.0203   -0.1174
        1.1835   -1.0175   -0.1116
        1.1977   -0.9928   -0.0881
        1.1055   -0.9781   -0.0881
        1.2477   -0.4990    0.0232
        1.2231   -0.4956    0.0334
        1.1986   -0.4921    0.0232
        1.1884   -0.4907   -0.0016
        1.1986   -0.4921   -0.0264
        1.2231   -0.4956   -0.0367
        1.2477   -0.4990   -0.0264
        1.2578   -0.5004   -0.0016
        1.2159   -0.7252    0.0232
        1.1913   -0.7218    0.0334
        1.1668   -0.7183    0.0232
        1.1566   -0.7169   -0.0016
        1.1668   -0.7183   -0.0264
        1.1913   -0.7218   -0.0367
        1.2159   -0.7252   -0.0264
        1.2260   -0.7267   -0.0016
        1.2231   -0.4956   -0.0016
        1.1913   -0.7218   -0.0016
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #3 LeftFork
    F = [ ...
        23    28    24    19
        22    27    28    23
        21    26    27    22
        20    25    26    21
        19    24    25    20
        28    33    29    24
        27    32    33    28
        26    31    32    27
        25    30    31    26
        24    29    30    25
        33    38    34    29
        32    37    38    33
        31    36    37    32
        30    35    36    31
        29    34    35    30
        38    43    39    34
        37    42    43    38
        36    41    42    37
        35    40    41    36
        34    39    40    35
        43    48    44    39
        42    47    48    43
        41    46    47    42
        40    45    46    41
        39    44    45    40
        48    53    49    44
        47    52    53    48
        46    51    52    47
        45    50    51    46
        44    49    50    45
        53    58    54    49
        52    57    58    53
        51    56    57    52
        50    55    56    51
        49    54    55    50
        18    10     9    17
        17     9     8    16
        16     8     7    15
        15     7     6    14
        14     6     5    13
        13     5     4    12
        12     4     3    11
        11     3    10    18
        18    17     2   NaN
        17    16     2   NaN
        16    15     2   NaN
        15    14     2   NaN
        14    13     2   NaN
        13    12     2   NaN
        12    11     2   NaN
        11    18     2   NaN
        9    10     1   NaN
        8     9     1   NaN
        7     8     1   NaN
        6     7     1   NaN
        5     6     1   NaN
        4     5     1   NaN
        3     4     1   NaN
        10     3     1   NaN
    ];
    V = [ ...
        3.0892   -0.5344    1.3874
        3.0959   -0.3494    1.3874
        3.1242   -0.5356    1.3874
        3.1140   -0.5353    1.4122
        3.0892   -0.5344    1.4224
        3.0644   -0.5335    1.4122
        3.0542   -0.5332    1.3874
        3.0644   -0.5335    1.3626
        3.0892   -0.5344    1.3523
        3.1140   -0.5353    1.3626
        3.1309   -0.3506    1.3874
        3.1206   -0.3503    1.4122
        3.0959   -0.3494    1.4224
        3.0711   -0.3485    1.4122
        3.0608   -0.3482    1.3874
        3.0711   -0.3485    1.3626
        3.0959   -0.3494    1.3523
        3.1206   -0.3503    1.3626
        3.0307   -0.7983    1.4739
        3.1239   -0.8033    1.4739
        3.1124   -0.8294    1.4973
        3.0772   -0.8358    1.5032
        3.0406   -0.8291    1.4973
        3.0387   -0.5983    1.4729
        3.1344   -0.6017    1.4729
        3.1231   -0.5926    1.4940
        3.0858   -0.5891    1.4993
        3.0483   -0.5900    1.4940
        3.0397   -0.5704    1.4465
        3.1354   -0.5737    1.4465
        3.1243   -0.5577    1.4610
        3.0871   -0.5525    1.4646
        3.0496   -0.5551    1.4610
        3.0402   -0.5550    1.4083
        3.1360   -0.5584    1.4083
        3.1250   -0.5385    1.4133
        3.0878   -0.5324    1.4146
        3.0502   -0.5359    1.4133
        3.0402   -0.5554    1.3660
        3.1359   -0.5587    1.3660
        3.1249   -0.5389    1.3606
        3.0878   -0.5328    1.3592
        3.0502   -0.5363    1.3606
        3.0396   -0.5713    1.3282
        3.1354   -0.5746    1.3282
        3.1242   -0.5588    1.3133
        3.0870   -0.5536    1.3096
        3.0495   -0.5562    1.3133
        3.0387   -0.5996    1.3023
        3.1344   -0.6029    1.3023
        3.1230   -0.5942    1.2810
        3.0857   -0.5908    1.2757
        3.0483   -0.5916    1.2810
        3.0305   -0.8026    1.3021
        3.1238   -0.8075    1.3021
        3.1122   -0.8339    1.2786
        3.0770   -0.8404    1.2727
        3.0404   -0.8337    1.2786
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #4 LeftCylinder
    F = [ ...
        9    16    18   NaN
        16    15    18   NaN
        15    14    18   NaN
        14    13    18   NaN
        13    12    18   NaN
        12    11    18   NaN
        11    10    18   NaN
        10     9    18   NaN
        8     1    17   NaN
        7     8    17   NaN
        6     7    17   NaN
        5     6    17   NaN
        4     5    17   NaN
        3     4    17   NaN
        2     3    17   NaN
        1     2    17   NaN
        8    16     9     1
        7    15    16     8
        6    14    15     7
        5    13    14     6
        4    12    13     5
        3    11    12     4
        2    10    11     3
        1     9    10     2
    ];
    V = [ ...
        3.1312   -0.2706    1.3535
        3.0990   -0.2694    1.3395
        3.0668   -0.2683    1.3535
        3.0535   -0.2679    1.3874
        3.0668   -0.2683    1.4213
        3.0990   -0.2694    1.4353
        3.1312   -0.2706    1.4213
        3.1446   -0.2710    1.3874
        3.1238   -0.4823    1.3535
        3.0916   -0.4812    1.3395
        3.0594   -0.4801    1.3535
        3.0461   -0.4796    1.3874
        3.0594   -0.4801    1.4213
        3.0916   -0.4812    1.4353
        3.1238   -0.4823    1.4213
        3.1372   -0.4828    1.3874
        3.0990   -0.2694    1.3874
        3.0916   -0.4812    1.3874
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #5 NoseWheelDoor
    F = [ ...
        1     2     3     4
        8     5     6     7
        5     4     3     6
        7     2     1     8
        8     1     4     5
        6     3     2     7
    ];
    V = [ ...
        1.0784   -0.6993   -0.1248
        1.4642   -0.7519   -0.1248
        1.4642   -0.7519   -0.1117
        1.0784   -0.6993   -0.1117
        1.1061   -0.5086   -0.1117
        1.4919   -0.5613   -0.1117
        1.4919   -0.5613   -0.1346
        1.1061   -0.5086   -0.1346
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #6 LeftGearDoor
    F = [ ...
        5
        4
        3
        2
        1
    ];
    V = [ ...
        3.0528   -0.4511    1.4732
        3.1669   -0.4479    1.4942
        3.2130   -0.7223    1.6072
        3.2078   -0.7644    1.6182
        3.0003   -0.7558    1.5760
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #7 NoseWheel
    F = [ ...
        76    61    62    77
        75    60    61    76
        74    59    60    75
        73    58    59    74
        72    57    58    73
        71    56    57    72
        70    55    56    71
        69    54    55    70
        68    53    54    69
        67    52    53    68
        66    51    52    67
        65    50    51    66
        64    49    50    65
        63    48    49    64
        77    62    48    63
        47    76    77   NaN
        47    75    76   NaN
        47    74    75   NaN
        47    73    74   NaN
        47    72    73   NaN
        47    71    72   NaN
        47    70    71   NaN
        47    69    70   NaN
        47    68    69   NaN
        47    67    68   NaN
        47    66    67   NaN
        47    65    66   NaN
        47    64    65   NaN
        47    63    64   NaN
        47    77    63   NaN
        46    62    61   NaN
        46    61    60   NaN
        46    60    59   NaN
        46    59    58   NaN
        46    58    57   NaN
        46    57    56   NaN
        46    56    55   NaN
        46    55    54   NaN
        46    54    53   NaN
        46    53    52   NaN
        46    52    51   NaN
        46    51    50   NaN
        46    50    49   NaN
        46    49    48   NaN
        46    48    62   NaN
        62    61    44    45
        45    44    42    43
        43    42    40    41
        61    60    39    44
        44    39    38    42
        42    38    37    40
        60    59    36    39
        39    36    35    38
        38    35    34    37
        59    58    33    36
        36    33    32    35
        35    32    31    34
        58    57    30    33
        33    30    29    32
        32    29    28    31
        57    56    27    30
        30    27    26    29
        29    26    25    28
        56    55    24    27
        27    24    23    26
        26    23    22    25
        55    54    21    24
        24    21    20    23
        23    20    19    22
        54    53    18    21
        21    18    17    20
        20    17    16    19
        53    52    15    18
        18    15    14    17
        17    14    13    16
        52    51    12    15
        15    12    11    14
        14    11    10    13
        51    50     9    12
        12     9     8    11
        11     8     7    10
        50    49     6     9
        9     6     5     8
        8     5     4     7
        49    48     3     6
        6     3     2     5
        5     2     1     4
        48    62    45     3
        3    45    43     2
        2    43    41     1
        78    41    40   NaN
        78    40    37   NaN
        78    37    34   NaN
        78    34    31   NaN
        78    31    28   NaN
        78    28    25   NaN
        78    25    22   NaN
        78    22    19   NaN
        78    19    16   NaN
        78    16    13   NaN
        78    13    10   NaN
        78    10     7   NaN
        78     7     4   NaN
        78     4     1   NaN
        78     1    41   NaN
    ];
    V = [ ...
        1.3401   -0.9806    0.0613
        1.3560   -0.9806    0.0395
        1.3652   -0.9806   -0.0017
        1.3240   -1.0567    0.0613
        1.3385   -1.0656    0.0395
        1.3469   -1.0688   -0.0017
        1.2784   -1.1197    0.0613
        1.2891   -1.1359    0.0395
        1.2951   -1.1418   -0.0017
        1.2112   -1.1586    0.0613
        1.2164   -1.1793    0.0395
        1.2187   -1.1868   -0.0017
        1.1340   -1.1667    0.0613
        1.1329   -1.1884    0.0395
        1.1311   -1.1962   -0.0017
        1.0602   -1.1427    0.0613
        1.0530   -1.1615    0.0395
        1.0472   -1.1684   -0.0017
        1.0025   -1.0906    0.0613
        0.9906   -1.1034    0.0395
        0.9817   -1.1081   -0.0017
        0.9709   -1.0195    0.0613
        0.9564   -1.0241    0.0395
        0.9459   -1.0257   -0.0017
        0.9709   -0.9417    0.0613
        0.9564   -0.9372    0.0395
        0.9459   -0.9356   -0.0017
        1.0025   -0.8707    0.0613
        0.9906   -0.8579    0.0395
        0.9817   -0.8532   -0.0017
        1.0602   -0.8186    0.0613
        1.0530   -0.7998    0.0395
        1.0472   -0.7929   -0.0017
        1.1340   -0.7946    0.0613
        1.1329   -0.7729    0.0395
        1.1311   -0.7651   -0.0017
        1.2112   -0.8027    0.0613
        1.2164   -0.7820    0.0395
        1.2187   -0.7745   -0.0017
        1.2784   -0.8416    0.0613
        1.3240   -0.9045    0.0613
        1.2891   -0.8254    0.0395
        1.3385   -0.8957    0.0395
        1.2951   -0.8195   -0.0017
        1.3469   -0.8925   -0.0017
        1.1533   -0.9793   -0.0429
        1.1515   -0.9787   -0.0626
        1.3546   -0.9793   -0.0429
        1.3373   -1.0629   -0.0429
        1.2881   -1.1321   -0.0429
        1.2155   -1.1748   -0.0429
        1.1323   -1.1837   -0.0429
        1.0527   -1.1573   -0.0429
        0.9905   -1.1001   -0.0429
        0.9564   -1.0221   -0.0429
        0.9564   -0.9366   -0.0429
        0.9905   -0.8585   -0.0429
        1.0527   -0.8013   -0.0429
        1.1323   -0.7749   -0.0429
        1.2155   -0.7838   -0.0429
        1.2881   -0.8266   -0.0429
        1.3373   -0.8957   -0.0429
        1.3362   -0.9787   -0.0626
        1.3202   -1.0556   -0.0626
        1.2751   -1.1192   -0.0626
        1.2086   -1.1585   -0.0626
        1.1322   -1.1667   -0.0626
        1.0592   -1.1424   -0.0626
        1.0022   -1.0898   -0.0626
        0.9709   -1.0180   -0.0626
        0.9709   -0.9394   -0.0626
        1.0022   -0.8675   -0.0626
        1.0592   -0.8149   -0.0626
        1.1322   -0.7906   -0.0626
        1.2086   -0.7989   -0.0626
        1.2751   -0.8382   -0.0626
        1.3202   -0.9018   -0.0626
        1.1535   -0.9806    0.0613
    ];
    cdata = [0.0000 0.0000 0.0000];
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #8 LeftWheel
    F = [ ...
        38    78     1   NaN
        78    75     1   NaN
        75    72     1   NaN
        72    69     1   NaN
        69    66     1   NaN
        66    63     1   NaN
        63    60     1   NaN
        60    57     1   NaN
        57    54     1   NaN
        54    51     1   NaN
        51    48     1   NaN
        48    45     1   NaN
        45    42     1   NaN
        42    39     1   NaN
        39    38     1   NaN
        78    38    36    77
        77    36    34    76
        76    34    17    31
        75    78    77    74
        74    77    76    73
        73    76    31    30
        72    75    74    71
        71    74    73    70
        70    73    30    29
        69    72    71    68
        68    71    70    67
        67    70    29    28
        66    69    68    65
        65    68    67    64
        64    67    28    27
        63    66    65    62
        62    65    64    61
        61    64    27    26
        60    63    62    59
        59    62    61    58
        58    61    26    25
        57    60    59    56
        56    59    58    55
        55    58    25    24
        54    57    56    53
        53    56    55    52
        52    55    24    23
        51    54    53    50
        50    53    52    49
        49    52    23    22
        48    51    50    47
        47    50    49    46
        46    49    22    21
        45    48    47    44
        44    47    46    43
        43    46    21    20
        42    45    44    41
        41    44    43    40
        40    43    20    19
        39    42    41    37
        37    41    40    35
        35    40    19    18
        38    39    37    36
        36    37    35    34
        34    35    18    17
        17    31    33   NaN
        31    30    33   NaN
        30    29    33   NaN
        29    28    33   NaN
        28    27    33   NaN
        27    26    33   NaN
        26    25    33   NaN
        25    24    33   NaN
        24    23    33   NaN
        23    22    33   NaN
        22    21    33   NaN
        21    20    33   NaN
        20    19    33   NaN
        19    18    33   NaN
        18    17    33   NaN
        16     2    32   NaN
        15    16    32   NaN
        14    15    32   NaN
        13    14    32   NaN
        12    13    32   NaN
        11    12    32   NaN
        10    11    32   NaN
        9    10    32   NaN
        8     9    32   NaN
        7     8    32   NaN
        6     7    32   NaN
        5     6    32   NaN
        4     5    32   NaN
        3     4    32   NaN
        2     3    32   NaN
        16    31    17     2
        15    30    31    16
        14    29    30    15
        13    28    29    14
        12    27    28    13
        11    26    27    12
        10    25    26    11
        9    24    25    10
        8    23    24     9
        7    22    23     8
        6    21    22     7
        5    20    21     6
        4    19    20     5
        3    18    19     4
        2    17    18     3
    ];
    V = [ ...
        3.0717   -0.7896    1.3243
        3.2384   -0.7107    1.4481
        3.1933   -0.6471    1.4481
        3.1268   -0.6078    1.4481
        3.0504   -0.5996    1.4481
        2.9774   -0.6239    1.4481
        2.9203   -0.6765    1.4481
        2.8891   -0.7483    1.4481
        2.8891   -0.8269    1.4481
        2.9203   -0.8988    1.4481
        2.9774   -0.9514    1.4481
        3.0504   -0.9757    1.4481
        3.1268   -0.9675    1.4481
        3.1933   -0.9281    1.4481
        3.2384   -0.8645    1.4481
        3.2544   -0.7876    1.4481
        3.2554   -0.7047    1.4284
        3.2062   -0.6355    1.4284
        3.1337   -0.5928    1.4284
        3.0505   -0.5839    1.4284
        2.9709   -0.6103    1.4284
        2.9086   -0.6675    1.4284
        2.8746   -0.7456    1.4284
        2.8746   -0.8310    1.4284
        2.9086   -0.9091    1.4284
        2.9709   -0.9663    1.4284
        3.0505   -0.9927    1.4284
        3.1337   -0.9838    1.4284
        3.2062   -0.9410    1.4284
        3.2554   -0.8719    1.4284
        3.2728   -0.7883    1.4284
        3.0697   -0.7876    1.4481
        3.0715   -0.7883    1.4284
        3.2650   -0.7014    1.3872
        3.2132   -0.6285    1.3872
        3.2567   -0.7047    1.3460
        3.2073   -0.6344    1.3460
        3.2422   -0.7135    1.3243
        3.1966   -0.6506    1.3243
        3.1369   -0.5834    1.3872
        3.1346   -0.5910    1.3460
        3.1293   -0.6117    1.3243
        3.0492   -0.5740    1.3872
        3.0511   -0.5819    1.3460
        3.0522   -0.6035    1.3243
        2.9654   -0.6019    1.3872
        2.9712   -0.6087    1.3460
        2.9783   -0.6276    1.3243
        2.8999   -0.6622    1.3872
        2.9088   -0.6668    1.3460
        2.9207   -0.6796    1.3243
        2.8640   -0.7445    1.3872
        2.8746   -0.7462    1.3460
        2.8891   -0.7507    1.3243
        2.8640   -0.8347    1.3872
        2.8746   -0.8330    1.3460
        2.8891   -0.8285    1.3243
        2.8999   -0.9170    1.3872
        2.9088   -0.9124    1.3460
        2.9207   -0.8996    1.3243
        2.9654   -0.9773    1.3872
        2.9712   -0.9705    1.3460
        2.9783   -0.9516    1.3243
        3.0492   -1.0052    1.3872
        3.0511   -0.9973    1.3460
        3.0522   -0.9757    1.3243
        3.1369   -0.9958    1.3872
        3.1346   -0.9882    1.3460
        3.1293   -0.9675    1.3243
        3.2132   -0.9507    1.3872
        3.2073   -0.9448    1.3460
        3.1966   -0.9286    1.3243
        3.2650   -0.8778    1.3872
        3.2567   -0.8746    1.3460
        3.2422   -0.8657    1.3243
        3.2834   -0.7896    1.3872
        3.2741   -0.7896    1.3460
        3.2583   -0.7896    1.3243
    ];
    cdata = [0.0000 0.0000 0.0000];
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #9 VHF-antena
    F = [ ...
    163   128   201
    128   163   176
    176   163   127
    127   163   202
    202   163   154
    154   163   194
    154   194   189
    189   194   164
    189   164   153
    153   164   207
    153   207   188
    153   188   152
    153   152   208
    188   207   151
    161   126   200
    126   161   175
    175   161   125
    125   161   201
    201   161   163
    163   161   193
    163   193   194
    194   193   162
    194   162   164
    164   162   206
    164   206   186
    164   186   207
    186   206   148
    207   186   149
    121   161   200
    161   121   173
    161   173   122
    161   122   199
    161   199   159
    161   159   193
    193   159   192
    193   192   162
    162   192   160
    162   160   206
    206   160   184
    184   160   205
    206   184   145
    184   205   144
    117   159   199
    159   117   171
    159   171   118
    159   118   198
    159   198   157
    159   157   192
    192   157   191
    192   191   160
    160   191   158
    160   158   205
    205   158   182
    182   158   204
    205   182   141
    182   204   140
    113   157   198
    157   113   169
    157   169   114
    157   114   197
    157   197   155
    157   155   191
    191   155   190
    191   190   158
    158   190   156
    158   156   204
    204   156   180
    180   156   203
    204   180   137
    180   203   136
    154   109   202
    109   154   166
    166   154   108
    108   154   197
    197   154   155
    155   154   189
    155   189   190
    190   189   153
    190   153   156
    156   153   208
    156   208   178
    156   178   203
    178   208   132
    203   178   133
    152   131   208
    131   152   177
    177   152   130
    130   152   188
    130   188   196
    196   188   147
    147   188   151
    147   151   187
    187   151   150
    150   151   207
    147   143   196
    143   147   187
    143   187   185
    185   187   150
    185   150   207
    185   207   146
    146   207   149
    146   149   186
    146   186   206
    143   139   196
    139   143   183
    183   143   142
    142   143   185
    142   185   205
    205   185   144
    144   185   146
    144   146   184
    184   146   145
    145   146   206
    138   140   204
    140   138   181
    140   181   182
    182   181   135
    182   135   196
    182   196   141
    141   196   139
    141   139   183
    141   183   205
    205   183   142
    134   136   203
    136   134   180
    180   134   137
    137   134   179
    137   179   204
    204   179   138
    138   179   129
    138   129   181
    181   129   135
    135   129   196
    133   134   203
    134   133   178
    134   178   179
    179   178   132
    179   132   208
    179   208   129
    129   208   131
    129   131   177
    129   177   130
    129   130   196
    110   127   202
    127   110   167
    127   167   105
    127   105   176
    176   105   195
    176   195   123
    176   123   128
    128   123   174
    128   174   124
    128   124   201
    119   123   195
    123   119   174
    174   119   172
    174   172   124
    124   172   201
    201   172   120
    201   120   125
    125   120   175
    175   120   200
    175   200   126
    115   119   195
    119   115   170
    119   170   116
    119   116   172
    172   116   199
    172   199   122
    172   122   120
    120   122   173
    120   173   121
    120   121   200
    118   112   198
    112   118   168
    168   118   171
    168   171   111
    111   171   195
    195   171   117
    195   117   115
    115   117   170
    170   117   199
    170   199   116
    114   107   197
    107   114   169
    107   169   113
    107   113   165
    165   113   198
    165   198   112
    165   112   106
    106   112   168
    106   168   111
    106   111   195
    107   108   197
    108   107   166
    166   107   165
    166   165   109
    109   165   202
    202   165   106
    202   106   110
    110   106   167
    167   106   105
    105   106   195
        48    49   104
        49    48    84
        49    84    47
        49    47   103
        49   103    60
        49    60    85
        85    60    90
        85    90    50
        50    90    59
        50    59    98
        98    59    72
        72    59    97
        98    72    23
        72    97    24
        45    60   103
        60    45    82
        60    82    44
        60    44   102
        60   102    58
        60    58    90
        90    58    89
        90    89    59
        59    89    57
        59    57    97
        97    57    71
        71    57    96
        97    71    21
        71    96    22
        56    40   101
        40    56    80
        80    56    41
        41    56   102
    102    56    58
        58    56    88
        58    88    89
        89    88    55
        89    55    57
        57    55    95
        57    95    69
        57    69    96
        69    95    18
        96    69    17
        54    36   100
        36    54    78
        78    54    37
        37    54   101
    101    54    56
        56    54    87
        56    87    88
        88    87    53
        88    53    55
        55    53    94
        55    94    67
        55    67    13
        55    13    95
        67    94    14
        52    32    99
        32    52    76
        76    52    33
        33    52   100
    100    52    54
        54    52    86
        54    86    87
        87    86    51
        87    51    53
        53    51    93
        53    93    65
        53    65    94
        65    93    10
        94    65     9
        52    29    99
        29    52    74
        74    52    28
        28    52   104
    104    52    49
        49    52    86
        49    86    85
        85    86    51
        85    51    50
        50    51    93
        50    93    62
        50    62    98
        62    93     4
        98    62     5
        27    48   104
        48    27    73
        48    73    26
        48    26    84
        84    26    92
        84    92    43
        84    43    47
        47    43    83
        47    83    46
        47    46   103
        39    43    92
        43    39    83
        83    39    81
        83    81    46
        46    81   103
    103    81    42
    103    42    45
        45    42    82
        82    42   102
        82   102    44
        35    39    92
        39    35    79
        39    79    38
        39    38    81
        81    38   101
        81   101    40
        81    40    42
        42    40    80
        42    80    41
        42    41   102
        36    34   100
        34    36    77
        77    36    78
        77    78    31
        31    78    92
        92    78    37
        92    37    35
        35    37    79
        79    37   101
        79   101    38
        32    30    99
        30    32    76
        30    76    33
        30    33    75
        75    33   100
        75   100    34
        75    34    25
        25    34    77
        25    77    31
        25    31    92
        30    29    99
        29    30    74
        74    30    75
        74    75    28
        28    75   104
    104    75    25
    104    25    27
        27    25    73
        73    25    26
        26    25    92
        23     6    98
        6    23    63
        63    23     1
        1    23    72
        1    72    91
        91    72    19
        19    72    24
        19    24    70
        70    24    20
        20    24    97
        19    15    91
        15    19    70
        15    70    68
        68    70    20
        68    20    97
        68    97    16
        16    97    21
        16    21    71
        16    71    96
        15    11    91
        11    15    66
        66    15    12
        12    15    68
        12    68    95
        95    68    18
        18    68    16
        18    16    69
        69    16    17
        17    16    96
        8    14    94
        14     8    64
        14    64    67
        67    64     7
        67     7    91
        67    91    13
        13    91    11
        13    11    66
        13    66    95
        95    66    12
        3    10    93
        10     3    65
        65     3     9
        9     3    61
        9    61    94
        94    61     8
        8    61     2
        8     2    64
        64     2     7
        7     2    91
        4     3    93
        3     4    62
        3    62    61
        61    62     5
        61     5    98
        61    98     2
        2    98     6
        2     6    63
        2    63     1
        2     1    91
    ];
    V = [ ...
        6.8131    1.6666    0.3321
        6.8125    1.6655    0.3317
        6.8105    1.6656    0.3299
        6.8100    1.6667    0.3295
        6.8111    1.6689    0.3304
        6.8121    1.6688    0.3313
        6.8130    1.6644    0.3321
        6.8119    1.6622    0.3313
        6.8109    1.6623    0.3304
        6.8099    1.6645    0.3295
        6.8140    1.6643    0.3330
        6.8150    1.6621    0.3339
        6.8145    1.6610    0.3335
        6.8124    1.6611    0.3317
        6.8146    1.6654    0.3335
        6.8167    1.6654    0.3352
        6.8172    1.6642    0.3357
        6.8160    1.6621    0.3348
        6.8141    1.6666    0.3330
        6.8152    1.6687    0.3339
        6.8163    1.6687    0.3348
        6.8172    1.6664    0.3357
        6.8127    1.6699    0.3317
        6.8148    1.6698    0.3335
        7.2234    1.6512    0.0217
        7.2240    1.6522    0.0221
        7.2230    1.6545    0.0212
        7.2220    1.6545    0.0203
        7.2208    1.6524    0.0195
        7.2213    1.6512    0.0199
        7.2239    1.6500    0.0221
        7.2208    1.6501    0.0195
        7.2217    1.6479    0.0203
        7.2228    1.6479    0.0212
        7.2249    1.6500    0.0230
        7.2233    1.6467    0.0217
        7.2253    1.6467    0.0234
        7.2259    1.6478    0.0239
        7.2255    1.6511    0.0234
        7.2269    1.6477    0.0248
        7.2280    1.6499    0.0257
        7.2276    1.6510    0.0252
        7.2250    1.6522    0.0230
        7.2281    1.6521    0.0257
        7.2271    1.6543    0.0248
        7.2261    1.6544    0.0239
        7.2256    1.6555    0.0234
        7.2236    1.6556    0.0217
        7.2187    1.6557    0.0725
        7.0020    1.6633    0.2163
        6.9997    1.6590    0.2146
        7.2165    1.6514    0.0707
        7.0016    1.6545    0.2163
        7.2184    1.6469    0.0725
        7.0058    1.6543    0.2199
        7.2225    1.6468    0.0760
        7.0080    1.6587    0.2217
        7.2248    1.6511    0.0778
        7.0061    1.6632    0.2199
        7.2228    1.6556    0.0760
        6.8115    1.6655    0.3308
        6.8105    1.6678    0.3299
        6.8126    1.6677    0.3317
        6.8125    1.6633    0.3317
        6.8104    1.6634    0.3299
        6.8145    1.6632    0.3335
        6.8134    1.6611    0.3326
        6.8156    1.6654    0.3344
        6.8166    1.6632    0.3352
        6.8147    1.6676    0.3335
        6.8168    1.6676    0.3352
        6.8137    1.6699    0.3326
        7.2235    1.6534    0.0217
        7.2214    1.6534    0.0199
        7.2224    1.6512    0.0208
        7.2213    1.6490    0.0199
        7.2233    1.6490    0.0217
        7.2243    1.6467    0.0226
        7.2254    1.6489    0.0234
        7.2275    1.6488    0.0252
        7.2265    1.6511    0.0243
        7.2276    1.6532    0.0252
        7.2256    1.6533    0.0234
        7.2246    1.6555    0.0226
        7.1923    1.6567    0.1019
        7.1900    1.6523    0.1001
        7.1920    1.6478    0.1019
        7.1961    1.6477    0.1054
        7.1983    1.6520    0.1072
        7.1964    1.6565    0.1054
        6.8136    1.6655    0.3326
        7.2244    1.6511    0.0226
        6.8094    1.6656    0.3290
        6.8113    1.6611    0.3308
        6.8155    1.6610    0.3344
        6.8177    1.6653    0.3361
        6.8158    1.6698    0.3344
        6.8116    1.6700    0.3308
        7.2203    1.6513    0.0190
        7.2222    1.6468    0.0208
        7.2264    1.6466    0.0243
        7.2286    1.6510    0.0261
        7.2267    1.6555    0.0243
        7.2225    1.6556    0.0208
        6.8131    1.6666   -0.3337
        6.8125    1.6655   -0.3332
        6.8105    1.6656   -0.3314
        6.8100    1.6667   -0.3310
        6.8111    1.6689   -0.3319
        6.8121    1.6688   -0.3328
        6.8130    1.6644   -0.3337
        6.8119    1.6622   -0.3328
        6.8109    1.6623   -0.3319
        6.8099    1.6645   -0.3310
        6.8140    1.6643   -0.3346
        6.8150    1.6621   -0.3354
        6.8145    1.6610   -0.3350
        6.8124    1.6611   -0.3332
        6.8146    1.6654   -0.3350
        6.8167    1.6654   -0.3368
        6.8172    1.6642   -0.3372
        6.8160    1.6621   -0.3363
        6.8141    1.6666   -0.3346
        6.8152    1.6687   -0.3354
        6.8163    1.6687   -0.3363
        6.8172    1.6664   -0.3372
        6.8127    1.6699   -0.3332
        6.8148    1.6698   -0.3350
        7.2234    1.6512   -0.0232
        7.2240    1.6522   -0.0236
        7.2230    1.6545   -0.0228
        7.2220    1.6545   -0.0219
        7.2208    1.6524   -0.0210
        7.2213    1.6512   -0.0214
        7.2239    1.6500   -0.0236
        7.2208    1.6501   -0.0210
        7.2217    1.6479   -0.0219
        7.2228    1.6479   -0.0228
        7.2249    1.6500   -0.0245
        7.2233    1.6467   -0.0232
        7.2253    1.6467   -0.0250
        7.2259    1.6478   -0.0254
        7.2255    1.6511   -0.0250
        7.2269    1.6477   -0.0263
        7.2280    1.6499   -0.0272
        7.2276    1.6510   -0.0268
        7.2250    1.6522   -0.0245
        7.2281    1.6521   -0.0272
        7.2271    1.6543   -0.0263
        7.2261    1.6544   -0.0254
        7.2256    1.6555   -0.0250
        7.2236    1.6556   -0.0232
        7.2187    1.6557   -0.0740
        7.0020    1.6633   -0.2179
        6.9997    1.6590   -0.2161
        7.2165    1.6514   -0.0722
        7.0016    1.6545   -0.2179
        7.2184    1.6469   -0.0740
        7.0058    1.6543   -0.2214
        7.2225    1.6468   -0.0775
        7.0080    1.6587   -0.2232
        7.2248    1.6511   -0.0793
        7.0061    1.6632   -0.2214
        7.2228    1.6556   -0.0775
        6.8115    1.6655   -0.3323
        6.8105    1.6678   -0.3314
        6.8126    1.6677   -0.3332
        6.8125    1.6633   -0.3332
        6.8104    1.6634   -0.3314
        6.8145    1.6632   -0.3350
        6.8134    1.6611   -0.3341
        6.8156    1.6654   -0.3359
        6.8166    1.6632   -0.3368
        6.8147    1.6676   -0.3350
        6.8168    1.6676   -0.3368
        6.8137    1.6699   -0.3341
        7.2235    1.6534   -0.0232
        7.2214    1.6534   -0.0214
        7.2224    1.6512   -0.0223
        7.2213    1.6490   -0.0214
        7.2233    1.6490   -0.0232
        7.2243    1.6467   -0.0241
        7.2254    1.6489   -0.0250
        7.2275    1.6488   -0.0268
        7.2265    1.6511   -0.0259
        7.2276    1.6532   -0.0268
        7.2256    1.6533   -0.0250
        7.2246    1.6555   -0.0241
        7.1923    1.6567   -0.1034
        7.1900    1.6523   -0.1016
        7.1920    1.6478   -0.1034
        7.1961    1.6477   -0.1069
        7.1983    1.6520   -0.1087
        7.1964    1.6565   -0.1069
        6.8136    1.6655   -0.3341
        7.2244    1.6511   -0.0241
        6.8094    1.6656   -0.3306
        6.8113    1.6611   -0.3323
        6.8155    1.6610   -0.3359
        6.8177    1.6653   -0.3377
        6.8158    1.6698   -0.3359
        6.8116    1.6700   -0.3323
        7.2203    1.6513   -0.0205
        7.2222    1.6468   -0.0223
        7.2264    1.6466   -0.0259
        7.2286    1.6510   -0.0276
        7.2267    1.6555   -0.0259
        7.2225    1.6556   -0.0223
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #10 Spinner
    F = [ ...
        26    22    11
        32     3    34
        22     4    11
        24    22    26
        27     4    19
        1     4    25
        23    33    22
        23    22    24
        21     6    33
        21    33    23
        33     4    22
        2     4     3
        28    11     9
        20     6    21
        18    14     6
        18     6    20
        30     4    27
        3    35    34
        26    11    28
        17    14    18
        15    19    14
        15    14    17
        19     4    14
        9     4     2
        29     9     2
        13    19    15
        13    27    19
        16     4    30
        29     2    31
        12    27    13
        10    30    27
        10    27    12
        14     4     6
        32     2     3
        8    16    30
        8    30    10
        6     4    33
        11     4     9
        7    25    16
        7    16     8
        5     1    25
        5    25     7
        28     9    29
        25     4    16
        35     3     1
        35     1     5
        3     4     1
        31     2    32
    ];
    V = [ ...
        0.2146    0.1258   -0.0394
        0.2141    0.0239   -0.1302
        0.2141    0.0924   -0.0950
        0.0016    0.0001    0.0003
        0.4383    0.1794   -0.0531
        0.2141   -0.1216    0.0531
        0.4383    0.1864    0.0003
        0.4383    0.1789    0.0555
        0.2146   -0.0395   -0.1254
        0.4383    0.1441    0.1197
        0.2146   -0.0846   -0.1006
        0.4383    0.1036    0.1552
        0.4383    0.0535    0.1796
        0.2141   -0.0718    0.1118
        0.4383   -0.0191    0.1864
        0.2146    0.1267    0.0372
        0.4383   -0.0711    0.1724
        0.4383   -0.1192    0.1443
        0.2141    0.0023    0.1330
        0.4383   -0.1547    0.1038
        0.4383   -0.1791    0.0537
        0.2141   -0.1233   -0.0485
        0.4383   -0.1861    0.0003
        0.4383   -0.1786   -0.0549
        0.2148    0.1315    0.0003
        0.4383   -0.1439   -0.1191
        0.2146    0.0636    0.1159
        0.4383   -0.1033   -0.1545
        0.4383   -0.0533   -0.1789
        0.2146    0.1030    0.0828
        0.4383    0.0001   -0.1859
        0.4383    0.0553   -0.1784
        0.2148   -0.1312    0.0003
        0.4383    0.1036   -0.1545
        0.4383    0.1453   -0.1176
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #11 RightFork
    F = [ ...
        58    56    49   NaN
        58    55    56   NaN
        58    54    55   NaN
        58    53    54   NaN
        58    52    53   NaN
        58    51    52   NaN
        58    50    51   NaN
        58    49    50   NaN
        57    41    48   NaN
        57    48    47   NaN
        57    47    46   NaN
        57    46    45   NaN
        57    45    44   NaN
        57    44    43   NaN
        57    43    42   NaN
        57    42    41   NaN
        41    49    56    48
        48    56    55    47
        47    55    54    46
        46    54    53    45
        45    53    52    44
        44    52    51    43
        43    51    50    42
        42    50    49    41
        9     4     5    10
        8     3     4     9
        7     2     3     8
        6     1     2     7
        10     5     1     6
        14     9    10    15
        13     8     9    14
        12     7     8    13
        11     6     7    12
        15    10     6    11
        19    14    15    20
        18    13    14    19
        17    12    13    18
        16    11    12    17
        20    15    11    16
        24    19    20    25
        23    18    19    24
        22    17    18    23
        21    16    17    22
        25    20    16    21
        29    24    25    30
        28    23    24    29
        27    22    23    28
        26    21    22    27
        30    25    21    26
        34    29    30    35
        33    28    29    34
        32    27    28    33
        31    26    27    32
        35    30    26    31
        39    34    35    40
        38    33    34    39
        37    32    33    38
        36    31    32    37
        40    35    31    36
    ];
    V = [ ...
        3.0404   -0.8337   -1.2801
        3.0770   -0.8404   -1.2743
        3.1122   -0.8339   -1.2801
        3.1238   -0.8075   -1.3036
        3.0305   -0.8026   -1.3036
        3.0483   -0.5916   -1.2826
        3.0857   -0.5908   -1.2772
        3.1230   -0.5942   -1.2826
        3.1344   -0.6029   -1.3039
        3.0387   -0.5996   -1.3039
        3.0495   -0.5562   -1.3149
        3.0870   -0.5536   -1.3112
        3.1242   -0.5588   -1.3149
        3.1354   -0.5746   -1.3297
        3.0396   -0.5713   -1.3297
        3.0502   -0.5363   -1.3621
        3.0878   -0.5328   -1.3608
        3.1249   -0.5389   -1.3621
        3.1359   -0.5587   -1.3676
        3.0402   -0.5554   -1.3676
        3.0502   -0.5359   -1.4149
        3.0878   -0.5324   -1.4161
        3.1250   -0.5385   -1.4149
        3.1360   -0.5584   -1.4098
        3.0402   -0.5550   -1.4098
        3.0496   -0.5551   -1.4625
        3.0871   -0.5525   -1.4662
        3.1243   -0.5577   -1.4625
        3.1354   -0.5737   -1.4480
        3.0397   -0.5704   -1.4480
        3.0483   -0.5900   -1.4956
        3.0858   -0.5891   -1.5009
        3.1231   -0.5926   -1.4956
        3.1344   -0.6017   -1.4745
        3.0387   -0.5983   -1.4745
        3.0406   -0.8291   -1.4989
        3.0772   -0.8358   -1.5048
        3.1124   -0.8294   -1.4989
        3.1239   -0.8033   -1.4754
        3.0307   -0.7983   -1.4754
        3.1206   -0.3503   -1.3642
        3.0959   -0.3494   -1.3539
        3.0711   -0.3485   -1.3642
        3.0608   -0.3482   -1.3889
        3.0711   -0.3485   -1.4137
        3.0959   -0.3494   -1.4240
        3.1206   -0.3503   -1.4137
        3.1309   -0.3506   -1.3889
        3.1140   -0.5353   -1.3642
        3.0892   -0.5344   -1.3539
        3.0644   -0.5335   -1.3642
        3.0542   -0.5332   -1.3889
        3.0644   -0.5335   -1.4137
        3.0892   -0.5344   -1.4240
        3.1140   -0.5353   -1.4137
        3.1242   -0.5356   -1.3889
        3.0959   -0.3494   -1.3889
        3.0892   -0.5344   -1.3889
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #12 RightWheel
    F = [ ...
        78     1    41   NaN
        78     4     1   NaN
        78     7     4   NaN
        78    10     7   NaN
        78    13    10   NaN
        78    16    13   NaN
        78    19    16   NaN
        78    22    19   NaN
        78    25    22   NaN
        78    28    25   NaN
        78    31    28   NaN
        78    34    31   NaN
        78    37    34   NaN
        78    40    37   NaN
        78    41    40   NaN
        2    43    41     1
        3    45    43     2
        48    62    45     3
        5     2     1     4
        6     3     2     5
        49    48     3     6
        8     5     4     7
        9     6     5     8
        50    49     6     9
        11     8     7    10
        12     9     8    11
        51    50     9    12
        14    11    10    13
        15    12    11    14
        52    51    12    15
        17    14    13    16
        18    15    14    17
        53    52    15    18
        20    17    16    19
        21    18    17    20
        54    53    18    21
        23    20    19    22
        24    21    20    23
        55    54    21    24
        26    23    22    25
        27    24    23    26
        56    55    24    27
        29    26    25    28
        30    27    26    29
        57    56    27    30
        32    29    28    31
        33    30    29    32
        58    57    30    33
        35    32    31    34
        36    33    32    35
        59    58    33    36
        38    35    34    37
        39    36    35    38
        60    59    36    39
        42    38    37    40
        44    39    38    42
        61    60    39    44
        43    42    40    41
        45    44    42    43
        62    61    44    45
        46    48    62   NaN
        46    49    48   NaN
        46    50    49   NaN
        46    51    50   NaN
        46    52    51   NaN
        46    53    52   NaN
        46    54    53   NaN
        46    55    54   NaN
        46    56    55   NaN
        46    57    56   NaN
        46    58    57   NaN
        46    59    58   NaN
        46    60    59   NaN
        46    61    60   NaN
        46    62    61   NaN
        47    77    63   NaN
        47    63    64   NaN
        47    64    65   NaN
        47    65    66   NaN
        47    66    67   NaN
        47    67    68   NaN
        47    68    69   NaN
        47    69    70   NaN
        47    70    71   NaN
        47    71    72   NaN
        47    72    73   NaN
        47    73    74   NaN
        47    74    75   NaN
        47    75    76   NaN
        47    76    77   NaN
        77    62    48    63
        63    48    49    64
        64    49    50    65
        65    50    51    66
        66    51    52    67
        67    52    53    68
        68    53    54    69
        69    54    55    70
        70    55    56    71
        71    56    57    72
        72    57    58    73
        73    58    59    74
        74    59    60    75
        75    60    61    76
        76    61    62    77
    ];
    V = [ ...
        3.2662   -0.7928   -1.3258
        3.2820   -0.7928   -1.3476
        3.2913   -0.7928   -1.3887
        3.2501   -0.8689   -1.3258
        3.2646   -0.8778   -1.3476
        3.2729   -0.8810   -1.3887
        3.2045   -0.9319   -1.3258
        3.2152   -0.9481   -1.3476
        3.2211   -0.9539   -1.3887
        3.1372   -0.9708   -1.3258
        3.1425   -0.9915   -1.3476
        3.1448   -0.9990   -1.3887
        3.0601   -0.9789   -1.3258
        3.0589   -1.0006   -1.3476
        3.0571   -1.0084   -1.3887
        2.9863   -0.9549   -1.3258
        2.9791   -0.9737   -1.3476
        2.9733   -0.9806   -1.3887
        2.9286   -0.9028   -1.3258
        2.9167   -0.9156   -1.3476
        2.9078   -0.9203   -1.3887
        2.8970   -0.8317   -1.3258
        2.8825   -0.8363   -1.3476
        2.8720   -0.8379   -1.3887
        2.8970   -0.7539   -1.3258
        2.8825   -0.7494   -1.3476
        2.8720   -0.7478   -1.3887
        2.9286   -0.6829   -1.3258
        2.9167   -0.6701   -1.3476
        2.9078   -0.6654   -1.3887
        2.9863   -0.6308   -1.3258
        2.9791   -0.6120   -1.3476
        2.9733   -0.6051   -1.3887
        3.0601   -0.6068   -1.3258
        3.0589   -0.5851   -1.3476
        3.0571   -0.5772   -1.3887
        3.1372   -0.6149   -1.3258
        3.1425   -0.5942   -1.3476
        3.1448   -0.5867   -1.3887
        3.2045   -0.6538   -1.3258
        3.2501   -0.7167   -1.3258
        3.2152   -0.6376   -1.3476
        3.2646   -0.7079   -1.3476
        3.2211   -0.6317   -1.3887
        3.2729   -0.7047   -1.3887
        3.0794   -0.7915   -1.4300
        3.0776   -0.7909   -1.4496
        3.2807   -0.7915   -1.4300
        3.2633   -0.8751   -1.4300
        3.2141   -0.9443   -1.4300
        3.1416   -0.9870   -1.4300
        3.0584   -0.9959   -1.4300
        2.9788   -0.9695   -1.4300
        2.9165   -0.9123   -1.4300
        2.8825   -0.8343   -1.4300
        2.8825   -0.7488   -1.4300
        2.9165   -0.6707   -1.4300
        2.9788   -0.6135   -1.4300
        3.0584   -0.5871   -1.4300
        3.1416   -0.5960   -1.4300
        3.2141   -0.6388   -1.4300
        3.2633   -0.7079   -1.4300
        3.2623   -0.7909   -1.4496
        3.2463   -0.8678   -1.4496
        3.2012   -0.9314   -1.4496
        3.1347   -0.9707   -1.4496
        3.0583   -0.9789   -1.4496
        2.9853   -0.9546   -1.4496
        2.9282   -0.9020   -1.4496
        2.8970   -0.8302   -1.4496
        2.8970   -0.7516   -1.4496
        2.9282   -0.6797   -1.4496
        2.9853   -0.6271   -1.4496
        3.0583   -0.6028   -1.4496
        3.1347   -0.6110   -1.4496
        3.2012   -0.6504   -1.4496
        3.2463   -0.7140   -1.4496
        3.0796   -0.7928   -1.3258
    ];
    cdata = [0.0000 0.0000 0.0000];
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #13 RightGearDoor
    F = [ ...
        5
        4
        3
        2
        1
    ];
    V = [ ...
        3.0035   -0.7575   -1.5793
        3.2118   -0.7625   -1.6179
        3.2160   -0.7203   -1.6070
        3.1631   -0.4464   -1.4960
        3.0487   -0.4515   -1.4770
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #14 RightCylinder
    F = [ ...
        17     9    10    18
        16     8     9    17
        15     7     8    16
        14     6     7    15
        13     5     6    14
        12     4     5    13
        11     3     4    12
        18    10     3    11
        2    17    18   NaN
        2    16    17   NaN
        2    15    16   NaN
        2    14    15   NaN
        2    13    14   NaN
        2    12    13   NaN
        2    11    12   NaN
        2    18    11   NaN
        1    10     9   NaN
        1     9     8   NaN
        1     8     7   NaN
        1     7     6   NaN
        1     6     5   NaN
        1     5     4   NaN
        1     4     3   NaN
        1     3    10   NaN
    ];
    V = [ ...
        3.0916   -0.4812   -1.3890
        3.0990   -0.2694   -1.3890
        3.1372   -0.4828   -1.3890
        3.1238   -0.4823   -1.4228
        3.0916   -0.4812   -1.4369
        3.0594   -0.4801   -1.4228
        3.0461   -0.4796   -1.3890
        3.0594   -0.4801   -1.3551
        3.0916   -0.4812   -1.3411
        3.1238   -0.4823   -1.3551
        3.1446   -0.2710   -1.3890
        3.1312   -0.2706   -1.4228
        3.0990   -0.2694   -1.4369
        3.0668   -0.2683   -1.4228
        3.0535   -0.2679   -1.3890
        3.0668   -0.2683   -1.3551
        3.0990   -0.2694   -1.3411
        3.1312   -0.2706   -1.3551
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #15 ellipse
    F = [ ...
        1
        2
        3
        4
        5
        6
        7
        8
        9
        10
        11
        12
    ];
    V = [ ...
        0.5806   -0.3914    0.1055
        0.5806   -0.3722    0.0912
        0.5806   -0.3581    0.0520
        0.5806   -0.3529   -0.0014
        0.5806   -0.3581   -0.0548
        0.5806   -0.3722   -0.0940
        0.5806   -0.3914   -0.1083
        0.5806   -0.4107   -0.0940
        0.5806   -0.4248   -0.0548
        0.5806   -0.4300   -0.0014
        0.5806   -0.4248    0.0520
        0.5806   -0.4107    0.0912
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #16 counterweights
    F = [ ...
        1     2     3     4
        5     6     3     4
        6     7     2     3
        7     8     1     2
        8     5     4     1
        8     7     6     5
        17    16    10   NaN
        10    11    17   NaN
        17    11    12   NaN
        12    18    17   NaN
        19    18    12   NaN
        12    13    19   NaN
        19    13    14   NaN
        14    20    19   NaN
        21    20    14   NaN
        14    15    21   NaN
        21    15    10   NaN
        10    16    21   NaN
        22    16    17   NaN
        17    23    22   NaN
        24    23    17   NaN
        17    18    24   NaN
        24    18    19   NaN
        19    25    24   NaN
        26    25    19   NaN
        19    20    26   NaN
        26    20    21   NaN
        21    27    26   NaN
        22    27    21   NaN
        21    16    22   NaN
        29    28    22   NaN
        22    23    29   NaN
        29    23    24   NaN
        24    30    29   NaN
        31    30    24   NaN
        24    25    31   NaN
        31    25    26   NaN
        26    32    31   NaN
        33    32    26   NaN
        26    27    33   NaN
        33    27    22   NaN
        22    28    33   NaN
        34    28    29   NaN
        29    35    34   NaN
        36    35    29   NaN
        29    30    36   NaN
        36    30    31   NaN
        31    37    36   NaN
        38    37    31   NaN
        31    32    38   NaN
        38    32    33   NaN
        33    39    38   NaN
        34    39    33   NaN
        33    28    34   NaN
        11    10     9   NaN
        12    11     9   NaN
        13    12     9   NaN
        14    13     9   NaN
        15    14     9   NaN
        10    15     9   NaN
        34    35    40   NaN
        35    36    40   NaN
        36    37    40   NaN
        37    38    40   NaN
        38    39    40   NaN
        39    34    40   NaN
        44    43    42    41
        44    43    46    45
        43    42    47    46
        42    41    48    47
        41    44    45    48
        45    46    47    48
        50    56    57   NaN
        57    51    50   NaN
        52    51    57   NaN
        57    58    52   NaN
        52    58    59   NaN
        59    53    52   NaN
        54    53    59   NaN
        59    60    54   NaN
        54    60    61   NaN
        61    55    54   NaN
        50    55    61   NaN
        61    56    50   NaN
        57    56    62   NaN
        62    63    57   NaN
        57    63    64   NaN
        64    58    57   NaN
        59    58    64   NaN
        64    65    59   NaN
        59    65    66   NaN
        66    60    59   NaN
        61    60    66   NaN
        66    67    61   NaN
        61    67    62   NaN
        62    56    61   NaN
        62    68    69   NaN
        69    63    62   NaN
        64    63    69   NaN
        69    70    64   NaN
        64    70    71   NaN
        71    65    64   NaN
        66    65    71   NaN
        71    72    66   NaN
        66    72    73   NaN
        73    67    66   NaN
        62    67    73   NaN
        73    68    62   NaN
        69    68    74   NaN
        74    75    69   NaN
        69    75    76   NaN
        76    70    69   NaN
        71    70    76   NaN
        76    77    71   NaN
        71    77    78   NaN
        78    72    71   NaN
        73    72    78   NaN
        78    79    73   NaN
        73    79    74   NaN
        74    68    73   NaN
        49    50    51   NaN
        49    51    52   NaN
        49    52    53   NaN
        49    53    54   NaN
        49    54    55   NaN
        49    55    50   NaN
        80    75    74   NaN
        80    76    75   NaN
        80    77    76   NaN
        80    78    77   NaN
        80    79    78   NaN
        80    74    79   NaN
    ];
    V = [ ...
        7.4162    1.6254    0.1320
        7.5001    1.6254    0.0331
        7.4460    1.6254    0.0373
        7.4048    1.6254    0.1224
        7.4048    1.6325    0.1224
        7.4460    1.6325    0.0373
        7.5001    1.6325    0.0331
        7.4162    1.6325    0.1320
        7.3769    1.6014    0.1458
        7.4069    1.6052    0.1458
        7.3919    1.6052    0.1333
        7.3619    1.6052    0.1333
        7.3469    1.6052    0.1458
        7.3619    1.6052    0.1584
        7.3919    1.6052    0.1584
        7.4289    1.6155    0.1458
        7.4029    1.6155    0.1241
        7.3509    1.6155    0.1241
        7.3249    1.6155    0.1458
        7.3509    1.6155    0.1675
        7.4029    1.6155    0.1675
        7.4369    1.6297    0.1458
        7.4069    1.6297    0.1208
        7.3469    1.6297    0.1208
        7.3168    1.6297    0.1458
        7.3469    1.6297    0.1709
        7.4069    1.6297    0.1709
        7.4289    1.6438    0.1458
        7.4029    1.6438    0.1241
        7.3509    1.6438    0.1241
        7.3249    1.6438    0.1458
        7.3509    1.6438    0.1675
        7.4029    1.6438    0.1675
        7.4069    1.6542    0.1458
        7.3919    1.6542    0.1333
        7.3619    1.6542    0.1333
        7.3469    1.6542    0.1458
        7.3619    1.6542    0.1584
        7.3919    1.6542    0.1584
        7.3769    1.6580    0.1458
        7.4162    1.6254   -0.1320
        7.5001    1.6254   -0.0331
        7.4460    1.6254   -0.0373
        7.4048    1.6254   -0.1224
        7.4048    1.6325   -0.1224
        7.4460    1.6325   -0.0373
        7.5001    1.6325   -0.0331
        7.4162    1.6325   -0.1320
        7.3769    1.6014   -0.1458
        7.4069    1.6052   -0.1458
        7.3919    1.6052   -0.1333
        7.3619    1.6052   -0.1333
        7.3469    1.6052   -0.1458
        7.3619    1.6052   -0.1584
        7.3919    1.6052   -0.1584
        7.4289    1.6155   -0.1458
        7.4029    1.6155   -0.1241
        7.3509    1.6155   -0.1241
        7.3249    1.6155   -0.1458
        7.3509    1.6155   -0.1675
        7.4029    1.6155   -0.1675
        7.4369    1.6297   -0.1458
        7.4069    1.6297   -0.1208
        7.3469    1.6297   -0.1208
        7.3168    1.6297   -0.1458
        7.3469    1.6297   -0.1709
        7.4069    1.6297   -0.1709
        7.4289    1.6438   -0.1458
        7.4029    1.6438   -0.1241
        7.3509    1.6438   -0.1241
        7.3249    1.6438   -0.1458
        7.3509    1.6438   -0.1675
        7.4029    1.6438   -0.1675
        7.4069    1.6542   -0.1458
        7.3919    1.6542   -0.1333
        7.3619    1.6542   -0.1333
        7.3469    1.6542   -0.1458
        7.3619    1.6542   -0.1584
        7.3919    1.6542   -0.1584
        7.3769    1.6580   -0.1458
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #17 nose-wheel-well
    F = [ ...
    101   106    33    28
    100   105   106   101
        99   104   105   100
        98   103   104    99
        97   103    98   NaN
    106   111    38    33
    105   110   111   106
    104   109   110   105
    103   108   109   104
        97   108   103   NaN
    111   116    43    38
    110   115   116   111
    109   114   115   110
    108   113   114   109
        97   113   108   NaN
    116   121    48    43
    115   120   121   116
    114   119   120   115
    113   118   119   114
        97   118   113   NaN
    121   126    53    48
    120   125   126   121
    119   124   125   120
    118   123   124   119
        97   123   118   NaN
    126   131    58    53
    125   130   131   126
    124   129   130   125
    123   128   129   124
        97   128   123   NaN
    131   136    63    58
    130   135   136   131
    129   134   135   130
    128   133   134   129
        97   133   128   NaN
        97    95    96   NaN
    107   102    89   NaN
        97    94    95   NaN
    112   107    89   NaN
        97    93    94   NaN
    117   112    89   NaN
        97    92    93   NaN
    122   117    89   NaN
        97    91    92   NaN
    127   122    89   NaN
        97    90    91   NaN
    132   127    89   NaN
        63   136    88    14
    136   135    87    88
    135   134    86    87
    134   133    85    86
    133    97    84    85
        97    84    90   NaN
    137   132    89   NaN
        96    95    89   NaN
        95    94    89   NaN
        94    93    89   NaN
        93    92    89   NaN
        92    91    89   NaN
        91    90    89   NaN
        90    84    89   NaN
        97    98    82    83
        98    99    81    82
        99   100    80    81
    100   101    79    80
    101    28     3    79
        78    77    84    97
        83   138   144   145
    138   139   146   144
    139   140   147   146
    140   141   148   147
    141   142   149   148
    142   143   150   149
    143    78    77   150
        28    33    32    27
        27    32    31    26
        26    31    30    25
        25    30    29    24
        24    29    23   NaN
        33    38    37    32
        32    37    36    31
        31    36    35    30
        30    35    34    29
        29    34    23   NaN
        38    43    42    37
        37    42    41    36
        36    41    40    35
        35    40    39    34
        34    39    23   NaN
        43    48    47    42
        42    47    46    41
        41    46    45    40
        40    45    44    39
        39    44    23   NaN
        48    53    52    47
        47    52    51    46
        46    51    50    45
        45    50    49    44
        44    49    23   NaN
        53    58    57    52
        52    57    56    51
        51    56    55    50
        50    55    54    49
        49    54    23   NaN
        58    63    62    57
        57    62    61    56
        56    61    60    55
        55    60    59    54
        54    59    23   NaN
        22    21    23   NaN
        21    20    23   NaN
        20    19    23   NaN
        19    18    23   NaN
        18    17    23   NaN
        17    16    23   NaN
        14    13    62    63
        13    12    61    62
        12    11    60    61
        11    10    59    60
        10     9    23    59
        16     9    23   NaN
        15    21    22   NaN
        15    20    21   NaN
        15    19    20   NaN
        15    18    19   NaN
        15    17    18   NaN
        15    16    17   NaN
        15     9    16   NaN
        8     7    24    23
        7     6    25    24
        6     5    26    25
        5     4    27    26
        4     3    28    27
        23     9     1     2
        71    70    64     8
        70    72    65    64
        72    73    66    65
        73    74    67    66
        74    75    68    67
        75    76    69    68
        76     1     2    69
    ];
    V = [ ...
        1.7486   -0.5423    0.1339
        1.9126   -0.5423    0.1339
        2.2162   -0.5415    0.0009
        2.2108   -0.5415    0.0511
        2.2000   -0.5415    0.0863
        2.1649   -0.5415    0.1184
        2.1135   -0.5415    0.1349
        1.9122   -0.5415    0.1339
        1.7486   -0.3423    0.1339
        1.7486   -0.1409    0.1349
        1.7486   -0.0896    0.1184
        1.7486   -0.0544    0.0863
        1.7486   -0.0436    0.0511
        1.7486   -0.0382    0.0009
        1.7508   -0.3394    0.0025
        1.7484   -0.3422    0.1339
        1.7483   -0.3421    0.1339
        1.7482   -0.3420    0.1339
        1.7482   -0.3419    0.1339
        1.7481   -0.3418    0.1339
        1.7481   -0.3416    0.1339
        1.7481   -0.3415    0.1339
        1.9123   -0.3419    0.1339
        2.1135   -0.3415    0.1349
        2.1649   -0.3415    0.1184
        2.2000   -0.3415    0.0863
        2.2108   -0.3415    0.0511
        2.2162   -0.3415    0.0009
        2.1085   -0.2968    0.1349
        2.1585   -0.2854    0.1184
        2.1928   -0.2776    0.0863
        2.2033   -0.2752    0.0511
        2.2086   -0.2739    0.0009
        2.0936   -0.2544    0.1349
        2.1398   -0.2321    0.1184
        2.1715   -0.2169    0.0863
        2.1812   -0.2122    0.0511
        2.1861   -0.2098    0.0009
        2.0696   -0.2163    0.1349
        2.1098   -0.1843    0.1184
        2.1372   -0.1624    0.0863
        2.1457   -0.1557    0.0511
        2.1499   -0.1523    0.0009
        2.0378   -0.1846    0.1349
        2.0698   -0.1444    0.1184
        2.0917   -0.1170    0.0863
        2.0985   -0.1085    0.0511
        2.1018   -0.1043    0.0009
        1.9997   -0.1607    0.1349
        2.0220   -0.1144    0.1184
        2.0372   -0.0828    0.0863
        2.0419   -0.0730    0.0511
        2.0443   -0.0682    0.0009
        1.9573   -0.1459    0.1349
        1.9687   -0.0958    0.1184
        1.9765   -0.0616    0.0863
        1.9789   -0.0510    0.0511
        1.9801   -0.0458    0.0009
        1.9126   -0.1409    0.1349
        1.9126   -0.0896    0.1184
        1.9126   -0.0544    0.0863
        1.9126   -0.0436    0.0511
        1.9126   -0.0382    0.0009
        1.9121   -0.5416    0.1339
        1.9121   -0.5418    0.1339
        1.9122   -0.5419    0.1339
        1.9122   -0.5420    0.1339
        1.9123   -0.5421    0.1339
        1.9125   -0.5422    0.1339
        1.7481   -0.5416    0.1339
        1.7481   -0.5415    0.1339
        1.7481   -0.5418    0.1339
        1.7482   -0.5419    0.1339
        1.7482   -0.5420    0.1339
        1.7483   -0.5421    0.1339
        1.7484   -0.5422    0.1339
        1.7486   -0.5423   -0.1321
        1.9126   -0.5423   -0.1321
        2.2108   -0.5415   -0.0493
        2.2000   -0.5415   -0.0845
        2.1649   -0.5415   -0.1166
        2.1135   -0.5415   -0.1331
        1.9122   -0.5415   -0.1321
        1.7486   -0.3423   -0.1321
        1.7486   -0.1409   -0.1331
        1.7486   -0.0896   -0.1166
        1.7486   -0.0544   -0.0845
        1.7486   -0.0436   -0.0493
        1.7508   -0.3394   -0.0007
        1.7484   -0.3422   -0.1321
        1.7483   -0.3421   -0.1321
        1.7482   -0.3420   -0.1321
        1.7482   -0.3419   -0.1321
        1.7481   -0.3418   -0.1321
        1.7481   -0.3416   -0.1321
        1.7481   -0.3415   -0.1321
        1.9123   -0.3419   -0.1321
        2.1135   -0.3415   -0.1331
        2.1649   -0.3415   -0.1166
        2.2000   -0.3415   -0.0845
        2.2108   -0.3415   -0.0493
        1.9162   -0.3415   -0.0007
        2.1085   -0.2968   -0.1331
        2.1585   -0.2854   -0.1166
        2.1928   -0.2776   -0.0845
        2.2033   -0.2752   -0.0493
        1.9161   -0.3407   -0.0007
        2.0936   -0.2544   -0.1331
        2.1398   -0.2321   -0.1166
        2.1715   -0.2169   -0.0845
        2.1812   -0.2122   -0.0493
        1.9158   -0.3400   -0.0007
        2.0696   -0.2163   -0.1331
        2.1098   -0.1843   -0.1166
        2.1372   -0.1624   -0.0845
        2.1457   -0.1557   -0.0493
        1.9153   -0.3394   -0.0007
        2.0378   -0.1846   -0.1331
        2.0698   -0.1444   -0.1166
        2.0917   -0.1170   -0.0845
        2.0985   -0.1085   -0.0493
        1.9148   -0.3389   -0.0007
        1.9997   -0.1607   -0.1331
        2.0220   -0.1144   -0.1166
        2.0372   -0.0828   -0.0845
        2.0419   -0.0730   -0.0493
        1.9141   -0.3385   -0.0007
        1.9573   -0.1459   -0.1331
        1.9687   -0.0958   -0.1166
        1.9765   -0.0616   -0.0845
        1.9789   -0.0510   -0.0493
        1.9134   -0.3383   -0.0007
        1.9126   -0.1409   -0.1331
        1.9126   -0.0896   -0.1166
        1.9126   -0.0544   -0.0845
        1.9126   -0.0436   -0.0493
        1.9126   -0.3382   -0.0007
        1.9121   -0.5416   -0.1321
        1.9121   -0.5418   -0.1321
        1.9122   -0.5419   -0.1321
        1.9122   -0.5420   -0.1321
        1.9123   -0.5421   -0.1321
        1.9125   -0.5422   -0.1321
        1.7481   -0.5416   -0.1321
        1.7481   -0.5415   -0.1321
        1.7481   -0.5418   -0.1321
        1.7482   -0.5419   -0.1321
        1.7482   -0.5420   -0.1321
        1.7483   -0.5421   -0.1321
        1.7484   -0.5422   -0.1321
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #18 engine-block
    F = [ ...
        26    25    31    32
        25    24    30    31
        24    23    29    30
        23    22    28    29
        22    21    27    28
        21    26    32    27
        32    31    20   NaN
        31    30    20   NaN
        30    29    20   NaN
        29    28    20   NaN
        28    27    20   NaN
        27    32    20   NaN
        25    26    19   NaN
        24    25    19   NaN
        23    24    19   NaN
        22    23    19   NaN
        21    22    19   NaN
        26    21    19   NaN
        17    25    26    18
        16    24    25    17
        15    23    24    16
        14    22    23    15
        13    21    22    14
        18    26    21    13
        17    18    33   NaN
        16    17    33   NaN
        15    16    33   NaN
        14    15    33   NaN
        13    14    33   NaN
        18    13    33   NaN
        11    17    18    12
        10    16    17    11
        9    15    16    10
        8    14    15     9
        7    13    14     8
        12    18    13     7
        11    12    34   NaN
        10    11    34   NaN
        9    10    34   NaN
        8     9    34   NaN
        7     8    34   NaN
        12     7    34   NaN
        11    12     5     6
        10    11     6     4
        9    10     4     3
        8     9     3     2
        7     8     2     1
        12     7     1     5
        6     5    35   NaN
        4     6    35   NaN
        3     4    35   NaN
        2     3    35   NaN
        1     2    35   NaN
        5     1    35   NaN
    ];
    V = [ ...
        0.4319   -0.0545    0.0002
        0.4319   -0.0273   -0.0454
        0.4319    0.0272   -0.0454
        0.4319    0.0545    0.0002
        0.4319   -0.0273    0.0457
        0.4319    0.0272    0.0457
        0.5319   -0.0545    0.0002
        0.5319   -0.0273   -0.0454
        0.5319    0.0272   -0.0454
        0.5319    0.0545    0.0002
        0.5319    0.0272    0.0457
        0.5319   -0.0273    0.0457
        0.5519   -0.1297   -0.0001
        0.5519   -0.0626   -0.1281
        0.5519    0.0716   -0.1281
        0.5519    0.1387   -0.0001
        0.5519    0.0716    0.1280
        0.5519   -0.0626    0.1280
        0.5719    0.0022    0.0004
        0.7236    0.0022    0.0004
        0.5719   -0.1657    0.0004
        0.5719   -0.0817   -0.1586
        0.5719    0.0862   -0.1586
        0.5719    0.1701    0.0004
        0.5719    0.0862    0.1594
        0.5719   -0.0817    0.1594
        0.7236   -0.1657    0.0004
        0.7236   -0.0817   -0.1586
        0.7236    0.0862   -0.1586
        0.7236    0.1701    0.0004
        0.7236    0.0862    0.1594
        0.7236   -0.0817    0.1594
        0.5519    0.0045   -0.0001
        0.5319   -0.0000    0.0002
        0.4319   -0.0000    0.0002
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #19 cylinders
    F = [ ...
        56    54    46   NaN
        56    53    54   NaN
        56    52    53   NaN
        56    51    52   NaN
        56    50    51   NaN
        56    49    50   NaN
        56    48    49   NaN
        56    47    48   NaN
        56    46    47   NaN
        45    37    55   NaN
        44    45    55   NaN
        43    44    55   NaN
        42    43    55   NaN
        41    42    55   NaN
        40    41    55   NaN
        39    40    55   NaN
        38    39    55   NaN
        37    38    55   NaN
        37    46    54    45
        45    54    53    44
        44    53    52    43
        43    52    51    42
        42    51    50    41
        41    50    49    40
        40    49    48    39
        39    48    47    38
        38    47    46    37
        36    35    34    33
        29    32    31    30
        32    33    34    31
        30    35    36    29
        32    29    36    33
        31    34    35    30
        18    26    28   NaN
        26    25    28   NaN
        25    24    28   NaN
        24    23    28   NaN
        23    22    28   NaN
        22    21    28   NaN
        21    20    28   NaN
        20    19    28   NaN
        19    18    28   NaN
        27     9    17   NaN
        27    17    16   NaN
        27    16    15   NaN
        27    15    14   NaN
        27    14    13   NaN
        27    13    12   NaN
        27    12    11   NaN
        27    11    10   NaN
        27    10     9   NaN
        17    26    18     9
        16    25    26    17
        15    24    25    16
        14    23    24    15
        13    22    23    14
        12    21    22    13
        11    20    21    12
        10    19    20    11
        9    18    19    10
        5     6     7     8
        2     3     4     1
        3     6     5     4
        1     8     7     2
        5     8     1     4
        2     7     6     3
    ];
    V = [ ...
        0.5799    0.0612    0.4199
        0.7280    0.0612    0.4199
        0.7280    0.0903    0.2624
        0.5799    0.0903    0.2624
        0.5799   -0.0874    0.2624
        0.7280   -0.0874    0.2624
        0.7280   -0.0670    0.4199
        0.5799   -0.0670    0.4199
        0.6967    0.0415    0.2616
        0.6621    0.0620    0.2616
        0.6227    0.0549    0.2616
        0.5971    0.0234    0.2616
        0.5971   -0.0177    0.2616
        0.6227   -0.0491    0.2616
        0.6621   -0.0563    0.2616
        0.6967   -0.0357    0.2616
        0.7103    0.0029    0.2616
        0.6967    0.0415    0.1584
        0.6621    0.0620    0.1584
        0.6227    0.0549    0.1584
        0.5971    0.0234    0.1584
        0.5971   -0.0177    0.1584
        0.6227   -0.0491    0.1584
        0.6621   -0.0563    0.1584
        0.6967   -0.0357    0.1584
        0.7103    0.0029    0.1584
        0.6519    0.0029    0.2616
        0.6519    0.0029    0.1584
        0.5799    0.0612   -0.4199
        0.7280    0.0612   -0.4199
        0.7280    0.0903   -0.2624
        0.5799    0.0903   -0.2624
        0.5799   -0.0874   -0.2624
        0.7280   -0.0874   -0.2624
        0.7280   -0.0670   -0.4199
        0.5799   -0.0670   -0.4199
        0.6967    0.0415   -0.2616
        0.6621    0.0620   -0.2616
        0.6227    0.0549   -0.2616
        0.5971    0.0234   -0.2616
        0.5971   -0.0177   -0.2616
        0.6227   -0.0491   -0.2616
        0.6621   -0.0563   -0.2616
        0.6967   -0.0357   -0.2616
        0.7103    0.0029   -0.2616
        0.6967    0.0415   -0.1584
        0.6621    0.0620   -0.1584
        0.6227    0.0549   -0.1584
        0.5971    0.0234   -0.1584
        0.5971   -0.0177   -0.1584
        0.6227   -0.0491   -0.1584
        0.6621   -0.0563   -0.1584
        0.6967   -0.0357   -0.1584
        0.7103    0.0029   -0.1584
        0.6519    0.0029   -0.2616
        0.6519    0.0029   -0.1584
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #20 baffel
    F = [ ...
        9    23    21    24    14    12    28    22    27    25    26
        18    17    19    13    20    12    14    16    11    15     4
        9     8     7     6    10   NaN   NaN   NaN   NaN   NaN   NaN
        5     1     2     3     4   NaN   NaN   NaN   NaN   NaN   NaN
    ];
    V = [ ...
        0.5226   -0.0387   -0.0528
        0.6006   -0.0387   -0.0512
        0.6006   -0.0387   -0.4437
        0.5242   -0.0387   -0.4242
        0.5234   -0.0387   -0.2385
        0.5226   -0.0387    0.0528
        0.6006   -0.0387    0.0512
        0.6006   -0.0387    0.4437
        0.5242   -0.0387    0.4242
        0.5234   -0.0387    0.2385
        0.5229   -0.0387   -0.0528
        0.4697   -0.2613         0
        0.4727   -0.2435   -0.2050
        0.5007   -0.0987         0
        0.5235   -0.0387   -0.2385
        0.5060   -0.0751   -0.0529
        0.4930   -0.1471   -0.3875
        0.5040   -0.0936   -0.4206
        0.4820   -0.1923   -0.3304
        0.4703   -0.2591   -0.1046
        0.5229   -0.0387    0.0528
        0.4727   -0.2435    0.2050
        0.5235   -0.0387    0.2385
        0.5060   -0.0751    0.0529
        0.4930   -0.1471    0.3875
        0.5040   -0.0936    0.4206
        0.4820   -0.1923    0.3304
        0.4703   -0.2591    0.1046
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #21 bendix
    F = [ ...
        37    28    29    38
        36    27    28    37
        35    26    27    36
        34    25    26    35
        33    24    25    34
        32    23    24    33
        31    22    23    32
        30    21    22    31
        38    29    21    30
        20    37    38   NaN
        20    36    37   NaN
        20    35    36   NaN
        20    34    35   NaN
        20    33    34   NaN
        20    32    33   NaN
        20    31    32   NaN
        20    30    31   NaN
        20    38    30   NaN
        19    29    28   NaN
        19    28    27   NaN
        19    27    26   NaN
        19    26    25   NaN
        19    25    24   NaN
        19    24    23   NaN
        19    23    22   NaN
        19    22    21   NaN
        19    21    29   NaN
        29    28    17    18
        18    17    15    16
        28    27    14    17
        17    14    13    15
        27    26    12    14
        14    12    11    13
        26    25    10    12
        12    10     9    11
        25    24     8    10
        10     8     7     9
        24    23     6     8
        8     6     5     7
        23    22     4     6
        6     4     3     5
        22    21     2     4
        4     2     1     3
        21    29    18     2
        2    18    16     1
        39    16    15   NaN
        39    15    13   NaN
        39    13    11   NaN
        39    11     9   NaN
        39     9     7   NaN
        39     7     5   NaN
        39     5     3   NaN
        39     3     1   NaN
        39     1    16   NaN
    ];
    V = [ ...
        0.4410   -0.1670    0.1067
        0.4460   -0.1666    0.1171
        0.4410   -0.1770    0.1029
        0.4460   -0.1832    0.1107
        0.4410   -0.1824    0.0933
        0.4460   -0.1920    0.0946
        0.4410   -0.1805    0.0824
        0.4460   -0.1889    0.0762
        0.4410   -0.1723    0.0753
        0.4460   -0.1754    0.0643
        0.4410   -0.1616    0.0753
        0.4460   -0.1578    0.0643
        0.4410   -0.1534    0.0824
        0.4460   -0.1443    0.0762
        0.4410   -0.1516    0.0933
        0.4410   -0.1569    0.1029
        0.4460   -0.1412    0.0946
        0.4460   -0.1501    0.1107
        0.4524   -0.1666    0.0901
        0.5113   -0.1666    0.0901
        0.4524   -0.1666    0.1209
        0.4524   -0.1855    0.1137
        0.4524   -0.1956    0.0954
        0.4524   -0.1921    0.0746
        0.4524   -0.1767    0.0610
        0.4524   -0.1566    0.0610
        0.4524   -0.1412    0.0746
        0.4524   -0.1377    0.0954
        0.4524   -0.1477    0.1137
        0.5113   -0.1666    0.1209
        0.5113   -0.1855    0.1137
        0.5113   -0.1956    0.0954
        0.5113   -0.1921    0.0746
        0.5113   -0.1767    0.0610
        0.5113   -0.1566    0.0610
        0.5113   -0.1412    0.0746
        0.5113   -0.1377    0.0954
        0.5113   -0.1477    0.1137
        0.4410   -0.1670    0.0905
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #22 alternator
    F = [ ...
        28    19    20    29
        27    18    19    28
        26    17    18    27
        25    16    17    26
        24    15    16    25
        23    14    15    24
        22    13    14    23
        21    12    13    22
        29    20    12    21
        11    28    29   NaN
        11    27    28   NaN
        11    26    27   NaN
        11    25    26   NaN
        11    24    25   NaN
        11    23    24   NaN
        11    22    23   NaN
        11    21    22   NaN
        11    29    21   NaN
        10    20    19   NaN
        10    19    18   NaN
        10    18    17   NaN
        10    17    16   NaN
        10    16    15   NaN
        10    15    14   NaN
        10    14    13   NaN
        10    13    12   NaN
        10    12    20   NaN
        20    19     8     9
        19    18     7     8
        18    17     6     7
        17    16     5     6
        16    15     4     5
        15    14     3     4
        14    13     2     3
        13    12     1     2
        12    20     9     1
        30     9     8   NaN
        30     8     7   NaN
        30     7     6   NaN
        30     6     5   NaN
        30     5     4   NaN
        30     4     3   NaN
        30     3     2   NaN
        30     2     1   NaN
        30     1     9   NaN
    ];
    V = [ ...
        0.4750   -0.1689   -0.1069
        0.4750   -0.1875   -0.1142
        0.4750   -0.1974   -0.1325
        0.4750   -0.1940   -0.1534
        0.4750   -0.1788   -0.1671
        0.4750   -0.1590   -0.1671
        0.4750   -0.1439   -0.1534
        0.4750   -0.1405   -0.1325
        0.4750   -0.1503   -0.1142
        0.4923   -0.1689   -0.1372
        0.5099   -0.1689   -0.1379
        0.4923   -0.1689   -0.1149
        0.4923   -0.1875   -0.1201
        0.4923   -0.1974   -0.1333
        0.4923   -0.1940   -0.1483
        0.4923   -0.1788   -0.1581
        0.4923   -0.1590   -0.1581
        0.4923   -0.1439   -0.1483
        0.4923   -0.1405   -0.1333
        0.4923   -0.1503   -0.1201
        0.5099   -0.1689   -0.1069
        0.5099   -0.1875   -0.1142
        0.5099   -0.1974   -0.1325
        0.5099   -0.1940   -0.1534
        0.5099   -0.1788   -0.1671
        0.5099   -0.1590   -0.1671
        0.5099   -0.1439   -0.1534
        0.5099   -0.1405   -0.1325
        0.5099   -0.1503   -0.1142
        0.4750   -0.1689   -0.1379
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #23 StrobeOff
    F = [ ...
        3     2     1
        3     2     4
        2     1     4
        1     3     4
        5     6     7
        8     6     7
        8     5     6
        8     7     5
    ];
    V = [ ...
        2.6843    0.0394    5.3618
        2.6315    0.0219    5.3618
        2.6315    0.0619    5.3618
        2.6491    0.0408    5.3829
        2.6848    0.0394   -5.3618
        2.6315    0.0219   -5.3618
        2.6315    0.0619   -5.3618
        2.6491    0.0403   -5.3968
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #24 RearNavLightOn
    F = [ ...
        4     1     2     5
        2     3     6     5
        4     5     6   NaN
        1     4     6     3
        12     9     7    10
        9     8     7   NaN
        11    10     7     8
        9    12    11     8
    ];
    V = [ ...
        7.4896    0.5358   -0.0206
        7.4896    0.5358    0.0206
        7.4921    0.4634   -0.0000
        7.5519    0.5358   -0.0206
        7.5519    0.5358    0.0206
        7.5552    0.4649   -0.0000
        7.5535    0.1785   -0.0000
        7.5503    0.1076   -0.0206
        7.5503    0.1076    0.0206
        7.4904    0.1800   -0.0000
        7.4880    0.1076   -0.0206
        7.4880    0.1076    0.0206
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #25 RearNavLightOff
    F = [ ...
        4     1     2     5
        2     3     6     5
        4     5     6   NaN
        1     4     6     3
        12     9     7    10
        9     8     7   NaN
        11    10     7     8
        9    12    11     8
    ];
    V = [ ...
        7.4880    0.1076    0.0206
        7.4880    0.1076   -0.0206
        7.4904    0.1800   -0.0000
        7.5503    0.1076    0.0206
        7.5503    0.1076   -0.0206
        7.5535    0.1785   -0.0000
        7.5552    0.4649   -0.0000
        7.5519    0.5358    0.0206
        7.5519    0.5358   -0.0206
        7.4921    0.4634   -0.0000
        7.4896    0.5358    0.0206
        7.4896    0.5358   -0.0206
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #26 LeftNavLightOn
    F = [ ...
        5     4     3     2     1
        10     6     5     1   NaN
        9    10     1     2   NaN
        8     9     2     3   NaN
        7     8     3     4   NaN
        6     7     4     5   NaN
        6     7     8     9    10
    ];
    V = [ ...
        2.6299    0.0315    5.3805
        2.6185    0.0323    5.3805
        2.6135    0.0409    5.3805
        2.6179    0.0493    5.3805
        2.6299    0.0522    5.3805
        2.6299    0.0683    5.3617
        2.6076    0.0613    5.3617
        2.5995    0.0409    5.3617
        2.6088    0.0199    5.3617
        2.6303    0.0167    5.3617
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #27 LeftNavLightOff
    F = [ ...
        5     4     3     2     1
        5     4     7     6   NaN
        4     3     8     7   NaN
        3     2     9     8   NaN
        2     1    10     9   NaN
        1     5     6    10   NaN
        6     7     8     9    10
    ];
    V = [ ...
        2.6302    0.0235    5.3614
        2.6125    0.0249    5.3614
        2.6046    0.0412    5.3614
        2.6115    0.0569    5.3614
        2.6302    0.0623    5.3614
        2.6302    0.0498    5.3779
        2.6201    0.0476    5.3779
        2.6164    0.0411    5.3779
        2.6207    0.0345    5.3779
        2.6302    0.0339    5.3779
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #28 RightNavLightOff
    F = [ ...
        1     2     3     4     5
        1     5     6    10   NaN
        2     1    10     9   NaN
        3     2     9     8   NaN
        4     3     8     7   NaN
        5     4     7     6   NaN
        10     9     8     7     6
    ];
    V = [ ...
        2.6302    0.0333   -5.3895
        2.6207    0.0339   -5.3895
        2.6164    0.0405   -5.3895
        2.6201    0.0470   -5.3895
        2.6302    0.0492   -5.3895
        2.6302    0.0617   -5.3617
        2.6115    0.0563   -5.3617
        2.6046    0.0406   -5.3617
        2.6125    0.0243   -5.3617
        2.6302    0.0229   -5.3617
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #29 RightNavLightOn
    F = [ ...
        1     2     3     4     5
        6     7     4     5   NaN
        7     8     3     4   NaN
        8     9     2     3   NaN
        9    10     1     2   NaN
        10     6     5     1   NaN
        10     9     8     7     6
    ];
    V = [ ...
        2.6302    0.0163   -5.3617
        2.6125    0.0183   -5.3617
        2.6046    0.0401   -5.3617
        2.6115    0.0613   -5.3617
        2.6302    0.0686   -5.3617
        2.6302    0.0518   -5.3924
        2.6201    0.0488   -5.3924
        2.6164    0.0401   -5.3924
        2.6207    0.0311   -5.3924
        2.6302    0.0303   -5.3924
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #30 Mixture
    F = [ ...
        34    39    38    33
        35    40    39    34
        36    41    40    35
        37    42    41    36
        33    38    42    37
        43    34    33   NaN
        43    35    34   NaN
        43    36    35   NaN
        43    37    36   NaN
        43    33    37   NaN
        44    38    39   NaN
        44    39    40   NaN
        44    40    41   NaN
        44    41    42   NaN
        44    42    38   NaN
        2     8     9   NaN
        9     3     2   NaN
        4     3     9   NaN
        9    10     4   NaN
        4    10    11   NaN
        11     5     4   NaN
        6     5    11   NaN
        11    12     6   NaN
        6    12    13   NaN
        13     7     6   NaN
        2     7    13   NaN
        13     8     2   NaN
        9     8    14   NaN
        14    15     9   NaN
        9    15    16   NaN
        16    10     9   NaN
        11    10    16   NaN
        16    17    11   NaN
        11    17    18   NaN
        18    12    11   NaN
        13    12    18   NaN
        18    19    13   NaN
        13    19    14   NaN
        14     8    13   NaN
        14    20    21   NaN
        21    15    14   NaN
        16    15    21   NaN
        21    22    16   NaN
        16    22    23   NaN
        23    17    16   NaN
        18    17    23   NaN
        23    24    18   NaN
        18    24    25   NaN
        25    19    18   NaN
        14    19    25   NaN
        25    20    14   NaN
        21    20    26   NaN
        26    27    21   NaN
        21    27    28   NaN
        28    22    21   NaN
        23    22    28   NaN
        28    29    23   NaN
        23    29    30   NaN
        30    24    23   NaN
        25    24    30   NaN
        30    31    25   NaN
        25    31    26   NaN
        26    20    25   NaN
        1     2     3   NaN
        1     3     4   NaN
        1     4     5   NaN
        1     5     6   NaN
        1     6     7   NaN
        1     7     2   NaN
        32    27    26   NaN
        32    28    27   NaN
        32    29    28   NaN
        32    30    29   NaN
        32    31    30   NaN
        32    26    31   NaN
    ];
    V = [ ...
        2.2087   -0.0119    0.0545
        2.2148   -0.0103    0.0545
        2.2118   -0.0103    0.0607
        2.2056   -0.0103    0.0607
        2.2025   -0.0103    0.0545
        2.2056   -0.0103    0.0484
        2.2118   -0.0103    0.0484
        2.2193   -0.0058    0.0545
        2.2140   -0.0058    0.0652
        2.2034   -0.0058    0.0652
        2.1980   -0.0058    0.0545
        2.2034   -0.0058    0.0439
        2.2140   -0.0058    0.0439
        2.2210    0.0004    0.0545
        2.2148    0.0004    0.0668
        2.2025    0.0004    0.0668
        2.1964    0.0004    0.0545
        2.2025    0.0004    0.0422
        2.2148    0.0004    0.0422
        2.2193    0.0065    0.0545
        2.2140    0.0065    0.0652
        2.2034    0.0065    0.0652
        2.1980    0.0065    0.0545
        2.2034    0.0065    0.0439
        2.2140    0.0065    0.0439
        2.2148    0.0110    0.0545
        2.2118    0.0110    0.0607
        2.2056    0.0110    0.0607
        2.2025    0.0110    0.0545
        2.2056    0.0110    0.0484
        2.2118    0.0110    0.0484
        2.2087    0.0127    0.0545
        2.1970    0.0033    0.0555
        2.1970    0.0021    0.0516
        2.1970   -0.0017    0.0516
        2.1970   -0.0028    0.0555
        2.1970    0.0002    0.0580
        2.0541    0.0033    0.0555
        2.0541    0.0021    0.0516
        2.0541   -0.0017    0.0516
        2.0541   -0.0028    0.0555
        2.0541    0.0002    0.0580
        2.1970    0.0002    0.0544
        2.0541    0.0002    0.0544
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #31 ThrotelLock
    F = [ ...
        1     3    11   NaN
        1     4     3   NaN
        1     5     4   NaN
        1     6     5   NaN
        1     7     6   NaN
        1     8     7   NaN
        1     9     8   NaN
        1    10     9   NaN
        1    11    10   NaN
        2    20    12   NaN
        2    12    13   NaN
        2    13    14   NaN
        2    14    15   NaN
        2    15    16   NaN
        2    16    17   NaN
        2    17    18   NaN
        2    18    19   NaN
        2    19    20   NaN
        20    11     3    12
        12     3     4    13
        13     4     5    14
        14     5     6    15
        15     6     7    16
        16     7     8    17
        17     8     9    18
        18     9    10    19
        19    10    11    20
    ];
    V = [ ...
        2.1225    0.0006    0.0085
        2.1311    0.0006    0.0085
        2.1225    0.0006    0.0179
        2.1225   -0.0054    0.0157
        2.1225   -0.0085    0.0101
        2.1225   -0.0074    0.0038
        2.1225   -0.0026   -0.0003
        2.1225    0.0037   -0.0003
        2.1225    0.0086    0.0038
        2.1225    0.0097    0.0101
        2.1225    0.0065    0.0157
        2.1311    0.0006    0.0179
        2.1311   -0.0054    0.0157
        2.1311   -0.0085    0.0101
        2.1311   -0.0074    0.0038
        2.1311   -0.0026   -0.0003
        2.1311    0.0037   -0.0003
        2.1311    0.0086    0.0038
        2.1311    0.0097    0.0101
        2.1311    0.0065    0.0157
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #32 Throttle
    F = [ ...
        2     8     9   NaN
        9     3     2   NaN
        4     3     9   NaN
        9    10     4   NaN
        4    10    11   NaN
        11     5     4   NaN
        6     5    11   NaN
        11    12     6   NaN
        6    12    13   NaN
        13     7     6   NaN
        2     7    13   NaN
        13     8     2   NaN
        9     8    14   NaN
        14    15     9   NaN
        9    15    16   NaN
        16    10     9   NaN
        11    10    16   NaN
        16    17    11   NaN
        11    17    18   NaN
        18    12    11   NaN
        13    12    18   NaN
        18    19    13   NaN
        13    19    14   NaN
        14     8    13   NaN
        14    20    21   NaN
        21    15    14   NaN
        16    15    21   NaN
        21    22    16   NaN
        16    22    23   NaN
        23    17    16   NaN
        18    17    23   NaN
        23    24    18   NaN
        18    24    25   NaN
        25    19    18   NaN
        14    19    25   NaN
        25    20    14   NaN
        21    20    26   NaN
        26    27    21   NaN
        21    27    28   NaN
        28    22    21   NaN
        23    22    28   NaN
        28    29    23   NaN
        23    29    30   NaN
        30    24    23   NaN
        25    24    30   NaN
        30    31    25   NaN
        25    31    26   NaN
        26    20    25   NaN
        1     2     3   NaN
        1     3     4   NaN
        1     4     5   NaN
        1     5     6   NaN
        1     6     7   NaN
        1     7     2   NaN
        32    27    26   NaN
        32    28    27   NaN
        32    29    28   NaN
        32    30    29   NaN
        32    31    30   NaN
        32    26    31   NaN
        34    41    40    33
        35    42    41    34
        36    43    42    35
        37    44    43    36
        38    45    44    37
        39    46    45    38
        33    40    46    39
        47    34    33   NaN
        47    35    34   NaN
        47    36    35   NaN
        47    37    36   NaN
        47    38    37   NaN
        47    39    38   NaN
        47    33    39   NaN
        48    40    41   NaN
        48    41    42   NaN
        48    42    43   NaN
        48    43    44   NaN
        48    44    45   NaN
        48    45    46   NaN
        48    46    40   NaN
    ];
    V = [ ...
        2.2330   -0.0153    0.0095
        2.2410   -0.0133    0.0095
        2.2370   -0.0133    0.0174
        2.2290   -0.0133    0.0174
        2.2250   -0.0133    0.0095
        2.2290   -0.0133    0.0017
        2.2370   -0.0133    0.0017
        2.2469   -0.0076    0.0095
        2.2399   -0.0076    0.0232
        2.2261   -0.0076    0.0232
        2.2191   -0.0076    0.0095
        2.2261   -0.0076   -0.0041
        2.2399   -0.0076   -0.0041
        2.2490    0.0001    0.0095
        2.2410    0.0001    0.0253
        2.2250    0.0001    0.0253
        2.2170    0.0001    0.0095
        2.2250    0.0001   -0.0062
        2.2410    0.0001   -0.0062
        2.2469    0.0078    0.0095
        2.2399    0.0078    0.0232
        2.2261    0.0078    0.0232
        2.2191    0.0078    0.0095
        2.2261    0.0078   -0.0041
        2.2399    0.0078   -0.0041
        2.2410    0.0134    0.0095
        2.2370    0.0134    0.0174
        2.2290    0.0134    0.0174
        2.2250    0.0134    0.0095
        2.2290    0.0134    0.0017
        2.2370    0.0134    0.0017
        2.2330    0.0155    0.0095
        2.2182    0.0035    0.0108
        2.2182    0.0043    0.0076
        2.2182    0.0021    0.0051
        2.2182   -0.0015    0.0051
        2.2182   -0.0037    0.0076
        2.2182   -0.0029    0.0108
        2.2182    0.0003    0.0123
        1.9616    0.0035    0.0108
        1.9616    0.0043    0.0076
        1.9616    0.0021    0.0051
        1.9616   -0.0015    0.0051
        1.9616   -0.0037    0.0076
        1.9616   -0.0029    0.0108
        1.9616    0.0003    0.0123
        2.2182    0.0003    0.0085
        1.9616    0.0003    0.0085
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #33 PropCont
    F = [ ...
        2     9     8     1
        3    10     9     2
        4    11    10     3
        5    12    11     4
        6    13    12     5
        7    14    13     6
        1     8    14     7
        15     2     1   NaN
        15     3     2   NaN
        15     4     3   NaN
        15     5     4   NaN
        15     6     5   NaN
        15     7     6   NaN
        15     1     7   NaN
        16     8     9   NaN
        16     9    10   NaN
        16    10    11   NaN
        16    11    12   NaN
        16    12    13   NaN
        16    13    14   NaN
        16    14     8   NaN
        19    27    26    18
        20    28    27    19
        21    29    28    20
        22    30    29    21
        23    31    30    22
        24    32    31    23
        25    33    32    24
        18    26    33    25
        34    19    18   NaN
        34    20    19   NaN
        34    21    20   NaN
        34    22    21   NaN
        34    23    22   NaN
        34    24    23   NaN
        34    25    24   NaN
        34    18    25   NaN
        35    26    27   NaN
        35    27    28   NaN
        35    28    29   NaN
        35    29    30   NaN
        35    30    31   NaN
        35    31    32   NaN
        35    32    33   NaN
        35    33    26   NaN
        26    27    37    36
        36    37    39    38
        27    28    40    37
        37    40    41    39
        28    29    42    40
        40    42    43    41
        29    30    44    42
        42    44    45    43
        30    31    46    44
        44    46    47    45
        31    32    48    46
        46    48    49    47
        32    33    50    48
        48    50    51    49
        33    26    36    50
        50    36    38    51
        17    38    39   NaN
        17    39    41   NaN
        17    41    43   NaN
        17    43    45   NaN
        17    45    47   NaN
        17    47    49   NaN
        17    49    51   NaN
        17    51    38   NaN
        53    58    57    52
        54    59    58    53
        55    60    59    54
        56    61    60    55
        52    57    61    56
        62    53    52   NaN
        62    54    53   NaN
        62    55    54   NaN
        62    56    55   NaN
        62    52    56   NaN
        63    57    58   NaN
        63    58    59   NaN
        63    59    60   NaN
        63    60    61   NaN
        63    61    57   NaN
    ];
    V = [ ...
        2.2596    0.0109   -0.0367
        2.2596    0.0135   -0.0493
        2.2596    0.0063   -0.0594
        2.2596   -0.0054   -0.0594
        2.2596   -0.0127   -0.0493
        2.2596   -0.0101   -0.0367
        2.2596    0.0004   -0.0311
        2.2522    0.0109   -0.0367
        2.2522    0.0135   -0.0493
        2.2522    0.0063   -0.0594
        2.2522   -0.0054   -0.0594
        2.2522   -0.0127   -0.0493
        2.2522   -0.0101   -0.0367
        2.2522    0.0004   -0.0311
        2.2596    0.0004   -0.0460
        2.2522    0.0004   -0.0460
        2.2139    0.0002   -0.0464
        2.2520    0.0123   -0.0344
        2.2520    0.0174   -0.0466
        2.2520    0.0123   -0.0587
        2.2520    0.0002   -0.0637
        2.2520   -0.0119   -0.0587
        2.2520   -0.0170   -0.0466
        2.2520   -0.0119   -0.0344
        2.2520    0.0002   -0.0294
        2.2304    0.0123   -0.0344
        2.2304    0.0174   -0.0466
        2.2304    0.0123   -0.0587
        2.2304    0.0002   -0.0637
        2.2304   -0.0119   -0.0587
        2.2304   -0.0170   -0.0466
        2.2304   -0.0119   -0.0344
        2.2304    0.0002   -0.0294
        2.2520    0.0002   -0.0466
        2.2304    0.0002   -0.0466
        2.2262    0.0069   -0.0404
        2.2262    0.0097   -0.0465
        2.2139    0.0058   -0.0415
        2.2139    0.0081   -0.0464
        2.2262    0.0069   -0.0527
        2.2139    0.0058   -0.0514
        2.2262    0.0002   -0.0552
        2.2139    0.0002   -0.0534
        2.2262   -0.0065   -0.0527
        2.2139   -0.0054   -0.0514
        2.2262   -0.0093   -0.0465
        2.2139   -0.0077   -0.0464
        2.2262   -0.0065   -0.0404
        2.2139   -0.0054   -0.0415
        2.2262    0.0002   -0.0378
        2.2139    0.0002   -0.0395
        2.2144    0.0032   -0.0457
        2.2144    0.0020   -0.0495
        2.2144   -0.0019   -0.0495
        2.2144   -0.0031   -0.0457
        2.2144    0.0000   -0.0433
        2.1029    0.0031   -0.0456
        2.1029    0.0019   -0.0495
        2.1029   -0.0019   -0.0495
        2.1029   -0.0031   -0.0456
        2.1029   -0.0000   -0.0432
        2.2144    0.0000   -0.0467
        2.1029   -0.0000   -0.0467
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #34 PropCylinder
    F = [ ...
        2     8     7     1
        3     9     8     2
        4    10     9     3
        5    11    10     4
        6    12    11     5
        1     7    12     6
        13     2     1   NaN
        13     3     2   NaN
        13     4     3   NaN
        13     5     4   NaN
        13     6     5   NaN
        13     1     6   NaN
        14     7     8   NaN
        14     8     9   NaN
        14     9    10   NaN
        14    10    11   NaN
        14    11    12   NaN
        14    12     7   NaN
        16    28    27    15
        17    29    28    16
        18    30    29    17
        19    31    30    18
        20    32    31    19
        21    33    32    20
        22    34    33    21
        23    35    34    22
        24    36    35    23
        25    37    36    24
        26    38    37    25
        15    27    38    26
        39    16    15   NaN
        39    17    16   NaN
        39    18    17   NaN
        39    19    18   NaN
        39    20    19   NaN
        39    21    20   NaN
        39    22    21   NaN
        39    23    22   NaN
        39    24    23   NaN
        39    25    24   NaN
        39    26    25   NaN
        39    15    26   NaN
        40    27    28   NaN
        40    28    29   NaN
        40    29    30   NaN
        40    30    31   NaN
        40    31    32   NaN
        40    32    33   NaN
        40    33    34   NaN
        40    34    35   NaN
        40    35    36   NaN
        40    36    37   NaN
        40    37    38   NaN
        40    38    27   NaN
    ];
    V = [ ...
        2.1283    0.0136   -0.0395
        2.1283    0.0136   -0.0548
        2.1283   -0.0006   -0.0625
        2.1283   -0.0147   -0.0548
        2.1283   -0.0147   -0.0395
        2.1283   -0.0006   -0.0318
        2.1230    0.0136   -0.0395
        2.1230    0.0136   -0.0548
        2.1230   -0.0006   -0.0625
        2.1230   -0.0147   -0.0548
        2.1230   -0.0147   -0.0395
        2.1230   -0.0006   -0.0318
        2.1283   -0.0006   -0.0471
        2.1230   -0.0006   -0.0471
        2.1355    0.0032   -0.0421
        2.1355    0.0055   -0.0442
        2.1355    0.0063   -0.0471
        2.1355    0.0055   -0.0500
        2.1355    0.0032   -0.0522
        2.1355    0.0002   -0.0530
        2.1355   -0.0028   -0.0522
        2.1355   -0.0051   -0.0500
        2.1355   -0.0059   -0.0471
        2.1355   -0.0051   -0.0442
        2.1355   -0.0028   -0.0421
        2.1355    0.0002   -0.0413
        2.1286    0.0032   -0.0421
        2.1286    0.0055   -0.0442
        2.1286    0.0063   -0.0471
        2.1286    0.0055   -0.0500
        2.1286    0.0032   -0.0522
        2.1286    0.0002   -0.0530
        2.1286   -0.0028   -0.0522
        2.1286   -0.0051   -0.0500
        2.1286   -0.0059   -0.0471
        2.1286   -0.0051   -0.0442
        2.1286   -0.0028   -0.0421
        2.1286    0.0002   -0.0413
        2.1355    0.0002   -0.0471
        2.1286    0.0002   -0.0471
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #35 GearGreen-e
    F = [ ...
        3
        2
        1
    ];
    V = [ ...
        2.1168    0.0375    0.1241
        2.1168    0.0642    0.1404
        2.1168    0.0642    0.1108
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #36 GearGreen-d
    F = [ ...
        1
        2
        3
    ];
    V = [ ...
        2.1168    0.0641    0.1108
        2.1168    0.0641    0.1404
        2.1168    0.0374    0.1241
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #37 GearYellow-d
    F = [ ...
        1
        2
        3
    ];
    V = [ ...
        2.1170    0.0939    0.1088
        2.1170    0.0939    0.1401
        2.1170    0.1200    0.1229
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #38 GearYellow-e
    F = [ ...
        3
        2
        1
    ];
    V = [ ...
        2.1170    0.1200    0.1242
        2.1170    0.0939    0.1414
        2.1170    0.0939    0.1101
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #39 CarbHeat
    F = [ ...
        2    11    10     1
        3    12    11     2
        4    13    12     3
        5    14    13     4
        6    15    14     5
        7    16    15     6
        8    17    16     7
        9    18    17     8
        1    10    18     9
        19     2     1   NaN
        19     3     2   NaN
        19     4     3   NaN
        19     5     4   NaN
        19     6     5   NaN
        19     7     6   NaN
        19     8     7   NaN
        19     9     8   NaN
        19     1     9   NaN
        20    10    11   NaN
        20    11    12   NaN
        20    12    13   NaN
        20    13    14   NaN
        20    14    15   NaN
        20    15    16   NaN
        20    16    17   NaN
        20    17    18   NaN
        20    18    10   NaN
        22    27    26    21
        23    28    27    22
        24    29    28    23
        25    30    29    24
        21    26    30    25
        31    22    21   NaN
        31    23    22   NaN
        31    24    23   NaN
        31    25    24   NaN
        31    21    25   NaN
        32    26    27   NaN
        32    27    28   NaN
        32    28    29   NaN
        32    29    30   NaN
        32    30    26   NaN
    ];
    V = [ ...
        2.1449    0.0066   -0.0979
        2.1449    0.0103   -0.1050
        2.1449    0.0090   -0.1130
        2.1449    0.0034   -0.1182
        2.1449   -0.0040   -0.1182
        2.1449   -0.0097   -0.1130
        2.1449   -0.0109   -0.1050
        2.1449   -0.0072   -0.0979
        2.1449   -0.0003   -0.0952
        2.1380    0.0066   -0.0979
        2.1380    0.0103   -0.1050
        2.1380    0.0090   -0.1130
        2.1380    0.0034   -0.1182
        2.1380   -0.0040   -0.1182
        2.1380   -0.0097   -0.1130
        2.1380   -0.0109   -0.1050
        2.1380   -0.0072   -0.0979
        2.1380   -0.0003   -0.0952
        2.1449   -0.0003   -0.1071
        2.1380   -0.0003   -0.1071
        2.1371    0.0017   -0.1064
        2.1371    0.0009   -0.1089
        2.1371   -0.0016   -0.1089
        2.1371   -0.0024   -0.1064
        2.1371   -0.0004   -0.1048
        2.0083    0.0017   -0.1064
        2.0083    0.0009   -0.1089
        2.0083   -0.0016   -0.1089
        2.0083   -0.0024   -0.1064
        2.0083   -0.0004   -0.1048
        2.1371   -0.0004   -0.1071
        2.0083   -0.0004   -0.1071
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #40 GearLever
    F = [ ...
        2    14    13     1
        33    29    14     2
        17     4     3    15
        26    30     4    17
        6     2     1     5
        37    33     2     6
        4     8     7     3
        30    34     8     4
        10     6     5     9
        41    37     6    10
        8    12    11     7
        34    38    12     8
        20    10     9    19
        45    41    10    20
        12    23    21    11
        38    42    23    12
        14    18    16    13
        29    25    18    14
        17    18    16    15
        26    25    18    17
        20    24    22    19
        45    46    24    20
        23    24    22    21
        42    46    24    23
        26    30    31   NaN
        31    27    26   NaN
        28    27    31   NaN
        31    32    28   NaN
        28    32    33   NaN
        33    29    28   NaN
        31    30    34   NaN
        34    35    31   NaN
        31    35    36   NaN
        36    32    31   NaN
        33    32    36   NaN
        36    37    33   NaN
        34    38    39   NaN
        39    35    34   NaN
        36    35    39   NaN
        39    40    36   NaN
        36    40    41   NaN
        41    37    36   NaN
        39    38    42   NaN
        42    43    39   NaN
        39    43    44   NaN
        44    40    39   NaN
        41    40    44   NaN
        44    45    41   NaN
        25    26    27   NaN
        25    27    28   NaN
        25    28    29   NaN
        46    43    42   NaN
        46    44    43   NaN
        46    45    44   NaN
    ];
    V = [ ...
        2.1238    0.0829    0.1555
        2.1310    0.0795    0.1555
        2.1238    0.0829    0.1524
        2.1310    0.0795    0.1524
        2.1242    0.0837    0.1557
        2.1314    0.0804    0.1557
        2.1242    0.0837    0.1522
        2.1314    0.0804    0.1522
        2.1246    0.0846    0.1555
        2.1318    0.0812    0.1555
        2.1246    0.0846    0.1524
        2.1318    0.0812    0.1524
        2.1235    0.0823    0.1548
        2.1307    0.0789    0.1548
        2.1235    0.0823    0.1531
        2.1234    0.0821    0.1540
        2.1307    0.0789    0.1531
        2.1306    0.0787    0.1540
        2.1249    0.0852    0.1548
        2.1321    0.0818    0.1548
        2.1249    0.0852    0.1531
        2.1250    0.0854    0.1540
        2.1321    0.0818    0.1531
        2.1322    0.0821    0.1540
        2.1526    0.0646    0.1539
        2.1529    0.0653    0.1510
        2.1556    0.0640    0.1524
        2.1556    0.0640    0.1553
        2.1529    0.0653    0.1567
        2.1537    0.0670    0.1489
        2.1585    0.0648    0.1514
        2.1585    0.0648    0.1563
        2.1537    0.0670    0.1588
        2.1548    0.0695    0.1482
        2.1603    0.0669    0.1510
        2.1603    0.0669    0.1567
        2.1548    0.0695    0.1596
        2.1560    0.0719    0.1489
        2.1607    0.0696    0.1514
        2.1607    0.0696    0.1563
        2.1560    0.0719    0.1588
        2.1568    0.0736    0.1510
        2.1595    0.0723    0.1524
        2.1595    0.0723    0.1553
        2.1568    0.0736    0.1567
        2.1571    0.0743    0.1539
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #41 gear-shield
    F = [ ...
        2     3     9     8
        8     9    11    10
        10    11    13    12
        12    13    15    14
        3     4    16     9
        9    16    17    11
        11    17    18    13
        13    18    19    15
        4     5    20    16
        16    20    21    17
        17    21    22    18
        18    22    23    19
        5     6    24    20
        20    24    25    21
        21    25    26    22
        22    26    27    23
        6     7    28    24
        24    28    29    25
        25    29    30    26
        26    30    31    27
        7     1    32    28
        28    32    33    29
        29    33    34    30
        30    34    35    31
    ];
    V = [ ...
        2.1369    0.0841    0.1629
        2.1369    0.0841    0.1455
        2.1295    0.0796    0.1466
        2.1240    0.0763    0.1498
        2.1220    0.0751    0.1542
        2.1240    0.0763    0.1586
        2.1295    0.0796    0.1618
        2.1431    0.0764    0.1455
        2.1357    0.0719    0.1466
        2.1493    0.0687    0.1455
        2.1419    0.0642    0.1466
        2.1553    0.0614    0.1455
        2.1489    0.0558    0.1466
        2.1625    0.0524    0.1455
        2.1611    0.0444    0.1466
        2.1302    0.0686    0.1498
        2.1364    0.0609    0.1498
        2.1442    0.0517    0.1498
        2.1601    0.0385    0.1498
        2.1282    0.0674    0.1542
        2.1344    0.0597    0.1542
        2.1425    0.0502    0.1542
        2.1597    0.0364    0.1542
        2.1302    0.0686    0.1586
        2.1364    0.0609    0.1586
        2.1442    0.0517    0.1586
        2.1601    0.0385    0.1586
        2.1357    0.0719    0.1618
        2.1419    0.0642    0.1618
        2.1489    0.0558    0.1618
        2.1611    0.0444    0.1618
        2.1431    0.0764    0.1629
        2.1493    0.0687    0.1629
        2.1553    0.0614    0.1629
        2.1625    0.0524    0.1629
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #42 gear-lever-nut
    F = [ ...
        1     3     8   NaN
        1     4     3   NaN
        1     5     4   NaN
        1     6     5   NaN
        1     7     6   NaN
        1     8     7   NaN
        2    14     9   NaN
        2     9    10   NaN
        2    10    11   NaN
        2    11    12   NaN
        2    12    13   NaN
        2    13    14   NaN
        14     8     3     9
        9     3     4    10
        10     4     5    11
        11     5     6    12
        12     6     7    13
        13     7     8    14
    ];
    V = [ ...
        2.1222    0.0834    0.1539
        2.1267    0.0834    0.1539
        2.1222    0.0834    0.1617
        2.1222    0.0771    0.1578
        2.1222    0.0771    0.1500
        2.1222    0.0834    0.1461
        2.1222    0.0896    0.1500
        2.1222    0.0896    0.1578
        2.1267    0.0834    0.1617
        2.1267    0.0771    0.1578
        2.1267    0.0771    0.1500
        2.1267    0.0834    0.1461
        2.1267    0.0896    0.1500
        2.1267    0.0896    0.1578
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #43 AntenaTx
    F = [ ...
        34    10    33
        10    34     7
        30    32    21
        23    24    22
        19    24    21
        21    24    27
        34     4     7
        4    34    35
        24    23    25
        21    29    30
        27    28    29
        33    13    32
        35     1     4
        1    35    36
        36    37    15
        29    21    27
        25    27    24
        13    33    10
        1    15    12
        15     1    36
        15    37    38
        16    21    32
        21    16    19
        24    19    22
        12     5    20
        5    12    15
        15    39    14
        39    15    38
        32    13    16
        15    14     5
        20    14     8
        14    20     5
        14    28    27
        28    14    39
        14    27    25
        32    30    31
        14    23     8
        23    14    25
        26     3     2
        3    26     6
        17    11     9
        11    17    18
        11     6     9
        6    11     3
        26    18    17
        18    26     2
        18     3    11
        3    18     2
        26     9     6
        9    26    17
    ];
    V = [ ...
        4.3508    0.6652    0.2306
        4.3459    0.6639    0.2315
        4.3459    0.6639    0.2349
        4.3474    0.6654    0.2317
        4.3502    0.6441    0.2212
        4.3534    0.6553    0.2349
        4.3461    0.6655    0.2332
        4.3635    0.6646    0.2317
        4.6948    0.9960    0.2349
        4.3474    0.6654    0.2347
        4.6921    0.9983    0.2349
        4.3554    0.6650    0.2302
        4.3508    0.6652    0.2357
        4.3570    0.6437    0.2263
        4.3562    0.6323    0.2158
        4.3554    0.6650    0.2361
        4.6948    0.9960    0.2315
        4.6921    0.9983    0.2315
        4.3601    0.6647    0.2357
        4.3601    0.6647    0.2306
        4.3562    0.6323    0.2479
        4.3635    0.6646    0.2347
        4.3647    0.6645    0.2332
        4.3570    0.6437    0.2401
        4.3595    0.6436    0.2332
        4.3534    0.6553    0.2315
        4.3727    0.6314    0.2318
        4.3980    0.6206    0.2325
        4.3907    0.6210    0.2462
        4.3708    0.6221    0.2562
        4.3435    0.6235    0.2598
        4.3162    0.6249    0.2562
        4.2962    0.6260    0.2462
        4.2889    0.6264    0.2325
        4.2962    0.6260    0.2188
        4.3162    0.6249    0.2088
        4.3435    0.6235    0.2052
        4.3708    0.6221    0.2088
        4.3907    0.6210    0.2188
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #44 Panel-3d
    F = [ ...
        6
        2
        1
        7
        3
        8
        5
        9
        4
        10
        12
        11
    ];
    V = [ ...
        2.1217    0.3993    0.4145
        2.1217    0.3993    0.2763
        2.1217    0.3424    0.5749
        2.1217    0.3424   -0.5753
        2.1217   -0.0561   -0.0002
        2.1217    0.3993   -0.0002
        2.1217    0.3993    0.5528
        2.1217   -0.0561    0.5749
        2.1217   -0.0561   -0.5753
        2.1217    0.3993   -0.5569
        2.1217    0.3993   -0.2786
        2.1217    0.3993   -0.4177
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #45 FuelSel
    F = [ ...
        4
        3
        2
        1
    ];
    V = [ ...
        2.7535   -0.4772    0.0736
        2.6083   -0.4772    0.0736
        2.6083   -0.4772   -0.0708
        2.7535   -0.4772   -0.0708
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #46 FuelValve
    F = [ ...
        7     6     5     4     3     2     1
        14     8     7     1   NaN   NaN   NaN
        13    14     1     2   NaN   NaN   NaN
        12    13     2     3   NaN   NaN   NaN
        11    12     3     4   NaN   NaN   NaN
        10    11     4     5   NaN   NaN   NaN
        9    10     5     6   NaN   NaN   NaN
        8     9     6     7   NaN   NaN   NaN
        8     9    10    11    12    13    14
    ];
    V = [ ...
        2.6488   -0.4671    0.0037
        2.6502   -0.4671    0.0014
        2.6898   -0.4671    0.0014
        2.6898   -0.4671   -0.0021
        2.6502   -0.4671   -0.0021
        2.6488   -0.4671   -0.0041
        2.6319   -0.4671    0.0000
        2.6319   -0.4729    0.0000
        2.6488   -0.4729   -0.0041
        2.6502   -0.4729   -0.0021
        2.6898   -0.4729   -0.0021
        2.6898   -0.4729    0.0014
        2.6502   -0.4729    0.0014
        2.6488   -0.4729    0.0037
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #47 Beacon
    F = [ ...
        1     6     7    12
        6     5     8     7
        5     4     9     8
        4     3    10     9
        3     2    11    10
        2     1    12    11
        11    12    13   NaN
        10    11    13   NaN
        9    10    13   NaN
        8     9    13   NaN
        7     8    13   NaN
        12     7    13   NaN
    ];
    V = [ ...
        4.5980    0.6036    0.0344
        4.5511    0.6069    0.0469
        4.5168    0.6093    0.0126
        4.5294    0.6084   -0.0344
        4.5762    0.6051   -0.0469
        4.6105    0.6027   -0.0126
        4.6083    0.7113   -0.0100
        4.5812    0.7132   -0.0372
        4.5441    0.7158   -0.0272
        4.5341    0.7165    0.0100
        4.5613    0.7146    0.0372
        4.5984    0.7120    0.0272
        4.5728    0.7360   -0.0000
    ];
    cdata = [0.6860 0.1330 0.0000];
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #48 Prime
    F = [ ...
        2    11    10     1
        3    12    11     2
        4    13    12     3
        5    14    13     4
        6    15    14     5
        7    16    15     6
        8    17    16     7
        9    18    17     8
        1    10    18     9
        19     2     1   NaN
        19     3     2   NaN
        19     4     3   NaN
        19     5     4   NaN
        19     6     5   NaN
        19     7     6   NaN
        19     8     7   NaN
        19     9     8   NaN
        19     1     9   NaN
        20    10    11   NaN
        20    11    12   NaN
        20    12    13   NaN
        20    13    14   NaN
        20    14    15   NaN
        20    15    16   NaN
        20    16    17   NaN
        20    17    18   NaN
        20    18    10   NaN
        22    31    30    21
        23    32    31    22
        24    33    32    23
        25    34    33    24
        26    35    34    25
        27    36    35    26
        28    37    36    27
        29    38    37    28
        21    30    38    29
        39    22    21   NaN
        39    23    22   NaN
        39    24    23   NaN
        39    25    24   NaN
        39    26    25   NaN
        39    27    26   NaN
        39    28    27   NaN
        39    29    28   NaN
        39    21    29   NaN
        40    30    31   NaN
        40    31    32   NaN
        40    32    33   NaN
        40    33    34   NaN
        40    34    35   NaN
        40    35    36   NaN
        40    36    37   NaN
        40    37    38   NaN
        40    38    30   NaN
    ];
    V = [ ...
        2.1259    0.0069   -0.2920
        2.1259    0.0096   -0.2969
        2.1259    0.0086   -0.3024
        2.1259    0.0046   -0.3060
        2.1259   -0.0007   -0.3060
        2.1259   -0.0048   -0.3024
        2.1259   -0.0057   -0.2969
        2.1259   -0.0031   -0.2920
        2.1259    0.0019   -0.2901
        2.0490    0.0069   -0.2920
        2.0490    0.0096   -0.2969
        2.0490    0.0086   -0.3024
        2.0490    0.0046   -0.3060
        2.0490   -0.0007   -0.3060
        2.0490   -0.0048   -0.3024
        2.0490   -0.0057   -0.2969
        2.0490   -0.0031   -0.2920
        2.0490    0.0019   -0.2901
        2.1259    0.0019   -0.2983
        2.0490    0.0019   -0.2983
        2.1354    0.0121   -0.2853
        2.1354    0.0174   -0.2951
        2.1354    0.0155   -0.3061
        2.1354    0.0074   -0.3134
        2.1354   -0.0032   -0.3134
        2.1354   -0.0113   -0.3061
        2.1354   -0.0132   -0.2951
        2.1354   -0.0079   -0.2853
        2.1354    0.0021   -0.2815
        2.1264    0.0121   -0.2853
        2.1264    0.0174   -0.2951
        2.1264    0.0155   -0.3061
        2.1264    0.0074   -0.3134
        2.1264   -0.0032   -0.3134
        2.1264   -0.0113   -0.3061
        2.1264   -0.0132   -0.2951
        2.1264   -0.0079   -0.2853
        2.1264    0.0021   -0.2815
        2.1354    0.0021   -0.2979
        2.1264    0.0021   -0.2979
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #49 LdgLt
    F = [ ...
        6     5     4     3
        8     7     2     1
        7     9    10     2
        9     6     3    10
        13    14    15    16
        11    12    17    18
        12    20    19    17
        20    13    16    19
    ];
    V = [ ...
        2.4980   -0.0522   -5.1755
        2.4133   -0.0290   -5.1910
        2.3767    0.0060   -5.1993
        2.4043    0.0365   -5.1971
        2.4044    0.0156   -4.9448
        2.3752   -0.0162   -4.9447
        2.4136   -0.0527   -4.9344
        2.5028   -0.0795   -4.9153
        2.3884   -0.0376   -4.9421
        2.3893   -0.0146   -5.1969
        2.4980   -0.0522    5.1755
        2.4133   -0.0290    5.1910
        2.3767    0.0060    5.1993
        2.4043    0.0365    5.1971
        2.4044    0.0156    4.9448
        2.3752   -0.0162    4.9447
        2.4136   -0.0527    4.9344
        2.5028   -0.0795    4.9153
        2.3884   -0.0376    4.9421
        2.3893   -0.0146    5.1969
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #50 ParkBrake
    F = [ ...
        2    11    12   NaN
        12     3     2   NaN
        4     3    12   NaN
        12    13     4   NaN
        4    13    14   NaN
        14     5     4   NaN
        6     5    14   NaN
        14    15     6   NaN
        6    15    16   NaN
        16     7     6   NaN
        8     7    16   NaN
        16    17     8   NaN
        8    17    18   NaN
        18     9     8   NaN
        10     9    18   NaN
        18    19    10   NaN
        10    19    11   NaN
        11     2    10   NaN
        12    11    20   NaN
        20    21    12   NaN
        12    21    22   NaN
        22    13    12   NaN
        14    13    22   NaN
        22    23    14   NaN
        14    23    24   NaN
        24    15    14   NaN
        16    15    24   NaN
        24    25    16   NaN
        16    25    26   NaN
        26    17    16   NaN
        18    17    26   NaN
        26    27    18   NaN
        18    27    28   NaN
        28    19    18   NaN
        11    19    28   NaN
        28    20    11   NaN
        20    29    30   NaN
        30    21    20   NaN
        22    21    30   NaN
        30    31    22   NaN
        22    31    32   NaN
        32    23    22   NaN
        24    23    32   NaN
        32    33    24   NaN
        24    33    34   NaN
        34    25    24   NaN
        26    25    34   NaN
        34    35    26   NaN
        26    35    36   NaN
        36    27    26   NaN
        28    27    36   NaN
        36    37    28   NaN
        28    37    29   NaN
        29    20    28   NaN
        30    29    38   NaN
        38    39    30   NaN
        30    39    40   NaN
        40    31    30   NaN
        32    31    40   NaN
        40    41    32   NaN
        32    41    42   NaN
        42    33    32   NaN
        34    33    42   NaN
        42    43    34   NaN
        34    43    44   NaN
        44    35    34   NaN
        36    35    44   NaN
        44    45    36   NaN
        36    45    46   NaN
        46    37    36   NaN
        29    37    46   NaN
        46    38    29   NaN
        38    47    48   NaN
        48    39    38   NaN
        40    39    48   NaN
        48    49    40   NaN
        40    49    50   NaN
        50    41    40   NaN
        42    41    50   NaN
        50    51    42   NaN
        42    51    52   NaN
        52    43    42   NaN
        44    43    52   NaN
        52    53    44   NaN
        44    53    54   NaN
        54    45    44   NaN
        46    45    54   NaN
        54    55    46   NaN
        46    55    47   NaN
        47    38    46   NaN
        48    47    56   NaN
        56    57    48   NaN
        48    57    58   NaN
        58    49    48   NaN
        50    49    58   NaN
        58    59    50   NaN
        50    59    60   NaN
        60    51    50   NaN
        52    51    60   NaN
        60    61    52   NaN
        52    61    62   NaN
        62    53    52   NaN
        54    53    62   NaN
        62    63    54   NaN
        54    63    64   NaN
        64    55    54   NaN
        47    55    64   NaN
        64    56    47   NaN
        56    65    66   NaN
        66    57    56   NaN
        58    57    66   NaN
        66    67    58   NaN
        58    67    68   NaN
        68    59    58   NaN
        60    59    68   NaN
        68    69    60   NaN
        60    69    70   NaN
        70    61    60   NaN
        62    61    70   NaN
        70    71    62   NaN
        62    71    72   NaN
        72    63    62   NaN
        64    63    72   NaN
        72    73    64   NaN
        64    73    65   NaN
        65    56    64   NaN
        1     2     3   NaN
        1     3     4   NaN
        1     4     5   NaN
        1     5     6   NaN
        1     6     7   NaN
        1     7     8   NaN
        1     8     9   NaN
        1     9    10   NaN
        1    10     2   NaN
        74    66    65   NaN
        74    67    66   NaN
        74    68    67   NaN
        74    69    68   NaN
        74    70    69   NaN
        74    71    70   NaN
        74    72    71   NaN
        74    73    72   NaN
        74    65    73   NaN
        76    85    84    75
        77    86    85    76
        78    87    86    77
        79    88    87    78
        80    89    88    79
        81    90    89    80
        82    91    90    81
        83    92    91    82
        75    84    92    83
        93    76    75   NaN
        93    77    76   NaN
        93    78    77   NaN
        93    79    78   NaN
        93    80    79   NaN
        93    81    80   NaN
        93    82    81   NaN
        93    83    82   NaN
        93    75    83   NaN
        94    84    85   NaN
        94    85    86   NaN
        94    86    87   NaN
        94    87    88   NaN
        94    88    89   NaN
        94    89    90   NaN
        94    90    91   NaN
        94    91    92   NaN
        94    92    84   NaN
    ];
    V = [ ...
        2.1416    0.0371    0.3386
        2.1433    0.0375    0.3386
        2.1429    0.0375    0.3438
        2.1419    0.0375    0.3466
        2.1408    0.0375    0.3456
        2.1400    0.0375    0.3414
        2.1400    0.0375    0.3359
        2.1408    0.0375    0.3316
        2.1419    0.0375    0.3307
        2.1429    0.0375    0.3334
        2.1448    0.0386    0.3386
        2.1440    0.0386    0.3484
        2.1422    0.0386    0.3536
        2.1400    0.0386    0.3518
        2.1386    0.0386    0.3438
        2.1386    0.0386    0.3334
        2.1400    0.0386    0.3255
        2.1422    0.0386    0.3237
        2.1440    0.0386    0.3289
        2.1459    0.0403    0.3386
        2.1449    0.0403    0.3518
        2.1423    0.0403    0.3587
        2.1395    0.0403    0.3563
        2.1376    0.0403    0.3456
        2.1376    0.0403    0.3316
        2.1395    0.0403    0.3209
        2.1423    0.0403    0.3185
        2.1449    0.0403    0.3255
        2.1465    0.0424    0.3386
        2.1453    0.0424    0.3536
        2.1425    0.0424    0.3615
        2.1392    0.0424    0.3587
        2.1370    0.0424    0.3466
        2.1370    0.0424    0.3307
        2.1392    0.0424    0.3185
        2.1425    0.0424    0.3157
        2.1453    0.0424    0.3237
        2.1465    0.0446    0.3386
        2.1453    0.0446    0.3536
        2.1425    0.0446    0.3615
        2.1392    0.0446    0.3587
        2.1370    0.0446    0.3466
        2.1370    0.0446    0.3307
        2.1392    0.0446    0.3185
        2.1425    0.0446    0.3157
        2.1453    0.0446    0.3237
        2.1459    0.0467    0.3386
        2.1449    0.0467    0.3518
        2.1423    0.0467    0.3587
        2.1395    0.0467    0.3563
        2.1376    0.0467    0.3456
        2.1376    0.0467    0.3316
        2.1395    0.0467    0.3209
        2.1423    0.0467    0.3185
        2.1449    0.0467    0.3255
        2.1448    0.0484    0.3386
        2.1440    0.0484    0.3484
        2.1422    0.0484    0.3536
        2.1400    0.0484    0.3518
        2.1386    0.0484    0.3438
        2.1386    0.0484    0.3334
        2.1400    0.0484    0.3255
        2.1422    0.0484    0.3237
        2.1440    0.0484    0.3289
        2.1433    0.0495    0.3386
        2.1429    0.0495    0.3438
        2.1419    0.0495    0.3466
        2.1408    0.0495    0.3456
        2.1400    0.0495    0.3414
        2.1400    0.0495    0.3359
        2.1408    0.0495    0.3316
        2.1419    0.0495    0.3307
        2.1429    0.0495    0.3334
        2.1416    0.0499    0.3386
        2.1386    0.0466    0.3421
        2.1386    0.0481    0.3394
        2.1386    0.0476    0.3364
        2.1386    0.0452    0.3344
        2.1386    0.0421    0.3344
        2.1386    0.0397    0.3364
        2.1386    0.0391    0.3394
        2.1386    0.0407    0.3421
        2.1386    0.0436    0.3431
        2.0555    0.0466    0.3421
        2.0555    0.0481    0.3394
        2.0555    0.0476    0.3364
        2.0555    0.0452    0.3344
        2.0555    0.0421    0.3344
        2.0555    0.0397    0.3364
        2.0555    0.0391    0.3394
        2.0555    0.0407    0.3421
        2.0555    0.0436    0.3431
        2.1386    0.0436    0.3386
        2.0555    0.0436    0.3386
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #51 Propeller
    F = [ ...
        9     1   NaN   NaN
        13     2   NaN   NaN
        10     3   NaN   NaN
        13    12     5   NaN
        13     5     8   NaN
        9     8     5   NaN
        9     5     7   NaN
        10     7     5   NaN
        11    10     5   NaN
        9     6     8   NaN
        13     8     6   NaN
        13     6    12   NaN
        9     7     6   NaN
        10     6     7   NaN
        11     6    10   NaN
        11     5     4     3
        12     2     4     5
        12     6     1     2
        11     3     1     6
        16    24    26    21
        15    21    26    25
        15    25    23    22
        16    22    23    24
        16    21    17   NaN
        17    21    20   NaN
        18    20    21   NaN
        14    21    15   NaN
        14    19    21   NaN
        18    21    19   NaN
        16    17    22   NaN
        17    20    22   NaN
        18    22    20   NaN
        18    19    22   NaN
        14    22    19   NaN
        14    15    22   NaN
        17    24   NaN   NaN
        14    25   NaN   NaN
        18    26   NaN   NaN
        35    27   NaN   NaN
        39    28   NaN   NaN
        36    29   NaN   NaN
        39    38    31   NaN
        39    31    34   NaN
        35    34    31   NaN
        35    31    33   NaN
        36    33    31   NaN
        37    36    31   NaN
        35    32    34   NaN
        39    34    32   NaN
        39    32    38   NaN
        35    33    32   NaN
        36    32    33   NaN
        37    32    36   NaN
        37    31    30    29
        38    28    30    31
        38    32    27    28
        37    29    27    32
    ];
    V = [ ...
        0.3680   -0.0139   -0.0123
        0.4196   -0.0039    0.0039
        0.3143   -0.0033    0.0051
        0.3684    0.0019    0.0134
        0.3801   -0.3880    0.2444
        0.3538   -0.3957    0.2318
        0.3583   -0.7992    0.5470
        0.3759   -0.8557    0.4552
        0.3671   -0.8485    0.5141
        0.3549   -0.7580    0.5459
        0.3300   -0.3573    0.2942
        0.4039   -0.4264    0.1820
        0.3792   -0.8361    0.4189
        0.3792    0.7843    0.5093
        0.4039    0.3743    0.2729
        0.3300    0.4369    0.1570
        0.3549    0.8552    0.3781
        0.3671    0.8729    0.4724
        0.3759    0.8255    0.5081
        0.3583    0.8768    0.4132
        0.3538    0.4021    0.2214
        0.3801    0.4091    0.2084
        0.3684    0.0141   -0.0136
        0.3143    0.0095   -0.0051
        0.4196    0.0088   -0.0039
        0.3680   -0.0002    0.0128
        0.3680    0.0134   -0.0071
        0.4196   -0.0056   -0.0065
        0.3143   -0.0069   -0.0065
        0.3684   -0.0167   -0.0062
        0.3801   -0.0218   -0.4594
        0.3538   -0.0071   -0.4598
        0.3583   -0.0783   -0.9668
        0.3759    0.0295   -0.9698
        0.3671   -0.0251   -0.9930
        0.3549   -0.0979   -0.9305
        0.3300   -0.0803   -0.4577
        0.4039    0.0514   -0.4614
        0.3792    0.0511   -0.9347
    ];
    cdata = [0.5330 0.5330 0.5330];
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #52 sczors-bot
    F = [ ...
        16    13    10     9
        16     9     7    15
        15     7     5    14
        14     5     1     4
        13    16    15    12
        12    15    14    11
        11    14     4     3
        10    13    12     8
        8    12    11     6
        6    11     3     2
        9    10     8     7
        7     8     6     5
        5     6     2     1
        1     2     3     4
    ];
    V = [ ...
        1.1312   -0.7423    0.0335
        1.1312   -0.7423   -0.0373
        1.1455   -0.7319   -0.0373
        1.1455   -0.7319    0.0335
        1.1022   -0.7023    0.0335
        1.1022   -0.7023   -0.0373
        1.0731   -0.6624    0.0335
        1.0731   -0.6624    0.0000
        1.0441   -0.6224    0.0335
        1.0441   -0.6224    0.0000
        1.1165   -0.6920   -0.0373
        1.0874   -0.6520    0.0000
        1.0584   -0.6121    0.0000
        1.1165   -0.6920    0.0335
        1.0874   -0.6520    0.0335
        1.0584   -0.6121    0.0335
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #53 sczors-top
    F = [ ...
        16    15    14    13
        16    12    11    15
        9    11    12    10
        8     7     9    10
        11     6    14    15
        9     5     6    11
        7     4     5     9
        14    13     3     6
        6     3     2     5
        5     2     1     4
        3    12    16    13
        2    10    12     3
        1     8    10     2
        1     4     7     8
    ];
    V = [ ...
        1.0546   -0.6371   -0.0373
        1.0961   -0.6102   -0.0373
        1.1375   -0.5833   -0.0373
        1.0546   -0.6371   -0.0032
        1.0961   -0.6102   -0.0032
        1.1375   -0.5833    0.0335
        1.0450   -0.6223   -0.0032
        1.0450   -0.6223   -0.0373
        1.0864   -0.5954   -0.0032
        1.0864   -0.5954   -0.0373
        1.1278   -0.5685    0.0335
        1.1278   -0.5685   -0.0373
        1.1789   -0.5564   -0.0373
        1.1789   -0.5564    0.0335
        1.1693   -0.5416    0.0335
        1.1693   -0.5416   -0.0373
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #54 sczors-left-top
    F = [ ...
        16    13    10     9
        16     9     7    15
        15     7     5    14
        14     5     1     4
        13    16    15    12
        12    15    14    11
        11    14     4     3
        10    13    12     8
        8    12    11     6
        6    11     3     2
        9    10     8     7
        7     8     6     5
        5     6     2     1
        1     2     3     4
    ];
    V = [ ...
        3.1413   -0.4479    1.4223
        3.1413   -0.4479    1.3515
        3.1365   -0.4645    1.3515
        3.1365   -0.4645    1.4223
        3.1783   -0.4648    1.4223
        3.1783   -0.4648    1.3515
        3.2153   -0.4817    1.4223
        3.2153   -0.4817    1.3888
        3.2523   -0.4986    1.4223
        3.2523   -0.4986    1.3888
        3.1735   -0.4814    1.3515
        3.2105   -0.4983    1.3888
        3.2475   -0.5151    1.3888
        3.1735   -0.4814    1.4223
        3.2105   -0.4983    1.4223
        3.2475   -0.5151    1.4223
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #55 sczors-left-bottom
    F = [ ...
        13    14    15    16
        16    12    11    15
        9    11    12    10
        8     7     9    10
        11     6    14    15
        9     5     6    11
        7     4     5     9
        6     3    13    14
        5     2     3     6
        4     1     2     5
        3    12    16    13
        2    10    12     3
        1     8    10     2
        1     4     7     8
    ];
    V = [ ...
        3.2479   -0.4967    1.3527
        3.2092   -0.5095    1.3527
        3.1704   -0.5223    1.3527
        3.2479   -0.4967    1.3868
        3.2092   -0.5095    1.3868
        3.1704   -0.5223    1.4235
        3.2516   -0.5138    1.3868
        3.2516   -0.5138    1.3527
        3.2129   -0.5266    1.3868
        3.2129   -0.5266    1.3527
        3.1742   -0.5393    1.4235
        3.1742   -0.5393    1.3527
        3.1317   -0.5351    1.3527
        3.1317   -0.5351    1.4235
        3.1354   -0.5521    1.4235
        3.1354   -0.5521    1.3527
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #56 sczors-right-top
    F = [ ...
        16    15    14    13
        12    11    15    16
        10     9    11    12
        8     7     9    10
        11     6    14    15
        9     5     6    11
        7     4     5     9
        6     3    13    14
        5     2     3     6
        4     1     2     5
        3    12    16    13
        2    10    12     3
        1     8    10     2
        1     4     7     8
    ];
    V = [ ...
        3.2475   -0.5156   -1.3539
        3.2105   -0.4987   -1.3539
        3.1735   -0.4818   -1.3539
        3.2475   -0.5156   -1.3874
        3.2105   -0.4987   -1.3874
        3.1735   -0.4818   -1.4247
        3.2523   -0.4990   -1.3874
        3.2523   -0.4990   -1.3539
        3.2153   -0.4821   -1.3874
        3.2153   -0.4821   -1.3539
        3.1783   -0.4652   -1.4247
        3.1783   -0.4652   -1.3539
        3.1365   -0.4649   -1.3539
        3.1365   -0.4649   -1.4247
        3.1413   -0.4483   -1.4247
        3.1413   -0.4483   -1.3539
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #57 sczors-right-bottom
    F = [ ...
        16    13    10     9
        16     9     7    15
        15     7     5    14
        14     5     1     4
        13    16    15    12
        12    15    14    11
        11    14     4     3
        10    13    12     8
        8    12    11     6
        6    11     3     2
        9    10     8     7
        8     6     5     7
        1     5     6     2
        1     2     3     4
    ];
    V = [ ...
        3.1354   -0.5525   -1.4235
        3.1354   -0.5525   -1.3527
        3.1317   -0.5355   -1.3527
        3.1317   -0.5355   -1.4235
        3.1742   -0.5398   -1.4235
        3.1742   -0.5398   -1.3527
        3.2129   -0.5270   -1.4235
        3.2129   -0.5270   -1.3894
        3.2516   -0.5142   -1.4235
        3.2516   -0.5142   -1.3894
        3.1704   -0.5227   -1.3527
        3.2092   -0.5099   -1.3894
        3.2479   -0.4971   -1.3894
        3.1704   -0.5227   -1.4235
        3.2092   -0.5099   -1.4235
        3.2479   -0.4971   -1.4235
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #58 FuelPumpSwitch
    F = [ ...
        15    16     1     2
        14    15     2     3
        13    14     3     4
        12    13     4     5
        11    12     5     6
        10    11     6     7
        9    10     7     8
        16     9     8     1
        16    24    17     9
        18    10     9    17
        19    11    10    18
        20    12    11    19
        21    13    12    20
        22    14    13    21
        23    15    14    22
        24    16    15    23
        28    25    26    27
    ];
    V = [ ...
        2.1270    0.0003    0.3775
        2.1270    0.0010    0.3778
        2.1270    0.0017    0.3775
        2.1270    0.0020    0.3768
        2.1270    0.0017    0.3760
        2.1270    0.0010    0.3758
        2.1270    0.0003    0.3760
        2.1270   -0.0000    0.3768
        2.1293   -0.0061    0.3768
        2.1293   -0.0039    0.3715
        2.1293    0.0013    0.3693
        2.1293    0.0066    0.3715
        2.1293    0.0088    0.3768
        2.1293    0.0066    0.3820
        2.1293    0.0013    0.3842
        2.1293   -0.0039    0.3820
        2.1237   -0.0083    0.3768
        2.1237   -0.0055    0.3700
        2.1236    0.0014    0.3671
        2.1236    0.0082    0.3700
        2.1236    0.0110    0.3768
        2.1236    0.0082    0.3836
        2.1236    0.0014    0.3864
        2.1237   -0.0055    0.3836
        2.1250   -0.0306    0.3606
        2.1254    0.0017    0.3606
        2.1254    0.0017    0.3929
        2.1250   -0.0306    0.3929
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #59 StrobeSwitch
    F = [ ...
        15    16     1     2
        14    15     2     3
        13    14     3     4
        12    13     4     5
        11    12     5     6
        10    11     6     7
        9    10     7     8
        16     9     8     1
        16    24    17     9
        18    10     9    17
        19    11    10    18
        20    12    11    19
        21    13    12    20
        22    14    13    21
        23    15    14    22
        24    16    15    23
        28    25    26    27
    ];
    V = [ ...
        2.1270    0.0003   -0.2116
        2.1270    0.0010   -0.2113
        2.1270    0.0017   -0.2116
        2.1270    0.0020   -0.2123
        2.1270    0.0017   -0.2130
        2.1270    0.0010   -0.2133
        2.1270    0.0003   -0.2130
        2.1270   -0.0000   -0.2123
        2.1293   -0.0061   -0.2123
        2.1293   -0.0039   -0.2176
        2.1293    0.0013   -0.2198
        2.1293    0.0066   -0.2176
        2.1293    0.0088   -0.2123
        2.1293    0.0066   -0.2071
        2.1293    0.0013   -0.2049
        2.1293   -0.0039   -0.2071
        2.1237   -0.0083   -0.2123
        2.1237   -0.0055   -0.2191
        2.1236    0.0014   -0.2220
        2.1236    0.0082   -0.2191
        2.1236    0.0110   -0.2123
        2.1236    0.0082   -0.2055
        2.1236    0.0014   -0.2027
        2.1237   -0.0055   -0.2055
        2.1250   -0.0306   -0.2285
        2.1254    0.0017   -0.2285
        2.1254    0.0017   -0.1962
        2.1250   -0.0306   -0.1962
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #60 AvionicsMasterSwitch
    F = [ ...
        1     4     3     2
        5    13    14     6
        6    14    15     7
        7    15    16     8
        8    16    17     9
        9    17    18    10
        10    18    19    11
        11    19    20    12
        13     5    12    20
        13    20    21    28
        20    19    22    21
        19    18    23    22
        18    17    24    23
        17    16    25    24
        16    15    26    25
        15    14    27    26
        14    13    28    27
    ];
    V = [ ...
        2.1250   -0.0306   -0.2322
        2.1254    0.0017   -0.2322
        2.1254    0.0017   -0.2645
        2.1250   -0.0306   -0.2645
        2.1237   -0.0055   -0.2415
        2.1236    0.0014   -0.2387
        2.1236    0.0082   -0.2415
        2.1236    0.0110   -0.2483
        2.1236    0.0082   -0.2551
        2.1236    0.0014   -0.2580
        2.1237   -0.0055   -0.2551
        2.1237   -0.0083   -0.2483
        2.1293   -0.0039   -0.2431
        2.1293    0.0013   -0.2409
        2.1293    0.0066   -0.2431
        2.1293    0.0088   -0.2483
        2.1293    0.0066   -0.2536
        2.1293    0.0013   -0.2558
        2.1293   -0.0039   -0.2536
        2.1293   -0.0061   -0.2483
        2.1270   -0.0000   -0.2483
        2.1270    0.0003   -0.2490
        2.1270    0.0010   -0.2493
        2.1270    0.0017   -0.2490
        2.1270    0.0020   -0.2483
        2.1270    0.0017   -0.2476
        2.1270    0.0010   -0.2473
        2.1270    0.0003   -0.2476
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #61 PitotHeatSwitch
    F = [ ...
        1     4     3     2
        5    13    14     6
        6    14    15     7
        7    15    16     8
        8    16    17     9
        9    17    18    10
        10    18    19    11
        11    19    20    12
        13     5    12    20
        13    20    21    28
        20    19    22    21
        19    18    23    22
        18    17    24    23
        17    16    25    24
        16    15    26    25
        15    14    27    26
        14    13    28    27
    ];
    V = [ ...
        2.1247   -0.0306    0.2083
        2.1251    0.0017    0.2083
        2.1251    0.0017    0.1760
        2.1247   -0.0306    0.1760
        2.1234   -0.0055    0.1989
        2.1233    0.0014    0.2018
        2.1233    0.0082    0.1989
        2.1233    0.0110    0.1921
        2.1233    0.0082    0.1853
        2.1233    0.0014    0.1825
        2.1234   -0.0055    0.1853
        2.1234   -0.0083    0.1921
        2.1290   -0.0039    0.1974
        2.1290    0.0013    0.1996
        2.1290    0.0066    0.1974
        2.1290    0.0088    0.1921
        2.1290    0.0066    0.1869
        2.1290    0.0013    0.1847
        2.1290   -0.0039    0.1869
        2.1290   -0.0061    0.1921
        2.1267   -0.0000    0.1921
        2.1267    0.0003    0.1914
        2.1267    0.0010    0.1911
        2.1267    0.0017    0.1914
        2.1267    0.0020    0.1921
        2.1267    0.0017    0.1929
        2.1267    0.0010    0.1931
        2.1267    0.0003    0.1929
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #62 RotBeaconSwitch
    F = [ ...
        15    16     1     2
        14    15     2     3
        13    14     3     4
        12    13     4     5
        11    12     5     6
        10    11     6     7
        9    10     7     8
        16     9     8     1
        16    24    17     9
        18    10     9    17
        19    11    10    18
        20    12    11    19
        21    13    12    20
        22    14    13    21
        23    15    14    22
        24    16    15    23
        28    25    26    27
    ];
    V = [ ...
        2.1270    0.0003    0.2264
        2.1270    0.0010    0.2266
        2.1270    0.0017    0.2264
        2.1270    0.0020    0.2256
        2.1270    0.0017    0.2249
        2.1270    0.0010    0.2246
        2.1270    0.0003    0.2249
        2.1270   -0.0000    0.2256
        2.1293   -0.0061    0.2256
        2.1293   -0.0039    0.2204
        2.1293    0.0013    0.2182
        2.1293    0.0066    0.2204
        2.1292    0.0088    0.2256
        2.1293    0.0066    0.2309
        2.1293    0.0013    0.2331
        2.1293   -0.0039    0.2309
        2.1236   -0.0083    0.2256
        2.1236   -0.0055    0.2188
        2.1236    0.0014    0.2160
        2.1236    0.0082    0.2188
        2.1236    0.0110    0.2256
        2.1236    0.0082    0.2324
        2.1236    0.0014    0.2353
        2.1236   -0.0055    0.2324
        2.1250   -0.0306    0.2095
        2.1253    0.0017    0.2095
        2.1253    0.0017    0.2418
        2.1250   -0.0306    0.2418
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #63 TurnBankSwitch
    F = [ ...
        1     4     3     2
        5    13    14     6
        6    14    15     7
        7    15    16     8
        8    16    17     9
        9    17    18    10
        10    18    19    11
        11    19    20    12
        13     5    12    20
        13    20    21    28
        20    19    22    21
        19    18    23    22
        18    17    24    23
        17    16    25    24
        16    15    26    25
        15    14    27    26
        14    13    28    27
    ];
    V = [ ...
        2.1250   -0.0306    0.2771
        2.1253    0.0017    0.2771
        2.1253    0.0017    0.2448
        2.1250   -0.0306    0.2448
        2.1236   -0.0055    0.2678
        2.1236    0.0014    0.2706
        2.1236    0.0082    0.2678
        2.1236    0.0110    0.2610
        2.1236    0.0082    0.2542
        2.1236    0.0014    0.2513
        2.1236   -0.0055    0.2542
        2.1236   -0.0083    0.2610
        2.1293   -0.0039    0.2662
        2.1293    0.0013    0.2684
        2.1293    0.0066    0.2662
        2.1292    0.0088    0.2610
        2.1293    0.0066    0.2557
        2.1293    0.0013    0.2535
        2.1293   -0.0039    0.2557
        2.1293   -0.0061    0.2610
        2.1270   -0.0000    0.2610
        2.1270    0.0003    0.2603
        2.1270    0.0010    0.2600
        2.1270    0.0017    0.2603
        2.1270    0.0020    0.2610
        2.1270    0.0017    0.2617
        2.1270    0.0010    0.2620
        2.1270    0.0003    0.2617
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #64 LdgLtRightSwitch
    F = [ ...
        15    16     1     2
        14    15     2     3
        13    14     3     4
        12    13     4     5
        11    12     5     6
        10    11     6     7
        9    10     7     8
        16     9     8     1
        16    24    17     9
        18    10     9    17
        19    11    10    18
        20    12    11    19
        21    13    12    20
        22    14    13    21
        23    15    14    22
        24    16    15    23
        28    25    26    27
    ];
    V = [ ...
        2.1270    0.0003    0.2949
        2.1270    0.0010    0.2952
        2.1270    0.0017    0.2949
        2.1270    0.0020    0.2942
        2.1270    0.0017    0.2935
        2.1270    0.0010    0.2932
        2.1270    0.0003    0.2935
        2.1270   -0.0000    0.2942
        2.1293   -0.0061    0.2942
        2.1293   -0.0039    0.2889
        2.1293    0.0013    0.2867
        2.1293    0.0066    0.2889
        2.1292    0.0088    0.2942
        2.1293    0.0066    0.2994
        2.1293    0.0013    0.3016
        2.1293   -0.0039    0.2994
        2.1236   -0.0083    0.2942
        2.1236   -0.0055    0.2874
        2.1236    0.0014    0.2846
        2.1236    0.0082    0.2874
        2.1236    0.0110    0.2942
        2.1236    0.0082    0.3010
        2.1236    0.0014    0.3038
        2.1236   -0.0055    0.3010
        2.1250   -0.0306    0.2780
        2.1253    0.0017    0.2780
        2.1253    0.0017    0.3103
        2.1250   -0.0306    0.3103
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #65 LdgLtLeftSwitch
    F = [ ...
        1     4     3     2
        5    13    14     6
        6    14    15     7
        7    15    16     8
        8    16    17     9
        9    17    18    10
        10    18    19    11
        11    19    20    12
        13     5    12    20
        13    20    21    28
        20    19    22    21
        19    18    23    22
        18    17    24    23
        17    16    25    24
        16    15    26    25
        15    14    27    26
        14    13    28    27
    ];
    V = [ ...
        2.1249   -0.0306    0.3434
        2.1252    0.0017    0.3434
        2.1252    0.0017    0.3111
        2.1249   -0.0306    0.3111
        2.1235   -0.0055    0.3340
        2.1235    0.0014    0.3368
        2.1235    0.0082    0.3340
        2.1235    0.0110    0.3272
        2.1235    0.0082    0.3204
        2.1235    0.0014    0.3176
        2.1235   -0.0055    0.3204
        2.1235   -0.0083    0.3272
        2.1292   -0.0039    0.3325
        2.1292    0.0013    0.3347
        2.1291    0.0066    0.3325
        2.1291    0.0088    0.3272
        2.1291    0.0066    0.3220
        2.1292    0.0013    0.3198
        2.1292   -0.0039    0.3220
        2.1292   -0.0061    0.3272
        2.1268   -0.0000    0.3272
        2.1268    0.0003    0.3265
        2.1268    0.0010    0.3262
        2.1268    0.0017    0.3265
        2.1268    0.0020    0.3272
        2.1268    0.0017    0.3279
        2.1268    0.0010    0.3282
        2.1268    0.0003    0.3279
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #66 MasterSwitch
    F = [ ...
        1     4     3     2
        5    13    14     6
        6    14    15     7
        7    15    16     8
        8    16    17     9
        9    17    18    10
        10    18    19    11
        11    19    20    12
        13     5    12    20
        13    20    21    28
        20    19    22    21
        19    18    23    22
        18    17    24    23
        17    16    25    24
        16    15    26    25
        15    14    27    26
        14    13    28    27
    ];
    V = [ ...
        2.1250   -0.0306    0.4245
        2.1254    0.0017    0.4245
        2.1254    0.0017    0.3922
        2.1250   -0.0306    0.3922
        2.1237   -0.0055    0.4152
        2.1236    0.0014    0.4180
        2.1236    0.0082    0.4152
        2.1236    0.0110    0.4084
        2.1236    0.0082    0.4016
        2.1236    0.0014    0.3988
        2.1237   -0.0055    0.4016
        2.1237   -0.0083    0.4084
        2.1293   -0.0039    0.4136
        2.1293    0.0013    0.4158
        2.1293    0.0066    0.4136
        2.1293    0.0088    0.4084
        2.1293    0.0066    0.4031
        2.1293    0.0013    0.4009
        2.1293   -0.0039    0.4031
        2.1293   -0.0061    0.4084
        2.1270   -0.0000    0.4084
        2.1270    0.0003    0.4077
        2.1270    0.0010    0.4074
        2.1270    0.0017    0.4077
        2.1270    0.0020    0.4084
        2.1270    0.0017    0.4091
        2.1270    0.0010    0.4094
        2.1270    0.0003    0.4091
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #67 MasterToggle
    F = [ ...
        11    10     9     8
        12    11     8     7
        13    12     7     6
        14    13     6     5
        15    14     5     4
        16    15     4     3
        17    16     3     2
        10    17     2     9
        1     8     9   NaN
        1     7     8   NaN
        1     6     7   NaN
        1     5     6   NaN
        1     4     5   NaN
        1     3     4   NaN
        1     2     3   NaN
        1     9     2   NaN
    ];
    V = [ ...
        2.1532   -0.0077    0.4073
        2.1511   -0.0023    0.4083
        2.1506   -0.0034    0.4114
        2.1496   -0.0063    0.4126
        2.1485   -0.0092    0.4114
        2.1481   -0.0103    0.4083
        2.1485   -0.0092    0.4053
        2.1496   -0.0063    0.4040
        2.1506   -0.0034    0.4053
        2.1273    0.0030    0.4069
        2.1269    0.0017    0.4064
        2.1264    0.0004    0.4069
        2.1262   -0.0001    0.4083
        2.1264    0.0004    0.4097
        2.1269    0.0017    0.4103
        2.1273    0.0030    0.4097
        2.1275    0.0035    0.4083
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #68 FuelPumpToggle
    F = [ ...
        17     9    16   NaN
        17    16    15   NaN
        17    15    14   NaN
        17    14    13   NaN
        17    13    12   NaN
        17    12    11   NaN
        17    11    10   NaN
        17    10     9   NaN
        8     1    16     9
        1     2    15    16
        2     3    14    15
        3     4    13    14
        4     5    12    13
        5     6    11    12
        6     7    10    11
        7     8     9    10
    ];
    V = [ ...
        2.1274    0.0035    0.3768
        2.1272    0.0030    0.3782
        2.1267    0.0017    0.3788
        2.1262    0.0004    0.3782
        2.1260   -0.0001    0.3768
        2.1262    0.0004    0.3755
        2.1267    0.0017    0.3749
        2.1272    0.0030    0.3755
        2.1505   -0.0034    0.3738
        2.1494   -0.0063    0.3725
        2.1484   -0.0092    0.3738
        2.1479   -0.0103    0.3768
        2.1484   -0.0092    0.3799
        2.1494   -0.0063    0.3811
        2.1505   -0.0034    0.3799
        2.1510   -0.0023    0.3768
        2.1531   -0.0077    0.3768
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #69 LdgLtLeftToggle
    F = [ ...
        11    10     9     8
        12    11     8     7
        13    12     7     6
        14    13     6     5
        15    14     5     4
        16    15     4     3
        17    16     3     2
        10    17     2     9
        1     8     9   NaN
        1     7     8   NaN
        1     6     7   NaN
        1     5     6   NaN
        1     4     5   NaN
        1     3     4   NaN
        1     2     3   NaN
        1     9     2   NaN
    ];
    V = [ ...
        2.1529   -0.0077    0.3273
        2.1508   -0.0023    0.3273
        2.1504   -0.0034    0.3303
        2.1493   -0.0063    0.3316
        2.1482   -0.0092    0.3303
        2.1478   -0.0103    0.3273
        2.1482   -0.0092    0.3242
        2.1493   -0.0063    0.3230
        2.1504   -0.0034    0.3242
        2.1271    0.0030    0.3259
        2.1266    0.0017    0.3253
        2.1261    0.0004    0.3259
        2.1259   -0.0001    0.3273
        2.1261    0.0004    0.3287
        2.1266    0.0017    0.3292
        2.1271    0.0030    0.3287
        2.1273    0.0035    0.3273
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #70 LdgLtRightToggle
    F = [ ...
        17     9    16   NaN
        17    16    15   NaN
        17    15    14   NaN
        17    14    13   NaN
        17    13    12   NaN
        17    12    11   NaN
        17    11    10   NaN
        17    10     9   NaN
        8     1    16     9
        1     2    15    16
        2     3    14    15
        3     4    13    14
        4     5    12    13
        5     6    11    12
        6     7    10    11
        7     8     9    10
    ];
    V = [ ...
        2.1274    0.0035    0.2943
        2.1272    0.0030    0.2956
        2.1267    0.0017    0.2962
        2.1262    0.0004    0.2956
        2.1260   -0.0001    0.2943
        2.1262    0.0004    0.2929
        2.1267    0.0017    0.2923
        2.1272    0.0030    0.2929
        2.1505   -0.0034    0.2912
        2.1494   -0.0063    0.2899
        2.1483   -0.0092    0.2912
        2.1479   -0.0103    0.2943
        2.1483   -0.0092    0.2973
        2.1494   -0.0063    0.2986
        2.1505   -0.0034    0.2973
        2.1509   -0.0023    0.2943
        2.1530   -0.0077    0.2943
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #71 TurnBankToggle
    F = [ ...
        11    10     9     8
        12    11     8     7
        13    12     7     6
        14    13     6     5
        15    14     5     4
        16    15     4     3
        17    16     3     2
        10    17     2     9
        1     8     9   NaN
        1     7     8   NaN
        1     6     7   NaN
        1     5     6   NaN
        1     4     5   NaN
        1     3     4   NaN
        1     2     3   NaN
        1     9     2   NaN
    ];
    V = [ ...
        2.1530   -0.0077    0.2610
        2.1509   -0.0023    0.2610
        2.1505   -0.0034    0.2641
        2.1494   -0.0063    0.2653
        2.1483   -0.0092    0.2641
        2.1479   -0.0103    0.2610
        2.1483   -0.0092    0.2580
        2.1494   -0.0063    0.2567
        2.1505   -0.0034    0.2580
        2.1272    0.0030    0.2597
        2.1267    0.0017    0.2591
        2.1262    0.0004    0.2597
        2.1260   -0.0001    0.2610
        2.1262    0.0004    0.2624
        2.1267    0.0017    0.2630
        2.1272    0.0030    0.2624
        2.1274    0.0035    0.2610
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #72 RotBeaconToggle
    F = [ ...
        17     9    16   NaN
        17    16    15   NaN
        17    15    14   NaN
        17    14    13   NaN
        17    13    12   NaN
        17    12    11   NaN
        17    11    10   NaN
        17    10     9   NaN
        8     1    16     9
        1     2    15    16
        2     3    14    15
        3     4    13    14
        4     5    12    13
        5     6    11    12
        6     7    10    11
        7     8     9    10
    ];
    V = [ ...
        2.1274    0.0035    0.2257
        2.1272    0.0030    0.2271
        2.1267    0.0017    0.2277
        2.1262    0.0004    0.2271
        2.1260   -0.0001    0.2257
        2.1262    0.0004    0.2243
        2.1267    0.0017    0.2238
        2.1272    0.0030    0.2243
        2.1505   -0.0034    0.2227
        2.1494   -0.0063    0.2214
        2.1483   -0.0092    0.2227
        2.1479   -0.0103    0.2257
        2.1483   -0.0092    0.2288
        2.1494   -0.0063    0.2300
        2.1505   -0.0034    0.2288
        2.1509   -0.0023    0.2257
        2.1530   -0.0077    0.2257
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #73 PitotHeatToggle
    F = [ ...
        11    10     9     8
        12    11     8     7
        13    12     7     6
        14    13     6     5
        15    14     5     4
        16    15     4     3
        17    16     3     2
        10    17     2     9
        1     8     9   NaN
        1     7     8   NaN
        1     6     7   NaN
        1     5     6   NaN
        1     4     5   NaN
        1     3     4   NaN
        1     2     3   NaN
        1     9     2   NaN
    ];
    V = [ ...
        2.1528   -0.0077    0.1922
        2.1506   -0.0023    0.1922
        2.1502   -0.0034    0.1953
        2.1491   -0.0063    0.1965
        2.1481   -0.0092    0.1953
        2.1476   -0.0103    0.1922
        2.1481   -0.0092    0.1892
        2.1491   -0.0063    0.1879
        2.1502   -0.0034    0.1892
        2.1269    0.0030    0.1908
        2.1264    0.0017    0.1903
        2.1259    0.0004    0.1908
        2.1257   -0.0001    0.1922
        2.1259    0.0004    0.1936
        2.1264    0.0017    0.1942
        2.1269    0.0030    0.1936
        2.1271    0.0035    0.1922
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #74 AvionicsMasterToggle
    F = [ ...
        11    10     9     8
        12    11     8     7
        13    12     7     6
        14    13     6     5
        15    14     5     4
        16    15     4     3
        17    16     3     2
        10    17     2     9
        1     8     9   NaN
        1     7     8   NaN
        1     6     7   NaN
        1     5     6   NaN
        1     4     5   NaN
        1     3     4   NaN
        1     2     3   NaN
        1     9     2   NaN
    ];
    V = [ ...
        2.1531   -0.0077   -0.2483
        2.1510   -0.0023   -0.2483
        2.1505   -0.0034   -0.2452
        2.1494   -0.0063   -0.2440
        2.1484   -0.0092   -0.2452
        2.1479   -0.0103   -0.2483
        2.1484   -0.0092   -0.2513
        2.1494   -0.0063   -0.2526
        2.1505   -0.0034   -0.2513
        2.1272    0.0030   -0.2496
        2.1267    0.0017   -0.2502
        2.1262    0.0004   -0.2496
        2.1260   -0.0001   -0.2483
        2.1262    0.0004   -0.2469
        2.1267    0.0017   -0.2463
        2.1272    0.0030   -0.2469
        2.1274    0.0035   -0.2483
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #75 StrobeToggle
    F = [ ...
        17     9    16   NaN
        17    16    15   NaN
        17    15    14   NaN
        17    14    13   NaN
        17    13    12   NaN
        17    12    11   NaN
        17    11    10   NaN
        17    10     9   NaN
        8     1    16     9
        1     2    15    16
        2     3    14    15
        3     4    13    14
        4     5    12    13
        5     6    11    12
        6     7    10    11
        7     8     9    10
    ];
    V = [ ...
        2.1275    0.0035   -0.2124
        2.1273    0.0030   -0.2110
        2.1269    0.0017   -0.2104
        2.1264    0.0004   -0.2110
        2.1262   -0.0001   -0.2124
        2.1264    0.0004   -0.2138
        2.1269    0.0017   -0.2143
        2.1273    0.0030   -0.2138
        2.1506   -0.0034   -0.2154
        2.1496   -0.0063   -0.2167
        2.1485   -0.0092   -0.2154
        2.1481   -0.0103   -0.2124
        2.1485   -0.0092   -0.2093
        2.1496   -0.0063   -0.2081
        2.1506   -0.0034   -0.2093
        2.1511   -0.0023   -0.2124
        2.1532   -0.0077   -0.2124
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #76 NavLightToggle
    F = [ ...
        3    11     2   NaN   NaN   NaN
        4     3     2   NaN   NaN   NaN
        5     4     2   NaN   NaN   NaN
        6     5     2   NaN   NaN   NaN
        7     6     2   NaN   NaN   NaN
        8     7     2   NaN   NaN   NaN
        9     8     2   NaN   NaN   NaN
        10     9     2   NaN   NaN   NaN
        11    10     2   NaN   NaN   NaN
        3    11    13    12   NaN   NaN
        4     3    12    14   NaN   NaN
        5     4    14    15   NaN   NaN
        6     5    15    16   NaN   NaN
        7     6    16    17   NaN   NaN
        8     7    17    18   NaN   NaN
        9     8    18    19   NaN   NaN
        10     9    19    20   NaN   NaN
        11    10    20    13   NaN   NaN
        12    13     1   NaN   NaN   NaN
        14    12     1   NaN   NaN   NaN
        15    14     1   NaN   NaN   NaN
        16    15     1   NaN   NaN   NaN
        17    16     1   NaN   NaN   NaN
        18    17     1   NaN   NaN   NaN
        19    18     1   NaN   NaN   NaN
        20    19     1   NaN   NaN   NaN
        13    20     1   NaN   NaN   NaN
        25    24    23    22    21     4
        25    24    27    26   NaN   NaN
        24    23    28    27   NaN   NaN
        23    22    29    28   NaN   NaN
        22    21    30    29   NaN   NaN
        21     4    14    30   NaN   NaN
        4    25    26    14   NaN   NaN
        26    27    28    29    30    14
    ];
    V = [ ...
        2.1335    0.0002    0.3521
        2.1228    0.0009    0.3522
        2.1228   -0.0035    0.3579
        2.1228   -0.0061    0.3535
        2.1228   -0.0054    0.3483
        2.1228   -0.0015    0.3451
        2.1228    0.0038    0.3459
        2.1228    0.0066    0.3503
        2.1228    0.0102    0.3540
        2.1228    0.0053    0.3562
        2.1228    0.0013    0.3588
        2.1294   -0.0035    0.3579
        2.1294    0.0013    0.3588
        2.1294   -0.0061    0.3535
        2.1294   -0.0054    0.3483
        2.1294   -0.0015    0.3451
        2.1294    0.0038    0.3459
        2.1294    0.0066    0.3503
        2.1294    0.0102    0.3540
        2.1294    0.0053    0.3562
        2.1228   -0.0097    0.3530
        2.1228   -0.0109    0.3513
        2.1228   -0.0103    0.3485
        2.1228   -0.0083    0.3476
        2.1228   -0.0052    0.3484
        2.1294   -0.0052    0.3484
        2.1294   -0.0083    0.3476
        2.1294   -0.0103    0.3485
        2.1294   -0.0109    0.3513
        2.1294   -0.0097    0.3530
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #77 wing
    F = [ ...
        14    15    96   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        14    95    96   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        14    94    95   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        12    14    94   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        94    12    13   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        13   207   101    94   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    117   118   203   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    115   116   197   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    196   115   197   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    203   117   198   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    198   117   116   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    198   116   197   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    122   205   206   124   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    120   204   205   122   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    118   203   204   120   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    108   112   202   114   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    205   200   201   206   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    204   199   200   205   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    203   198   199   204   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    112   220   195   202   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    200   193   194   201   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    199   192   193   200   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    198   191   192   199   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    197   190   191   198   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    196   189   190   197   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    195   188   189   196   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    220   227   188   195   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    193   186   187   194   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    192   185   186   193   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    191   184   185   192   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    190   183   184   191   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    189   182   183   190   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    188   181   182   189   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    227   226   181   188   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    186   179   180   187   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    185   178   179   186   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    184   177   178   185   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    183   176   177   184   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    182   175   176   183   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    181   174   175   182   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    226   222   224   219   225   221   223   174   181   NaN   NaN   NaN   NaN   NaN
    179   172   173   180   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    178   171   172   179   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    177   170   171   178   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    176   169   231   170   177   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    175   168   169   176   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    174   167   168   175   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    236   167   174   223   221   225   219   224   222   218   NaN   NaN   NaN   NaN
    172   165   166   173   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    171   164   165   172   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    170   163   164   171   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    231   169   162   232   163   170   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    168   161   162   169   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    167   160   161   168   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    236   218   217   160   167   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    165   158   159   166   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    164   157   158   165   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    163   156   157   164   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    232   162   155   233   156   163   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    161   154   155   162   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    160   153   154   161   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    217   216   153   160   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    158   151   152   159   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    157   150   151   158   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    156   149   150   157   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    233   155   148   234   149   156   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    154   147   148   155   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    153   146   147   154   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    216   146   153   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    151   144   145   152   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    150   143   144   151   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    149   142   143   150   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    234   148   141   235   142   149   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    147   140   141   148   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    146   139   140   147   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        1   230   139   146   216   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    144   137   138   145   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    143   136   137   144   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    142   135   136   143   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    235   141   134   135   142   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    140   133   134   141   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    139   132   133   140   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    230   111   132   139   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    137   130   131   138   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    136   129   130   137   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    135   128   129   136   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    134   127   128   135   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    133   126   127   134   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    132   125   126   133   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    111   110   125   132   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    130   121   123   131   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    129   119   121   130   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    128   117   119   129   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    127   116   117   128   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    126   115   116   127   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    125   113   115   126   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    110   109   113   125   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    121   122   124   123   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    119   120   122   121   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    117   118   120   119   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    109   108   114   113   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    106   107   108   112   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    220   106   112   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    107   109   108   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    107   109   110   111   230     1   216   217   218   222   226   227   220   106
        97    16   102   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        16   102    17   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        15    16    97   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        96    15    97   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        23   105   104    21   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        21   104   103    19   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        19   103   102    17   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        13   207   101    11     7   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    105   100    99   104   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    104    99    98   103   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    103    98    97   102   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    101    94   208    11   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    100    93    92    99   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        99    92    91    98   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        98    91    90    97   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        97    90    89    96   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        96    89    88    95   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        95    88    87    94   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    208    94    87   215   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        93    86    85    92   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        92    85    84    91   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        91    84    83    90   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        90    83    82    89   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        89    82    81    88   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        88    81    80    87   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    215    87    80   228   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        86    79    78    85   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        85    78    77    84   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        84    77    76    83   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        83    76    75    82   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        82    75    74    81   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        81    74    73    80   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    228    80    73   229   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        79    72    71    78   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        78    71    70    77   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        77    70    69    76   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        76    69    68    75   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        75    68    67    74   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        74    67    66    73   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    229    73    66   209   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        72    65    64    71   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        71    64    63    70   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        70    63    62    69   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        69    62    61    68   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        68    61    60    67   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        67    60    59    66   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    209    66    59   210   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        65    58    57    64   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        64    57    56    63   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        63    56    55    62   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        62    55    54    61   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        61    54    53    60   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        60    53    52    59   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    210    59    52   214   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        58    51    50    57   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        57    50    49    56   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        56    49    48    55   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        55    48    47    54   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        54    47    46    53   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        53    46    45    52   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    214    52    45   213   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        51    44    43    50   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        50    43    42    49   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        49    42    41    48   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        48    41    40    47   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        47    40    39    46   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        46    39    38    45   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    213    45    38   211   212   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        44    37    36    43   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        43    36    35    42   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        42    35    34    41   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        41    34    33    40   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        40    33    32    39   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        39    32    31    38   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    211    38    31    10   212   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        37    30    29    36   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        36    29    28    35   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        35    28    27    34   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        34    27    26    33   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        33    26    25    32   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        32    25    24    31   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        31    24     9    10   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        30    22    20    29   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        29    20    18    28   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        28    18    16    27   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        27    16    15    26   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        26    15    14    25   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        25    14    12    24   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        24    12     8     9   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        22    23    21    20   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        20    21    19    18   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        18    19    17    16   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        12    13     7     8   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        11     7     6     2   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    208    11     2   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        10   212     3   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        9    10     3     4   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        8     9     4     5   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        7     8     5     6   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        2   208   215   228   229   209   210   214   213   212     3     4     5     6
    195   202   113   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    202   114   113   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    195   113   196   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    113   115   196   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        1   146   216   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
        1   230   216   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
    ];
    V = [ ...
        2.1023   -0.4694    0.5398
        4.2347   -0.4125   -0.4014
        2.5746   -0.5495   -0.5136
        3.0915   -0.5376   -0.5129
        3.8814   -0.4692   -0.4513
        4.2505   -0.4191   -0.4013
        4.2507   -0.4191   -0.4013
        3.8815   -0.4691   -0.4512
        3.0916   -0.5375   -0.5128
        2.5747   -0.5494   -0.5135
        4.2348   -0.4124   -0.4013
        3.8648   -0.4599   -0.6282
        4.2092   -0.4050   -0.6142
        3.7187   -0.3809   -1.4618
        3.4124   -0.2097   -3.1672
        3.0645   -0.0122   -5.1562
        3.3241    0.0322   -5.1972
        3.1292    0.0008   -5.2615
        3.3022    0.0353   -5.2614
        2.9517    0.0083   -5.3204
        3.0746    0.0362   -5.3204
        2.6653    0.0310   -5.3608
        2.6788    0.0388   -5.3608
        3.1193   -0.5264   -0.6155
        3.1846   -0.4393   -1.4626
        3.0324   -0.2501   -3.1787
        2.8495   -0.0438   -5.1701
        2.8384   -0.0323   -5.2618
        2.7451   -0.0176   -5.3207
        2.6423    0.0247   -5.3608
        2.6127   -0.5381   -0.6162
        2.7978   -0.4489   -1.4631
        2.7234   -0.2632   -3.1791
        2.6325   -0.0568   -5.1703
        2.6264   -0.0448   -5.2621
        2.5944   -0.0269   -5.3209
        2.6254    0.0233   -5.3608
        2.3184   -0.5219   -0.6168
        2.5730   -0.4336   -1.4636
        2.5436   -0.2542   -3.1794
        2.5060   -0.0523   -5.1651
        2.5028   -0.0412   -5.2623
        2.5065   -0.0231   -5.3210
        2.6154    0.0254   -5.3609
        2.1232   -0.4693   -0.6173
        2.4238   -0.3854   -1.4640
        2.4238   -0.2182   -3.1798
        2.4212   -0.0274   -5.1984
        2.4201   -0.0189   -5.2626
        2.4476   -0.0039   -5.3212
        2.6086    0.0322   -5.3609
        2.0685   -0.4400   -0.6175
        2.3820   -0.3585   -1.4642
        2.3900   -0.1976   -3.1799
        2.3972   -0.0126   -5.1985
        2.3967   -0.0057   -5.2626
        2.4308    0.0073   -5.3213
        2.6066    0.0360   -5.3609
        2.0409   -0.4002   -0.6178
        2.3607   -0.3223   -1.4644
        2.3726   -0.1693   -3.1801
        2.3846    0.0080   -5.1986
        2.3844    0.0128   -5.2628
        2.4220    0.0229   -5.3214
        2.6055    0.0412   -5.3610
        2.1080   -0.3443   -0.6179
        2.4119   -0.2715   -1.4645
        2.4128   -0.1284   -3.1802
        2.4123    0.0384   -5.1987
        2.4116    0.0403   -5.2628
        2.4411    0.0459   -5.3214
        2.6074    0.0484   -5.3610
        2.3288   -0.2763   -0.6178
        2.5804   -0.2100   -1.4645
        2.5465   -0.0775   -3.1802
        2.5056    0.0775   -5.1656
        2.5029    0.0757   -5.2628
        2.5058    0.0751   -5.3215
        2.6144    0.0572   -5.3610
        2.6089   -0.2426   -0.6175
        2.7943   -0.1798   -1.4643
        2.7170   -0.0506   -3.1800
        2.6250    0.0991   -5.1710
        2.6197    0.0956   -5.2627
        2.5888    0.0911   -5.3214
        2.6235    0.0615   -5.3610
        2.9619   -0.2480   -0.6169
        3.0639   -0.1854   -1.4639
        2.9324   -0.0513   -3.1797
        2.7765    0.1011   -5.1708
        2.7676    0.0979   -5.2625
        2.6940    0.0921   -5.3212
        2.6354    0.0608   -5.3610
        3.8570   -0.3416   -0.6287
        3.7077   -0.2728   -1.4624
        3.4039   -0.1126   -3.1676
        3.0572    0.0590   -5.1565
        3.1223    0.0649   -5.2618
        2.9465    0.0621   -5.3207
        2.6641    0.0485   -5.3609
        4.1956   -0.3994   -0.6143
        3.3177    0.0372   -5.1972
        3.2960    0.0469   -5.2614
        3.0701    0.0460   -5.3204
        2.6782    0.0421   -5.3608
        4.2366   -0.4125    0.3998
        4.2506   -0.4191    0.3997
        4.2507   -0.4191    0.3997
        3.8814   -0.4691    0.4497
        3.0916   -0.5376    0.5113
        2.5747   -0.5494    0.5120
        4.2367   -0.4124    0.3998
        3.8648   -0.4599    0.6267
        4.2092   -0.4050    0.6127
        3.7187   -0.3809    1.4602
        3.4124   -0.2097    3.1656
        3.0645   -0.0122    5.1546
        3.3241    0.0322    5.1956
        3.1292    0.0008    5.2599
        3.3022    0.0353    5.2598
        2.9517    0.0083    5.3189
        3.0746    0.0362    5.3188
        2.6653    0.0310    5.3593
        2.6788    0.0388    5.3593
        3.1193   -0.5264    0.6139
        3.1846   -0.4393    1.4610
        3.0324   -0.2501    3.1771
        2.8495   -0.0438    5.1685
        2.8384   -0.0323    5.2603
        2.7451   -0.0176    5.3191
        2.6423    0.0247    5.3593
        2.6127   -0.5381    0.6147
        2.7978   -0.4489    1.4616
        2.7234   -0.2632    3.1776
        2.6325   -0.0568    5.1688
        2.6264   -0.0448    5.2606
        2.5944   -0.0269    5.3193
        2.6254    0.0233    5.3593
        2.3184   -0.5219    0.6152
        2.5730   -0.4336    1.4620
        2.5436   -0.2542    3.1779
        2.5060   -0.0523    5.1635
        2.5028   -0.0412    5.2608
        2.5065   -0.0231    5.3195
        2.6154    0.0254    5.3593
        2.1232   -0.4693    0.6158
        2.4238   -0.3854    1.4625
        2.4238   -0.2182    3.1782
        2.4212   -0.0274    5.1968
        2.4201   -0.0189    5.2610
        2.4476   -0.0039    5.3197
        2.6086    0.0322    5.3594
        2.0685   -0.4400    0.6160
        2.3820   -0.3585    1.4627
        2.3900   -0.1976    3.1784
        2.3972   -0.0126    5.1969
        2.3967   -0.0057    5.2611
        2.4308    0.0073    5.3197
        2.6066    0.0360    5.3594
        2.0409   -0.4002    0.6162
        2.3607   -0.3223    1.4628
        2.3726   -0.1693    3.1785
        2.3846    0.0080    5.1970
        2.3844    0.0128    5.2612
        2.4220    0.0229    5.3198
        2.6055    0.0412    5.3594
        2.1080   -0.3443    0.6163
        2.4119   -0.2715    1.4630
        2.4128   -0.1284    3.1786
        2.4123    0.0384    5.1971
        2.4116    0.0403    5.2613
        2.4411    0.0459    5.3199
        2.6074    0.0484    5.3594
        2.3288   -0.2763    0.6163
        2.5804   -0.2100    1.4630
        2.5465   -0.0775    3.1786
        2.5056    0.0775    5.1641
        2.5029    0.0757    5.2613
        2.5058    0.0751    5.3199
        2.6144    0.0572    5.3594
        2.6089   -0.2426    0.6160
        2.7943   -0.1798    1.4628
        2.7170   -0.0506    3.1785
        2.6250    0.0991    5.1695
        2.6197    0.0956    5.2612
        2.5888    0.0911    5.3198
        2.6235    0.0615    5.3595
        2.9619   -0.2480    0.6154
        3.0639   -0.1854    1.4623
        2.9324   -0.0513    3.1781
        2.7765    0.1011    5.1693
        2.7676    0.0979    5.2609
        2.6940    0.0921    5.3197
        2.6354    0.0608    5.3594
        3.8570   -0.3416    0.6272
        3.7077   -0.2728    1.4609
        3.4039   -0.1126    3.1661
        3.0572    0.0590    5.1550
        3.1223    0.0649    5.2602
        2.9465    0.0621    5.3191
        2.6641    0.0485    5.3593
        4.1956   -0.3994    0.6127
        3.3177    0.0372    5.1956
        3.2960    0.0469    5.2599
        3.0701    0.0460    5.3189
        2.6782    0.0421    5.3593
        4.2024   -0.4022   -0.6143
        3.7991   -0.3478   -0.5270
        2.0885   -0.3469   -0.5606
        2.0170   -0.4036   -0.5578
        2.2964   -0.5273   -0.5654
        2.2744   -0.5328   -0.5141
        2.0854   -0.4774   -0.5371
        2.0356   -0.4459   -0.5488
        2.9452   -0.2483   -0.5761
        2.0410   -0.4419    0.5535
        2.0182   -0.4045    0.5594
        2.0853   -0.3472    0.5702
        2.3241   -0.2768    0.6053
        3.8088   -0.3468    0.5424
        2.3265   -0.2765    0.6108
        2.3114   -0.2781    0.5756
        2.3276   -0.2764    0.6135
        2.3178   -0.2775    0.5904
        2.3253   -0.2766    0.6080
        2.5955   -0.2439    0.5798
        2.9522   -0.2492    0.5834
        2.5862   -0.2464   -0.5760
        2.3133   -0.2798   -0.5744
        2.2902   -0.5214    0.5232
        2.4123    0.0176    4.9448
        2.3831   -0.0142    4.9447
        2.3963   -0.0357    4.9446
        2.4216   -0.0512    4.9445
        2.5107   -0.0775    4.9153
        2.0966   -0.3458    0.5922
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #78 RightFlap
    F = [ ...
        5     9     6   NaN
        6    12     9   NaN
        9     5     3   NaN
        3     8     9   NaN
        2    10     7   NaN
        7     1     2   NaN
        8     3     1   NaN
        1     7     8   NaN
        6    12    11     4
        4    11    10     2
        12     9     8    11
        11     8     7    10
        5     6     4     3
        3     4     2     1
    ];
    V = [ ...
        3.8648   -0.4599   -0.6282
        4.2092   -0.4050   -0.6142
        3.7187   -0.3809   -1.4618
        4.0447   -0.3265   -1.4649
        3.4124   -0.2097   -3.1672
        3.6996   -0.1617   -3.2235
        3.8570   -0.3416   -0.6287
        3.7077   -0.2728   -1.4624
        3.4039   -0.1126   -3.1676
        4.1956   -0.3994   -0.6143
        4.0315   -0.3208   -1.4650
        3.6909   -0.1574   -3.2235
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #79 LeftFlap
    F = [ ...
        6     9     5   NaN
        6    12     9   NaN
        3     5     9   NaN
        9     8     3   NaN
        2     1     7   NaN
        1     3     8   NaN
        8     7     1   NaN
        4    11    12     6
        11     8     9    12
        10     7     8    11
        3     4     6     5
        1     2     4     3
        4     2    10    11
        2     7    10   NaN
    ];
    V = [ ...
        3.8648   -0.4599    0.6267
        4.2092   -0.4050    0.6127
        3.7187   -0.3809    1.4602
        4.0447   -0.3265    1.4634
        3.4124   -0.2097    3.1656
        3.6996   -0.1617    3.2220
        3.8570   -0.3416    0.6272
        3.7077   -0.2728    1.4609
        3.4039   -0.1126    3.1661
        4.1956   -0.3994    0.6127
        4.0315   -0.3208    1.4634
        3.6909   -0.1574    3.2220
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #80 RightAileron
    F = [ ...
        3     8     4
        3     6     8
        4     8     2
        5     6     3
        5     1     3
        5     7     6
        8     6     7
        1     3     2
        4     2     3
        7     1     5
        1     7     2
    ];
    V = [ ...
        3.3211    0.0367   -5.1939
        3.6928   -0.1560   -3.2198
        3.0604    0.0569   -5.1535
        3.4054   -0.1129   -3.1643
        3.3275    0.0317   -5.1939
        3.0681   -0.0143   -5.1532
        3.7015   -0.1602   -3.2197
        3.4145   -0.2099   -3.1638
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #81 LeftAileron
    F = [ ...
        7     2     8
        2     8     4
        6     7     5
        7     6     8
        2     3     1
        3     2     4
        6     8     4
        6     3     4
        7     1     5
        1     3     6
        5     1     6
    ];
    V = [ ...
        3.4145   -0.2099    3.1623
        3.7015   -0.1602    3.2182
        3.0681   -0.0143    5.1517
        3.3275    0.0317    5.1923
        3.4054   -0.1129    3.1627
        3.0604    0.0569    5.1520
        3.6928   -0.1560    3.2182
        3.3211    0.0367    5.1923
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #82 AntiServoTab
    F = [ ...
        1     3    13     7
        25     1     3   NaN
        3    13     4   NaN
        25     3    16   NaN
        23    26    27    24
        22    25    26    23
        22     2     1    25
        20    23    24    21
        19    22    23    20
        2    22    19   NaN
        17    20    21    18
        16    19    20    17
        2    19    16     3
        24    21    27   NaN
        21    27    18   NaN
        18    27    26   NaN
        18    26    17   NaN
        25    17    26   NaN
        25    16    17   NaN
        12    15    14    11
        11    14    13    10
        10    13     1     2
        9    12    11     8
        8    11    10     7
        7    10     2   NaN
        6     9     8     5
        5     8     7     4
        4     7     2     3
        12     9    15   NaN
        6    15     9   NaN
        14    15     6   NaN
        5    14     6   NaN
        14     5    13   NaN
        5     4    13   NaN
    ];
    V = [ ...
        7.5172    0.2835   -0.0007
        7.6980    0.3260   -0.0007
        7.5125    0.3555   -0.0007
        7.5142    0.3555    0.1070
        7.5134    0.3555    0.5747
        7.5136    0.3555    1.3935
        7.6924    0.3312    0.1070
        7.6730    0.3312    0.5775
        7.6413    0.3299    1.3969
        7.6970    0.3237    0.1070
        7.6770    0.3237    0.5775
        7.6445    0.3222    1.3969
        7.5188    0.2871    0.1070
        7.5174    0.2871    0.5747
        7.5167    0.2871    1.3935
        7.5142    0.3555   -0.1086
        7.5134    0.3555   -0.5762
        7.5136    0.3555   -1.3950
        7.6924    0.3312   -0.1086
        7.6730    0.3312   -0.5791
        7.6413    0.3299   -1.3984
        7.6970    0.3220   -0.1086
        7.6770    0.3237   -0.5791
        7.6445    0.3222   -1.3984
        7.5188    0.2835   -0.1086
        7.5174    0.2871   -0.5762
        7.5167    0.2871   -1.3950
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #83 Rudder
    F = [ ...
        29    16    15    14     1    27    28
        17    16    29    30   NaN   NaN   NaN
        30    31    18    17   NaN   NaN   NaN
        5     9    19    32    23   NaN   NaN
        19    18    32   NaN   NaN   NaN   NaN
        31    32    18   NaN   NaN   NaN   NaN
        30    26    32    31   NaN   NaN   NaN
        29    25    26    30   NaN   NaN   NaN
        28    24    25    29   NaN   NaN   NaN
        27    10    24    28   NaN   NaN   NaN
        1    10    27   NaN   NaN   NaN   NaN
        32    26    23   NaN   NaN   NaN   NaN
        25    22    23    26   NaN   NaN   NaN
        24    21    22    25   NaN   NaN   NaN
        10    20    21    24   NaN   NaN   NaN
        22     4     5    23   NaN   NaN   NaN
        21     3     4    22   NaN   NaN   NaN
        20     2     3    21   NaN   NaN   NaN
        1     2    20   NaN   NaN   NaN   NaN
        18    19    13    17   NaN   NaN   NaN
        17    13    12    16   NaN   NaN   NaN
        16    12    11    15   NaN   NaN   NaN
        15    11    10    14   NaN   NaN   NaN
        14    10     1   NaN   NaN   NaN   NaN
        9    13    19   NaN   NaN   NaN   NaN
        13     9     8    12   NaN   NaN   NaN
        12     8     7    11   NaN   NaN   NaN
        11     7     6    10   NaN   NaN   NaN
        9     5     4     8   NaN   NaN   NaN
        8     4     3     7   NaN   NaN   NaN
        7     3     2     6   NaN   NaN   NaN
        6     2     1   NaN   NaN   NaN   NaN
    ];
    V = [ ...
        7.4527    1.7236   -0.0004
        7.7653    1.6914   -0.0008
        7.8206    1.6653   -0.0008
        7.8143    1.6299   -0.0008
        7.4920    0.5563   -0.0014
        7.7664    1.6915    0.0014
        7.8217    1.6655    0.0014
        7.8155    1.6301    0.0016
        7.4899    0.5585    0.0034
        7.6683    1.6998   -0.0008
        7.6400    1.6657    0.0201
        7.6157    1.6299    0.0277
        7.3165    0.5569    0.0277
        7.4461    1.7061    0.0186
        7.4340    1.6637    0.0329
        7.4247    1.6330    0.0430
        7.0980    0.5569    0.0430
        7.0718    0.4684    0.0430
        7.3061    0.5245    0.0277
        7.7664    1.6914   -0.0035
        7.8217    1.6659   -0.0039
        7.8155    1.6296   -0.0037
        7.4899    0.5567   -0.0057
        7.6400    1.6657   -0.0217
        7.6157    1.6299   -0.0293
        7.3165    0.5569   -0.0293
        7.4461    1.7061   -0.0201
        7.4340    1.6637   -0.0344
        7.4247    1.6330   -0.0446
        7.0980    0.5569   -0.0446
        7.0718    0.4684   -0.0446
        7.3061    0.5245   -0.0293
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #84 vertical-stab
    F = [ ...
        45    50    55
        50    45    49
        48    45    44
        45    48    49
        47    44    43
        44    47    48
        46    43    42
        43    46    47
        57    54    25
        54    57    42
        42    57    46
        46    57    24
        44    41    40
        41    44    45
        43    40    39
        40    43    44
        42    39    38
        39    42    43
        25    53    26
        53    25    54
        53    54    38
        38    54    42
        36    55    37
        55    36    41
        40    36    34
        36    40    41
        39    34    32
        34    39    40
        38    32    30
        32    38    39
        26    52    27
        52    26    53
        52    53    30
        30    53    38
        34    35    33
        35    34    36
        32    33    31
        33    32    34
        30    31    29
        31    30    32
        27    51    28
        51    27    52
        51    52    29
        29    52    30
        55    20    16
        20    55    50
        16    19    15
        19    16    20
        15    18    14
        18    15    19
        14    17    13
        17    14    18
        23    56     2
        56    23    13
        56    13    17
        56    17     1
        12    15    11
        15    12    16
        11    14    10
        14    11    15
        10    13     9
        13    10    14
        22     2     3
        2    22    23
        23    22     9
        23     9    13
        8    55    12
        55     8    37
        8    11     7
        11     8    12
        7    10     6
        10     7    11
        6     9     5
        9     6    10
        21     3     4
        3    21    22
        22    21     5
        22     5     9
        33     8     7
        8    33    35
        33     6    31
        6    33     7
        31     5    29
        5    31     6
        51     4    28
        4    51    21
        21    51    29
        21    29     5
        41    45    55
        35    36    37
        55    16    12
        37     8    35
        24     1    46
        46     1    17
        17    18    46
        46    18    47
        48    47    18
        18    19    48
        49    48    19
        19    20    49
        50    49    20
    ];
    V = [ ...
        7.0718    0.4684   -0.0446
        5.4580    0.5432   -0.0633
        5.1907    0.5557   -0.0446
        5.0647    0.5744   -0.0235
        6.3538    0.6752   -0.0235
        7.1069    1.6299   -0.0150
        7.1353    1.6622   -0.0158
        7.1854    1.7005   -0.0127
        6.3838    0.6454   -0.0446
        7.1592    1.6299   -0.0327
        7.2008    1.6586   -0.0269
        7.2458    1.7046   -0.0183
        6.5007    0.5587   -0.0633
        7.3064    1.6299   -0.0463
        7.3121    1.6661   -0.0387
        7.3174    1.7071   -0.0268
        7.0981    0.5568   -0.0446
        7.4247    1.6330   -0.0446
        7.4340    1.6637   -0.0344
        7.4461    1.7061   -0.0201
        6.2109    0.5905   -0.0235
        6.2443    0.5730   -0.0446
        6.2803    0.5569   -0.0633
        7.0718    0.4684    0.0430
        5.4580    0.5432    0.0617
        5.1907    0.5557    0.0430
        5.0647    0.5744    0.0220
        5.0379    0.5744   -0.0008
        6.3247    0.6971   -0.0008
        6.3538    0.6752    0.0220
        7.0819    1.6299   -0.0008
        7.1069    1.6299    0.0134
        7.1127    1.6591   -0.0008
        7.1353    1.6622    0.0142
        7.1536    1.6914   -0.0008
        7.1860    1.7005    0.0119
        7.2178    1.7128   -0.0008
        6.3838    0.6454    0.0430
        7.1592    1.6299    0.0311
        7.2008    1.6586    0.0253
        7.2458    1.7046    0.0175
        6.5007    0.5587    0.0617
        7.3064    1.6299    0.0447
        7.3121    1.6661    0.0372
        7.3174    1.7071    0.0253
        7.0981    0.5568    0.0430
        7.4247    1.6330    0.0430
        7.4340    1.6637    0.0329
        7.4461    1.7061    0.0186
        7.4527    1.7236   -0.0004
        6.1643    0.6170   -0.0008
        6.2109    0.5905    0.0220
        6.2443    0.5730    0.0430
        6.2803    0.5569    0.0617
        7.3188    1.7231   -0.0008
        6.6059    0.4544   -0.0621
        6.6059    0.4544    0.0605
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #85 Stabilator
    F = [ ...
    135    83   134   NaN   NaN   NaN   NaN   NaN   NaN
    134    83    81   133   NaN   NaN   NaN   NaN   NaN
    133    81    79   132   NaN   NaN   NaN   NaN   NaN
    132    79    77   131   NaN   NaN   NaN   NaN   NaN
    131    77    75   130   NaN   NaN   NaN   NaN   NaN
    130    75    73   129   NaN   NaN   NaN   NaN   NaN
    129    73     3     1   NaN   NaN   NaN   NaN   NaN
    135   134   128   NaN   NaN   NaN   NaN   NaN   NaN
    128   134   133   127   NaN   NaN   NaN   NaN   NaN
    127   133   132   126   NaN   NaN   NaN   NaN   NaN
    126   132   131   125   NaN   NaN   NaN   NaN   NaN
    125   131   130   124   NaN   NaN   NaN   NaN   NaN
    124   130   129   123   NaN   NaN   NaN   NaN   NaN
    123   129     1    67   NaN   NaN   NaN   NaN   NaN
    135   128   122   NaN   NaN   NaN   NaN   NaN   NaN
    122   128   127   121   NaN   NaN   NaN   NaN   NaN
    121   127   126   120   NaN   NaN   NaN   NaN   NaN
    120   126   125   119   NaN   NaN   NaN   NaN   NaN
    119   125   124   118   NaN   NaN   NaN   NaN   NaN
    118   124   123   117   NaN   NaN   NaN   NaN   NaN
    117   123    67    68   NaN   NaN   NaN   NaN   NaN
    135   122   116   NaN   NaN   NaN   NaN   NaN   NaN
    116   122   121   115   NaN   NaN   NaN   NaN   NaN
    115   121   120   114   NaN   NaN   NaN   NaN   NaN
    114   120   119   113   NaN   NaN   NaN   NaN   NaN
    113   119   118   112   NaN   NaN   NaN   NaN   NaN
    112   118   117   111   NaN   NaN   NaN   NaN   NaN
    111   117    68    69   NaN   NaN   NaN   NaN   NaN
    135   116   110   NaN   NaN   NaN   NaN   NaN   NaN
    110   116   115   109   NaN   NaN   NaN   NaN   NaN
    109   115   114   108   NaN   NaN   NaN   NaN   NaN
    108   114   113   107   NaN   NaN   NaN   NaN   NaN
    135   110   106   NaN   NaN   NaN   NaN   NaN   NaN
    106   110   109   105   NaN   NaN   NaN   NaN   NaN
    105   109   108   104   NaN   NaN   NaN   NaN   NaN
    104   108   107   103   NaN   NaN   NaN   NaN   NaN
    135   106   102   NaN   NaN   NaN   NaN   NaN   NaN
    102   106   105   101   NaN   NaN   NaN   NaN   NaN
    101   105   104   100   NaN   NaN   NaN   NaN   NaN
    100   104   103    99   NaN   NaN   NaN   NaN   NaN
    135   102    96   NaN   NaN   NaN   NaN   NaN   NaN
        96   102   101    95   NaN   NaN   NaN   NaN   NaN
        95   101   100    94   NaN   NaN   NaN   NaN   NaN
        94   100    99    93   NaN   NaN   NaN   NaN   NaN
        93    99    98    92   NaN   NaN   NaN   NaN   NaN
        92    98    97    91   NaN   NaN   NaN   NaN   NaN
        91    97    70    71   NaN   NaN   NaN   NaN   NaN
    135    96    90   NaN   NaN   NaN   NaN   NaN   NaN
        90    96    95    89   NaN   NaN   NaN   NaN   NaN
        89    95    94    88   NaN   NaN   NaN   NaN   NaN
        88    94    93    87   NaN   NaN   NaN   NaN   NaN
        87    93    92    86   NaN   NaN   NaN   NaN   NaN
        86    92    91    85   NaN   NaN   NaN   NaN   NaN
        85    91    71    72   NaN   NaN   NaN   NaN   NaN
    135    90    84   NaN   NaN   NaN   NaN   NaN   NaN
        84    90    89    82   NaN   NaN   NaN   NaN   NaN
        82    89    88    80   NaN   NaN   NaN   NaN   NaN
        80    88    87    78   NaN   NaN   NaN   NaN   NaN
        78    87    86    76   NaN   NaN   NaN   NaN   NaN
        76    86    85    74   NaN   NaN   NaN   NaN   NaN
        74    85    72     2   NaN   NaN   NaN   NaN   NaN
    135    84    83   NaN   NaN   NaN   NaN   NaN   NaN
        83    84    82    81   NaN   NaN   NaN   NaN   NaN
        81    82    80    79   NaN   NaN   NaN   NaN   NaN
        79    80    78    77   NaN   NaN   NaN   NaN   NaN
        77    78    76    75   NaN   NaN   NaN   NaN   NaN
        75    76    74    73   NaN   NaN   NaN   NaN   NaN
        73    74     2     3   NaN   NaN   NaN   NaN   NaN
        65    14    66   NaN   NaN   NaN   NaN   NaN   NaN
        64    12    14    65   NaN   NaN   NaN   NaN   NaN
        63    10    12    64   NaN   NaN   NaN   NaN   NaN
        62     8    10    63   NaN   NaN   NaN   NaN   NaN
        61     6     8    62   NaN   NaN   NaN   NaN   NaN
        60     4     6    61   NaN   NaN   NaN   NaN   NaN
        1     3     4    60   NaN   NaN   NaN   NaN   NaN
        59    65    66   NaN   NaN   NaN   NaN   NaN   NaN
        58    64    65    59   NaN   NaN   NaN   NaN   NaN
        57    63    64    58   NaN   NaN   NaN   NaN   NaN
        56    62    63    57   NaN   NaN   NaN   NaN   NaN
        55    61    62    56   NaN   NaN   NaN   NaN   NaN
        54    60    61    55   NaN   NaN   NaN   NaN   NaN
        67     1    60    54   NaN   NaN   NaN   NaN   NaN
        53    59    66   NaN   NaN   NaN   NaN   NaN   NaN
        52    58    59    53   NaN   NaN   NaN   NaN   NaN
        51    57    58    52   NaN   NaN   NaN   NaN   NaN
        50    56    57    51   NaN   NaN   NaN   NaN   NaN
        49    55    56    50   NaN   NaN   NaN   NaN   NaN
        48    54    55    49   NaN   NaN   NaN   NaN   NaN
        68    67    54    48   NaN   NaN   NaN   NaN   NaN
        47    53    66   NaN   NaN   NaN   NaN   NaN   NaN
        46    52    53    47   NaN   NaN   NaN   NaN   NaN
        45    51    52    46   NaN   NaN   NaN   NaN   NaN
        44    50    51    45   NaN   NaN   NaN   NaN   NaN
        43    49    50    44   NaN   NaN   NaN   NaN   NaN
        42    48    49    43   NaN   NaN   NaN   NaN   NaN
        69    68    48    42   NaN   NaN   NaN   NaN   NaN
        41    47    66   NaN   NaN   NaN   NaN   NaN   NaN
        40    46    47    41   NaN   NaN   NaN   NaN   NaN
        39    45    46    40   NaN   NaN   NaN   NaN   NaN
        38    44    45    39   NaN   NaN   NaN   NaN   NaN
        37    41    66   NaN   NaN   NaN   NaN   NaN   NaN
        36    40    41    37   NaN   NaN   NaN   NaN   NaN
        35    39    40    36   NaN   NaN   NaN   NaN   NaN
        34    38    39    35   NaN   NaN   NaN   NaN   NaN
        33    37    66   NaN   NaN   NaN   NaN   NaN   NaN
        32    36    37    33   NaN   NaN   NaN   NaN   NaN
        31    35    36    32   NaN   NaN   NaN   NaN   NaN
        30    34    35    31   NaN   NaN   NaN   NaN   NaN
        27    33    66   NaN   NaN   NaN   NaN   NaN   NaN
        26    32    33    27   NaN   NaN   NaN   NaN   NaN
        25    31    32    26   NaN   NaN   NaN   NaN   NaN
        24    30    31    25   NaN   NaN   NaN   NaN   NaN
        23    29    30    24   NaN   NaN   NaN   NaN   NaN
        22    28    29    23   NaN   NaN   NaN   NaN   NaN
        71    70    28    22   NaN   NaN   NaN   NaN   NaN
        21    27    66   NaN   NaN   NaN   NaN   NaN   NaN
        20    26    27    21   NaN   NaN   NaN   NaN   NaN
        19    25    26    20   NaN   NaN   NaN   NaN   NaN
        18    24    25    19   NaN   NaN   NaN   NaN   NaN
        17    23    24    18   NaN   NaN   NaN   NaN   NaN
        16    22    23    17   NaN   NaN   NaN   NaN   NaN
        72    71    22    16   NaN   NaN   NaN   NaN   NaN
        15    21    66   NaN   NaN   NaN   NaN   NaN   NaN
        13    20    21    15   NaN   NaN   NaN   NaN   NaN
        11    19    20    13   NaN   NaN   NaN   NaN   NaN
        9    18    19    11   NaN   NaN   NaN   NaN   NaN
        7    17    18     9   NaN   NaN   NaN   NaN   NaN
        5    16    17     7   NaN   NaN   NaN   NaN   NaN
        2    72    16     5   NaN   NaN   NaN   NaN   NaN
        14    15    66   NaN   NaN   NaN   NaN   NaN   NaN
        12    13    15    14   NaN   NaN   NaN   NaN   NaN
        10    11    13    12   NaN   NaN   NaN   NaN   NaN
        8     9    11    10   NaN   NaN   NaN   NaN   NaN
        6     7     9     8   NaN   NaN   NaN   NaN   NaN
        4     5     7     6   NaN   NaN   NaN   NaN   NaN
        3     2     5     4   NaN   NaN   NaN   NaN   NaN
        3     2    72    71    70    69    68    67     1
        44    38    34   NaN   NaN   NaN   NaN   NaN   NaN
        30    44    34   NaN   NaN   NaN   NaN   NaN   NaN
        44    30    43   NaN   NaN   NaN   NaN   NaN   NaN
        30    29    43   NaN   NaN   NaN   NaN   NaN   NaN
        29    42    43   NaN   NaN   NaN   NaN   NaN   NaN
        28    42    29   NaN   NaN   NaN   NaN   NaN   NaN
    112    42    28   NaN   NaN   NaN   NaN   NaN   NaN
        28    98   112   NaN   NaN   NaN   NaN   NaN   NaN
    113   112    98   NaN   NaN   NaN   NaN   NaN   NaN
        98    99   113   NaN   NaN   NaN   NaN   NaN   NaN
        99   107   113   NaN   NaN   NaN   NaN   NaN   NaN
    107   103    99   NaN   NaN   NaN   NaN   NaN   NaN
    ];
    V = [ ...
        6.7239    0.2871   -0.0008
        6.7286    0.3509   -0.0008
        6.6864    0.3099   -0.0008
        6.7103    0.3099   -0.1086
        6.7515    0.3509   -0.1086
        6.8061    0.3099   -0.5722
        6.8428    0.3509   -0.5722
        6.9635    0.3099   -1.3950
        6.9918    0.3509   -1.3950
        7.0337    0.3099   -1.7283
        7.0582    0.3509   -1.7283
        7.0480    0.3103   -1.7865
        7.0694    0.3460   -1.7865
        7.0656    0.3117   -1.8190
        7.0817    0.3386   -1.8190
        6.8202    0.3646   -0.1086
        6.9039    0.3646   -0.5722
        7.0389    0.3646   -1.3950
        7.0990    0.3646   -1.7283
        7.1052    0.3579   -1.7865
        7.1086    0.3475   -1.8190
        7.0720    0.3692   -0.1086
        7.1279    0.3692   -0.5722
        7.2118    0.3692   -1.3950
        7.2488    0.3692   -1.7283
        7.2363    0.3619   -1.7865
        7.2072    0.3505   -1.8190
        7.5142    0.3555   -0.1086
        7.5134    0.3555   -0.5762
        7.5136    0.3555   -1.3950
        7.5102    0.3555   -1.7283
        7.5076    0.3500   -1.7865
        7.4106    0.3416   -1.8190
        7.6413    0.3299   -1.3984
        7.6218    0.3299   -1.7283
        7.6239    0.3289   -1.7865
        7.4980    0.3287   -1.8190
        7.6445    0.3222   -1.3984
        7.6246    0.3222   -1.7283
        7.6267    0.3221   -1.7865
        7.5001    0.3226   -1.8190
        7.5188    0.2871   -0.1086
        7.5174    0.2871   -0.5762
        7.5167    0.2871   -1.3950
        7.5129    0.2871   -1.7283
        7.5104    0.2904   -1.7865
        7.4127    0.2968   -1.8190
        7.0811    0.2551   -0.1086
        7.1361    0.2551   -0.5722
        7.2181    0.2551   -1.3950
        7.2542    0.2551   -1.7283
        7.2411    0.2626   -1.7865
        7.2107    0.2759   -1.8190
        6.8248    0.2642   -0.1086
        6.9079    0.2642   -0.5722
        7.0421    0.2642   -1.3950
        7.1018    0.2642   -1.7283
        7.1076    0.2705   -1.7865
        7.1104    0.2819   -1.8190
        6.7469    0.2871   -0.1086
        6.8387    0.2871   -0.5722
        6.9886    0.2871   -1.3950
        7.0555    0.2871   -1.7283
        7.0670    0.2904   -1.7865
        7.0799    0.2968   -1.8190
        7.1710    0.3089   -1.8438
        6.8036    0.2642   -0.0008
        7.0661    0.2551   -0.0008
        7.5172    0.2871   -0.0008
        7.5125    0.3555   -0.0008
        7.0568    0.3692   -0.0008
        6.7989    0.3646   -0.0008
        6.7103    0.3099    0.1070
        6.7515    0.3509    0.1070
        6.8061    0.3099    0.5706
        6.8428    0.3509    0.5706
        6.9635    0.3099    1.3935
        6.9918    0.3509    1.3935
        7.0337    0.3099    1.7268
        7.0582    0.3509    1.7268
        7.0480    0.3103    1.7850
        7.0694    0.3460    1.7850
        7.0656    0.3117    1.8174
        7.0817    0.3386    1.8174
        6.8202    0.3646    0.1070
        6.9039    0.3646    0.5706
        7.0389    0.3646    1.3935
        7.0990    0.3646    1.7268
        7.1052    0.3579    1.7850
        7.1086    0.3475    1.8174
        7.0720    0.3692    0.1070
        7.1279    0.3692    0.5706
        7.2118    0.3692    1.3935
        7.2488    0.3692    1.7268
        7.2363    0.3619    1.7850
        7.2072    0.3505    1.8174
        7.5142    0.3555    0.1070
        7.5134    0.3555    0.5747
        7.5136    0.3555    1.3935
        7.5102    0.3555    1.7268
        7.5076    0.3500    1.7850
        7.4106    0.3416    1.8174
        7.6413    0.3299    1.3969
        7.6218    0.3299    1.7268
        7.6239    0.3289    1.7850
        7.4980    0.3287    1.8174
        7.6445    0.3222    1.3969
        7.6246    0.3222    1.7268
        7.6267    0.3221    1.7850
        7.5001    0.3226    1.8174
        7.5188    0.2871    0.1070
        7.5174    0.2871    0.5747
        7.5167    0.2871    1.3935
        7.5129    0.2871    1.7268
        7.5104    0.2904    1.7850
        7.4127    0.2968    1.8174
        7.0811    0.2551    0.1070
        7.1361    0.2551    0.5706
        7.2181    0.2551    1.3935
        7.2542    0.2551    1.7268
        7.2411    0.2626    1.7850
        7.2107    0.2759    1.8174
        6.8248    0.2642    0.1070
        6.9079    0.2642    0.5706
        7.0421    0.2642    1.3935
        7.1018    0.2642    1.7268
        7.1076    0.2705    1.7850
        7.1104    0.2819    1.8174
        6.7469    0.2871    0.1070
        6.8387    0.2871    0.5706
        6.9886    0.2871    1.3935
        7.0555    0.2871    1.7268
        7.0670    0.2904    1.7850
        7.0799    0.2968    1.8174
        7.1710    0.3089    1.8423
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #86 tail-cone
    F = [ ...
        6     2     1     5
        7     3     2     6
        8     4     3     7
        39    40     4     8
        10     6     5     9
        11     7     6    10
        12     8     7    11
        38    39     8    12
        14    10     9    13
        15    11    10    14
        16    12    11    15
        37    38    12    16
        18    14    13    17
        19    15    14    18
        20    16    15    19
        36    37    16    20
        22    18    17    21
        23    19    18    22
        24    20    19    23
        35    36    20    24
        27    22    21    25
        29    23    22    27
        31    24    23    29
        34    35    24    31
        28    27    25    26
        30    29    27    28
        32    31    29    30
        33    34    31    32
        41     1     2    42
        42     2     3    43
        43     3     4    44
        44     4    40    70
        45    41    42    46
        46    42    43    47
        47    43    44    48
        48    44    70    69
        49    45    46    50
        50    46    47    51
        51    47    48    52
        52    48    69    68
        53    49    50    54
        54    50    51    55
        55    51    52    56
        56    52    68    67
        57    53    54    58
        58    54    55    59
        59    55    56    60
        60    56    67    66
        61    57    58    62
        62    58    59    63
        63    59    60    64
        64    60    66    65
        26    61    62    28
        28    62    63    30
        30    63    64    32
        32    64    65    33
    ];
    V = [ ...
        7.4794    0.2189   -0.0005
        7.4912    0.1898   -0.0005
        7.4909    0.1070   -0.0005
        7.4840    0.0800   -0.0005
        7.4794    0.2265    0.0086
        7.4912    0.1959    0.0161
        7.4909    0.1217    0.0259
        7.4840    0.0964    0.0330
        7.4794    0.2429    0.0105
        7.4912    0.2119    0.0199
        7.4909    0.1536    0.0317
        7.4840    0.1320    0.0404
        7.4794    0.3060    0.0105
        7.4912    0.2856    0.0207
        7.4909    0.2762    0.0317
        7.4840    0.2688    0.0404
        7.4794    0.3628    0.0105
        7.4912    0.3788    0.0207
        7.4909    0.3866    0.0317
        7.4840    0.3920    0.0404
        7.4794    0.4070    0.0105
        7.4912    0.4513    0.0207
        7.4909    0.4724    0.0317
        7.4840    0.4878    0.0404
        7.4794    0.4260    0.0086
        7.4794    0.4323   -0.0005
        7.4912    0.4823    0.0171
        7.4912    0.4927   -0.0005
        7.4909    0.5092    0.0259
        7.4909    0.5214   -0.0005
        7.4840    0.5288    0.0330
        7.4840    0.5425   -0.0005
        7.4660    0.5472   -0.0005
        7.4660    0.5332    0.0375
        7.4660    0.4913    0.0459
        7.4660    0.3936    0.0459
        7.4660    0.2680    0.0459
        7.4660    0.1283    0.0459
        7.4660    0.0920    0.0375
        7.4660    0.0753   -0.0005
        7.4794    0.2265   -0.0096
        7.4912    0.1959   -0.0172
        7.4909    0.1217   -0.0270
        7.4840    0.0964   -0.0340
        7.4794    0.2429   -0.0116
        7.4912    0.2119   -0.0210
        7.4909    0.1536   -0.0328
        7.4840    0.1320   -0.0415
        7.4794    0.3060   -0.0116
        7.4912    0.2856   -0.0217
        7.4909    0.2762   -0.0328
        7.4840    0.2688   -0.0415
        7.4794    0.3628   -0.0116
        7.4912    0.3788   -0.0217
        7.4909    0.3866   -0.0328
        7.4840    0.3920   -0.0415
        7.4794    0.4070   -0.0116
        7.4912    0.4513   -0.0217
        7.4909    0.4724   -0.0328
        7.4840    0.4878   -0.0415
        7.4794    0.4260   -0.0096
        7.4912    0.4823   -0.0182
        7.4909    0.5092   -0.0270
        7.4840    0.5288   -0.0340
        7.4660    0.5332   -0.0385
        7.4660    0.4913   -0.0470
        7.4660    0.3936   -0.0470
        7.4660    0.2680   -0.0470
        7.4660    0.1283   -0.0470
        7.4660    0.0920   -0.0385
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #87 air-filter-intake
    F = [ ...
        4     2     3     5   NaN   NaN   NaN
        5     3    37    36   NaN   NaN   NaN
        6     4     5     7   NaN   NaN   NaN
        7     5    36    35   NaN   NaN   NaN
        8     6     7     9   NaN   NaN   NaN
        9     7    35    34   NaN   NaN   NaN
        10     8     9    12   NaN   NaN   NaN
        12     9    34    33   NaN   NaN   NaN
        11    10    12    13   NaN   NaN   NaN
        13    12    33    32   NaN   NaN   NaN
        18    15    14    17   NaN   NaN   NaN
        19    16    15    18   NaN   NaN   NaN
        36    37    16    19   NaN   NaN   NaN
        21    18    17    20   NaN   NaN   NaN
        22    19    18    21   NaN   NaN   NaN
        35    36    19    22   NaN   NaN   NaN
        24    21    20    23   NaN   NaN   NaN
        25    22    21    24   NaN   NaN   NaN
        34    35    22    25   NaN   NaN   NaN
        28    24    23    26   NaN   NaN   NaN
        30    25    24    28   NaN   NaN   NaN
        33    34    25    30   NaN   NaN   NaN
        29    28    26    27   NaN   NaN   NaN
        31    30    28    29   NaN   NaN   NaN
        32    33    30    31   NaN   NaN   NaN
        39     3     2    38   NaN   NaN   NaN
        67    37     3    39   NaN   NaN   NaN
        41    39    38    40   NaN   NaN   NaN
        66    67    39    41   NaN   NaN   NaN
        43    41    40    42   NaN   NaN   NaN
        65    66    41    43   NaN   NaN   NaN
        46    43    42    44   NaN   NaN   NaN
        64    65    43    46   NaN   NaN   NaN
        47    46    44    45   NaN   NaN   NaN
        63    64    46    47   NaN   NaN   NaN
        48    14    15    49   NaN   NaN   NaN
        49    15    16    50   NaN   NaN   NaN
        50    16    37    67   NaN   NaN   NaN
        51    48    49    52   NaN   NaN   NaN
        52    49    50    53   NaN   NaN   NaN
        53    50    67    66   NaN   NaN   NaN
        54    51    52    55   NaN   NaN   NaN
        55    52    53    56   NaN   NaN   NaN
        56    53    66    65   NaN   NaN   NaN
        57    54    55    59   NaN   NaN   NaN
        59    55    56    61   NaN   NaN   NaN
        61    56    65    64   NaN   NaN   NaN
        58    57    59    60   NaN   NaN   NaN
        60    59    61    62   NaN   NaN   NaN
        62    61    64    63   NaN   NaN   NaN
        45    44    42    40    38     2     1
        1     2     4     6     8    10    11
    ];
    V = [ ...
        0.5810   -0.3195   -0.0015
        0.5810   -0.4217   -0.0015
        0.5891   -0.4474   -0.0015
        0.5810   -0.4200    0.0416
        0.5891   -0.4454    0.0500
        0.5810   -0.4158    0.0761
        0.5891   -0.4401    0.0913
        0.5810   -0.4023    0.0993
        0.5891   -0.4234    0.1191
        0.5810   -0.3752    0.1121
        0.5810   -0.3195    0.1201
        0.5891   -0.3898    0.1345
        0.5891   -0.3206    0.1441
        1.0266   -0.4833   -0.0015
        0.8408   -0.4818   -0.0015
        0.6896   -0.4807   -0.0004
        1.0266   -0.4807    0.0630
        0.8408   -0.4792    0.0630
        0.6896   -0.4781    0.0599
        1.0266   -0.4745    0.1151
        0.8408   -0.4731    0.1151
        0.6896   -0.4719    0.1085
        1.0266   -0.4549    0.1502
        0.8408   -0.4534    0.1502
        0.6896   -0.4523    0.1413
        1.0266   -0.4155    0.1695
        1.0266   -0.3343    0.1817
        0.8408   -0.4140    0.1695
        0.8408   -0.3328    0.1817
        0.6896   -0.4129    0.1594
        0.6896   -0.3317    0.1707
        0.6208   -0.3319    0.1602
        0.6208   -0.4037    0.1496
        0.6208   -0.4385    0.1328
        0.6208   -0.4559    0.1022
        0.6208   -0.4614    0.0568
        0.6208   -0.4637    0.0006
        0.5810   -0.4200   -0.0446
        0.5891   -0.4454   -0.0529
        0.5810   -0.4158   -0.0790
        0.5891   -0.4401   -0.0942
        0.5810   -0.4023   -0.1022
        0.5891   -0.4234   -0.1221
        0.5810   -0.3752   -0.1151
        0.5810   -0.3195   -0.1231
        0.5891   -0.3898   -0.1375
        0.5891   -0.3206   -0.1471
        1.0266   -0.4807   -0.0660
        0.8408   -0.4792   -0.0660
        0.6896   -0.4781   -0.0608
        1.0266   -0.4745   -0.1180
        0.8408   -0.4731   -0.1180
        0.6896   -0.4719   -0.1094
        1.0266   -0.4549   -0.1532
        0.8408   -0.4534   -0.1532
        0.6896   -0.4523   -0.1422
        1.0266   -0.4155   -0.1725
        1.0266   -0.3343   -0.1846
        0.8408   -0.4140   -0.1725
        0.8408   -0.3328   -0.1846
        0.6896   -0.4129   -0.1603
        0.6896   -0.3317   -0.1716
        0.6208   -0.3319   -0.1589
        0.6208   -0.4037   -0.1484
        0.6208   -0.4385   -0.1315
        0.6208   -0.4559   -0.1009
        0.6208   -0.4614   -0.0556
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #88 fuselage
    F = [ ...
    105   112   350   104   NaN   NaN   NaN
    279   272   271   353   NaN   NaN   NaN
    111     6   351   NaN   NaN   NaN   NaN
    351   352    35   NaN   NaN   NaN   NaN
    278   353   355   NaN   NaN   NaN   NaN
    355   356   219   NaN   NaN   NaN   NaN
    355   219   192   NaN   NaN   NaN   NaN
    355   192   278   NaN   NaN   NaN   NaN
    278   279   353   NaN   NaN   NaN   NaN
        40   352   351   NaN   NaN   NaN   NaN
    350   111   351   NaN   NaN   NaN   NaN
    228   348   368   NaN   NaN   NaN   NaN
    348   228   188   NaN   NaN   NaN   NaN
    349   336   220   368   348   347   NaN
    344   345   241   240   NaN   NaN   NaN
    241   236   341   345   NaN   NaN   NaN
    343   344   240   239   NaN   NaN   NaN
    342   343   239   238   NaN   NaN   NaN
    233   238   342   337   NaN   NaN   NaN
    340   341   236   231   NaN   NaN   NaN
    230   231   340   339   NaN   NaN   NaN
    230   229   338   339   NaN   NaN   NaN
    228   229   338   NaN   NaN   NaN   NaN
    233   228   337   NaN   NaN   NaN   NaN
    333   332   331   171   NaN   NaN   NaN
    170   171   331   330   NaN   NaN   NaN
    169   170   330   329   NaN   NaN   NaN
    168   169   329   328   NaN   NaN   NaN
    167   168   328   327   NaN   NaN   NaN
    166   167   327   326   NaN   NaN   NaN
        2   166   326   203   NaN   NaN   NaN
    332   325   324   331   NaN   NaN   NaN
    330   331   324   323   NaN   NaN   NaN
    329   330   323   322   NaN   NaN   NaN
    328   329   322   321   NaN   NaN   NaN
    327   328   321   320   NaN   NaN   NaN
    326   327   320   319   NaN   NaN   NaN
    203   326   319   202   NaN   NaN   NaN
    325   318   317   324   NaN   NaN   NaN
    323   324   317   316   NaN   NaN   NaN
    322   323   316   315   NaN   NaN   NaN
    321   322   315   314   NaN   NaN   NaN
    320   321   314   313   NaN   NaN   NaN
    319   320   313   312   NaN   NaN   NaN
    202   319   312   201   NaN   NaN   NaN
    318   311   310   317   NaN   NaN   NaN
    316   317   310   309   NaN   NaN   NaN
    315   316   309   308   NaN   NaN   NaN
    314   315   308   307   NaN   NaN   NaN
    313   314   307   306   NaN   NaN   NaN
    312   313   306   305   NaN   NaN   NaN
    201   312   305   200   NaN   NaN   NaN
    311   304   303   310   NaN   NaN   NaN
    309   310   303   302   NaN   NaN   NaN
    308   309   302   301   NaN   NaN   NaN
    307   308   301   300   NaN   NaN   NaN
    306   307   300   299   NaN   NaN   NaN
    305   306   299   298   NaN   NaN   NaN
    200   305   298   199   NaN   NaN   NaN
    303   304   297   296   NaN   NaN   NaN
    302   303   296   295   NaN   NaN   NaN
    301   302   295   294   NaN   NaN   NaN
    300   301   294   293   NaN   NaN   NaN
    299   300   293   292   NaN   NaN   NaN
    298   299   292   NaN   NaN   NaN   NaN
    199   298   292   334   191   NaN   NaN
    296   297   291   290   NaN   NaN   NaN
    295   296   290   289   NaN   NaN   NaN
    294   295   289   288   NaN   NaN   NaN
    293   294   288   287   NaN   NaN   NaN
    292   293   287   286   NaN   NaN   NaN
    292   286   285   NaN   NaN   NaN   NaN
    290   291   284   283   NaN   NaN   NaN
    289   290   283   282   NaN   NaN   NaN
    288   289   282   281   NaN   NaN   NaN
    287   288   281   280   NaN   NaN   NaN
    285   286   279   278   NaN   NaN   NaN
    283   284   277   276   NaN   NaN   NaN
    282   283   276   275   NaN   NaN   NaN
    281   282   275   274   NaN   NaN   NaN
    280   281   274   273   NaN   NaN   NaN
    276   277   270   269   NaN   NaN   NaN
    275   276   269   268   NaN   NaN   NaN
    274   275   268   267   NaN   NaN   NaN
    273   274   267   266   NaN   NaN   NaN
    271   272   265   264   NaN   NaN   NaN
    354   271   264   198   NaN   NaN   NaN
    269   270   263   262   NaN   NaN   NaN
    268   269   262   261   NaN   NaN   NaN
    267   268   261   260   NaN   NaN   NaN
    266   267   260   259   NaN   NaN   NaN
    264   265   258   257   NaN   NaN   NaN
    198   264   257   197   NaN   NaN   NaN
    262   263    96    94   NaN   NaN   NaN
    261   262    94    92   NaN   NaN   NaN
    260   261    92    90   NaN   NaN   NaN
    259   260    90    88   NaN   NaN   NaN
    257   258    86    84   NaN   NaN   NaN
    197   257    84     7   NaN   NaN   NaN
        81   255   256    82   NaN   NaN   NaN
        80   254   255    81   NaN   NaN   NaN
        79   253   254    80   NaN   NaN   NaN
        78   252   253    79   NaN   NaN   NaN
    203   252    78     2   NaN   NaN   NaN
    255   250   251   256   NaN   NaN   NaN
    254   249   250   255   NaN   NaN   NaN
    253   248   249   254   NaN   NaN   NaN
    252   247   248   253   NaN   NaN   NaN
    202   247   252   203   NaN   NaN   NaN
    250   245   246   251   NaN   NaN   NaN
    249   244   245   250   NaN   NaN   NaN
    248   243   244   249   NaN   NaN   NaN
    247   242   243   248   NaN   NaN   NaN
    201   242   247   202   NaN   NaN   NaN
    245   240   241   246   NaN   NaN   NaN
    244   239   240   245   NaN   NaN   NaN
    243   238   239   244   NaN   NaN   NaN
    242   237   238   243   NaN   NaN   NaN
    200   237   242   201   NaN   NaN   NaN
    240   235   236   241   NaN   NaN   NaN
    239   234   235   240   NaN   NaN   NaN
    238   233   234   239   NaN   NaN   NaN
    237   232   233   238   NaN   NaN   NaN
    199   232   237   200   NaN   NaN   NaN
    235   230   231   236   NaN   NaN   NaN
    234   229   230   235   NaN   NaN   NaN
    228   229   234   233   NaN   NaN   NaN
    232   227   188   228   233   NaN   NaN
    335   227   232   199   191   NaN   NaN
    230   225   226   231   NaN   NaN   NaN
    229   224   225   230   NaN   NaN   NaN
    228   368   369   224   229   NaN   NaN
    225   222   223   226   NaN   NaN   NaN
    224   221   222   225   NaN   NaN   NaN
    369   368   220   357   221   224   NaN
    222   217   218   223   NaN   NaN   NaN
    221   216   217   222   NaN   NaN   NaN
    357   220   215   359   216   221   NaN
    356   214   215   220   336   346   219
    217   212   213   218   NaN   NaN   NaN
    216   358   211   212   217   NaN   NaN
    359   215   210   360   211   358   216
    214   209   210   215   NaN   NaN   NaN
    198   209   214   354   NaN   NaN   NaN
    212   207   208   213   NaN   NaN   NaN
    211   206   207   212   NaN   NaN   NaN
    360   210   205   361   206   211   NaN
    209   204   205   210   NaN   NaN   NaN
    197   204   209   198   NaN   NaN   NaN
    207    27    29   208   NaN   NaN   NaN
    206    25    27   207   NaN   NaN   NaN
    361   205    23   362    25   206   NaN
    204    21    23   205   NaN   NaN   NaN
        7    21   204   197   NaN   NaN   NaN
        2   203   196   NaN   NaN   NaN   NaN
    196   203   202   195   NaN   NaN   NaN
    195   202   201   NaN   NaN   NaN   NaN
    194   196     2   NaN   NaN   NaN   NaN
    193   195   196   194   NaN   NaN   NaN
    201   195   193   NaN   NaN   NaN   NaN
        2   194   189   NaN   NaN   NaN   NaN
    189   194   193   190   NaN   NaN   NaN
    190   193   201   NaN   NaN   NaN   NaN
    367   186    49   NaN   NaN   NaN   NaN
    186     1    49   NaN   NaN   NaN   NaN
    185   186   367    41   174   187   NaN
        61    62   183   182   NaN   NaN   NaN
    183   179    57    62   NaN   NaN   NaN
        60    61   182   181   NaN   NaN   NaN
        59    60   181   180   NaN   NaN   NaN
    175   180    59    54   NaN   NaN   NaN
        52    57   179   178   NaN   NaN   NaN
    177   178    52    51   NaN   NaN   NaN
    177   176    50    51   NaN   NaN   NaN
        49   176    50   NaN   NaN   NaN   NaN
    175    49    54   NaN   NaN   NaN   NaN
    171   164   165   333   NaN   NaN   NaN
    163   164   171   170   NaN   NaN   NaN
    162   163   170   169   NaN   NaN   NaN
    161   162   169   168   NaN   NaN   NaN
    160   161   168   167   NaN   NaN   NaN
    159   160   167   166   NaN   NaN   NaN
        19   159   166     2   NaN   NaN   NaN
    164   157   158   165   NaN   NaN   NaN
    156   157   164   163   NaN   NaN   NaN
    155   156   163   162   NaN   NaN   NaN
    154   155   162   161   NaN   NaN   NaN
    153   154   161   160   NaN   NaN   NaN
    152   153   160   159   NaN   NaN   NaN
        18   152   159    19   NaN   NaN   NaN
    157   150   151   158   NaN   NaN   NaN
    149   150   157   156   NaN   NaN   NaN
    148   149   156   155   NaN   NaN   NaN
    147   148   155   154   NaN   NaN   NaN
    146   147   154   153   NaN   NaN   NaN
    145   146   153   152   NaN   NaN   NaN
        17   145   152    18   NaN   NaN   NaN
    150   143   144   151   NaN   NaN   NaN
    142   143   150   149   NaN   NaN   NaN
    141   142   149   148   NaN   NaN   NaN
    140   141   148   147   NaN   NaN   NaN
    139   140   147   146   NaN   NaN   NaN
    138   139   146   145   NaN   NaN   NaN
        16   138   145    17   NaN   NaN   NaN
    143   136   137   144   NaN   NaN   NaN
    135   136   143   142   NaN   NaN   NaN
    134   135   142   141   NaN   NaN   NaN
    133   134   141   140   NaN   NaN   NaN
    132   133   140   139   NaN   NaN   NaN
    131   132   139   138   NaN   NaN   NaN
        15   131   138    16   NaN   NaN   NaN
    129   130   137   136   NaN   NaN   NaN
    128   129   136   135   NaN   NaN   NaN
    127   128   135   134   NaN   NaN   NaN
    126   127   134   133   NaN   NaN   NaN
    125   126   133   132   NaN   NaN   NaN
    125   132   131   NaN   NaN   NaN   NaN
    172   125   131    15     5   NaN   NaN
    123   124   130   129   NaN   NaN   NaN
    122   123   129   128   NaN   NaN   NaN
    121   122   128   127   NaN   NaN   NaN
    120   121   127   126   NaN   NaN   NaN
    119   120   126   125   NaN   NaN   NaN
    125   118   119   NaN   NaN   NaN   NaN
    116   117   124   123   NaN   NaN   NaN
    115   116   123   122   NaN   NaN   NaN
    114   115   122   121   NaN   NaN   NaN
    113   114   121   120   NaN   NaN   NaN
    111   112   119   118   NaN   NaN   NaN
    109   110   117   116   NaN   NaN   NaN
    108   109   116   115   NaN   NaN   NaN
    107   108   115   114   NaN   NaN   NaN
    106   107   114   113   NaN   NaN   NaN
    102   103   110   109   NaN   NaN   NaN
    101   102   109   108   NaN   NaN   NaN
    100   101   108   107   NaN   NaN   NaN
        99   100   107   106   NaN   NaN   NaN
        97    98   105   104   NaN   NaN   NaN
        13    97   104    14   NaN   NaN   NaN
        93    95   103   102   NaN   NaN   NaN
        91    93   102   101   NaN   NaN   NaN
        89    91   101   100   NaN   NaN   NaN
        87    89   100    99   NaN   NaN   NaN
        83    85    98    97   NaN   NaN   NaN
        12    83    97    13   NaN   NaN   NaN
        94    96    95    93   NaN   NaN   NaN
        92    94    93    91   NaN   NaN   NaN
        90    92    91    89   NaN   NaN   NaN
        88    90    89    87   NaN   NaN   NaN
        84    86    85    83   NaN   NaN   NaN
        7    84    83    12   NaN   NaN   NaN
        82    77    76    81   NaN   NaN   NaN
        81    76    75    80   NaN   NaN   NaN
        80    75    74    79   NaN   NaN   NaN
        79    74    73    78   NaN   NaN   NaN
        2    78    73    19   NaN   NaN   NaN
        77    72    71    76   NaN   NaN   NaN
        76    71    70    75   NaN   NaN   NaN
        75    70    69    74   NaN   NaN   NaN
        74    69    68    73   NaN   NaN   NaN
        19    73    68    18   NaN   NaN   NaN
        72    67    66    71   NaN   NaN   NaN
        71    66    65    70   NaN   NaN   NaN
        70    65    64    69   NaN   NaN   NaN
        69    64    63    68   NaN   NaN   NaN
        18    68    63    17   NaN   NaN   NaN
        67    62    61    66   NaN   NaN   NaN
        66    61    60    65   NaN   NaN   NaN
        65    60    59    64   NaN   NaN   NaN
        64    59    58    63   NaN   NaN   NaN
        17    63    58    16   NaN   NaN   NaN
        62    57    56    61   NaN   NaN   NaN
        61    56    55    60   NaN   NaN   NaN
        60    55    54    59   NaN   NaN   NaN
        59    54    53    58   NaN   NaN   NaN
        16    58    53    15   NaN   NaN   NaN
        57    52    51    56   NaN   NaN   NaN
        56    51    50    55   NaN   NaN   NaN
        55    50    49    54   NaN   NaN   NaN
        54    49     1    48    53   NaN   NaN
        5    15    53    48   173   NaN   NaN
        52    47    46    51   NaN   NaN   NaN
        51    46    45    50   NaN   NaN   NaN
        50    45   370   367    49   NaN   NaN
        47    44    43    46   NaN   NaN   NaN
        46    43    42    45   NaN   NaN   NaN
    370    45    42   366    41   367   NaN
        44    39    38    43   NaN   NaN   NaN
        43    38    37    42   NaN   NaN   NaN
    366    42    37   365    36    41   NaN
    352    40   184   174    41    36    35
        39    34    33    38   NaN   NaN   NaN
        38    33    32    37   NaN   NaN   NaN
    365    37    32   364    31    36   NaN
        36    31    30    35   NaN   NaN   NaN
        14    35    30    13   NaN   NaN   NaN
        34    28    26    33   NaN   NaN   NaN
        33    26    24    32   NaN   NaN   NaN
    364    32    24   363    22    31   NaN
        31    22    20    30   NaN   NaN   NaN
        13    30    20    12   NaN   NaN   NaN
        28    29    27    26   NaN   NaN   NaN
        26    27    25    24   NaN   NaN   NaN
    363    24    25   362    23    22   NaN
        22    23    21    20   NaN   NaN   NaN
        12    20    21     7   NaN   NaN   NaN
        11    19     2   NaN   NaN   NaN   NaN
        10    18    19    11   NaN   NaN   NaN
        17    18    10   NaN   NaN   NaN   NaN
        2    11     9   NaN   NaN   NaN   NaN
        9    11    10     8   NaN   NaN   NaN
        8    10    17   NaN   NaN   NaN   NaN
        3     9     2   NaN   NaN   NaN   NaN
        4     8     9     3   NaN   NaN   NaN
        17     8     4   NaN   NaN   NaN   NaN
    355   214   356   NaN   NaN   NaN   NaN
    351    35    14   NaN   NaN   NaN   NaN
    355   354   214   NaN   NaN   NaN   NaN
        40   351     6   NaN   NaN   NaN   NaN
    355   353   271   354   NaN   NaN   NaN
    350   351    14   104   NaN   NaN   NaN
    112   111   350   NaN   NaN   NaN   NaN
    ];
    V = [ ...
        3.6070    0.2436    0.5862
        2.8206   -0.6108   -0.0000
        2.8206   -0.6152    0.3575
        2.8206   -0.5753    0.4973
        2.8202    0.2435    0.5984
        2.8235    0.5378    0.5498
        2.8206    0.7249   -0.0046
        2.8206   -0.5752    0.4972
        2.8206   -0.6151    0.3574
        2.8206   -0.5751    0.4971
        2.8206   -0.6150    0.3574
        2.8206    0.7254    0.2420
        2.8206    0.7128    0.4161
        2.8232    0.6680    0.5052
        2.8206   -0.0822    0.5984
        2.8206   -0.3843    0.5761
        2.8206   -0.4975    0.5518
        2.8206   -0.5750    0.4970
        2.8206   -0.6149    0.3573
        3.1499    0.7074    0.2394
        3.1499    0.7122   -0.0001
        3.8523    0.6586    0.2333
        3.8524    0.6570   -0.0001
        6.5952    0.4599    0.0793
        6.5952    0.4583   -0.0000
        7.0315    0.4655    0.0579
        7.0316    0.4641   -0.0000
        7.4651    0.5488    0.0167
        7.4651    0.5473   -0.0012
        3.1499    0.6951    0.4136
        3.8523    0.6476    0.4031
        6.5952    0.4550    0.1386
        7.0315    0.4612    0.1019
        7.4651    0.5443    0.0312
        3.1499    0.6582    0.5027
        3.8523    0.6146    0.4900
        6.5952    0.4404    0.1690
        7.0315    0.4485    0.1245
        7.4651    0.5311    0.0387
        3.1304    0.5247    0.5465
        3.8496    0.5155    0.5455
        6.5952    0.4080    0.1842
        7.0315    0.4202    0.1358
        7.4651    0.5015    0.0424
        6.5952    0.3325    0.1987
        7.0315    0.3544    0.1465
        7.4651    0.4330    0.0459
        3.1599    0.2443    0.5915
        3.8524    0.2417    0.5808
        6.5952    0.2643    0.2007
        7.0315    0.2814    0.1450
        7.4651    0.3710    0.0464
        3.1499   -0.0816    0.5959
        3.8523   -0.0474    0.5808
        6.5952    0.1475    0.2007
        7.0315    0.1932    0.1480
        7.4651    0.2648    0.0464
        3.1499   -0.3767    0.5736
        3.8523   -0.3115    0.5591
        6.5952    0.0306    0.1931
        7.0315    0.0913    0.1424
        7.4651    0.1586    0.0446
        3.1499   -0.4873    0.5493
        3.8523   -0.4105    0.5354
        6.5952   -0.0132    0.1849
        7.0315    0.0532    0.1363
        7.4651    0.1187    0.0426
        3.1499   -0.5631    0.4946
        3.8523   -0.4783    0.4821
        6.5952   -0.0432    0.1662
        7.0315    0.0270    0.1224
        7.4651    0.0914    0.0380
        3.1499   -0.6021    0.3549
        3.8523   -0.5132    0.3459
        6.5952   -0.0586    0.1186
        7.0315    0.0136    0.0871
        7.4651    0.0774    0.0263
        3.1499   -0.5980   -0.0000
        3.8524   -0.5095   -0.0000
        6.5952   -0.0570   -0.0000
        7.0316    0.0150   -0.0000
        7.4651    0.0789   -0.0000
        2.4613    0.7145    0.2408
        2.4392    0.7239    0.0002
        2.2922    0.6700    0.2448
        2.2696    0.6660   -0.0000
        1.7681    0.3603    0.2249
        1.7521    0.3699   -0.0000
        1.0379    0.2660    0.1880
        1.0462    0.2870   -0.0000
        0.6242    0.2026    0.1678
        0.6242    0.2251   -0.0000
        0.4872    0.1602    0.1544
        0.4872    0.1763   -0.0000
        0.4557    0.1101    0.1291
        0.4557    0.1089   -0.0000
        2.4920    0.6963    0.4160
        2.3330    0.6301    0.4081
        1.7882    0.3500    0.3898
        1.0458    0.2519    0.3125
        0.6242    0.1711    0.2517
        0.4872    0.1433    0.2328
        0.4557    0.1065    0.2212
        2.4973    0.6611    0.5009
        2.3669    0.5973    0.4766
        1.8115    0.3283    0.4741
        1.0479    0.2237    0.3946
        0.6242    0.1506    0.3193
        0.4872    0.1263    0.3049
        0.4557    0.0959    0.2684
        2.4867    0.5499    0.5496
        2.4104    0.5580    0.5384
        1.9013    0.2989    0.5547
        1.0482    0.1792    0.4767
        0.6242    0.1152    0.4076
        0.4872    0.0981    0.3731
        0.4557    0.0822    0.3293
        2.3850    0.4010    0.5751
        2.2117    0.2660    0.5956
        1.9881    0.2843    0.5826
        1.0462    0.0919    0.5102
        0.6242    0.0556    0.4482
        0.4872    0.0487    0.4224
        0.4557    0.0375    0.3824
        2.2851    0.2515    0.5926
        1.7521    0.1242    0.5912
        1.0462   -0.0138    0.5154
        0.6242   -0.0377    0.4645
        0.4872   -0.0226    0.4304
        0.4557   -0.0188    0.4027
        2.5364   -0.0907    0.5952
        2.2937   -0.1061    0.5852
        1.7521   -0.1329    0.5841
        1.0462   -0.1473    0.5061
        0.6242   -0.1171    0.4483
        0.4872   -0.0920    0.4240
        0.4557   -0.0859    0.3900
        2.5364   -0.3832    0.5760
        2.2937   -0.4072    0.5708
        1.7521   -0.4377    0.5620
        1.0462   -0.2870    0.4822
        0.6242   -0.1999    0.3962
        0.4872   -0.1646    0.3784
        0.4557   -0.1480    0.3453
        2.5364   -0.4969    0.5517
        2.2937   -0.4985    0.5412
        1.7521   -0.5144    0.5335
        1.0462   -0.3821    0.4411
        0.6242   -0.2615    0.3333
        0.4872   -0.2221    0.3138
        0.4557   -0.1891    0.2606
        2.5364   -0.5748    0.4970
        2.2937   -0.5736    0.4876
        1.7521   -0.5749    0.4656
        1.0462   -0.4416    0.3735
        0.6242   -0.3068    0.2445
        0.4872   -0.2687    0.2219
        0.4557   -0.2094    0.2071
        2.5364   -0.6149    0.3572
        2.2975   -0.6121    0.3467
        1.7521   -0.5927    0.3347
        1.0462   -0.4918    0.2343
        0.6242   -0.3527    0.1409
        0.4872   -0.2948    0.1119
        0.4557   -0.2380    0.1039
        2.5364   -0.6107   -0.0000
        2.2523   -0.6080   -0.0000
        1.7521   -0.5896   -0.0000
        1.0462   -0.5123   -0.0000
        0.6242   -0.3703   -0.0000
        0.4872   -0.3058   -0.0000
        2.5515    0.2441    0.5954
        3.1042    0.2444    0.5919
        3.3289    0.5176    0.5466
        3.8524   -0.0473    0.5807
        6.5953    0.2644    0.2006
        7.0316    0.2815    0.1449
        7.4652    0.3711    0.0463
        7.4652    0.2649    0.0463
        3.8524   -0.3114    0.5590
        6.5953    0.0307    0.1930
        7.0316    0.0914    0.1423
        7.4652    0.1587    0.0445
        3.1770    0.5244    0.5470
        3.5854    0.4645    0.5543
        3.7463    0.4033    0.5605
        3.4606    0.4956    0.5491
        3.6070    0.2436   -0.5863
        2.8206   -0.6152   -0.3576
        2.8206   -0.5753   -0.4974
        2.8202    0.2435   -0.5985
        2.8235    0.5378   -0.5499
        2.8206   -0.5752   -0.4973
        2.8206   -0.6151   -0.3575
        2.8206   -0.5751   -0.4972
        2.8206   -0.6150   -0.3574
        2.8206    0.7254   -0.2420
        2.8206    0.7128   -0.4162
        2.8206   -0.0822   -0.5985
        2.8206   -0.3843   -0.5762
        2.8206   -0.4975   -0.5519
        2.8206   -0.5750   -0.4971
        2.8206   -0.6149   -0.3573
        3.1499    0.7074   -0.2395
        3.8523    0.6586   -0.2334
        6.5952    0.4599   -0.0793
        7.0315    0.4655   -0.0580
        7.4651    0.5488   -0.0168
        3.1499    0.6951   -0.4137
        3.8523    0.6476   -0.4032
        6.5952    0.4550   -0.1387
        7.0315    0.4612   -0.1020
        7.4651    0.5443   -0.0313
        3.1499    0.6582   -0.5028
        3.8523    0.6146   -0.4901
        6.5952    0.4404   -0.1691
        7.0315    0.4485   -0.1246
        7.4651    0.5311   -0.0388
        3.1411    0.5247   -0.5471
        3.8496    0.5155   -0.5456
        6.5952    0.4080   -0.1842
        7.0315    0.4202   -0.1358
        7.4651    0.5015   -0.0425
        6.5952    0.3325   -0.1987
        7.0315    0.3544   -0.1466
        7.4651    0.4330   -0.0460
        3.1599    0.2487   -0.5948
        3.8524    0.2417   -0.5808
        6.5952    0.2643   -0.2008
        7.0315    0.2814   -0.1451
        7.4651    0.3710   -0.0465
        3.1499   -0.0816   -0.5959
        3.8523   -0.0474   -0.5809
        6.5952    0.1475   -0.2008
        7.0315    0.1932   -0.1481
        7.4651    0.2648   -0.0465
        3.1499   -0.3767   -0.5737
        3.8523   -0.3115   -0.5592
        6.5952    0.0306   -0.1932
        7.0315    0.0913   -0.1425
        7.4651    0.1586   -0.0447
        3.1499   -0.4873   -0.5494
        3.8523   -0.4105   -0.5355
        6.5952   -0.0132   -0.1849
        7.0315    0.0532   -0.1363
        7.4651    0.1187   -0.0426
        3.1499   -0.5631   -0.4947
        3.8523   -0.4783   -0.4822
        6.5952   -0.0432   -0.1663
        7.0315    0.0270   -0.1225
        7.4651    0.0914   -0.0381
        3.1499   -0.6021   -0.3550
        3.8523   -0.5132   -0.3460
        6.5952   -0.0586   -0.1187
        7.0315    0.0136   -0.0872
        7.4651    0.0774   -0.0264
        2.4613    0.7145   -0.2409
        2.2922    0.6700   -0.2448
        1.7685    0.3599   -0.2255
        1.0379    0.2660   -0.1881
        0.6242    0.2026   -0.1679
        0.4872    0.1602   -0.1545
        0.4557    0.1101   -0.1292
        2.4920    0.6963   -0.4161
        2.3330    0.6301   -0.4082
        1.7882    0.3500   -0.3899
        1.0458    0.2519   -0.3126
        0.6242    0.1711   -0.2518
        0.4872    0.1433   -0.2329
        0.4557    0.1065   -0.2213
        2.4973    0.6611   -0.5010
        2.3669    0.5973   -0.4767
        1.8130    0.3288   -0.4697
        1.0479    0.2237   -0.3947
        0.6242    0.1506   -0.3194
        0.4872    0.1263   -0.3050
        0.4557    0.0959   -0.2685
        2.4867    0.5499   -0.5497
        2.4104    0.5580   -0.5385
        1.9013    0.2989   -0.5547
        1.0482    0.1792   -0.4768
        0.6242    0.1152   -0.4076
        0.4872    0.0981   -0.3731
        0.4557    0.0822   -0.3294
        2.3850    0.4010   -0.5752
        2.2117    0.2660   -0.5957
        1.9881    0.2843   -0.5827
        1.0462    0.0919   -0.5103
        0.6242    0.0556   -0.4482
        0.4872    0.0487   -0.4225
        0.4557    0.0375   -0.3825
        2.2851    0.2515   -0.5927
        1.7521    0.1242   -0.5913
        1.0462   -0.0138   -0.5155
        0.6242   -0.0377   -0.4646
        0.4872   -0.0226   -0.4305
        0.4557   -0.0188   -0.4027
        2.5364   -0.0907   -0.5953
        2.2937   -0.1061   -0.5853
        1.7521   -0.1329   -0.5842
        1.0462   -0.1473   -0.5062
        0.6242   -0.1171   -0.4484
        0.4872   -0.0920   -0.4241
        0.4557   -0.0859   -0.3901
        2.5364   -0.3832   -0.5760
        2.2937   -0.4072   -0.5709
        1.7521   -0.4377   -0.5621
        1.0462   -0.2870   -0.4823
        0.6242   -0.1999   -0.3962
        0.4872   -0.1646   -0.3785
        0.4557   -0.1480   -0.3454
        2.5364   -0.4969   -0.5517
        2.2937   -0.4985   -0.5413
        1.7521   -0.5144   -0.5336
        1.0462   -0.3821   -0.4412
        0.6242   -0.2615   -0.3334
        0.4872   -0.2221   -0.3139
        0.4557   -0.1891   -0.2607
        2.5364   -0.5748   -0.4971
        2.2937   -0.5736   -0.4877
        1.7521   -0.5749   -0.4657
        1.0462   -0.4416   -0.3736
        0.6242   -0.3068   -0.2446
        0.4872   -0.2687   -0.2219
        0.4557   -0.2094   -0.2072
        2.5364   -0.6149   -0.3573
        2.2975   -0.6121   -0.3468
        1.7521   -0.5927   -0.3348
        1.0462   -0.4918   -0.2344
        0.6242   -0.3527   -0.1410
        0.4872   -0.2948   -0.1119
        0.4557   -0.2380   -0.1039
        0.4557   -0.2425   -0.0000
        2.5515    0.2441   -0.5955
        3.1042    0.2465   -0.5971
        3.3325    0.5149   -0.5438
        3.8524   -0.0473   -0.5808
        6.5953    0.2644   -0.2007
        7.0316    0.2815   -0.1450
        7.4652    0.3711   -0.0464
        7.4652    0.2649   -0.0464
        3.8524   -0.3114   -0.5591
        6.5953    0.0307   -0.1931
        7.0316    0.0914   -0.1424
        7.4652    0.1587   -0.0446
        3.1807    0.5227   -0.5463
        3.5905    0.4645   -0.5507
        3.7462    0.4008   -0.5616
        3.4597    0.4955   -0.5477
        2.4920    0.6103    0.5309
        2.8234    0.6081    0.5344
        3.1455    0.5947    0.5316
        2.4920    0.6064   -0.5325
        2.8232    0.6680   -0.5053
        2.8234    0.6037   -0.5341
        3.1455    0.5942   -0.5321
        4.5360    0.4886   -0.4552
        6.5952    0.4477   -0.1539
        4.5380    0.5711   -0.4098
        4.5380    0.5995   -0.3371
        4.5380    0.6089   -0.1949
        4.5381    0.6073   -0.0000
        4.5380    0.6089    0.1948
        4.5380    0.5995    0.3370
        4.5380    0.5711    0.4097
        4.5360    0.4886    0.4552
        3.8523    0.3766    0.5653
        3.8523    0.3766   -0.5654
        4.5380    0.3656   -0.4737
        4.5380    0.3656    0.4736
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #89 window-rect
    F = [ ...
        1     9     8     7     6
        2     3     4     5   NaN
    ];
    V = [ ...
        3.1141    0.3841   -0.5712
        3.1042    0.2433    0.5935
        3.1599    0.2435    0.5885
        3.1770    0.5229    0.5453
        3.1240    0.5232    0.5459
        3.1042    0.2450   -0.5978
        3.1599    0.2472   -0.5955
        3.1806    0.5212   -0.5460
        3.1240    0.5232   -0.5475
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #90 front-windows
    F = [ ...
        20    19    22    21
        19    18    22   NaN
        14    15    16   NaN
        15    13    14   NaN
        15    12    13   NaN
        15    17    12   NaN
        5    17    15    16
        8     7     9   NaN
        7     6     9   NaN
        9     6    11   NaN
        9    11    10   NaN
        4     2     3   NaN
        1     4     3   NaN
    ];
    V = [ ...
        2.8202    0.2420    0.5977
        2.2851    0.2500    0.5919
        2.5515    0.2426    0.5947
        2.3850    0.3995    0.5744
        3.1141    0.3841   -0.5712
        2.8202    0.2420    0.5977
        2.3850    0.3995    0.5744
        2.4867    0.5484    0.5489
        2.8235    0.5363    0.5491
        3.1240    0.5232    0.5459
        3.1042    0.2433    0.5935
        2.8202    0.2420   -0.5992
        2.3850    0.3995   -0.5759
        2.4867    0.5484   -0.5505
        2.8235    0.5363   -0.5506
        3.1240    0.5232   -0.5475
        3.1042    0.2450   -0.5978
        2.8202    0.2420   -0.5992
        2.3850    0.3995   -0.5759
        2.2851    0.2500   -0.5934
        2.2851    0.2500   -0.5934
        2.5515    0.2426   -0.5962
    ];
    cdata = offwhite;
    alpha = 0;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #91 Windshield
    F = [ ...
        22    21    20
        16    19    17
        18    16    17
        14    19    13
        19    16    13
        18    12    16
        19    15     9
        15     8     9
        15    19    14
        7    10     8
        15     7     8
        5     6    10
        7     5    10
        11     3    18
        2    11    18
        3    12    18
        1    11     2
        20     1     2
        20     4     1
        4    11     1
        21     4    20
    ];
    V = [ ...
        2.3669    0.5957   -0.4774
        2.3330    0.6286   -0.4089
        1.7882    0.3485   -0.3906
        1.9013    0.2974   -0.5555
        1.9881    0.2828    0.5818
        2.2117    0.2644    0.5949
        1.9013    0.2974    0.5539
        2.3669    0.5957    0.4759
        2.3330    0.6286    0.4074
        2.4104    0.5565    0.5377
        1.8130    0.3273   -0.4704
        1.7685    0.3584   -0.2262
        1.7681    0.3588    0.2242
        1.7882    0.3485    0.3890
        1.8115    0.3268    0.4733
        1.7521    0.3684   -0.0008
        2.2696    0.6645   -0.0008
        2.2922    0.6685   -0.2456
        2.2922    0.6685    0.2440
        2.4104    0.5565   -0.5392
        1.9881    0.2828   -0.5834
        2.2117    0.2644   -0.5965
    ];
    cdata = offwhite;
    alpha = 0;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #92 rear-windows
    F = [ ...
        5     1     2
        3     4     2
        6     4     3
        6     3     7
        3     2     1
        9     8    12
        9    11    10
        10    11    13
        14    10    13
        8     9    10
    ];
    V = [ ...
        3.4606    0.4940    0.5472
        3.7463    0.4018    0.5598
        3.3289    0.5161    0.5438
        3.6070    0.2421    0.5855
        3.5854    0.4630    0.5536
        3.1599    0.2435    0.5885
        3.1770    0.5229    0.5453
        3.4606    0.4940   -0.5472
        3.7463    0.4018   -0.5598
        3.3289    0.5161   -0.5438
        3.6070    0.2421   -0.5855
        3.5853    0.4651   -0.5513
        3.1599    0.2485   -0.5941
        3.1770    0.5229   -0.5453
    ];
    cdata = offwhite;
    alpha = 0;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #93 gear-speed
    F = [ ...
        4
        3
        2
        1
    ];
    V = [ ...
        2.1238    0.0680    0.1800
        2.1238    0.0680    0.2294
        2.1238    0.0984    0.2294
        2.1238    0.0984    0.1800
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #94 LandingPlacard
    F = [ ...
        1     4     5
        4     1     2
        6     2     1
        2     6     3
    ];
    V = [ ...
        2.1262    0.1386    0.1042
        2.1262    0.1386    0.1668
        2.1262    0.1590    0.1668
        2.1262    0.1181    0.1668
        2.1262    0.1181    0.1042
        2.1262    0.1590    0.1042
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #95 TakeOffPlacard
    F = [ ...
        4     2     1
        2     4     3
    ];
    V = [ ...
        2.1246    0.2515    0.0465
        2.1246    0.2515    0.1014
        2.1246    0.3151    0.1014
        2.1246    0.3151    0.0465
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #96 ParkBrakePlacard
    F = [ ...
        4
        3
        2
        1
    ];
    V = [ ...
        2.1265    0.0577    0.3043
        2.1265    0.0577    0.3721
        2.1265    0.0904    0.3721
        2.1265    0.0904    0.3043
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    % #97 N7764P
    F = [ ...
        4
        3
        2
        1
    ];
    V = [ ...
        2.1245    0.3602    0.0482
        2.1245    0.3602    0.1071
        2.1245    0.3844    0.1071
        2.1245    0.3844    0.0482
    ];
    cdata = bluegreen;
    alpha = 1;
    
    V = (V*D + mu)/sigma;
    V = scale*V*Z;
    
    patch(Parent = H, ...
        Faces = F, ...
        Vertices = V, ...
        FaceAlpha = alpha, ...
        FaceColor = cdata)
    
    end
    %% prop.m
    function prop(arg,~)
        p51 = plane_prop;
        cdata = [0.5330 0.5330 0.5330];
        bluegreen = [.5 .8 .9]/.9;
        sigma = 5.3;
        mu = [3.18 0 0];
        D = diag([-1 1 -1]);
        Z = [0 -1 0;  0 0 1; -1  0 0];
        scale = 2;
        d = 0;
        if all(arg.BackgroundColor == [1 1 1])
            apce = arg.Parent.Children(end);
            prp = apce.Children.Children(47);
            if length(prp.Faces) ~= 57
                prp = apce.Children.Children(1);
            end
            delete(prp)
            arg.BackgroundColor = bluegreen;
            set(arg.Parent.Children(2:3),'visible','on');
            speed = arg.Parent.Children(3);
            M = eye(4,4);
            ch = flipud(arg.Parent.Children);
            matframe = ch(2);
            matframe.Value = mat4(M);
            matframe.UserData = M; 
            ch = arg.Parent.Children(end);
            H = ch.Children;
            ch = flipud(H.Children);
            delete(ch(51));
            pv = [];
            while arg.BackgroundColor(1) == bluegreen(1)
                M = Ry(d);
                d = mod(d + get(speed,'value'),360);
                matframe.Value = mat4(M);
                matframe.UserData = M; 
                V = p51.V;
                V = (V*D + mu)/sigma;
                V = scale*V*Z*M(1:3,1:3);
                delete(pv)
                pv = patch( ...
                    Parent = H, ...
                    Faces = p51.F, ...
                    Vertices = V, ...
                    FaceAlpha = 1, ...
                    FaceColor = cdata);
                pause(1/4)
            end
        else
            set(arg.Parent.Children(2:3),'visible','off');
            arg.BackgroundColor = [1 1 1];
        end
    end

    %% takeoff.m
    function takeoff(G)
        for d = 0:5:45  
            M = Rx(d);
            Grafix(G,M)
            drawnow
        end
        for d = 0:-5:-45  
            M = Ry(d) * Rx(45);
            Grafix(G,M)
            drawnow
        end
        for t = 0:.1:3  
            M = Tx(-t) * Ty(t) * S(-t) * Rz(40*t) * Ry(-45) * Rx(45);
            Grafix(G,M)
            drawnow
        end
        for t = 3.1:.1:5 
            M = Tx(-t) * Ty(t) * S(-t) * Rz(120) * Ry(-45) * Rx(45);
            Grafix(G,M)
            drawnow
        end
    end
    %% taxi.m
    function taxi(G)
        for d = 0:3:90
            M = Rz(-d);
            Grafix(G,M)
            drawnow
        end
        pause(1)
        for t = 0:0.2:6.0
            M = Tx(t) * Rz(-90);
            Grafix(G,M)
            drawnow
        end
    end
    %% teapot.m
    function teapot(G)
        offset = G.H.Parent.Parent.UserData(26:29);
        set(offset,'visible','on')
        reso = G.H.Parent.Parent.UserData(26);
        res = max(2,round(get(reso,'value')));
        set(reso,'value',res);
        [V,F] = teapotGeometry(res);
        V = V - mean(V);
        V = V/max(max(abs(V)));

        % M = G.H.Matrix;
        % V = V*M(1:3,1:3) + M(1:3,4)';

        n = size(V,1)/8;
        off = get(G.H.Parent.Parent.UserData(28),'value')/8;
        j = 1:n;
        k = 3*n+j; V(k,1) = V(k,1) - off;
        k = 4*n+j; V(k,1) = V(k,1) + off;
        k = 5*n+j; V(k,3) = V(k,3) + off;
        k = 6*n+j; V(k,3) = V(k,3) + off/2;
        k = 7*n+j; V(k,3) = V(k,3) - off;
        
        gold = [212 175 55]/212;
        patch(Parent = G.H, ...
            Vertices = V, ...
            Faces = F, ...
            FaceColor = gold, ...
            LineWidth = 0.5, ...
            EdgeColor = 'k');
        
        % -------------------------------------------------------------------------

        function [pv, pf, pc] = teapotGeometry(res)
        % [V,F,C] = teapotGeometry(res) generates vertices, faces, and colors that
        % represent the surface of Martin Newell's Utah teapot with a specified
        % resolution. The default is res = 12.

        %   Copyright 2014-2021 The MathWorks, Inc.

            if nargin == 0
                res = 12;
            end

            verts = teapotVertices;
            quads = teapotControlPoints;
            
            % Initialize the vertex, face, and color arrays
            pv = [];
            pf = [];
            pc = [];

            % loop over the patches, creating (n-1)*(n-1) quads on the surface
            for i = 1:size(quads,3)
            points = verts(quads(:,:,i),:);    % extract the control points for the patch
            x = points(:,1);                   % separate the X, Y, and Z components
            y = points(:,2);
            z = points(:,3);

            % use evalCubicBezierPatch to generate quadrilaterals
            [f,v,c] = evalCubicBezierPatch(x,y,z,res);

            % append these quads to the list
            numv = size(pv,1);
            pv = [pv; v];      %Mok<AGROW>
            pf = [pf; f+numv]; %Mok<AGROW>
            pc = [pc; c];      %Mok<AGROW>
            end
        end

        function [f,v,c] = evalCubicBezierPatch(xc,yc,zc,n)
        % The function evalCubicBezierPatch(n,xc,yc,zc) creates a surface from
        %   a cubic bezier patch.  XC, YC, and ZC are the X, Y, and Z coordinates
        %   of the 16 control points.
        %
        % The equation for a point on the surface is:
        %   P(u,v) = [u^3 3u^2(1-u) 3u(1-u)^2 (1-u)^3]*P*[v^3 3v^2(1-v) 3v(1-v)^2 (1-v)^3]'
        %
        % where:
        %   0 <= u <= 1
        %   0 <= v <= 1
        %   P is a 4x4 containing the 16 control points
        %
            % generate n values for U and build the params for curves of constant U.

            u = (0:n-1)'/(n-1);
            A = [(u.^3) (3 * u.^2 .* (1-u)) (3 * u .* (1-u).^2) ((1-u).^3)];

            % generate n values for V and build the params for curves of constant V.
            v = (0:n-1)'/(n-1);
            B = [(v.^3) (3 * v.^2 .* (1-v)) (3 * v .* (1-v).^2) ((1-v).^3)];

            % build the tensor product of the U's & V's
            mat = kron(A,B);

            % multiply by the control points
            xd = mat*xc;
            yd = mat*yc;
            zd = mat*zc;

            % reshape the data into square matrices
            x = reshape(xd,n,n);
            y = reshape(yd,n,n);
            z = reshape(zd,n,n);

            % Set the colors indexed to the z value
            colors = z;

            % Return the geometry in the correct form for patch
            [f, v, c] = surf2patch(x,y,z,colors);
        end
    end
    %% viz.m
    function viz(uic,~)
        if nargin == 2
            uic = flipud(uic.Parent.Children);
        end
        sze = get(0,'ScreenSize');
        xm = sze(3)-40;
        ym = sze(4)-80;
        if isequal(get(uic(end),'vis'),'on')
            set(uic(3:end),'vis','off')
            set(uic(27),'vis','on', ...
                'pos',[xm-50 20 40 30], ...
                'background',.9*[1,1,1], ...
                'text','')
        else
            set(uic([2:end-7 end]),'vis','on')
            set(uic(27),'vis','on', ...
                'pos',[xm-100 ym-400 60 30], ...
                'background',[1,1,1], ...
                'text','Viz')
        end
    end
    %% lib\Rx.m
    function R = Rx(d)
        % Rx(d), Rotation by d degrees about x-axis.
        c = cosd(d);
        s = sind(d);
        R = [ 1  0  0  0  
            0  c  s  0
            0 -s  c  0
            0  0  0  1 ];
    end
    %% lib\Ry.m
    function R = Ry(d)
        % Ry(d), Rotation by d degrees about y-axis.
        c = cosd(d);
        s = sind(d);
        R = [ c  0  s  0  
            0  1  0  0
            -s  0  c  0
            0  0  0  1 ];
    end
    %% lib\Rz.m
    function R = Rz(d)
        % Rz(d), Rotation by d degrees about z-axis.
        c = cosd(d);
        s = sind(d);
        R = [ c  s  0  0 
            -s  c  0  0
            0  0  1  0
            0  0  0  1 ];
    end
    %% lib\S.m
    function S = S(t)
        % S(t), Scale by 2^(t/2).
        r = sqrt(2);
        S  = [ r^t  0   0   0
                0  r^t  0   0
                0   0  r^t  0
                0   0   0   1 ];
    end
    %% lib\Tx.m
    function T = Tx(t)
        % Tx(t), Translation by t units about x-axis.
        T = [ 1  0  0  t  
            0  1  0  0
            0  0  1  0
            0  0  0  1 ];
    end
    %% lib\Ty.m
    function T = Ty(t)
        % Ty(t), Translation by t units about y-axis.
        T = [ 1  0  0  0  
            0  1  0  t
            0  0  1  0
            0  0  0  1 ];
    end
    %% lib\Tz.m
    function T = Tz(t)
        % Tz(t), Translation by t units about z-axis.
        T = [ 1  0  0  0
            0  1  0  0
            0  0  1  t
            0  0  0  1 ];
    end
    %% lib\make_plane.m
    function make_plane
        delete("new_plane.m")
        diary("new_plane.m")

        disp("function plane(G)")
        disp("% Aero Toolbox")
        disp("% A = Aero.Animation;")
        disp("% A.createBody('pa24-250_blue.ac','Ac3d');")
        disp("% Body = A.Bodies{1};")
        disp("% Plane = Body.Geometry.FaceVertexColorData;")
        disp("% See Grafix/lib/make_plane")
        disp(" ")
        disp('format compact')
        disp('H = G.H;')
        disp('bluegreen = [.5 .8 .9]/.9;')
        disp('offwhite = .8*[1 1 1];')
        disp('sigma = 5.3;')
        disp('mu = [3.18 0 0];')
        disp('D = diag([-1 1 -1]);')
        disp('Z = [0 -1 0;  0 0 1; -1  0 0];')
        disp('scale = 2;')
        disp(' ')

        A = Aero.Animation;
        A.createBody('pa24-250_blue.ac','Ac3d');
        Body = A.Bodies{1};
        Plane = Body.Geometry.FaceVertexColorData;
        format compact
        for k = 1:97
            fprintf('%s #%d %s\n','%',k,Plane(k).name)
        
            disp('F = [ ...')
            if size(Plane(k).faces,1) == 1
                disp(Plane(k).faces(:))
            else
                disp(Plane(k).faces)
            end
            disp('];')
        
            disp('V = [ ...')
            disp(Plane(k).vertices)
            disp('];')
        
            if size(Plane(k).faces,1) == 1
                muc = Plane(k).cdata;
            else
                muc = mean(Plane(k).cdata);
            end
            if norm(Plane(k).cdata-muc) > 1e-6
                disp('cdata = [ ...')
                disp(Plane(k).cdata)
                disp('];')
            elseif isequal(muc,[0 0 1])
                fprintf('cdata = bluegreen;\n')
            elseif isequal(round(10*muc),8*[1 1 1])
                fprintf('cdata = offwhite;\n')
            else
                fprintf('cdata = [%0.4f %0.4f %0.4f];\n',muc)
            end
        
            mua = mean(Plane(k).alpha);
            if abs(k-91) < 2
                fprintf('alpha = 0;\n') 
            elseif mua == 1
                fprintf('alpha = 1;\n') 
            else
                fprintf('alpha = %0.4f;\n', mua)
            end
        
            disp(' ')
            disp('V = (V*D + mu)/sigma;')
            disp('V = scale*V*Z;')
            disp(' ')
            disp('patch(Parent = H, ...')
            disp('    Faces = F, ...')
            disp('    Vertices = V, ...')
            disp('    FaceAlpha = alpha, ...')
            disp('    FaceColor = cdata)')
            disp(' ')
        end
        disp(" ")
        disp("end")
        diary off
    end

    %% lib\mat4.m
    function txt = mat4(M)
        txt = newline;
        for k = 1:size(M,1)
            for j = 1:size(M,2)
                if M(k,j) == 0
                    txt = [txt sprintf('%6.0f',abs(M(k,j)))];
                elseif M(k,j) == round(M(k,j))
                    txt = [txt sprintf('%6.0f',M(k,j))];
                else
                    txt = [txt sprintf('%6.2f',M(k,j))];
                end
            end
            txt = [txt newline];
        end
    end
    %% lib\plane_prop.m
    function p51 = plane_prop

    o = NaN;
    % 51 Propeller
    p51.F = [ ...
    9   1   o   o 
    13   2   o   o 
    10   3   o   o 
    13  12   5   o 
    13   5   8   o 
    9   8   5   o 
    9   5   7   o 
    10   7   5   o 
    11  10   5   o 
    9   6   8   o 
    13   8   6   o 
    13   6  12   o 
    9   7   6   o 
    10   6   7   o 
    11   6  10   o 
    11   5   4   3 
    12   2   4   5 
    12   6   1   2 
    11   3   1   6 
    16  24  26  21 
    15  21  26  25 
    15  25  23  22 
    16  22  23  24 
    16  21  17   o 
    17  21  20   o 
    18  20  21   o 
    14  21  15   o 
    14  19  21   o 
    18  21  19   o 
    16  17  22   o 
    17  20  22   o 
    18  22  20   o 
    18  19  22   o 
    14  22  19   o 
    14  15  22   o 
    17  24   o   o 
    14  25   o   o 
    18  26   o   o 
    35  27   o   o 
    39  28   o   o 
    36  29   o   o 
    39  38  31   o 
    39  31  34   o 
    35  34  31   o 
    35  31  33   o 
    36  33  31   o 
    37  36  31   o 
    35  32  34   o 
    39  34  32   o 
    39  32  38   o 
    35  33  32   o 
    36  32  33   o 
    37  32  36   o 
    37  31  30  29 
    38  28  30  31 
    38  32  27  28 
    37  29  27  32 
    ];
    p51.V = [ ...
        0.3680   -0.0139   -0.0123
        0.4196   -0.0039    0.0039
        0.3143   -0.0033    0.0051
        0.3684    0.0019    0.0134
        0.3801   -0.3880    0.2444
        0.3538   -0.3957    0.2318
        0.3583   -0.7992    0.5470
        0.3759   -0.8557    0.4552
        0.3671   -0.8485    0.5141
        0.3549   -0.7580    0.5459
        0.3300   -0.3573    0.2942
        0.4039   -0.4264    0.1820
        0.3792   -0.8361    0.4189
        0.3792    0.7843    0.5093
        0.4039    0.3743    0.2729
        0.3300    0.4369    0.1570
        0.3549    0.8552    0.3781
        0.3671    0.8729    0.4724
        0.3759    0.8255    0.5081
        0.3583    0.8768    0.4132
        0.3538    0.4021    0.2214
        0.3801    0.4091    0.2084
        0.3684    0.0141   -0.0136
        0.3143    0.0095   -0.0051
        0.4196    0.0088   -0.0039
        0.3680   -0.0002    0.0128
        0.3680    0.0134   -0.0071
        0.4196   -0.0056   -0.0065
        0.3143   -0.0069   -0.0065
        0.3684   -0.0167   -0.0062
        0.3801   -0.0218   -0.4594
        0.3538   -0.0071   -0.4598
        0.3583   -0.0783   -0.9668
        0.3759    0.0295   -0.9698
        0.3671   -0.0251   -0.9930
        0.3549   -0.0979   -0.9305
        0.3300   -0.0803   -0.4577
        0.4039    0.0514   -0.4614
        0.3792    0.0511   -0.9347
    ];

    end
    %% lib\teapotControlPoints.m
    function quads = teapotControlPoints()
    % Function quads selects the control points that are used for each of the
    % 32 bezier patches

    quads = [ ... 
    % rim
        1   2   3   4 ;   5   6   7   8 ;   9  10  11  12 ;  13  14  15  16 ;
        4  17  18  19 ;   8  20  21  22 ;  12  23  24  25 ;  16  26  27  28 ;
    19  29  30  31 ;  22  32  33  34 ;  25  35  36  37 ;  28  38  39  40 ;
    31  41  42   1 ;  34  43  44   5 ;  37  45  46   9 ;  40  47  48  13 ;
    % body
    13  14  15  16 ;  49  50  51  52 ;  53  54  55  56 ;  57  58  59  60 ;
    16  26  27  28 ;  52  61  62  63 ;  56  64  65  66 ;  60  67  68  69 ;
    28  38  39  40 ;  63  70  71  72 ;  66  73  74  75 ;  69  76  77  78 ;
    40  47  48  13 ;  72  79  80  49 ;  75  81  82  53 ;  78  83  84  57 ;
    57  58  59  60 ;  85  86  87  88 ;  89  90  91  92 ;  93  94  95  96 ;
    60  67  68  69 ;  88  97  98  99 ;  92 100 101 102 ;  96 103 104 105 ;
    69  76  77  78 ;  99 106 107 108 ; 102 109 110 111 ; 105 112 113 114 ;
    78  83  84  57 ; 108 115 116  85 ; 111 117 118  89 ; 114 119 120  93 ;
    % handle
    121 122 123 124 ; 125 126 127 128 ; 129 130 131 132 ; 133 134 135 136 ;
    124 137 138 121 ; 128 139 140 125 ; 132 141 142 129 ; 136 143 144 133 ;
    133 134 135 136 ; 145 146 147 148 ; 149 150 151 152 ;  69 153 154 155 ;
    136 143 144 133 ; 148 156 157 145 ; 152 158 159 149 ; 155 160 161  69 ;
    % spout
    162 163 164 165 ; 166 167 168 169 ; 170 171 172 173 ; 174 175 176 177 ;
    165 178 179 162 ; 169 180 181 166 ; 173 182 183 170 ; 177 184 185 174 ;
    174 175 176 177 ; 186 187 188 189 ; 190 191 192 193 ; 194 195 196 197 ;
    177 184 185 174 ; 189 198 199 186 ; 193 200 201 190 ; 197 202 203 194 ;
    % lid
    204 204 204 204 ; 207 208 209 210 ; 211 211 211 211 ; 212 213 214 215 ;
    204 204 204 204 ; 210 217 218 219 ; 211 211 211 211 ; 215 220 221 222 ;
    204 204 204 204 ; 219 224 225 226 ; 211 211 211 211 ; 222 227 228 229 ;
    204 204 204 204 ; 226 230 231 207 ; 211 211 211 211 ; 229 232 233 212 ;
    212 213 214 215 ; 234 235 236 237 ; 238 239 240 241 ; 242 243 244 245 ;
    215 220 221 222 ; 237 246 247 248 ; 241 249 250 251 ; 245 252 253 254 ;
    222 227 228 229 ; 248 255 256 257 ; 251 258 259 260 ; 254 261 262 263 ;
    229 232 233 212 ; 257 264 265 234 ; 260 266 267 238 ; 263 268 269 242 ;
    % bottom
    270 270 270 270 ; 279 280 281 282 ; 275 276 277 278 ; 271 272 273 274 ;
    270 270 270 270 ; 282 289 290 291 ; 278 286 287 288 ; 274 283 284 285 ;
    270 270 270 270 ; 291 298 299 300 ; 288 295 296 297 ; 285 292 293 294 ;
    270 270 270 270 ; 300 305 306 279 ; 297 303 304 275 ; 294 301 302 271 ];

    quads = reshape(quads',4,4,32);

    end
    %% lib\teapotVertices.m
    function verts = teapotVertices
    % Function verts defines the control points for the generated bezier
    % patches.

    verts = [ ...
    1.4     0.     2.4     ;
    1.4    -0.784  2.4     ;
    0.784  -1.4    2.4     ;
    0.     -1.4    2.4     ;
    1.3375  0.     2.53125 ;
    1.3375 -0.749  2.53125 ;
    0.749  -1.3375 2.53125 ;
    0.     -1.3375 2.53125 ;
    1.4375  0.     2.53125 ;
    1.4375 -0.805  2.53125 ;
    0.805  -1.4375 2.53125 ;
    0.     -1.4375 2.53125 ;
    1.5     0.     2.4     ;
    1.5    -0.84   2.4     ;
    0.84   -1.5    2.4     ;
    0.     -1.5    2.4     ;
    -0.784  -1.4    2.4     ;
    -1.4    -0.784  2.4     ;
    -1.4     0.     2.4     ;
    -0.749  -1.3375 2.53125 ;
    -1.3375 -0.749  2.53125 ;
    -1.3375  0.0    2.53125 ;
    -0.805  -1.4375 2.53125 ;
    -1.4375 -0.805  2.53125 ;
    -1.4375  0.0    2.53125 ;
    -0.84   -1.5    2.4     ;
    -1.5    -0.84   2.4     ;
    -1.5     0.     2.4     ;
    -1.4     0.784  2.4     ;
    -0.784   1.4    2.4     ;
    0.      1.4    2.4     ;
    -1.3375  0.749  2.53125 ;
    -0.749   1.3375 2.53125 ;
    0.      1.3375 2.53125 ;
    -1.4375  0.805  2.53125 ;
    -0.805   1.4375 2.53125 ;
    0.      1.4375 2.53125 ;
    -1.5     0.84   2.4     ;
    -0.84    1.5    2.4     ;
    0.      1.5    2.4     ;
    0.784   1.4    2.4     ;
    1.4     0.784  2.4     ;
    0.749   1.3375 2.53125 ;
    1.3375  0.749  2.53125 ;
    0.805   1.4375 2.53125 ;
    1.4375  0.805  2.53125 ;
    0.84    1.5    2.4     ;
    1.5     0.84   2.4     ;
    1.75    0.     1.875   ;
    1.75   -0.98   1.875   ;
    0.98   -1.75   1.875   ;
    0.     -1.75   1.875   ;
    2.      0.     1.35    ;
    2.     -1.12   1.35    ;
    1.12   -2.     1.35    ;
    0.     -2.     1.35    ;
    2.      0.     0.9     ;
    2.     -1.12   0.9     ;
    1.12   -2.     0.9     ;
    0.     -2.     0.9     ;
    -0.98   -1.75   1.875   ;
    -1.75   -0.98   1.875   ;
    -1.75    0.     1.875   ;
    -1.12   -2.     1.35    ;
    -2.     -1.12   1.35    ;
    -2.      0.     1.35    ;
    -1.12   -2.     0.9     ;
    -2.     -1.12   0.9     ;
    -2.      0.     0.9     ;
    -1.75    0.98   1.875   ;
    -0.98    1.75   1.875   ;
    0.      1.75   1.875   ;
    -2.      1.12   1.35    ;
    -1.12    2.     1.35    ;
    0.      2.     1.35    ;
    -2.      1.12   0.9     ;
    -1.12    2.     0.9     ;
    0.0     2.     0.9     ;
    0.98    1.75   1.875   ;
    1.75    0.98   1.875   ;
    1.12    2.     1.35    ;
    2.      1.12   1.35    ;
    1.12    2.     0.9     ;
    2.      1.12   0.9     ;
    2.      0.     0.45    ;
    2.     -1.12   0.45    ;
    1.12   -2.     0.45    ;
    0.     -2.     0.45    ;
    1.5     0.     0.225   ;
    1.5    -0.84   0.225   ;
    0.84   -1.5    0.225   ;
    0.     -1.5    0.225   ;
    1.5     0.     0.15    ;
    1.5    -0.84   0.15    ;
    0.84   -1.5    0.15    ;
    0.0    -1.5    0.15    ;
    -1.12   -2.     0.45    ;
    -2.     -1.12   0.45    ;
    -2.      0.     0.45    ;
    -0.84   -1.5    0.225   ;
    -1.5    -0.84   0.225   ;
    -1.5     0.     0.225   ;
    -0.84   -1.5    0.15    ;
    -1.5    -0.84   0.15    ;
    -1.5     0.     0.15    ;
    -2.      1.12   0.45    ;
    -1.12    2.     0.45    ;
    0.      2.     0.45    ;
    -1.5     0.84   0.225   ;
    -0.84    1.5    0.225   ;
    0.      1.5    0.225   ;
    -1.5     0.84   0.15    ;
    -0.84    1.5    0.15    ;
    0.      1.5    0.15    ;
    1.12    2.     0.45    ;
    2.      1.12   0.45    ;
    0.84    1.5    0.225   ;
    1.5     0.84   0.225   ;
    0.84    1.5    0.15    ;
    1.5     0.84   0.15    ;
    -1.6     0.     2.025   ;
    -1.6    -0.3    2.025   ;
    -1.5    -0.3    2.25    ;
    -1.5     0      2.25    ;
    -2.3     0.     2.025   ;
    -2.3    -0.3    2.025   ;
    -2.5    -0.3    2.25    ;
    -2.5     0.     2.25    ;
    -2.7     0.     2.025   ;
    -2.7    -0.3    2.025   ;
    -3.     -0.3    2.25    ;
    -3.      0.     2.25    ;
    -2.7     0.     1.8     ;
    -2.7    -0.3    1.8     ;
    -3.     -0.3    1.8     ;
    -3.      0.     1.8     ;
    -1.5     0.3    2.25    ;
    -1.6     0.3    2.025   ;
    -2.5     0.3    2.25    ;
    -2.3     0.3    2.025   ;
    -3.      0.3    2.25    ;
    -2.7     0.3    2.025   ;
    -3.      0.3    1.8     ;
    -2.7     0.3    1.8     ;
    -2.7     0.     1.575   ;
    -2.7    -0.3    1.575   ;
    -3.     -0.3    1.35    ;
    -3.      0.     1.35    ;
    -2.5     0.     1.125   ;
    -2.5    -0.3    1.125   ;
    -2.65   -0.3    0.9375  ;
    -2.65    0.     0.9375  ;
    -2.     -0.3    0.9     ;
    -1.9    -0.3    0.6     ;
    -1.9     0.     0.6     ;
    -3.      0.3    1.35    ;
    -2.7     0.3    1.575   ;
    -2.65    0.3    0.9375  ;
    -2.5     0.3    1.125   ;
    -1.9     0.3    0.6     ;
    -2.      0.3    0.9     ;
    1.7     0.     1.425   ;
    1.7    -0.66   1.425   ;
    1.7    -0.66   0.6     ;
    1.7     0.     0.6     ;
    2.6     0.     1.425   ;
    2.6    -0.66   1.425   ;
    3.1    -0.66   0.825   ;
    3.1     0.     0.825   ;
    2.3     0.     2.1     ;
    2.3    -0.25   2.1     ;
    2.4    -0.25   2.025   ;
    2.4     0.     2.025   ;
    2.7     0.     2.4     ;
    2.7    -0.25   2.4     ;
    3.3    -0.25   2.4     ;
    3.3     0.     2.4     ;
    1.7     0.66   0.6     ;
    1.7     0.66   1.425   ;
    3.1     0.66   0.825   ;
    2.6     0.66   1.425   ;
    2.4     0.25   2.025   ;
    2.3     0.25   2.1     ;
    3.3     0.25   2.4     ;
    2.7     0.25   2.4     ;
    2.8     0.     2.475   ;
    2.8    -0.25   2.475   ;
    3.525  -0.25   2.49375 ;
    3.525   0.     2.49375 ;
    2.9     0.     2.475   ;
    2.9    -0.15   2.475   ;
    3.45   -0.15   2.5125  ;
    3.45    0.     2.5125  ;
    2.8     0.     2.4     ;
    2.8    -0.15   2.4     ;
    3.2    -0.15   2.4     ;
    3.2     0.     2.4     ;
    3.525   0.25   2.49375 ;
    2.8     0.25   2.475   ;
    3.45    0.15   2.5125  ;
    2.9     0.15   2.475   ;
    3.2     0.15   2.4     ;
    2.8     0.15   2.4     ;
    0.      0.     3.15    ;
    0.     -0.002  3.15    ;
    0.002   0.     3.15    ;
    0.8     0.     3.15    ;
    0.8    -0.45   3.15    ;
    0.45   -0.8    3.15    ;
    0.     -0.8    3.15    ;
    0.      0.     2.85    ;
    0.2     0.     2.7     ;
    0.2    -0.112  2.7     ;
    0.112  -0.2    2.7     ;
    0.     -0.2    2.7     ;
    -0.002   0.     3.15    ;
    -0.45   -0.8    3.15    ;
    -0.8    -0.45   3.15    ;
    -0.8     0.     3.15    ;
    -0.112  -0.2    2.7     ;
    -0.2    -0.112  2.7     ;
    -0.2     0.     2.7     ;
    0       0.002  3.15    ;
    -0.8     0.45   3.15    ;
    -0.45    0.8    3.15    ;
    0.      0.8    3.15    ;
    -0.2     0.112  2.7     ;
    -0.112   0.2    2.7     ;
    0.      0.2    2.7     ;
    0.45    0.8    3.15    ;
    0.8     0.45   3.15    ;
    0.112   0.2    2.7     ;
    0.2     0.112  2.7     ;
    0.4     0.     2.55    ;
    0.4    -0.224  2.55    ;
    0.224  -0.4    2.55    ;
    0.     -0.4    2.55    ;
    1.3     0.     2.55    ;
    1.3    -0.728  2.55    ;
    0.728  -1.3    2.55    ;
    0.     -1.3    2.55    ;
    1.3     0.     2.4     ;
    1.3    -0.728  2.4     ;
    0.728  -1.3    2.4     ;
    0.     -1.3    2.4     ;
    -0.224  -0.4    2.55    ;
    -0.4    -0.224  2.55    ;
    -0.4     0.     2.55    ;
    -0.728  -1.3    2.55    ;
    -1.3    -0.728  2.55    ;
    -1.3     0.     2.55    ;
    -0.728  -1.3    2.4     ;
    -1.3    -0.728  2.4     ;
    -1.3     0.     2.4     ;
    -0.4     0.224  2.55    ;
    -0.224   0.4    2.55    ;
    0.      0.4    2.55    ;
    -1.3     0.728  2.55    ;
    -0.728   1.3    2.55    ;
    0.      1.3    2.55    ;
    -1.3     0.728  2.4     ;
    -0.728   1.3    2.4     ;
    0.      1.3    2.4     ;
    0.224   0.4    2.55    ;
    0.4     0.224  2.55    ;
    0.728   1.3    2.55    ;
    1.3     0.728  2.55    ;
    0.728   1.3    2.4     ;
    1.3     0.728  2.4     ;
    0.      0.     0.      ;
    1.5     0.     0.15    ;
    1.5     0.84   0.15    ;
    0.84    1.5    0.15    ;
    0.      1.5    0.15    ;
    1.5     0.     0.075   ;
    1.5     0.84   0.075   ;
    0.83    1.5    0.075   ;
    0.      1.5    0.075   ;
    1.425   0.     0.      ;
    1.425   0.798  0.      ;
    0.798   1.425  0.      ;
    0.      1.425  0.      ;
    -0.84    1.5    0.15    ;
    -1.5     0.84   0.15    ;
    -1.5     0.     0.15    ;
    -0.84    1.5    0.075   ;
    -1.5     0.84   0.075   ;
    -1.5     0.     0.075   ;
    -0.798   1.425  0.      ;
    -1.425   0.798  0.      ;
    -1.425   0.     0.      ;
    -1.5    -0.84   0.15    ;
    -0.84   -1.5    0.15    ;
    0.     -1.5    0.15    ;
    -1.5    -0.84   0.075   ;
    -0.84   -1.5    0.075   ;
    0.     -1.5    0.075   ;
    -1.425  -0.798  0.      ;
    -0.798  -1.425  0.      ;
    0.     -1.425  0.      ;
    0.84   -1.5    0.15    ;
    1.5    -0.84   0.15    ;
    0.84   -1.5    0.075   ;
    1.5    -0.84   0.075   ;
    0.798  -1.425  0.      ;
    1.425  -0.798  0.      ];
    end
    %% EOF